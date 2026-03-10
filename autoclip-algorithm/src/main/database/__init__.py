from enum import Enum, unique


@unique
class DataBaseType(Enum):
    HOLOGRES = "hologres"
    CLICKHOUSE = "clickhouse"
