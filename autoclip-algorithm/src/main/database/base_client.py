from abc import ABC, abstractmethod
from typing import Any

from dbutils.pooled_db import PooledDB  # type: ignore

from src.main.config.config import DataSourceConfig


class DatabaseClient(ABC):
    def __init__(self, config: DataSourceConfig):
        self.password = str(config.password)
        self.user = str(config.user)
        self.database = str(config.database)
        self.port: int = config.port
        self.host = str(config.host)
        self.cluster = config.cluster
        self.connection_count = config.connection_count
        self.pool = self.get_pool()

    @abstractmethod
    def get_pool(self) -> PooledDB:
        pass

    def get_conn(self) -> Any:
        return self.pool.connection()

    def execute_sql_with_params(self, sql: str, params: list[object]) -> None:
        conn = self.get_conn()
        cur = conn.cursor()
        cur.execute(sql, params)
        conn.commit()
        cur.close()
        conn.close()

    def execute_sql(self, sql: str) -> None:
        conn = self.get_conn()
        cur = conn.cursor()
        cur.execute(sql)
        conn.commit()
        cur.close()
        conn.close()

    def execute_sql_with_result(self, sql: str) -> list[dict[str, object]]:
        conn = self.get_conn()
        try:
            cur = conn.cursor()
            cur.execute(sql)
            result: list[dict[str, object]] = []
            column_names = [desc[0] for desc in cur.description]
            rows = cur.fetchall()
            for row in rows:
                row_dict = dict(zip(column_names, row, strict=False))
                result.append(row_dict)
            conn.commit()
            cur.close()
            return result
        finally:
            if conn:
                conn.close()

    @abstractmethod
    def close(self) -> None:
        pass
