from enum import Enum
from typing import Any, TypeVar


T = TypeVar("T")


class TableField(Enum):
    def __init__(self, f_name: str, f_type: str = "String", f_comment: str = "") -> None:
        self.f_name: str = f_name
        self.f_type: str = f_type
        self.f_comment: str = f_comment


class MysqlTableField(TableField):
    def __init__(
        self,
        f_name: str,
        f_type: str = "String",
        f_comment: str = "",
        is_primary_key: bool = False,
        is_nullable: bool = False,
        is_index: bool = False,
        is_auto_increment: bool = False,
        default_value: Any = None,
    ) -> None:
        super().__init__(f_name, f_type, f_comment)
        self.default_value: Any = default_value
        self.is_auto_increment: bool = is_auto_increment
        self.is_index: bool = is_index
        self.is_primary_key: bool = is_primary_key
        self.is_nullable: bool = is_nullable
