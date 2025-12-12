# app/mq/kafka.py
from __future__ import annotations

import json
import ssl
from typing import Any, Optional

from aiokafka import AIOKafkaProducer
from aws_msk_iam_sasl_signer import MSKAuthTokenProvider

from ..config import get_settings

_settings = get_settings()


class MSKTokenProvider():
    def token(self):
        token, _ = MSKAuthTokenProvider.generate_auth_token('ca-central-1')
        return token


tp = MSKTokenProvider()

# Internal global producer instance: shared by the whole app
_producer: Optional[AIOKafkaProducer] = None


def _get_kafka_security_kwargs() -> dict[str, Any]:
    """
    Return security-related kwargs for AIOKafkaProducer based on environment.
    - Local Docker: PLAINTEXT
    - AWS MSK (TLS only): SSL + ssl_context
    """
    if _settings.env in ("queue", "staging", "prod"):
        ctx = ssl.create_default_context()
        return {
            "security_protocol": "SSL",
            "ssl_context": ctx,
        }
    else:
        # Local dev (docker-compose)
        return {
            "security_protocol": "PLAINTEXT",
        }


def _serialize_value(value: Any) -> bytes:
    """
    Serialize Python objects to JSON bytes for Kafka value.
    """
    return json.dumps(value, default=str).encode("utf-8")


def _serialize_key(key: Any) -> Optional[bytes]:
    """
    Serialize Kafka message key.

    - str -> utf-8 bytes
    - bytes -> as-is
    - None -> None
    """
    if key is None:
        return None
    if isinstance(key, bytes):
        return key
    if isinstance(key, str):
        return key.encode("utf-8")
    # Fallback: cast to str
    return str(key).encode("utf-8")


async def init_kafka_producer() -> None:
    """
    Initialize and start the global Kafka producer.

    Call this once at application startup (FastAPI lifespan/startup event).
    """
    global _producer
    if _producer is not None:
        return

    _producer = AIOKafkaProducer(
        bootstrap_servers=_settings.kafka_bootstrap_servers,
        client_id=_settings.kafka.client_id,
        value_serializer=_serialize_value,
        key_serializer=_serialize_key,
        acks="all",
        linger_ms=5,
        sasl_mechanism='OAUTHBEARER',
        sasl_oauth_token_provider=tp,
        ssl_context=ssl.create_default_context(),
        # enable_idempotence=True,
    )
    await _producer.start()


async def close_kafka_producer() -> None:
    """
    Cleanly stop the global Kafka producer.

    Call this once at application shutdown.
    """
    global _producer
    if _producer is not None:
        await _producer.stop()
        _producer = None


def get_kafka_producer() -> AIOKafkaProducer:
    """
    Return the initialized Kafka producer.

    Raises:
        RuntimeError: if init_kafka_producer has not been called.
    """
    if _producer is None:
        raise RuntimeError(
            "Kafka producer not initialized. Did you call init_kafka_producer at startup?")
    return _producer
