import re

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.dependencies import get_db
from app.domain.schemas import (
    AnalysisHistoryItem,
    AnalysisResponse,
    PortfolioBuilderRequest,
    PortfolioBuilderResponse,
    PortfolioRequest,
    PortfolioResponse,
)
from app.infrastructure.claude_client import complete
from app.infrastructure.market_data import fetch_ohlcv
from app.repositories.analysis_repository import AnalysisRepository
from app.services.analysis_service import ANALYSIS_MODES, build_rag_prompt, calc_indicators, calc_score
from app.services.portfolio_builder_service import (
    STRATEGY_METRICS,
    build_allocations,
    build_builder_prompt,
    get_rag_context,
    parse_claude_response,
)
from app.services.portfolio_service import build_portfolio_rag_prompt

router = APIRouter()

_TICKER_RE = re.compile(r"^[A-Z]{1,10}$")


@router.post("/portfolio-builder", response_model=PortfolioBuilderResponse)
async def portfolio_builder(req: PortfolioBuilderRequest, db: Session = Depends(get_db)):
    if req.amount <= 0:
        raise HTTPException(status_code=400, detail={"error": "invalidAmount"})

    strategy = req.risk_strategy.value
    rag_context = get_rag_context()
    prompt = build_builder_prompt(req.amount, strategy, rag_context)

    try:
        response_text = complete(prompt)
    except Exception as e:
        raise HTTPException(status_code=503, detail={"error": "aiUnavailable", "message": str(e)})

    try:
        claude_data = parse_claude_response(response_text)
        allocations = build_allocations(claude_data["allocations"], req.amount)
    except Exception as e:
        raise HTTPException(status_code=500, detail={"error": "parseError", "message": str(e)})

    fallback = STRATEGY_METRICS[strategy]
    analysis = claude_data.get("analysis", "")

    AnalysisRepository(db).save(
        ticker="PORTFOLIO_BUILDER",
        mode="portfolio_builder",
        analysis=analysis,
    )

    return PortfolioBuilderResponse(
        strategy=strategy,
        total_amount=round(req.amount, 2),
        expected_return_min=claude_data.get("expected_return_min", fallback["return_min"]),
        expected_return_max=claude_data.get("expected_return_max", fallback["return_max"]),
        max_drawdown=claude_data.get("max_drawdown", fallback["max_drawdown"]),
        rebalancing_frequency=claude_data.get("rebalancing_frequency", fallback["rebalancing"]),
        allocations=allocations,
        analysis=analysis,
    )


@router.post("/portfolio", response_model=PortfolioResponse)
async def analyze_portfolio(req: PortfolioRequest, db: Session = Depends(get_db)):
    if not req.positions:
        raise HTTPException(status_code=400, detail="Список позиций пуст")

    total_value = sum(p.market_value for p in req.positions)
    total_pnl = sum(p.pnl for p in req.positions)
    profitable = sum(1 for p in req.positions if p.pnl > 0)

    try:
        prompt = build_portfolio_rag_prompt(req.positions, req.context)
        analysis = complete(prompt)
    except Exception as e:
        analysis = f"AI анализ временно недоступен: {str(e)}"

    AnalysisRepository(db).save(ticker="PORTFOLIO", mode="portfolio", analysis=analysis)

    return PortfolioResponse(
        mode="portfolio",
        mode_description=ANALYSIS_MODES["portfolio"]["description"],
        total_value=round(total_value, 2),
        total_pnl=round(total_pnl, 2),
        positions_count=len(req.positions),
        profitable_positions=profitable,
        analysis=analysis,
    )


@router.get("/{ticker}", response_model=AnalysisResponse)
async def analyze(
    ticker: str,
    mode: str = "full",
    context: str = "",
    db: Session = Depends(get_db),
):
    ticker = ticker.upper().strip()

    if not _TICKER_RE.match(ticker):
        raise HTTPException(status_code=400, detail={"error": "invalidTicker"})
    if mode not in ANALYSIS_MODES:
        raise HTTPException(status_code=400, detail={"error": "invalidMode"})

    try:
        df = fetch_ohlcv(ticker)
    except ValueError as e:
        raise HTTPException(status_code=404, detail={"error": "tickerNotFound", "message": str(e)})

    ind = calc_indicators(df)
    score = calc_score(ind)
    trend = "Bullish" if ind["sma20"] > ind["sma50"] else "Bearish"

    try:
        prompt = build_rag_prompt(ticker, ind, mode, context)
        analysis = complete(prompt)
    except Exception as e:
        analysis = f"AI анализ временно недоступен: {str(e)}"

    AnalysisRepository(db).save(
        ticker=ticker, mode=mode, analysis=analysis,
        score=score, trend=trend, price=ind["price"],
    )

    return AnalysisResponse(
        ticker=ticker,
        mode=mode,
        mode_description=ANALYSIS_MODES[mode]["description"],
        price=round(ind["price"], 2),
        change_1m=round(ind["change_1m"], 1),
        rsi=round(ind["rsi"], 1),
        sma20=round(ind["sma20"], 2),
        sma50=round(ind["sma50"], 2),
        macd=round(ind["macd"], 4),
        macd_signal=round(ind["macd_signal"], 4),
        bb_upper=round(ind["bb_upper"], 2),
        bb_lower=round(ind["bb_lower"], 2),
        atr=round(ind["atr"], 2),
        trend=trend,
        score=score,
        analysis=analysis,
    )


@router.get("/{ticker}/history", response_model=list[AnalysisHistoryItem])
async def get_history(ticker: str, limit: int = 10, db: Session = Depends(get_db)):
    ticker = ticker.upper().strip()
    return AnalysisRepository(db).get_by_ticker(ticker, limit=limit)
