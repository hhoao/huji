from collections.abc import Collection
from typing import Any


def check_not_none(value: Any, message: str | None = None) -> Any:
    if value is None:
        if message is None:
            message = "Value must not be None"
        raise ValueError(message)
    return value


def check_argument(expression: bool, message: str | None = None) -> None:
    if not expression:
        if message is None:
            message = "Invalid argument"
        raise ValueError(message)


def check_state(expression: bool, message: str | None = None) -> None:
    if not expression:
        if message is None:
            message = "Invalid state"
        raise RuntimeError(message)


def check_index(index: int, size: int, message: str | None = None) -> None:
    if not (0 <= index < size):
        if message is None:
            message = f"Index {index} out of bounds for size {size}"
        raise IndexError(message)


def check_not_empty(value: Collection[Any], message: str | None = None) -> Collection[Any]:
    if not value:
        if message is None:
            message = "Value must not be empty"
        raise ValueError(message)
    return value


def check_positive(value: int | float, message: str | None = None) -> int | float:
    if value <= 0:
        if message is None:
            message = "Value must be positive"
        raise ValueError(message)
    return value


def check_non_negative(value: int | float, message: str | None = None) -> int | float:
    if value < 0:
        if message is None:
            message = "Value must be non-negative"
        raise ValueError(message)
    return value


def check_in_range(
    value: float, min_value: float, max_value: float, message: str | None = None
) -> float:
    if not (min_value <= value <= max_value):
        if message is None:
            message = f"Value {value} must be between {min_value} and {max_value}"
        raise ValueError(message)
    return value


def check_type[T](value: Any, expected_type: type[T], message: str | None = None) -> T:
    if not isinstance(value, expected_type):
        if message is None:
            message = f"Expected type {expected_type}, got {type(value)}"
        raise TypeError(message)
    return value


def check_contains(container: Collection[Any], item: Any, message: str | None = None) -> Any:
    if item not in container:
        if message is None:
            message = f"Container does not contain {item}"
        raise ValueError(message)
    return item


def check_not_contains(container: Collection[Any], item: Any, message: str | None = None) -> Any:
    if item in container:
        if message is None:
            message = f"Container should not contain {item}"
        raise ValueError(message)
    return item
