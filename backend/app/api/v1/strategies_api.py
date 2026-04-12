from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, Header, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.domain.models import Strategy, StrategyPosition
from app.infrastructure.database import get_db

router = APIRouter()

# ── Auth helper ──────────────────────────────────────────────────────────────

def _get_user_email(x_user_email: str = Header(..., alias="X-User-Email")) -> str:
    """Extract user email from request header."""
    if not x_user_email or "@" not in x_user_email:
        raise HTTPException(status_code=401, detail="Missing or invalid X-User-Email header")
    return x_user_email.lower().strip()


# ── Schemas ───────────────────────────────────────────────────────────────────

class PositionIn(BaseModel):
    symbol: str
    qty: float


class StrategyCreate(BaseModel):
    name: str
    description: str = ""
    icon: str = "pie_chart"
    color: str = "#6366F1"
    target_pct: float = 0.0
    notes: str = ""
    positions: list[PositionIn] = []


class StrategyUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    icon: Optional[str] = None
    color: Optional[str] = None
    target_pct: Optional[float] = None
    notes: Optional[str] = None
    positions: Optional[list[PositionIn]] = None


class PositionOut(BaseModel):
    id: int
    symbol: str
    qty: float


class StrategyOut(BaseModel):
    id: str
    name: str
    description: str
    icon: str
    color: str
    target_pct: float
    notes: str
    positions: list[PositionOut]
    created_at: str
    updated_at: str


def _to_out(s: Strategy) -> StrategyOut:
    return StrategyOut(
        id=s.id,
        name=s.name,
        description=s.description,
        icon=s.icon,
        color=s.color,
        target_pct=s.target_pct,
        notes=s.notes,
        positions=[PositionOut(id=p.id, symbol=p.symbol, qty=p.qty) for p in s.positions],
        created_at=s.created_at.isoformat() if s.created_at else "",
        updated_at=s.updated_at.isoformat() if s.updated_at else "",
    )


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get("", response_model=list[StrategyOut])
def list_strategies(
    db: Session = Depends(get_db),
    user_email: str = Depends(_get_user_email),
):
    strategies = (
        db.query(Strategy)
        .filter(Strategy.user_email == user_email)
        .order_by(Strategy.created_at)
        .all()
    )
    return [_to_out(s) for s in strategies]


@router.post("", response_model=StrategyOut, status_code=201)
def create_strategy(
    data: StrategyCreate,
    db: Session = Depends(get_db),
    user_email: str = Depends(_get_user_email),
):
    strategy = Strategy(
        user_email=user_email,
        name=data.name,
        description=data.description,
        icon=data.icon,
        color=data.color,
        target_pct=data.target_pct,
        notes=data.notes,
    )
    db.add(strategy)
    db.flush()  # get strategy.id before adding positions

    for p in data.positions:
        db.add(StrategyPosition(strategy_id=strategy.id, symbol=p.symbol.upper(), qty=p.qty))

    db.commit()
    db.refresh(strategy)
    return _to_out(strategy)


@router.put("/{strategy_id}", response_model=StrategyOut)
def update_strategy(
    strategy_id: str,
    data: StrategyUpdate,
    db: Session = Depends(get_db),
    user_email: str = Depends(_get_user_email),
):
    strategy = db.query(Strategy).filter(
        Strategy.id == strategy_id,
        Strategy.user_email == user_email,
    ).first()
    if not strategy:
        raise HTTPException(status_code=404, detail="Strategy not found")

    if data.name is not None:
        strategy.name = data.name
    if data.description is not None:
        strategy.description = data.description
    if data.icon is not None:
        strategy.icon = data.icon
    if data.color is not None:
        strategy.color = data.color
    if data.target_pct is not None:
        strategy.target_pct = data.target_pct
    if data.notes is not None:
        strategy.notes = data.notes
    strategy.updated_at = datetime.utcnow()

    # Replace positions if provided
    if data.positions is not None:
        for pos in strategy.positions:
            db.delete(pos)
        db.flush()
        for p in data.positions:
            db.add(StrategyPosition(strategy_id=strategy.id, symbol=p.symbol.upper(), qty=p.qty))

    db.commit()
    db.refresh(strategy)
    return _to_out(strategy)


@router.delete("/{strategy_id}", status_code=204)
def delete_strategy(
    strategy_id: str,
    db: Session = Depends(get_db),
    user_email: str = Depends(_get_user_email),
):
    strategy = db.query(Strategy).filter(
        Strategy.id == strategy_id,
        Strategy.user_email == user_email,
    ).first()
    if not strategy:
        raise HTTPException(status_code=404, detail="Strategy not found")
    db.delete(strategy)
    db.commit()
