# kafka/consumer/mq/kafka.py
from __future__ import annotations

import json
from typing import Any

from aiokafka import AIOKafkaConsumer

from ..config import get_settings

settings=get_settings()


def value_deserializer(raw: bytes) -> dict[str, Any]:
    """JSON bytes -> dict."""
    return json.loads(raw.decode("utf-8"))


def key_deserializer(raw: bytes | None) -> str | None:
    if raw is None:
        return None
    return raw.decode("utf-8")


def create_consumer() -> AIOKafkaConsumer:
    """
    Create an AIOKafkaConsumer configured for the telemetry ingest topic.
    The caller is responsible for .start() / .stop().
    """
    return AIOKafkaConsumer(
        settings.kafka.topic_telemetry,
        bootstrap_servers=settings.kafka_bootstrap_servers,
        group_id=settings.kafka.group_id,
        enable_auto_commit=False,   # we commit manually after DB write
        auto_offset_reset="earliest",
        value_deserializer=value_deserializer,
        key_deserializer=key_deserializer,
    )
