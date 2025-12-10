# app/mq/topic.py
from __future__ import annotations

from dataclasses import dataclass

from ..config import get_settings


@dataclass(frozen=True)
class KafkaTopics:
    """
    Kafka topic names used by the application.

    Attributes:
        telemetry_ingest: Main topic for real-time telemetry events.
        telemetry_dlq: Dead Letter Queue (DLQ) topic for failed events.
    """
    telemetry_ingest: str
    telemetry_dlq: str


# Create a single KafkaTopics instance at import time
_settings = get_settings()
KAFKA_TOPICS = KafkaTopics(
    telemetry_ingest=_settings.kafka.topic_telemetry_ingest,
    telemetry_dlq=_settings.kafka.topic_telemetry_dlq,
)


def get_kafka_topics() -> KafkaTopics:
    """
    Return the configured Kafka topics.

    Topic names are loaded from Settings.kafka.* (which in turn may be
    configured via environment variables, for example:

        KAFKA__TOPIC_TELEMETRY_INGEST
        KAFKA__TOPIC_TELEMETRY_DLQ

    Returns:
        KafkaTopics: Immutable container with topic names.
    """
    return KAFKA_TOPICS
