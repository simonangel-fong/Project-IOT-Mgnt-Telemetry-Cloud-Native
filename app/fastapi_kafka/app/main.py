from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import get_settings, setup_logging
from .mq import init_producer, close_producer
from .routers import home, health, device, telemetry

setup_logging()
logger = logging.getLogger(__name__)

API_PREFIX = "/api"
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_producer()
    yield
    await close_producer()


app = FastAPI(
    title="IoT Device Management API",
    version="0.1.0",
    description=(
        "Device Management API for registering IoT devices and handling their "
        "telemetry data. Device-facing endpoints authenticate using device UUIDs "
        "and API keys, while administrative endpoints are intended for internal "
        "operations and tooling."
    ),
    lifespan=lifespan,
)

# ====================
# CORS
# ====================
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_list,
    allow_credentials=False,  # no cookies for devices
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type", "x-api-key"],
)

# ====================
# Routers
# ====================
app.include_router(home.router, prefix=API_PREFIX)
app.include_router(health.router, prefix=API_PREFIX)
app.include_router(device.router, prefix=API_PREFIX)
app.include_router(telemetry.router, prefix=API_PREFIX)
