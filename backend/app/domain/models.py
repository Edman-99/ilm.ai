import enum
import uuid
from datetime import datetime

from sqlalchemy import Column, Date, DateTime, Enum, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import ARRAY as PG_ARRAY
from sqlalchemy import JSON

from app.infrastructure.database import Base


class Plan(str, enum.Enum):
    free = "free"
    pro = "pro"
    premium = "premium"


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String, unique=True, nullable=False, index=True)
    password = Column(String, nullable=False)  # bcrypt hash
    plan = Column(Enum(Plan), nullable=False, default=Plan.free)
    daily_usage = Column(Integer, nullable=False, default=0)
    last_usage_date = Column(Date, nullable=True)  # for lazy daily reset at 00:00 UTC
    created_at = Column(DateTime, default=datetime.utcnow)

    analyses = relationship("AnalysisHistory", back_populates="user")


class Strategy(Base):
    __tablename__ = "strategies"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_email = Column(String(255), nullable=False, index=True)
    name = Column(String(100), nullable=False)
    description = Column(Text, nullable=False, default="")
    icon = Column(String(50), nullable=False, default="pie_chart")
    color = Column(String(7), nullable=False, default="#6366F1")
    target_pct = Column(Float, nullable=False, default=0.0)  # target allocation %
    notes = Column(Text, nullable=False, default="")
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    positions = relationship("StrategyPosition", back_populates="strategy", cascade="all, delete-orphan")


class StrategyPosition(Base):
    """Individual ticker allocation within a strategy."""
    __tablename__ = "strategy_positions"

    id = Column(Integer, primary_key=True, index=True)
    strategy_id = Column(String, ForeignKey("strategies.id", ondelete="CASCADE"), nullable=False, index=True)
    symbol = Column(String(20), nullable=False)
    qty = Column(Float, nullable=False, default=0.0)  # number of shares assigned to this strategy

    strategy = relationship("Strategy", back_populates="positions")


class Lead(Base):
    __tablename__ = "leads"

    id = Column(Integer, primary_key=True, index=True)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    email = Column(String(255), nullable=False, index=True)
    whatsapp = Column(String(50), nullable=False)
    source = Column(String(50), nullable=False, default="ai_analysis")
    created_at = Column(DateTime, default=datetime.utcnow)


class AnalysisHistory(Base):
    __tablename__ = "analysis_history"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=True)  # nullable until auth is added
    ticker = Column(String, nullable=False, index=True)
    mode = Column(String, nullable=False)
    score = Column(Integer, nullable=True)
    trend = Column(String, nullable=True)
    price = Column(Float, nullable=True)
    analysis = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="analyses")
