import asyncio

from .mq.kafka_consumer import init_consumer, close_consumer, get_consumer


async def main():
    # Start consumer once
    await init_consumer()
    consumer = get_consumer()

    try:
        # Consume messages continuously
        async for msg in consumer:
            print(
                f"Received | "
                f"topic={msg.topic} "
                f"partition={msg.partition} "
                f"offset={msg.offset} "
                f"value={msg.value}"
            )
    finally:
        # Graceful shutdown
        await close_consumer()


if __name__ == "__main__":
    asyncio.run(main())
