# Financial Modeling Prep (FMP) — интеграция для бэкенда

## Зачем

Yahoo Finance даёт rate limit / бан IP при burst-запросах с сервера. FMP — платный API с ключом, стабильный, поддерживает batch-запросы до 50 тикеров за один вызов.

## API Key

```
rnBntzheijvbhAlufqVgDSYivYmJYoIE
```

## Base URL

```
https://financialmodelingprep.com/stable/
```

Авторизация — query param `?apikey=KEY` в каждом запросе.

---

## Лимиты

| Тариф | Запросов/день | Цена |
|-------|---------------|------|
| Бесплатно | 250 | $0 |
| Starter | 10,000 | $19/mo |

250 req/day хватит на старте. Один portfolio-builder = 1 запрос (batch).

---

## Эндпоинты которые нам нужны

### 1. Batch Quote (цены нескольких тикеров за 1 запрос)

**Используется в:** portfolio-builder, analyze/{ticker}

```
GET https://financialmodelingprep.com/stable/batch-quote?symbols=AAPL,VOO,BND,MSFT,GOOGL&apikey=rnBntzheijvbhAlufqVgDSYivYmJYoIE
```

**Ответ:**
```json
[
  {
    "symbol": "AAPL",
    "name": "Apple Inc.",
    "price": 189.50,
    "changesPercentage": 1.25,
    "change": 2.34,
    "dayLow": 187.10,
    "dayHigh": 190.80,
    "yearHigh": 199.62,
    "yearLow": 124.17,
    "marketCap": 2950000000000,
    "volume": 54320000,
    "avgVolume": 58000000,
    "exchange": "NASDAQ",
    "open": 188.00,
    "previousClose": 187.16,
    "pe": 31.2,
    "sharesOutstanding": 15550000000
  }
]
```

**Лимит:** до 50 тикеров через запятую.

### 2. Single Quote (один тикер)

**Используется в:** analyze/{ticker} для получения цены

```
GET https://financialmodelingprep.com/stable/quote?symbol=AAPL&apikey=rnBntzheijvbhAlufqVgDSYivYmJYoIE
```

Ответ — тот же формат, массив из одного элемента.

### 3. Technical Indicators (если нужны RSI, SMA, MACD с сервера)

```
GET https://financialmodelingprep.com/stable/technical-indicator/1day/AAPL?type=rsi&period=14&apikey=rnBntzheijvbhAlufqVgDSYivYmJYoIE
```

Доступные типы: `rsi`, `sma`, `ema`, `macd`, `adx`, `williams`, `stochastic`

---

## Как заменить Yahoo на FMP

### Portfolio Builder (`POST /analyze/portfolio-builder`)

**Было (Yahoo):**
```python
import yfinance as yf

# N отдельных запросов или один download
data = yf.download(tickers=["VOO", "AAPL", "BND"], period="1d")
```

**Стало (FMP):**
```python
import httpx

FMP_KEY = "rnBntzheijvbhAlufqVgDSYivYmJYoIE"
FMP_BASE = "https://financialmodelingprep.com/stable"

async def get_batch_prices(tickers: list[str]) -> dict[str, float]:
    """Один запрос — все цены."""
    symbols = ",".join(tickers)
    url = f"{FMP_BASE}/batch-quote?symbols={symbols}&apikey={FMP_KEY}"

    async with httpx.AsyncClient() as client:
        resp = await client.get(url)
        resp.raise_for_status()

    return {item["symbol"]: item["price"] for item in resp.json()}
```

**Использование в portfolio-builder:**
```python
# 1. Claude возвращает allocations с тикерами и процентами
allocations = claude_response["allocations"]
tickers = [a["ticker"] for a in allocations]

# 2. Один batch-запрос к FMP
prices = await get_batch_prices(tickers)  # {"VOO": 435.50, "AAPL": 189.50, ...}

# 3. Рассчитать amount и shares
for a in allocations:
    price = prices.get(a["ticker"], 0)
    a["price"] = price
    a["amount"] = round(total_amount * a["percentage"] / 100, 2)
    a["shares"] = round(a["amount"] / price, 4) if price > 0 else 0
```

### Analyze Ticker (`GET /analyze/{ticker}`)

**Было:**
```python
stock = yf.Ticker(ticker)
price = stock.info.get("currentPrice", 0)
```

**Стало:**
```python
async def get_price(ticker: str) -> dict:
    url = f"{FMP_BASE}/quote?symbol={ticker}&apikey={FMP_KEY}"
    async with httpx.AsyncClient() as client:
        resp = await client.get(url)
        resp.raise_for_status()
    data = resp.json()
    if not data:
        raise ValueError(f"Ticker not found: {ticker}")
    return data[0]  # {"symbol": "AAPL", "price": 189.50, ...}
```

---

## Кэширование (рекомендация)

Даже с FMP стоит кэшировать цены на 5–10 минут чтобы экономить лимит:

```python
from cachetools import TTLCache

# Кэш на 600 секунд (10 минут), максимум 500 тикеров
_price_cache = TTLCache(maxsize=500, ttl=600)

async def get_price_cached(ticker: str) -> float:
    if ticker in _price_cache:
        return _price_cache[ticker]

    data = await get_price(ticker)
    price = data["price"]
    _price_cache[ticker] = price
    return price

async def get_batch_prices_cached(tickers: list[str]) -> dict[str, float]:
    result = {}
    missing = []

    for t in tickers:
        if t in _price_cache:
            result[t] = _price_cache[t]
        else:
            missing.append(t)

    if missing:
        fresh = await get_batch_prices(missing)
        for t, p in fresh.items():
            _price_cache[t] = p
            result[t] = p

    return result
```

С кэшом 10 мин: 250 req/day хватит на ~2500 уникальных запросов (каждый тикер запрашивается раз в 10 мин).

---

## Маппинг полей FMP → наш API

| Наш ответ | FMP поле |
|-----------|----------|
| `price` | `price` |
| `change_1m` | нет напрямую, считать из historical или использовать `changesPercentage` (1 day) |
| P/E (для скринера) | `pe` |
| Market Cap | `marketCap` |
| Volume | `volume` |

Для `change_1m` (месячное изменение) — можно взять historical endpoint:
```
GET /stable/historical-price-eod/full?symbol=AAPL&from=2026-02-24&to=2026-03-24&apikey=KEY
```

---

## Checklist миграции

- [ ] Установить `httpx` (или использовать существующий HTTP-клиент)
- [ ] Добавить `FMP_KEY` в env переменные (не хардкодить)
- [ ] Заменить `yfinance` вызовы на FMP в:
  - [ ] `POST /analyze/portfolio-builder` — batch quote
  - [ ] `GET /analyze/{ticker}` — single quote
- [ ] Добавить кэш (`cachetools.TTLCache` или Redis)
- [ ] Добавить fallback: если FMP недоступен → вернуть `503 marketDataUnavailable`
- [ ] Убрать `yfinance` из `requirements.txt` когда всё работает
