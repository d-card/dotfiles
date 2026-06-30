"""Plan listing routes."""
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from database import get_db
from models import Plan

router = APIRouter()


class PlanResponse(BaseModel):
    id: str
    name: str
    product_type: str
    cpu_cores: int
    ram_mb: int
    disk_gb: int
    price_cents: int
    stripe_price_id: str | None


class PlansResponse(BaseModel):
    vps: list[PlanResponse]
    gameserver: list[PlanResponse]


@router.get("", response_model=PlansResponse)
def list_plans(db: Session = Depends(get_db)):
    plans = db.query(Plan).filter(Plan.is_active == 1).all()

    vps = [p for p in plans if p.product_type == "vps"]
    gs = [p for p in plans if p.product_type == "gameserver"]

    return PlansResponse(
        vps=[PlanResponse(**p.__dict__) for p in vps],
        gameserver=[PlanResponse(**p.__dict__) for p in gs],
    )
