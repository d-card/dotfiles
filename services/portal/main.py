"""
Hosting Portal — FastAPI application.

Self-service VPS and game server management.
Talks to Incus REST API and Pterodactyl API.
"""
import os
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse

from database import engine, Base
from config import settings
from routers import auth, instances, billing, plans


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create tables on startup (PoC — use alembic in production)
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(
    title="Zentryx Hosting",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(plans.router, prefix="/plans", tags=["plans"])
app.include_router(instances.router, prefix="/instances", tags=["instances"])
app.include_router(billing.router, prefix="/billing", tags=["billing"])



app.mount("/static", StaticFiles(directory="static"), name="static")


@app.get("/")
async def root():
    return FileResponse("static/index.html")


@app.get("/health")
async def health():
    return {"status": "ok"}
