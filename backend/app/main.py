import asyncio
import json
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1 import analysis, strategies, leads as leads_router, proxy as proxy_router
from app.api.v1 import bot as bot_router
from app.config import settings
from app.domain import models
from app.infrastructure.database import engine
from app.services.analysis_service import ANALYSIS_MODES

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

# ── WebSocket clients ─────────────────────────────────────────────────────────

ws_clients: list[WebSocket] = []


async def _broadcast_loop():
    while True:
        await asyncio.sleep(5)
        if not ws_clients:
            continue
        try:
            payload = json.dumps({
                "type": "update",
                "account": bot_router.bot.get_account(),
                "positions": bot_router.bot.get_positions(),
                "signals": bot_router.bot.get_signals(),
                "trades": bot_router.bot.get_trades()[:30],
                "bot_status": bot_router.bot.get_status(),
            })
            dead = []
            for ws in ws_clients:
                try:
                    await ws.send_text(payload)
                except Exception:
                    dead.append(ws)
            for ws in dead:
                ws_clients.remove(ws)
        except Exception as e:
            logging.error(f"Broadcast: {e}")


# ── Lifespan ──────────────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    models.Base.metadata.create_all(bind=engine)
    task = asyncio.create_task(_broadcast_loop())
    yield
    task.cancel()


# ── App ───────────────────────────────────────────────────────────────────────

app = FastAPI(title="ILM — AI Stock Analyzer + Trading Bot", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization", "ngrok-skip-browser-warning"],
)

# AI Stock Analyzer routes
app.include_router(analysis.router,      prefix="/analyze",    tags=["analysis"])
app.include_router(strategies.router,    prefix="/strategies", tags=["strategies"])
app.include_router(leads_router.router,  prefix="/leads",      tags=["leads"])
app.include_router(proxy_router.router,  prefix="/ivlk",       tags=["proxy"])

# Trading Bot routes
app.include_router(bot_router.router, prefix="/api/bot", tags=["bot"])


# ── WebSocket ─────────────────────────────────────────────────────────────────

@app.websocket("/ws/updates")
async def ws_endpoint(ws: WebSocket):
    await ws.accept()
    ws_clients.append(ws)
    try:
        while True:
            await ws.receive_text()
    except WebSocketDisconnect:
        if ws in ws_clients:
            ws_clients.remove(ws)


# ── Common endpoints ──────────────────────────────────────────────────────────

@app.get("/modes", tags=["analysis"])
async def get_modes():
    return {k: v["description"] for k, v in ANALYSIS_MODES.items()}


@app.get("/health")
async def health():
    return {"status": "ok"}
