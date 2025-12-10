# app/routers/health.py
import logging
from fastapi import APIRouter, Depends
from fastapi.concurrency import run_in_threadpool
from fastapi.responses import JSONResponse
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from aiokafka import AIOKafkaProducer

from ..config import get_settings
from ..db import get_db, redis_client
from ..mq import get_kafka_producer, get_kafka_topics


router = APIRouter(prefix="/health", tags=["health"])

logger = logging.getLogger(__name__)

settings = get_settings()


@router.get("/", summary="App health check")
async def health() -> dict:
    """
    Basic app-level health check.
    """
    return {
        "status": "ok",
        "app": settings.app_name,
        "environment": settings.env,
    }


@router.get("/db", summary="Database health check")
async def health_db(
    db: AsyncSession = Depends(get_db),
) -> JSONResponse:
    """
    Check if PostgreSQL is reachable by doing a lightweight SELECT 1.
    """
    try:
        await db.execute(text("SELECT 1"))
        return JSONResponse({"database": "reachable"})
    except Exception as exc:
        logger.exception("Database health check failed")
        detail: str | None = str(exc) if settings.debug else None
        return JSONResponse(
            status_code=503,
            content={
                "database": "unreachable",
                "detail": detail,
            },
        )


@router.get("/redis", summary="Redis health check")
async def health_redis() -> JSONResponse:
    """
    Check if Redis is reachable by sending a PING.
    """
    try:
        pong = await redis_client.ping()
        return JSONResponse({"redis": "reachable", "pong": pong})
    except Exception as exc:
        logger.exception("Redis health check failed")
        detail: str | None = str(exc) if settings.debug else None
        return JSONResponse(
            status_code=503,
            content={
                "redis": "unreachable",
                "detail": detail,
            },
        )


@router.get("/kafka", summary="Kafka health check")
async def health_kafka(
    producer: AIOKafkaProducer = Depends(get_kafka_producer),
) -> JSONResponse:
    """
    Check if Kafka is reachable and the telemetry ingest topic has partitions.

    This is a lightweight readiness-style check:
    - Uses producer.metadata to look up partitions for the ingest topic.
    - If metadata is missing or empty, report unhealthy.
    """
    topics = get_kafka_topics()

    try:
        # Ask Kafka for partition metadata for the ingest topic.
        # For AIOKafkaProducer, partitions_for(...) is an async method.
        partitions = await producer.partitions_for(topics.telemetry_ingest)

        if not partitions:
            raise RuntimeError(
                f"No partitions available for topic '{topics.telemetry_ingest}'"
            )

        return JSONResponse(
            {
                "kafka": "reachable",
                "topic": topics.telemetry_ingest,
                "partitions": sorted(list(partitions)),
                "bootstrap_servers": settings.kafka_bootstrap_servers,
            }
        )

    except Exception as exc:
        logger.exception("Kafka health check failed")
        detail: str | None = str(exc) if settings.debug else None
        return JSONResponse(
            status_code=503,
            content={
                "kafka": "unreachable",
                "topic": topics.telemetry_ingest,
                "detail": detail,
            },
        )
