import os
import threading
import logging
from datetime import datetime, timezone
from typing import Optional

import httpx
import pandas as pd
import numpy as np

logger = logging.getLogger(__name__)

# Alpaca Broker API — тот же токен что в мобильном приложении investlink
BROKER_SANDBOX_URL = 'https://broker-api.sandbox.alpaca.markets'
BROKER_LIVE_URL    = 'https://broker-api.alpaca.markets'
BROKER_SANDBOX_TOKEN = 'Basic Q0tNSklLNERCNkw1SUcxNEZBV0s6cDJzcWdDcGJvTEtCZzZTdVpId0wzZkNXZXlrQjhuVXFSblFKNzBWWg=='
BROKER_LIVE_TOKEN    = 'Basic Q0s1SDJFS0RIMEpBWTdRVU41VEI6dHhuZ3B3Nmdha05VaHdleXkxYkVhbzh5OUNKSFl1cUxhS0VScVVjTw=='

MARKET_SANDBOX_URL = 'https://data.sandbox.alpaca.markets'
MARKET_LIVE_URL    = 'https://data.alpaca.markets'

USE_SANDBOX  = os.getenv('ALPACA_SANDBOX', 'true').lower() != 'false'
BROKER_URL   = BROKER_SANDBOX_URL  if USE_SANDBOX else BROKER_LIVE_URL
BROKER_TOKEN = BROKER_SANDBOX_TOKEN if USE_SANDBOX else BROKER_LIVE_TOKEN
MARKET_URL   = MARKET_SANDBOX_URL  if USE_SANDBOX else MARKET_LIVE_URL

AUTH_BACKEND_URL = os.getenv('AUTH_BACKEND_URL', 'https://app12-us-sw.ivlk.io')

_BROKER_HEADERS = {
    'Authorization': BROKER_TOKEN,
    'Content-Type': 'application/json',
}
_MARKET_HEADERS = {
    'Authorization': BROKER_TOKEN,
    'Content-Type': 'application/json',
}

DEFAULT_SETTINGS = {
    'symbols': ['AAPL', 'MSFT', 'NVDA', 'GOOGL', 'AMZN'],
    'rsi_period': 14,
    'rsi_oversold': 30,
    'rsi_overbought': 70,
    'macd_fast': 12,
    'macd_slow': 26,
    'macd_signal': 9,
    'stop_loss_pct': 0.05,
    'take_profit_pct': 0.10,
    'max_position_pct': 0.20,
    'max_positions': 5,
    'check_interval_seconds': 60,
}


class BotEngine:
    def __init__(self):
        self.settings = DEFAULT_SETTINGS.copy()
        self.is_running = False
        self.cycle_count = 0
        self.last_check: Optional[str] = None
        self.trades: list[dict] = []
        self.signals: dict[str, dict] = {}
        self._thread: Optional[threading.Thread] = None
        self._stop_event = threading.Event()
        self._account_id: Optional[str] = None
        self._staging_token: Optional[str] = None

    # ── Auth ──────────────────────────────────────────────────────────────────

    async def login_staging(self, email: str, password: str):
        """Логин через наш бэкенд — получаем access token и broker_id."""
        async with httpx.AsyncClient(timeout=15.0, follow_redirects=True) as client:
            r = await client.post(
                f'{AUTH_BACKEND_URL}/auth_db/login/',
                json={'email': email, 'password': password},
            )
            r.raise_for_status()
            data = r.json()
            self._staging_token = data['tokens']['access']

            r2 = await client.get(
                f'{AUTH_BACKEND_URL}/auth/get_user_data',
                params={'email': email},
                headers={'Authorization': f'Bearer {self._staging_token}'},
            )
            if r2.status_code == 200:
                self._account_id = r2.json().get('broker_id')

            if not self._account_id:
                raise ValueError('broker_id не найден — аккаунт не подключён к Alpaca')

    # ── Indicators ────────────────────────────────────────────────────────────

    @staticmethod
    def _safe_float(v, default=0.0) -> float:
        try:
            f = float(v)
            return default if (f != f or f == float('inf') or f == float('-inf')) else f
        except Exception:
            return default

    def _rsi(self, prices: pd.Series, period: int) -> float:
        delta = prices.diff()
        gain = delta.where(delta > 0, 0.0)
        loss = -delta.where(delta < 0, 0.0)
        avg_g = gain.ewm(com=period - 1, min_periods=period).mean()
        avg_l = loss.ewm(com=period - 1, min_periods=period).mean()
        rs = avg_g / avg_l.replace(0, np.nan)
        return round(self._safe_float((100 - 100 / (1 + rs)).iloc[-1], 50.0), 2)

    def _macd(self, prices: pd.Series, fast: int, slow: int, sig: int):
        ema_f = prices.ewm(span=fast, adjust=False).mean()
        ema_s = prices.ewm(span=slow, adjust=False).mean()
        line = ema_f - ema_s
        signal = line.ewm(span=sig, adjust=False).mean()
        diff = line - signal
        crossover = 'none'
        if len(diff) >= 2:
            p = self._safe_float(diff.iloc[-2])
            c = self._safe_float(diff.iloc[-1])
            if p < 0 and c >= 0:
                crossover = 'bullish'
            elif p > 0 and c <= 0:
                crossover = 'bearish'
        return (
            round(self._safe_float(line.iloc[-1]), 4),
            round(self._safe_float(signal.iloc[-1]), 4),
            crossover,
        )

    # ── Market data ───────────────────────────────────────────────────────────

    def _prices_sync(self, symbol: str, limit: int = 100) -> pd.Series:
        with httpx.Client(timeout=15.0) as client:
            r = client.get(
                f'{MARKET_URL}/v2/stocks/{symbol}/bars',
                params={'timeframe': '1Hour', 'limit': limit, 'adjustment': 'raw'},
                headers=_MARKET_HEADERS,
            )
            r.raise_for_status()
            bars = r.json().get('bars', [])
            return pd.Series([b['c'] for b in bars])

    # ── Account ───────────────────────────────────────────────────────────────

    def get_account(self) -> dict:
        if not self._account_id:
            return {'equity': 0, 'cash': 0, 'buying_power': 0, 'day_pnl': 0, 'day_pnl_pct': 0}
        with httpx.Client(timeout=15.0) as client:
            r = client.get(
                f'{BROKER_URL}/v1/trading/accounts/{self._account_id}/account',
                headers=_BROKER_HEADERS,
            )
            r.raise_for_status()
            a = r.json()
            eq  = float(a.get('equity', 0))
            leq = float(a.get('last_equity', eq))
            pnl = round(eq - leq, 2)
            return {
                'equity': round(eq, 2),
                'cash': round(float(a.get('cash', 0)), 2),
                'buying_power': round(float(a.get('buying_power', 0)), 2),
                'day_pnl': pnl,
                'day_pnl_pct': round((pnl / leq) * 100, 2) if leq else 0.0,
            }

    def get_positions(self) -> list[dict]:
        if not self._account_id:
            return []
        with httpx.Client(timeout=15.0) as client:
            r = client.get(
                f'{BROKER_URL}/v1/trading/accounts/{self._account_id}/positions',
                headers=_BROKER_HEADERS,
            )
            r.raise_for_status()
            return [
                {
                    'symbol': p['symbol'],
                    'qty': float(p.get('qty', 0)),
                    'avg_entry': round(float(p.get('avg_entry_price', 0)), 2),
                    'current_price': round(float(p.get('current_price', 0)), 2),
                    'market_value': round(float(p.get('market_value', 0)), 2),
                    'unrealized_pnl': round(float(p.get('unrealized_pl', 0)), 2),
                    'unrealized_pnl_pct': round(float(p.get('unrealized_plpc', 0)) * 100, 2),
                    'side': p.get('side', 'long'),
                }
                for p in r.json()
            ]

    def get_trades(self) -> list[dict]:
        return list(reversed(self.trades))

    def get_signals(self) -> list[dict]:
        import math
        def _clean(v):
            if isinstance(v, float) and (math.isnan(v) or math.isinf(v)):
                return 0.0
            return v
        return [{k: _clean(val) for k, val in sig.items()} for sig in self.signals.values()]

    # ── Signal analysis ───────────────────────────────────────────────────────

    def _analyze(self, symbol: str) -> dict:
        try:
            prices = self._prices_sync(symbol)
            s = self.settings
            rsi  = self._rsi(prices, s['rsi_period'])
            macd, macd_sig, cross = self._macd(prices, s['macd_fast'], s['macd_slow'], s['macd_signal'])
            price = round(self._safe_float(prices.iloc[-1]), 2)

            if rsi < s['rsi_oversold'] and cross == 'bullish':
                signal = 'BUY'
            elif rsi > s['rsi_overbought'] and cross == 'bearish':
                signal = 'SELL'
            else:
                signal = 'HOLD'

            return {'symbol': symbol, 'price': price, 'rsi': rsi, 'macd': macd,
                    'macd_signal': macd_sig, 'crossover': cross, 'signal': signal,
                    'updated_at': datetime.now(timezone.utc).isoformat()}
        except Exception as e:
            logger.error(f'Analyze {symbol}: {e}')
            return {'symbol': symbol, 'price': 0, 'rsi': 50, 'macd': 0, 'macd_signal': 0,
                    'crossover': 'none', 'signal': 'HOLD',
                    'updated_at': datetime.now(timezone.utc).isoformat(), 'error': str(e)}

    # ── Orders ────────────────────────────────────────────────────────────────

    def _submit_order(self, symbol: str, qty: int, side: str):
        with httpx.Client(timeout=15.0) as client:
            r = client.post(
                f'{BROKER_URL}/v1/trading/accounts/{self._account_id}/orders',
                headers=_BROKER_HEADERS,
                json={'symbol': symbol, 'qty': str(qty), 'side': side,
                      'type': 'market', 'time_in_force': 'day'},
            )
            r.raise_for_status()

    def _execute(self, sig: dict):
        if not self._account_id:
            return
        symbol, signal, price = sig['symbol'], sig['signal'], sig['price']
        s = self.settings
        try:
            positions = self.get_positions()
            symbols   = [p['symbol'] for p in positions]
            if signal == 'BUY':
                if symbol in symbols or len(positions) >= s['max_positions']:
                    return
                qty = int(self.get_account()['equity'] * s['max_position_pct'] / price)
                if qty < 1:
                    return
                self._submit_order(symbol, qty, 'buy')
                self.trades.append({
                    'time': datetime.now(timezone.utc).isoformat(),
                    'symbol': symbol, 'side': 'BUY', 'qty': qty, 'price': price,
                    'amount': round(qty * price, 2),
                    'reason': f"RSI={sig['rsi']:.1f}, MACD bullish cross", 'pnl': None,
                })
            elif signal == 'SELL':
                pos = next((p for p in positions if p['symbol'] == symbol), None)
                if pos is None:
                    return
                qty = int(pos['qty'])
                self._submit_order(symbol, qty, 'sell')
                self.trades.append({
                    'time': datetime.now(timezone.utc).isoformat(),
                    'symbol': symbol, 'side': 'SELL', 'qty': qty, 'price': price,
                    'amount': round(qty * price, 2),
                    'reason': f"RSI={sig['rsi']:.1f}, MACD bearish cross",
                    'pnl': round((price - pos['avg_entry']) * qty, 2),
                })
        except Exception as e:
            logger.error(f'Order {symbol}: {e}')

    def _check_risk(self):
        s = self.settings
        try:
            for pos in self.get_positions():
                pct = pos['unrealized_pnl_pct'] / 100
                reason = None
                if pct <= -s['stop_loss_pct']:
                    reason = f"Stop-loss ({pct*100:.1f}%)"
                elif pct >= s['take_profit_pct']:
                    reason = f"Take-profit ({pct*100:.1f}%)"
                if reason:
                    qty = int(pos['qty'])
                    self._submit_order(pos['symbol'], qty, 'sell')
                    self.trades.append({
                        'time': datetime.now(timezone.utc).isoformat(),
                        'symbol': pos['symbol'], 'side': 'SELL', 'qty': qty,
                        'price': pos['current_price'], 'amount': round(pos['market_value'], 2),
                        'reason': reason, 'pnl': round(pos['unrealized_pnl'], 2),
                    })
        except Exception as e:
            logger.error(f'Risk check: {e}')

    # ── Bot loop ──────────────────────────────────────────────────────────────

    def _loop(self):
        logger.info('Bot started')
        while not self._stop_event.is_set():
            try:
                self._check_risk()
                for symbol in self.settings['symbols']:
                    sig = self._analyze(symbol)
                    self.signals[symbol] = sig
                    if sig['signal'] in ('BUY', 'SELL'):
                        self._execute(sig)
                self.cycle_count += 1
                self.last_check = datetime.now(timezone.utc).isoformat()
            except Exception as e:
                logger.error(f'Cycle: {e}')
            self._stop_event.wait(self.settings['check_interval_seconds'])
        logger.info('Bot stopped')

    def start(self):
        if self.is_running:
            return
        self._stop_event.clear()
        self._thread = threading.Thread(target=self._loop, daemon=True)
        self._thread.start()
        self.is_running = True

    def stop(self):
        self._stop_event.set()
        self.is_running = False

    def get_status(self) -> dict:
        return {
            'running': self.is_running,
            'cycle_count': self.cycle_count,
            'last_check': self.last_check,
            'symbols': self.settings['symbols'],
            'account_id': self._account_id,
        }

    def update_keys(self, api_key: str, secret_key: str):
        """Placeholder — бот использует Broker токен, не личные ключи."""
        pass
