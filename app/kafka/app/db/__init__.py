# app/db/__init__.py
from .postgres import async_session_maker

__all__ = [
    "async_session_maker",
]
