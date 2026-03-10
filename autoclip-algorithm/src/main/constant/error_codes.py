class ErrorCode:
    def __init__(self, code: int, message: str):
        self.code = code
        self.message = message

    def __str__(self):
        return f"{self.code}: {self.message}"


class ErrorCodes:
    # 请检验视频格式是否正确,
    NO_VALID_SEGMENT = ErrorCode(
        1000000000,
        "系统未识别出有效的片段, 请校验视频格式(方向、编码格式等)或者配置参数是否合理",
    )


class ServiceError(Exception):
    def __init__(self, error_code: ErrorCode):
        self.error_code = error_code

    def __str__(self):
        return str(self.error_code)
