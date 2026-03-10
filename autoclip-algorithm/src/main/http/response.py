from typing import Any

from pydantic import BaseModel, ConfigDict

from src.main.utils.string_utils import is_empty


class ErrorCode(BaseModel):
    code: int
    msg: str


class GlobalErrorCodeConstants:
    SUCCESS = ErrorCode(code=0, msg="成功")
    INTERNAL_SERVER_ERROR = ErrorCode(code=500, msg="系统异常")


class CommonResult(BaseModel):
    code: int | None = None
    data: Any = ""
    msg: str = ""
    model_config = ConfigDict(arbitrary_types_allowed=True)

    @staticmethod
    def success(data: Any, msg: str | None = None) -> str:
        result = CommonResult()
        result.code = GlobalErrorCodeConstants.SUCCESS.code
        result.data = data
        result.msg = msg or GlobalErrorCodeConstants.SUCCESS.msg
        return result.model_dump_json()

    @staticmethod
    def error(
        code: int | None = None,
        exception: Exception | None = None,
        message: str | None = None,
    ) -> str:
        result = CommonResult()
        result.code = code or GlobalErrorCodeConstants.INTERNAL_SERVER_ERROR.code
        error_message = message or ""
        if exception is not None:
            error_message = error_message + str(exception)
        if is_empty(error_message):
            error_message = GlobalErrorCodeConstants.INTERNAL_SERVER_ERROR.msg

        result.msg = error_message

        return result.model_dump_json()
