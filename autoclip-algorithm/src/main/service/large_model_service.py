import random
import shutil
from pathlib import Path

from ultralytics import YOLO  # type: ignore

from src.main.config.config import LargeModelServiceConfig, ModelConfig
from src.main.constant.autoclip_constant import ActionType
from src.main.logger import LOG


# QT_QPA_PLATFORM=wayland
class ModelPredictor:
    def __init__(self, model_path: str, debug: bool) -> None:
        self.debug = debug
        self.model_path = model_path
        self.model_cache: YOLO | None = None

    def _get_model(self) -> YOLO:
        if self.model_cache is None:
            self.model_cache = YOLO(self.model_path, task="classify")
        return self.model_cache

    def predict(self, img_path: str, classes_mapping: dict[str, ActionType]) -> ActionType:
        res = self._get_model().predict(img_path, verbose=self.debug)  # type: ignore
        top1: str = res[0].names[res[0].probs.top1]  # type: ignore
        if top1 in classes_mapping:
            return classes_mapping[top1]
        raise Exception(f"Unknown action type: {top1}")


class LargeModelService:
    def __init__(self, large_model_service_config: LargeModelServiceConfig) -> None:
        self.models: dict[str, ModelConfig] = large_model_service_config.models

        self.train_model_name: str = large_model_service_config.train_model_name
        self.train_model_config: ModelConfig = self.models[self.train_model_name]
        self.train_model_path: str = self.train_model_config.train_model_path

        self.debug = large_model_service_config.debug

    def train(self) -> None:
        model = YOLO(self.train_model_path)
        LOG.info(f"start to link dataset to {self.train_model_config.train_dataset_path}")
        total_dataset_path = self.train_model_config.total_dataset_path

        class_dirs = list(Path(total_dataset_path).glob("*"))
        LOG.info(f"total {len(class_dirs)} classes")

        train_dataset_path = Path(self.train_model_config.train_dataset_path)
        if train_dataset_path.exists():
            shutil.rmtree(train_dataset_path)
        train_dataset_path.mkdir(parents=True, exist_ok=True)

        for class_dir in class_dirs:
            files = list(class_dir.rglob("**/*"))
            files = [file for file in files if file.is_file()]

            random.shuffle(files)
            train_files = files[: int(len(files) * 0.8)]
            val_files = files[int(len(files) * 0.8) :]

            class_train_dataset_path = train_dataset_path / "train" / class_dir.name
            class_train_dataset_path.mkdir(parents=True, exist_ok=True)

            class_val_dataset_path = train_dataset_path / "val" / class_dir.name
            class_val_dataset_path.mkdir(parents=True, exist_ok=True)

            for index, file in enumerate(train_files):
                if file.is_file():
                    link_soft_path = class_train_dataset_path / f"{index}.{file.suffix}"
                    link_soft_path.symlink_to(file)

            LOG.info(
                f"End to link train dataset to {class_train_dataset_path},\
                    total {len(train_files)} files"
            )

            for index, file in enumerate(val_files):
                if file.is_file():
                    link_soft_path = class_val_dataset_path / f"{index}.{file.suffix}"
                    link_soft_path.symlink_to(file)

            LOG.info(
                f"End to link val dataset to {class_val_dataset_path},\
                total {len(val_files)} files"
            )

        model.train(  # type: ignore
            data=self.train_model_config.train_dataset_path,
            hsv_h=1.0,
            hsv_s=1.0,
            epochs=100,
            imgsz=640,
            name=self.train_model_config.train_output_path,
            device=0,
            verbose=self.debug,
        )

    def get_predictor(self, model_name: str) -> ModelPredictor:
        model_path = self.get_model_path(model_name)
        return ModelPredictor(model_path, self.debug)

    def get_model_path(self, model_name: str) -> str:
        return self.models[model_name].predict_model_path
