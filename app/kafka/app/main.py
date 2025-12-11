# app/main.py
from __future__ import annotations

import asyncio
import logging
from typing import Any

from aiokafka import AIOKafkaConsumer
from sqlalchemy.ext.asyncio import AsyncSession

from .config import get_settings
from .db import async_session_maker
from .mq import create_consumer
from .models import TelemetryEvent
from .schemas import TelemetryItem

logger = logging.getLogger(__name__)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s - %(message)s",
)

settings = get_settings()


async def process_batch(messages: list[Any], session: AsyncSession) -> None:
    """
    Convert Kafka messages into TelemetryEvent rows and insert them.

    Expects message.value (from Kafka) to be a dict that matches TelemetryMessage.
    """
    if not messages:
        return

    events: list[TelemetryEvent] = []

    for msg in messages:
        data = msg.value  # already deserialized dict from value_deserializer

        try:
            telemetry = TelemetryItem.model_validate(data)

            events.append(
                TelemetryEvent(
                    device_uuid=telemetry.device_uuid,
                    x_coord=telemetry.x_coord,
                    y_coord=telemetry.y_coord,
                    device_time=telemetry.device_time or telemetry.system_time_utc,
                    system_time_utc=telemetry.system_time_utc,
                )
            )
        except Exception:
            logger.exception(
                "Failed to parse telemetry message",
                extra={"raw_value": data},
            )

    if not events:
        return

    session.add_all(events)
    await session.commit()

    logger.info("Inserted %d telemetry events", len(events))


async def run_consumer() -> None:
    """
    Main consumer loop:

    - Creates an AIOKafkaConsumer
    - Polls messages in batches using getmany()
    - For each batch, opens a DB session and writes TelemetryEvent rows
    - Commits Kafka offsets only after a successful DB commit
    """
    consumer: AIOKafkaConsumer = create_consumer()

    await consumer.start()
    logger.info(
        "Telemetry consumer started. topic=%s, bootstrap_servers=%s",
        settings.kafka.kafka_topic_telemetry
        if hasattr(settings, "kafka") and hasattr(settings.kafka, "kafka_topic_telemetry")
        else getattr(settings, "kafka_topic_telemetry", "telemetry_ingest"),
        getattr(settings, "kafka_bootstrap_servers", "unknown"),
    )

    try:
        while True:
            # getmany() -> {TopicPartition: [messages]}
            batch_map = await consumer.getmany(
                timeout_ms=1000,
                max_records=500,  # tune batch size
            )

            if not batch_map:
                continue

            flat_messages = [
                msg for _, msgs in batch_map.items() for msg in msgs
            ]

            async with async_session_maker() as session:
                try:
                    await process_batch(flat_messages, session)
                    # Only commit offsets if DB write succeeded
                    await consumer.commit()
                except Exception:
                    logger.exception(
                        "Error while processing batch; offsets not committed"
                    )
                    # Optional: small backoff to avoid tight failure loop
                    await asyncio.sleep(1)

    finally:
        logger.info("Stopping telemetry consumer...")
        await consumer.stop()
        logger.info("Telemetry consumer stopped.")


if __name__ == "__main__":
    asyncio.run(run_consumer())
