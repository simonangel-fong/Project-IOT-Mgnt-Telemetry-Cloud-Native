# app/mq/kafka.py
from __future__ import annotations
import json
from functools import lru_cache
from kafka import KafkaProducer

from ..config import get_settings


@lru_cache(maxsize=1)
def get_kafka_producer() -> KafkaProducer:
    """
    Lazily create a singleton KafkaProducer using app settings.
    """
    settings = get_settings()

    producer = KafkaProducer(
        bootstrap_servers=settings.kafka.bootstrap_servers,
        client_id=settings.kafka.client_id,
        value_serializer=lambda v: json.dumps(v).encode("utf-8"),
        key_serializer=lambda v: v.encode("utf-8") if isinstance(v, str) else v,
    )
    return producer
