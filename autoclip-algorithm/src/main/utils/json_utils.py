import re
from typing import Any


JsonValue = dict[str, Any] | list[Any] | str | int | float | bool | None


def snake_to_camel(snake_str: str) -> str:
    """将下划线命名转换为驼峰命名"""
    if not snake_str:
        return snake_str

    components: list[str] = snake_str.split("_")
    return components[0] + "".join(word.capitalize() for word in components[1:])


def camel_to_snake(camel_str: str) -> str:
    """将驼峰命名转换为下划线命名"""
    if not camel_str:
        return camel_str

    # 在大写字母前插入下划线，然后转小写倒
    snake_str: str = re.sub("([a-z0-9])([A-Z])", r"\1_\2", camel_str).lower()
    return snake_str


def convert_keys_to_camel(data: JsonValue) -> JsonValue:
    """递归转换字典的键为驼峰命名"""
    if isinstance(data, dict):
        return {snake_to_camel(key): convert_keys_to_camel(value) for key, value in data.items()}
    if isinstance(data, list):
        return [convert_keys_to_camel(item) for item in data]
    return data


def convert_keys_to_snake(data: JsonValue) -> JsonValue:
    """递归转换字典的键为下划线命名"""
    if isinstance(data, dict):
        return {camel_to_snake(key): convert_keys_to_snake(value) for key, value in data.items()}
    if isinstance(data, list):
        return [convert_keys_to_snake(item) for item in data]
    return data
