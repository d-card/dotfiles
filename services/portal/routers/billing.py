"""Billing routes — Stripe webhook and checkout session."""
import stripe
from fastapi import APIRouter, Request, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session
from database import get_db
from models import User, Plan, Payment
from config import settings

router = APIRouter()

stripe.api_key = settings.stripe_secret_key


class CheckoutRequest(BaseModel):
    plan_id: str


@router.post("/checkout")
async def create_checkout(
    req: CheckoutRequest,
    request: Request,
):
    """Create a Stripe Checkout session for a plan. (PoC: returns a placeholder)"""
    if not settings.stripe_secret_key:
        raise HTTPException(status_code=501, detail="Stripe not configured")

    # TODO: Full Stripe Checkout integration
    # session = stripe.checkout.Session.create(
    #     mode="subscription",
    #     line_items=[{"price": plan.stripe_price_id, "quantity": 1}],
    #     success_url="...",
    #     cancel_url="...",
    # )
    # return {"url": session.url}

    return {"url": "https://stripe.com/checkout-placeholder"}


@router.post("/webhook")
async def stripe_webhook(request: Request):
    """Handle Stripe webhook events."""
    if not settings.stripe_webhook_secret:
        return {"status": "skipped", "reason": "Stripe not configured"}

    payload = await request.body()
    sig = request.headers.get("stripe-signature", "")

    try:
        event = stripe.Webhook.construct_event(
            payload, sig, settings.stripe_webhook_secret
        )
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid signature")

    # Handle events
    match event.type:
        case "invoice.paid":
            pass  # TODO: mark payment, activate instance
        case "invoice.payment_failed":
            pass  # TODO: suspend instance after grace period
        case "customer.subscription.deleted":
            pass  # TODO: delete instance

    return {"status": "ok", "type": event.type}
