# router/home.py
import os
from fastapi import APIRouter, Depends

from ..config.setting import get_settings

# ====================
# Root endpoint
# ====================

router = APIRouter(prefix="", tags=["home"])
settings = get_settings()

HOSTNAME = os.getenv("HOSTNAME", "my_host")


@router.get(
    "/",
    tags=["root"],
    summary="Service status",
    description=(
        "Return basic information about the Device Management API service. "
    ),
)
async def home() -> dict:
    """
    Return basic service metadata and status.
    """
    print(settings.cors_list)
    response: dict = {
        "app": settings.app_name,
        "status": "ok",
        "environment": settings.env,
        "debug": settings.debug,
        "docs": {
            "openapi": "/openapi.json",
            "swagger_ui": "/docs",
            "redoc": "/redoc",
        },
    }

    if settings.debug:
        response["fastapi"] = {
            "fastapi_host": HOSTNAME,
        }

        response["cors"] = settings.cors_list

        response["tune"] = {
            "pool_size": settings.pool_size,
            "max_overflow": settings.max_overflow,
        }

        response["postgres"] = {
            "host": settings.postgres.host,
            "port": settings.postgres.port,
            "db_name": settings.postgres.db,
            "user": settings.postgres.user,
        }

        response["redis"] = {
            "host": settings.redis.host,
            "port": settings.redis.port,
            "db_name": settings.redis.db,
        }

        response["mq"] = {
            "host": settings.kafka.host,
            "port": settings.kafka.port,
            "client_id": settings.kafka.client_id
        }

    return response
