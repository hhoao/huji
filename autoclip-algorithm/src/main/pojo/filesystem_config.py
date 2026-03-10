import ast
import json
import re
from enum import Enum
from typing import Any


def check_and_get[T](config: dict[str, Any], name: str, vtype: type[T]) -> T:
    """从配置中获取指定类型的值

    Args:
        config: 配置字典
        name: 配置项名称
        vtype: 期望的类型

    Returns:
        指定类型的值

    Raises:
        Exception: 当配置项不存在或类型不匹配时抛出异常
    """
    value = config.get(name)
    if value is None:
        raise Exception(f"{name} is required")
    if not isinstance(value, vtype):
        raise Exception(f"{name} must be of type {vtype.__name__}, got {type(value).__name__}")
    return value


class FileStorageEnum(Enum):
    DB = 1
    LOCAL = 10
    FTP = 11
    SFTP = 12
    S3 = 20


def _parse_config(config: str) -> dict[str, Any]:
    """安全地解析配置字符串，支持 Python 字面量表达式"""
    try:
        # 首先尝试使用 ast.literal_eval 解析 Python 字面量
        return ast.literal_eval(config)  # type: ignore
    except (SyntaxError, ValueError):
        try:
            # 如果失败，尝试作为 JSON 解析
            return json.loads(config)
        except json.JSONDecodeError:
            # 如果都失败了，尝试修复 JSON 字符串
            fixed_config = config.replace("'", '"')
            fixed_config = re.sub(r"(\w+):", r'"\1":', fixed_config)
            return json.loads(fixed_config)


class FileSystemConfigVO:
    def __init__(self, config_id: int, storage: int):
        self.id = config_id
        self.storage = FileStorageEnum(storage)


class LocalFileSystemConfigVO(FileSystemConfigVO):
    def __init__(self, config_id: int, storage: int, config: str):
        super().__init__(config_id, storage)
        config_json = _parse_config(config)
        self.base_path = check_and_get(config_json, "base_path", str)
        self.domain = config_json.get("domain")


class S3FileSystemConfigVO(FileSystemConfigVO):
    def __init__(self, config_id: int, storage: int, config: str):
        super().__init__(config_id, storage)
        config_json = _parse_config(config)

        self.endpoint = check_and_get(config_json, "endpoint", str)
        self.bucket = check_and_get(config_json, "bucket", str)
        self.access_key = check_and_get(config_json, "access_key", str)
        self.access_secret = check_and_get(config_json, "access_secret", str)
        self.enable_path_style_access = check_and_get(config_json, "enable_path_style_access", bool)
