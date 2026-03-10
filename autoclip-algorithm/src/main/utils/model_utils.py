from enum import Enum

from ultralytics import YOLO


"""
详见"模型导出": https://docs.ultralytics.com/zh/modes/export/#export-formats
"""

class ModelFormatType(Enum):
    """
    (PC推荐) ONNX: 通用模型表示，导出为ONNX格式, 适用于跨平台部署, 如TensorFlow, PyTorch等
    """
    ONNX = "onnx"
    """
    TorchScript 由 PyTorch 的创建者开发，是一个强大的工具，
    用于优化和部署各种平台上的 PyTorch 模型。
    将 YOLO11 模型导出到 TorchScript 对于从研究转向实际应用至关重要。
    TorchScript 是 PyTorch 框架的一部分，通过允许在不支持 Python 的环境中使用 PyTorch 模型，
    有助于使这种过渡更加顺畅。
    https://docs.ultralytics.com/zh/integrations/torchscript/
    """
    TORCHSCRIPT = "torchscript"
    """
    (移动端推荐) TFLITE适用于边缘计算: https://docs.ultralytics.com/zh/integrations/tflite/#why-should-you-export-to-tflite
    """
    TFLITE = "tflite"
    """
    SAVED_MODEL: 导出为SAVED_MODEL格式, 适用于TensorFlow, TensorFlow Lite等
    https://docs.ultralytics.com/zh/integrations/saved-model/
    """
    SAVED_MODEL = "saved_model"
    """
    EDGETPU: 导出为EDGETPU格式, 适用于Google Coral Edge TPU, 如Coral Dev Board等
    https://docs.ultralytics.com/zh/integrations/edgetpu/
    """
    EDGETPU = "edgetpu"
    """
    TFJS: TensorFlow.js, 导出为TFJS格式, 适用于浏览器, 如Chrome, Firefox等
    https://docs.ultralytics.com/zh/integrations/tfjs/
    """
    TFJS = "tfjs"
    """
    RKNN: 瑞芯微的RKNN格式, 导出为RKNN格式, 适用于瑞芯微硬件, 如RK3588等
    https://docs.ultralytics.com/zh/integrations/rknn/
    """
    RKNN = "rknn"
    """
    ENGINE: TensorRT, 导出为ENGINE格式, 适用于NVIDIA GPU, 如RTX 30系列等
    https://docs.ultralytics.com/zh/integrations/tensorrt/
    """
    ENGINE = "engine"
    """
    PB: TensorFlow的protobuf格式, 导出为PB格式, 适用于TensorFlow, TensorFlow Lite等
    https://docs.ultralytics.com/zh/integrations/tf-graphdef/
    """
    PB = "pb"
    """
    NCNN: 腾讯的ncnn框架, 导出为NCNN格式, 适用于移动端, 如Android, iOS等
    https://docs.ultralytics.com/zh/integrations/ncnn/
    """
    NCNN = "ncnn"
    """
    CoreML: 苹果的核心机器学习框架, 导出为CoreML格式, 适用于iOS, macOS等Apple设备, 在 iPhone 和 Mac 等 Apple 设备上部署计算机视觉模型需要一种能够确保无缝性能的格式。
    https://docs.ultralytics.com/zh/integrations/coreml/
    """
    COREML = "coreml"
    """
    IMX500: 索尼的IMX500芯片, 导出为IMX500格式, 适用于索尼硬件, 如Raspberry Pi等
    https://docs.ultralytics.com/zh/integrations/sony-imx500/
    """
    IMX500 = "imx"
    """
    MNN 是一种高效且轻量级的深度学习框架。它支持深度学习模型的推理和训练，
    并在设备上的推理和训练方面具有行业领先的性能。
    目前，MNN 已集成到阿里巴巴集团的 30 多个应用程序中，
    例如淘宝、天猫、优酷、钉钉、闲鱼等，涵盖直播、短视频拍摄、
    搜索推荐、以图搜商品、互动营销、股权分配、安全风险控制等 70 多个使用场景。
    此外，MNN 还应用于嵌入式设备，如物联网。
    https://docs.ultralytics.com/zh/integrations/mnn/
    """
    MNN = "mnn"
    """
    在不同条件下，开发和部署现实世界中的计算机视觉模型之间的差距可能难以弥合。PaddlePaddle 专注于灵活性、性能以及在分布式环境中进行并行处理的能力，从而简化了此过程。这意味着您可以在各种设备和平台上使用您的 YOLO11 计算机视觉模型，从智能手机到基于云的服务器。
    https://docs.ultralytics.com/zh/integrations/paddlepaddle/
    """
    PADDLE = "paddle"
    """
    OpenVINO: 英特尔的开源推理引擎, 导出为OpenVINO格式, 适用于英特尔硬件, 如CPU, GPU, FPGA等
    https://docs.ultralytics.com/zh/integrations/openvino/
    """
    OPENVINO = "openvino"



"""
PC端推荐导出ONNX格式
移动端推荐导出TFLITE格式
"""
def export_model(model_path: str, model_format: ModelFormatType) -> None:
    model = YOLO(model_path)
    model.export(format=model_format.value)
