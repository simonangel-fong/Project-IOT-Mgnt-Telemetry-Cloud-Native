# app/main.py
from __future__ import annotations
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
# cors
from fastapi.middleware.cors import CORSMiddleware

from .config import get_settings
from .mq import init_kafka_producer, close_kafka_producer
from .routers import home, health, device, telemetry
# from .routers import health, device, telemetry
from .config.logging import setup_logging

setup_logging()
logger = logging.getLogger(__name__)

API_PREFIX = "/api"
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        await init_kafka_producer()
    except KafkaConnectionError as exc:
        logger.exception(
            "Kafka initialization failed during startup", exc_info=exc)
    yield
    # Shutdown
    await close_kafka_producer()

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
# Home
app.include_router(home.router, prefix=API_PREFIX)

# Health check & readiness probes
app.include_router(health.router, prefix=API_PREFIX)

# Administrative device registry endpoints (UUID-based lookups)
app.include_router(device.router, prefix=API_PREFIX)

# Device-facing telemetry ingestion and listing endpoints
app.include_router(telemetry.router, prefix=API_PREFIX)
