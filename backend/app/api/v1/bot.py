from __future__ import annotations

from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from pydantic import BaseModel

from app.config import settings
from app.bot_engine import BotEngine

router = APIRouter()
security = HTTPBearer()

bot = BotEngine()

# ── JWT helpers ───────────────────────────────────────────────────────────────

def _make_token(email: str) -> str:
    return jwt.encode(
        {"sub": email, "exp": datetime.utcnow() + timedelta(hours=24)},
        settings.bot_jwt_secret,
        algorithm="HS256",
    )


def _get_email(creds: HTTPAuthorizationCredentials = Depends(security)) -> str:
    try:
        payload = jwt.decode(creds.credentials, settings.bot_jwt_secret, algorithms=["HS256"])
        email = payload.get("sub")
        if not email:
            raise HTTPException(status_code=401, detail="Invalid token")
        return email
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")


# ── Auth ──────────────────────────────────────────────────────────────────────

class LoginRequest(BaseModel):
    email: str
    password: str


@router.post("/auth/login")
async def bot_login(req: LoginRequest):
    import httpx
    try:
        await bot.login_staging(req.email, req.password)
    except httpx.HTTPStatusError:
        raise HTTPException(status_code=401, detail="Wrong credentials")
    except httpx.RequestError:
        raise HTTPException(status_code=503, detail="Auth service unavailable")
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    return {"access_token": _make_token(req.email), "token_type": "bearer"}


# ── Data ──────────────────────────────────────────────────────────────────────

@router.get("/account")
def bot_account(_: str = Depends(_get_email)):
    return bot.get_account()


@router.get("/positions")
def bot_positions(_: str = Depends(_get_email)):
    return bot.get_positions()


@router.get("/signals")
def bot_signals(_: str = Depends(_get_email)):
    return bot.get_signals()


@router.get("/trades")
def bot_trades(_: str = Depends(_get_email)):
    return bot.get_trades()


@router.get("/status")
def bot_status(_: str = Depends(_get_email)):
    return bot.get_status()


# ── Control ───────────────────────────────────────────────────────────────────

@router.post("/start")
def bot_start(_: str = Depends(_get_email)):
    bot.start()
    return {"status": "started"}


@router.post("/stop")
def bot_stop(_: str = Depends(_get_email)):
    bot.stop()
    return {"status": "stopped"}


# ── Settings ──────────────────────────────────────────────────────────────────

class SettingsBody(BaseModel):
    symbols: list[str] | None = None
    rsi_period: int | None = None
    rsi_oversold: float | None = None
    rsi_overbought: float | None = None
    macd_fast: int | None = None
    macd_slow: int | None = None
    macd_signal: int | None = None
    stop_loss_pct: float | None = None
    take_profit_pct: float | None = None
    max_position_pct: float | None = None
    max_positions: int | None = None
    check_interval_seconds: int | None = None


@router.get("/settings")
def get_bot_settings(_: str = Depends(_get_email)):
    return bot.settings


@router.put("/settings")
def update_bot_settings(body: SettingsBody, _: str = Depends(_get_email)):
    bot.settings.update(body.model_dump(exclude_none=True))
    return bot.settings


class KeysBody(BaseModel):
    api_key: str
    secret_key: str


@router.put("/settings/keys")
def update_bot_keys(body: KeysBody, _: str = Depends(_get_email)):
    bot.update_keys(body.api_key, body.secret_key)
    return {"status": "updated"}
