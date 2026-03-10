# endpoint ="cos.ap-guangzhou.myqcloud.com"
# https://metac-puyun.oss-cn-hangzhou.aliyuncs.com/temp/electricity/mete_data
import re

from src.main.constant.autoclip_constant import EndpointInfo


cos_pattern: re.Pattern[str] = re.compile(r"^cos\.[a-z0-9-]+\.myqcloud\.com$")
oss_pattern: re.Pattern[str] = re.compile(r"^oss\.[a-z0-9-]+\.aliyuncs\.com$")
s3_pattern: re.Pattern[str] = re.compile(r"^s3\.[a-z0-9-]+\.amazonaws\.com$")  # 扩展支持


def parse_endpoint(endpoint: str) -> EndpointInfo:
    """
    解析对象存储服务的完整端点，提取服务提供商和区域信息

    Args:
        endpoint: 完整端点字符串，例如 "cos.ap-guangzhou.myqcloud.com"

    Returns:
        包含服务提供商和区域信息的字典，例如：
        {
            "provider": "tencent",
            "region": "ap-guangzhou",
            "service": "cos"
        }
        如果无法解析，返回 None
    """
    # 标准化端点（去除协议和路径）
    endpoint = endpoint.strip().lower()
    # 移除可能的协议前缀
    if endpoint.startswith(("http://", "https://")):
        endpoint = endpoint.split("//", 1)[1]
    # 移除可能的路径后缀
    if "/" in endpoint:
        endpoint = endpoint.split("/", 1)[0]

    # 解析腾讯云 COS
    cos_match = cos_pattern.match(endpoint)
    if cos_match:
        parts: list[str] = endpoint.split(".")
        if len(parts) >= 3:
            return EndpointInfo(provider="tencent", region=parts[1], service=parts[0])

    # 解析阿里云 OSS
    oss_match = oss_pattern.match(endpoint)
    if oss_match:
        parts = endpoint.split(".")
        if len(parts) >= 3:
            return EndpointInfo(provider="aliyun", region=parts[1], service=parts[0])

    # 解析 AWS S3（示例扩展）
    s3_match = s3_pattern.match(endpoint)
    if s3_match:
        parts = endpoint.split(".")
        if len(parts) >= 3:
            return EndpointInfo(provider="aws", region=parts[1], service=parts[0])
    raise ValueError(f"Can't parse endpoint: {endpoint}")
