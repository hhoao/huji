import datetime
import re
from typing import Any, cast, override

import numpy as np
import pandas as pd
import pymysql
from dbutils.pooled_db import PooledDB  # type: ignore
from pandas import DataFrame
from sqlalchemy import create_engine
from sqlalchemy.engine import Engine

from src.main.constant.database_constant import MysqlTableField
from src.main.database.base_client import DatabaseClient
from src.main.logger import LOG
from src.main.utils.string_utils import is_empty


class MySQLDatabaseClient(DatabaseClient):
    @override
    def get_pool(self) -> PooledDB:
        return PooledDB(
            creator=pymysql,
            host=self.host,
            port=self.port,
            user=self.user,
            password=self.password,
            database=self.database,
            charset="utf8mb4",
            maxconnections=self.connection_count,
        )

    def get_version(self) -> str:
        conn = self.get_conn()
        cur = conn.cursor()
        cur.execute("SELECT VERSION();")
        info = cur.fetchone()
        if not info or not info[0]:
            raise ValueError("Failed to get MySQL version")
        pattern = r"(\d+\.\d+\.\d+)"
        match = re.search(pattern, info[0])
        if not match:
            raise ValueError(f"Invalid MySQL version format: {info[0]}")
        version = match.group(1)
        cur.close()
        conn.close()
        return version

    def compare_versions(self, version1: str, version2: str) -> int:
        v1_parts = [int(part) for part in version1.split(".")]
        v2_parts = [int(part) for part in version2.split(".")]

        max_length = max(len(v1_parts), len(v2_parts))
        v1_parts.extend([0] * (max_length - len(v1_parts)))
        v2_parts.extend([0] * (max_length - len(v2_parts)))

        for i in range(max_length):
            if v1_parts[i] > v2_parts[i]:
                return 1
            if v1_parts[i] < v2_parts[i]:
                return -1
        return 0

    def generate_create_table_sql(
        self, table_name: str, fields: list[MysqlTableField]
    ) -> list[str]:
        field_definitions: list[str] = []
        primary_keys: list[str] = []
        indexes: list[str] = []

        for field in fields:
            if field.is_primary_key:
                primary_keys.append(field.f_name)
            if field.is_index:
                indexes.append(field.f_name)

            # 处理字段定义
            nullable_statement = "" if field.is_nullable else "NOT NULL"
            auto_increment = "AUTO_INCREMENT" if field.is_auto_increment else ""
            default_value = (
                f"DEFAULT {field.default_value}"
                if hasattr(field, "default_value") and field.default_value is not None
                else ""
            )

            field_def = (
                f"    `{field.f_name}` {field.f_type} "
                f"{nullable_statement} {auto_increment} {default_value}"
            ).strip()
            if field.f_comment:
                field_def += f" COMMENT '{field.f_comment}'"

            field_definitions.append(field_def)

        # 构建主键语句
        primary_statement = f"PRIMARY KEY (`{'`, `'.join(primary_keys)}`)" if primary_keys else ""

        # 构建索引语句
        index_statements = [f"INDEX `idx_{idx_field}` (`{idx_field}`)" for idx_field in indexes]

        # 组合所有定义
        all_definitions: list[str] = field_definitions.copy()
        if primary_statement:
            all_definitions.append(primary_statement)
        all_definitions.extend(index_statements)

        fields_statement = ",\n".join(all_definitions)

        create_sql = f"""
CREATE TABLE IF NOT EXISTS `{table_name}` (
{fields_statement}
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
"""

        return [create_sql]

    def connect_statement(self, *args: str) -> str:
        stats = list(filter(lambda f: not is_empty(f), args))
        return ",\n".join(stats)

    def generate_insert_sql(self, table_name: str, fields: list[MysqlTableField]) -> str:
        """
        生成插入数据的SQL语句

        Args:
            table_name: 表名
            fields: 字段列表

        Returns:
            str: 插入数据的SQL语句
        """
        field_names = [field.f_name for field in fields]
        return f"""
INSERT INTO `{table_name}` (
    `{"`, `".join(field_names)}`
) VALUES
"""

    def create_table(
        self, table_name: str, fields: list[MysqlTableField], override: bool = False
    ) -> None:
        if override:
            self.execute_sql(f"DROP TABLE IF EXISTS `{table_name}`")

        create_sqls = self.generate_create_table_sql(table_name, fields)

        for sql in create_sqls:
            self.execute_sql(sql)

    def _insert_batch_mysql(
        self, table_name: str, conn: Any, fields: list[str], datas: list[list[Any]]
    ) -> None:
        """使用批量插入优化MySQL性能"""
        with conn.cursor() as cur:
            # 构建占位符
            placeholders = ", ".join(["%s"] * len(fields))
            columns = "`, `".join(fields)

            sql = f"INSERT INTO `{table_name}` (`{columns}`) VALUES ({placeholders})"

            # 批量执行
            cur.executemany(sql, datas)
        conn.commit()

    def array_to_string(self, arr: list[Any] | np.ndarray[Any, Any] | Any) -> str:
        """MySQL中处理数组，可以转换为JSON格式"""
        if isinstance(arr, list | np.ndarray):
            return str(list(arr))  # pyright: ignore [reportUnknownArgumentType]
        return str(arr)

    def format_data(self, datas: list[list[Any]]) -> list[list[Any]]:
        for data in datas:
            for i, value in enumerate(data):
                if isinstance(value, str) and value == "":
                    data[i] = None  # MySQL中空字符串可以用NULL
                elif isinstance(value, list | np.ndarray):
                    data[i] = self.array_to_string(value)  # type: ignore
                elif isinstance(value, datetime.datetime):
                    data[i] = value.strftime("%Y-%m-%d %H:%M:%S")
                elif isinstance(value, datetime.date):
                    data[i] = value.strftime("%Y-%m-%d")
                elif isinstance(value, bool):
                    data[i] = 1 if value else 0
                elif value is None:
                    data[i] = None
                else:
                    data[i] = value
        return datas

    def insert_batch(self, table: str, columns: list[str], datas: list[list[Any]]) -> None:
        """批量插入数据"""
        formatted_data = self.format_data(datas)

        conn = self.get_conn()
        try:
            self._insert_batch_mysql(table, conn, columns, formatted_data)
        except Exception as e:
            conn.rollback()
            raise e
        finally:
            conn.close()

    def insert_batch_with_pandas(
        self, table: str, columns: list[str], datas: list[list[Any]]
    ) -> None:
        """使用pandas批量插入（适用于大数据量）"""
        formatted_data = self.format_data(datas)
        pd_data: DataFrame = pd.DataFrame(data=formatted_data, columns=pd.Index(columns))

        # 构建MySQL连接字符串
        conn_str = f"mysql+pymysql://{self.user}:{self.password}@{self.host}:{self.port}/{self.database}?charset=utf8mb4"
        engine: Engine = create_engine(conn_str)

        # 使用pandas的to_sql方法批量插入数据
        pd_data.to_sql(
            name=table,
            con=engine,
            if_exists="append",
            index=False,
            chunksize=1000,  # 分批插入，避免内存问题
        )

    def update(
        self,
        table_name: str,
        where_columns: list[str],
        update_columns: list[str],
        where_data: dict[str, Any] | list[Any] | Any,
        update_data: dict[str, Any] | list[Any] | Any,
    ) -> int:
        """
        Updates records in the specified table.

        Args:
            table_name (str): The name of the table to update
            where_columns (list): Columns to use in the WHERE clause for selecting records
            update_columns (list): Columns to update
            where_data: Data values to match in the WHERE clause
            update_data: New data values to update

        Returns:
            int: Number of rows updated
        """
        if is_empty(table_name) or not where_columns or not update_columns:
            LOG.error("Invalid parameters for update")
            return 0

        # Build the SET clause
        set_clause = ", ".join([f"`{col}` = %s" for col in update_columns])

        # Build the WHERE clause
        where_conditions: list[str] = []
        where_values: list[Any] = []

        if isinstance(where_data, dict):
            for col in where_columns:
                if col in where_data:
                    where_conditions.append(f"`{col}` = %s")
                    where_values.append(where_data[col])
        else:
            # Assume where_data is a single value or list matching where_columns order
            if isinstance(where_data, list):
                where_values = cast(list[Any], where_data)  # type: ignore
            else:
                where_values = [where_data]
            where_conditions = [f"`{col}` = %s" for col in where_columns]

        where_clause = " AND ".join(where_conditions)

        # Prepare update values
        update_values: list[Any] = []
        if isinstance(update_data, dict):
            update_values.extend(
                cast(Any, update_data[col])
                for col in update_columns
                if col in update_data  # type: ignore
            )
        # Assume update_data is a single value or list matching update_columns order
        elif isinstance(update_data, list):
            update_values = cast(list[Any], update_data)  # type: ignore
        else:
            update_values = [update_data]

        # Combine all values for the query
        all_values = update_values + where_values

        # Execute the update
        sql = f"UPDATE `{table_name}` SET {set_clause} WHERE {where_clause}"
        conn = self.get_conn()
        try:
            with conn.cursor() as cur:
                rows_affected = cur.execute(sql, all_values)
            conn.commit()
            return rows_affected
        except Exception as e:
            conn.rollback()
            LOG.error(f"Error updating table {table_name}: {e!s}")
            return 0
        finally:
            conn.close()

    def drop_table(self, table_name: str) -> None:
        self.execute_sql(f"DROP TABLE IF EXISTS `{table_name}`")

    @override
    def close(self) -> None:
        if self.pool:
            self.pool.close()

    def create_partition_table(
        self, table_name: str, partition_field: str, partition_type: str = "RANGE"
    ) -> None:
        self.execute_sql(
            f"ALTER TABLE `{table_name}` PARTITION BY {partition_type} ({partition_field})"
        )

    def table_exists(self, table_name: str) -> bool:
        conn = self.get_conn()
        try:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT COUNT(*) FROM information_schema.tables\
                        WHERE table_schema = %s AND table_name = %s",
                    (self.database, table_name),
                )
                result = cur.fetchone()
                return bool(result and result[0] > 0)
        finally:
            conn.close()

    def get_table_info(self, table_name: str) -> list[dict[str, Any]]:
        conn = self.get_conn()
        try:
            with conn.cursor() as cur:
                cur.execute(f"SHOW COLUMNS FROM `{table_name}`")
                columns = [col[0] for col in cur.description] if cur.description else []
                return [dict(zip(columns, row, strict=False)) for row in cur.fetchall()]
        finally:
            conn.close()

    def create_index(
        self, table_name: str, index_name: str, columns: list[str], unique: bool = False
    ) -> None:
        unique_str = "UNIQUE" if unique else ""
        columns_str = "`, `".join(columns)
        self.execute_sql(
            f"CREATE {unique_str} INDEX `{index_name}` ON `{table_name}` (`{columns_str}`)"
        )

    def drop_index(self, table_name: str, index_name: str) -> None:
        self.execute_sql(f"DROP INDEX `{index_name}` ON `{table_name}`")
