from pickle import loads

import torch
from ultralytics import YOLO
from ultralytics.engine.results import Results
import tensorflow as tf
from PIL import Image
import numpy as np



from src.main.service.large_model_service import LargeModelService
from src.test.base.test_base import TestCaseBase


class TestFileSystemService(TestCaseBase):
    def _setup_internal(self):
        self.service = LargeModelService(self.config.large_model_service_config)

    def test_tf(self):
        interpreter = tf.lite.Interpreter(model_path="/home/hhoa/autoclip/autoclip-algorithm/src/resources/models/ping_pong/profession/best_saved_model/best_float32.tflite")
        interpreter.allocate_tensors()

        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()

        # 准备输入图像
        img = Image.open('/home/hhoa/autoclip/materials/ping_pong/singles/profession/dataset/fireball/from_val/professtion/未命名-f000025.png')

        print(f"原始图像模式: {img.mode}")

        # 自动处理不同的图像模式
        if img.mode in ('RGBA', 'LA', 'P'):
            # RGBA -> RGB, LA -> L, P -> RGB
            if img.mode == 'P':
                img = img.convert('RGBA')
            img = img.convert('RGB')
        elif img.mode == 'L':
            # 灰度图转 RGB
            img = img.convert('RGB')
        elif img.mode != 'RGB':
            # 其他模式都转为 RGB
            img = img.convert('RGB')

        img = img.resize((640, 640))

        # 转换为 numpy 数组
        input_data = np.array(img, dtype=np.float32)
        print(f"转换后图像形状: {input_data.shape}")

        # 归一化
        input_data = input_data / 255.0

        # 添加 batch 维度
        input_data = np.expand_dims(input_data, axis=0)

        expected_shape = tuple(input_details[0]['shape'])
        print(f"输入形状: {input_data.shape}")
        print(f"期望形状: {expected_shape}")

        # 推理
        interpreter.set_tensor(input_details[0]['index'], input_data)
        interpreter.invoke()

        # 获取输出
        output_data = interpreter.get_tensor(output_details[0]['index'])
        print(f"\n✓ 推理成功!")
        print(f"输出形状: {output_data.shape}")


    def load_and_preprocess_image(image_path, target_size=(640, 640)):
        """加载并预处理图像，确保是 RGB 格式"""
        img = Image.open(image_path)

        # 转换为 RGB（处理 RGBA、灰度图等）
        if img.mode != 'RGB':
            if img.mode == 'RGBA':
                # 如果有透明通道，使用白色背景
                background = Image.new('RGB', img.size, (255, 255, 255))
                background.paste(img, mask=img.split()[3])
                img = background
            else:
                img = img.convert('RGB')

        # 调整大小
        img = img.resize(target_size)

        # 转为数组并归一化
        img_array = np.array(img, dtype=np.float32) / 255.0

        # 添加 batch 维度
        img_array = np.expand_dims(img_array, axis=0)

        return img_array

    def test_yolo_predict(self):
        model = YOLO("/home/hhoa/autoclip/autoclip-algorithm/src/resources/models/ping_pong/profession/best_saved_model/best_float32.tflite", task="classify")

        path = "/home/hhoa/autoclip/materials/ping_pong/singles/profession/dataset/fireball/from_val/professtion/未命名-f000025.png"
        # img_array = self.load_and_preprocess_image("/home/hhoa/autoclip/materials/ping_pong/singles/profession/dataset/fireball/from_val/professtion/未命名-f000025.png")

        results: list[Results] = model.predict(  # pyright: ignore [reportUnknownVariableType]
            path,
            # "/home/hhoa/autoclip/materials/ping_pong/singles/profession/dataset/fireball/from_val/professtion/未命名-f000025.png"
        )  # type: ignore


    def test_pose_predit(self):
        model = YOLO("../../resources/models/yolo/yolo11n-pose.pt")

        results: list[Results] = model.predict(  # pyright: ignore [reportUnknownVariableType]
            "/home/hhoa/autoclip/materials/ping_pong/singles/profession/dataset/fireball/from_val/professtion/未命名-f000025.png"
        )  # type: ignore

        # Access the results
        for result in results:
            result.show()  # type: ignore
            xy: torch.Tensor = result.keypoints.xy  # type: ignore
            xyn: torch.Tensor = result.keypoints.xyn  # type: ignore
            kpts: torch.Tensor = result.keypoints.data  # type: ignore
            print(xy.shape)  # type: ignore
            print(xyn.shape)  # type: ignore
            print(kpts.shape)  # type: ignore
