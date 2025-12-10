# mq/__init__.py
from .kafka import get_kafka_producer

__all__ = [
    "get_kafka_producer",
]
