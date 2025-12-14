# mq/kafka_producer.py
from __future__ import annotations

import ssl
import json
import asyncio
import logging
from typing import Optional

from aiokafka import AIOKafkaProducer
from aiokafka.abc import AbstractTokenProvider
from aws_msk_iam_sasl_signer import MSKAuthTokenProvider

from ..config import get_settings

settings = get_settings()
logger = logging.getLogger(__name__)

# singleton
_producer: Optional[AIOKafkaProducer] = None
_init_lock = asyncio.Lock()


class MSKTokenProvider(AbstractTokenProvider):
    def __init__(self, aws_region: str):
        self.aws_region = aws_region

    async def token(self) -> str:
        token, _ = MSKAuthTokenProvider.generate_auth_token(self.aws_region)
        return token


def _build_ssl_context() -> ssl.SSLContext:
    # Default TLS
    return ssl.create_default_context()


async def init_producer() -> AIOKafkaProducer:
    """
    Initialize and start the global Kafka producer (singleton).

    Returns the started producer instance.
    """
    global _producer

    if _producer is not None:
        return _producer

    # acquire lock
    async with _init_lock:
        # Re-check after acquiring lock
        if _producer is not None:
            return _producer

        settings = get_settings()

        producer = AIOKafkaProducer(
            bootstrap_servers=settings.kafka_bootstrap_servers,
            client_id=getattr(settings.kafka, "client_id", None) or "producer",
            value_serializer=lambda v: json.dumps(v).encode("utf-8"),
            security_protocol="SASL_SSL",
            sasl_mechanism="OAUTHBEARER",
            sasl_oauth_token_provider=MSKTokenProvider(settings.aws_region),
            ssl_context=_build_ssl_context(),
            request_timeout_ms=30000,
            retry_backoff_ms=500,
        )

        try:
            await producer.start()
        except Exception:
            # Best-effort cleanup
            try:
                await producer.stop()
            except Exception:
                pass
            raise

        _producer = producer
        return _producer


async def close_producer() -> None:
    """Stop and clear the global producer."""
    global _producer

    if _producer is None:
        return

    # Acquire lock
    async with _init_lock:
        if _producer is None:
            return

        try:
            await _producer.stop()
        finally:
            _producer = None


def get_producer() -> AIOKafkaProducer:
    """Get the started producer; raise if not initialized."""
    if _producer is None:
        raise RuntimeError(
            "Kafka producer not initialized. Call await init_producer() first."
        )
    return _producer
