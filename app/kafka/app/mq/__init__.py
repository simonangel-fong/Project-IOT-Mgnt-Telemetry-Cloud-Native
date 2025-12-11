# mq/__init__.py
from .kafka import create_consumer
# from .topic import get_kafka_topics

__all__ = [
    "create_consumer",
    # "get_kafka_topics",
]
