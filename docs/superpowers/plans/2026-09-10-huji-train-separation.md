# huji-algorithm 训练分离(huji-train)+ 推理去 ultralytics 化 — 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把训练代码复制到独立的 huji-train 仓库(可运行),然后从 huji-algorithm 删除训练代码并把推理从 ultralytics 切到 ncnn。

**Architecture:** 两阶段。阶段一:依赖闭包复制(保留 `src.main.*` 包路径,零 import 改动)到 `~/autoclip/huji-train`,训练专用 main.py 三模式(train / gen-frames / export-ncnn),配置与依赖裁剪。阶段二:huji-algorithm 删训练代码,`ModelPredictor` 重写为 ncnn 实现(letterbox 640 / pad 114 / /255,镜像 app 侧 Dart 行为),移除 ultralytics/torch。

**Tech Stack:** Python 3.12、ultralytics(仅 huji-train)、ncnn(python binding)、ruamel.yaml、ray[client]、unittest、ruff。

**规格:** `docs/superpowers/specs/2026-09-10-huji-train-separation-design.md`

## Global Constraints

- 源仓库:`/home/hhoa/git/hhoa/huji/huji-algorithm`(下称 `$ALGO`);目标仓库:`/home/hhoa/autoclip/huji-train`(下称 `$TRAIN`,git 远程 `github.com/hhoao/huji-train.git` 已配好,main 分支无提交)。
- 复制的文件**保留原路径与原内容**(`src/main/...`),不改 import(`src.main.*` 顶层包名不变)。
- 提交信息格式(两仓库 pre-commit 均强制):`<type>(<scope>)?: <subject>`,type ∈ feat|fix|docs|style|refactor|perf|test|chore|revert|ci|build。
- Python 3.12(`.python-version` = 3.12.8),ruff line-length 100。
- 阶段二开始前,阶段一必须全部完成并验证(训练能力任何时刻不缺失)。
- 不搬:`src/resources/video/`、`docker/`、示例视频。
- ncnn 模型 IO:`in0` 输入 3×640×640,`out0` 输出;类别名在 `metadata.yaml` 的 `names`(int→str dict)。
- letterbox 规范(与 `huji-app/lib/services/inference/image_preprocessor.dart` 一致):scale = min(640/w, 640/h),双三次插值,画布 640×640 填 pad 114,居中贴图。

---

## 阶段一:huji-train 复制建仓

### Task 1: 复制闭包代码与资源到 huji-train

**Files:**
- Create(huji-train 下,均为 `$ALGO` 同路径复制):`src/__init__.py`
- Create: `src/main/train/{__init__.py,train_helper.py}`
- Create: `src/main/core/{__init__.py,action_segment_detector.py,auto_clipper.py,badminton_action_segment_detector.py,badminton_auto_clipper.py,frame_action_predictor.py,ping_pong_action_segment_detector.py,pingpong_auto_clipper.py}`
- Create: `src/main/service/{__init__.py,large_model_service.py,progress_handler.py}`
- Create: `src/main/config/{__init__.py,config.py}`
- Create: `src/main/constant/{__init__.py,autoclip_constant.py,common_constant.py,error_codes.py,progress_constant.py,server_api.py}`
- Create: `src/main/pojo/{__init__.py,video_clip_vo.py}`
- Create: `src/main/logger/__init__.py`
- Create: `src/main/__init__.py`(空)
- Create: `src/main/utils/{__init__.py,path_utils.py,video_utils.py,cleanup_utils.py,common_util.py,string_utils.py,filesystem_utils.py,jasypt4py.py}`
- Create: `src/main/utils/stopit/{__init__.py,signalstop.py,threadstop.py,utils.py}`
- Create: `src/resources/models/`(整个目录,含 `badminton/{singles,doubles}/`、`ping_pong/{normal,profession}/` 的 `best.pt`+`last.pt`、`yolo/yolo11n-cls.pt`+`yolo11n-pose.pt`)
- Create: `scripts/{export_ncnn.py,verify_ncnn_parity.py}`
- Create: `yolo11n.pt`
- Test: Task 4 的 import 冒烟

**Interfaces:**
- Consumes: 无(第一个任务)
- Produces: huji-train 下完整的 `src.main.*` 包(后续任务原地裁剪 config.py / yml)

- [ ] **Step 1: 用 cp 复制全部闭包文件(保留目录结构)**

在 shell 里执行(一次性、机械):

```bash
TRAIN=/home/hhoa/autoclip/huji-train
ALGO=/home/hhoa/git/hhoa/huji/huji-algorithm

# 包骨架
mkdir -p $TRAIN/src/main/{train,core,service,config,constant,pojo,logger,utils/stopit}
mkdir -p $TRAIN/src/resources $TRAIN/scripts $TRAIN/src/test/{base,train,service}

# src 根 + main 包
cp $ALGO/src/__init__.py $TRAIN/src/
cp $ALGO/src/main/__init__.py $TRAIN/src/main/

# train
cp $ALGO/src/main/train/*.py $TRAIN/src/main/train/

# core(全部 7 个 py + __init__)
cp $ALGO/src/main/core/*.py $TRAIN/src/main/core/

# service(只取闭包内的 3 个)
cp $ALGO/src/main/service/{__init__,large_model_service,progress_handler}.py $TRAIN/src/main/service/

# config / constant / pojo / logger
cp $ALGO/src/main/config/*.py $TRAIN/src/main/config/
cp $ALGO/src/main/constant/{__init__,autoclip_constant,common_constant,error_codes,progress_constant,server_api}.py $TRAIN/src/main/constant/
cp $ALGO/src/main/pojo/*.py $TRAIN/src/main/pojo/
cp $ALGO/src/main/logger/__init__.py $TRAIN/src/main/logger/

# utils
cp $ALGO/src/main/utils/{__init__,path_utils,video_utils,cleanup_utils,common_util,string_utils,filesystem_utils,jasypt4py}.py $TRAIN/src/main/utils/
cp $ALGO/src/main/utils/stopit/*.py $TRAIN/src/main/utils/stopit/

# 资源:模型权重
cp -r $ALGO/src/resources/models $TRAIN/src/resources/

# 脚本与底模
cp $ALGO/scripts/{export_ncnn.py,verify_ncnn_parity.py} $TRAIN/scripts/
cp $ALGO/yolo11n.pt $TRAIN/
```

注意:**不要复制** `__pycache__`、`src/resources/{ncnn_models,video,test,application*.yml}`(yml 在 Task 2 重写)。

- [ ] **Step 2: 校验文件清单与源一致**

Run: `diff -r --exclude=__pycache__ $ALGO/src/main/train $TRAIN/src/main/train && diff $ALGO/src/main/core/auto_clipper.py $TRAIN/src/main/core/auto_clipper.py && ls $TRAIN/src/resources/models/ping_pong/normal/`
Expected: 无 diff 输出;models 下能看到 `best.pt last.pt`。

- [ ] **Step 3: Commit(huji-train 仓库)**

```bash
cd /home/hhoa/autoclip/huji-train
git add -A
git commit -m "feat: copy training code closure from huji-algorithm"
```

(注:huji-train 尚无 pre-commit hooks,提交不会受阻;Task 3 会装上。)

### Task 2: 裁剪 config.py 与 application*.yml

**Files:**
- Modify: `/home/hhoa/autoclip/huji-train/src/main/config/config.py`
- Create: `/home/hhoa/autoclip/huji-train/src/resources/application.yml`
- Create: `/home/hhoa/autoclip/huji-train/src/resources/application_dev.yml`
- Create: `/home/hhoa/autoclip/huji-train/src/resources/application_prod.yml`
- Test: `python -c "from src.main.config.config import load_config; load_config()"`(Task 4 运行)

**Interfaces:**
- Consumes: Task 1 复制的 config.py
- Produces: `Config` 类只含 `env/logger_level/debug/job_type/large_model_service_config/auto_clip_config` 六个属性;`load_config()` 不变(签名 `load_config(config_path: str = CONFIG_PATH) -> Config`);`ModelConfig`/`LargeModelServiceConfig`/`CommonAutoClipOptions` 等闭包类保持原样

- [ ] **Step 1: 从 config.py 删除非训练配置类**

删除以下类定义(整块删除,共 6 个类):`DataSourceConfig`、`DataSourcesConfig`、`ServiceConfig`、`InternalHttpConfig`、`InternalConfig`、`KafkaConfig`。

`FileSystemConfig`/`FTPConfig`/`S3Config`/`FileSystemsConfig` 也删除(服务端对象存储,训练不用);`filesystem_utils` 的 import 若因此不再使用则一并删除(`filesystem_utils` 仅被 `S3Config` 和 `config.py` 头部引用,删除后从 import 行去掉 `filesystem_utils`,保留 `path_utils, string_utils`;`EndpointInfo` 的 import 同样从 `autoclip_constant` import 行去掉,保留 `MatchType, ModeEnum`)。

`Config.__init__` 末尾删除五行:

```python
        self.service_config: ServiceConfig = ServiceConfig(self._get_sub_config_context("service"))
        self.filesystem_config: FileSystemsConfig = FileSystemsConfig(
            self._get_sub_config_context("filesystem")
        )
        self.datasource_config: DataSourcesConfig = DataSourcesConfig(
            self._get_sub_config_context("datasource")
        )
        self.kafka_config: KafkaConfig = KafkaConfig(self._get_sub_config_context("kafka"))
        self.internal: InternalConfig = InternalConfig(self._get_sub_config_context("internal"))
```

保留:`ConfigContext`、`SecurityConfig`、`AutoClipCleanupConfig`、`CommonAutoClipOptions`、`PingPongAutoClipOptions`、`BadmintonAutoClipOptions`、`AutoClipServiceConfig`、`ModelConfig`、`LargeModelServiceConfig`、`Config`、`load_config`。

- [ ] **Step 2: 写裁剪版 application.yml**

完整内容(基于 `$ALGO/src/resources/application.yml` 删除 filesystem/service/kafka/internal 段,`$PROJECT_ROOT`/`$PROJECT_RESOURCES` 前缀机制不变):

```yaml
logger_level: info
env: "dev"
job_type: train_model
debug: True

large_model:
  train_model_name: ping_pong_singles_profession
  models:
    ping_pong_singles_profession:
      train_output_path: output/models/classify/ping_pong/profession/result
      total_dataset_path: "$PROJECT_ROOT/materials/ping_pong/singles/profession/dataset"
      train_dataset_path: "$PROJECT_ROOT/materials/ping_pong/singles/profession/train_dataset"
      train_model_path: "$PROJECT_RESOURCES/models/ping_pong/profession/last.pt"
      predict_model_path: "$PROJECT_RESOURCES/models/ping_pong/profession/best.pt"
    badminton_doubles:
      train_output_path: output/models/classify/badminton/doubles/result
      total_dataset_path: "$PROJECT_ROOT/materials/badminton/doubles/dataset"
      train_dataset_path: "$PROJECT_ROOT/materials/badminton/doubles/train_dataset"
      train_model_path: "$PROJECT_RESOURCES/models/badminton/doubles/last.pt"
      predict_model_path: "$PROJECT_RESOURCES/models/badminton/doubles/best.pt"
    badminton_singles:
      train_output_path: output/models/classify/badminton/singles/result
      total_dataset_path: "$PROJECT_ROOT/materials/badminton/singles/dataset"
      train_dataset_path: "$PROJECT_ROOT/materials/badminton/singles/train_dataset"
      train_model_path: "$PROJECT_RESOURCES/models/badminton/singles/last.pt"
      predict_model_path: "$PROJECT_RESOURCES/models/badminton/singles/best.pt"

autoclip_service_config:
  ping_pong:
    models:
      singles: ping_pong_singles_profession
  badminton:
    models:
      singles: badminton_singles
      doubles: badminton_doubles
  common:
    cache_path: "$PROJECT_ROOT/output/cache"
    output_dir: "$PROJECT_ROOT/output/clipped"
```

- [ ] **Step 3: 写 application_dev.yml 与 application_prod.yml**

dev(`job_type: train_model` 是训练仓库的默认职责):

```yaml
logger_level: DEBUG
env: dev
job_type: train_model

autoclip_service_config:
  common:
    cache_path: "$PROJECT_ROOT/output/cache"
    output_dir: "$PROJECT_ROOT/output/clipped"
    debug_clip_frame_output_dir: "$PROJECT_ROOT/output/clip_snippet"
    cleanup:
      enabled: True
      clean_resized: True
      clean_clipped: False
      clean_snippet: False
      cache_retention_days: 7
```

prod:

```yaml
logger_level: INFO
env: "prod"
job_type: train_model
debug: False
```

- [ ] **Step 4: Commit**

```bash
cd /home/hhoa/autoclip/huji-train
git add src/main/config/config.py src/resources/
git commit -m "refactor(config): trim to training-only config sections"
```

### Task 3: 仓库脚手架(requirements / setup / 工具链)

**Files:**
- Create: `/home/hhoa/autoclip/huji-train/requirements.txt`
- Create: `/home/hhoa/autoclip/huji-train/{setup.sh,setup.ps1,pyproject.toml,.pre-commit-config.yaml,.python-version,.gitattributes,.cursorindexingignore,pyrightconfig.json,.env.example,.gitignore}`
- Create: `/home/hhoa/autoclip/huji-train/scripts/{commit-check.sh,format-check.sh}`
- Create: `/home/hhoa/autoclip/huji-train/README.md`

**Interfaces:**
- Consumes: 无
- Produces: `./setup.sh` 可建立 `.venv` 并安装全部依赖;pre-commit hooks 生效

- [ ] **Step 1: 写 requirements.txt(裁剪 + 新增)**

完整内容:

```
setuptools<81

ruamel.yaml==0.18.10

pycryptodome~=3.22.0
tenacity~=9.1.2
loguru~=0.7.3
opencv-python~=4.11.0.86
ultralytics~=8.3.130

tqdm~=4.67.1
typing_extensions~=4.13.2

httpx~=0.28.1

numpy~=2.2.5

orjson~=3.10.18
pydantic~=2.11.4

ray[client]==2.41.0

onnxruntime~=1.20.0
ncnn~=1.0.20250514
```

(相对 $ALGO:删 flask/flask-cors/oss2/cos-sdk/DBUtils/pandas/PyMySQL/mysql-connector/SQLAlchemy/confluent-kafka/requests/types-confluent-kafka/pandas-stubs;加 onnxruntime、ncnn。ncnn 版本号以 `pip index versions ncnn` 或 pip 安装时的最新 1.0.x 为准,若计划版本不存在则用安装时解析到的版本并回写。)

- [ ] **Step 2: 复制仓库元文件**

```bash
TRAIN=/home/hhoa/autoclip/huji-train
ALGO=/home/hhoa/git/hhoa/huji/huji-algorithm
cp $ALGO/{setup.sh,setup.ps1,pyproject.toml,.pre-commit-config.yaml,.python-version,.gitattributes,.cursorindexingignore,pyrightconfig.json,.env.example} $TRAIN/
mkdir -p $TRAIN/scripts
cp $ALGO/scripts/{commit-check.sh,format-check.sh} $TRAIN/scripts/
```

- [ ] **Step 3: 写 .gitignore**

在 $ALGO 版本基础上加训练输出与 ncnn 产物:

```gitignore
# IntelliJ project files
.idea
*.iml
out
gen
output
runs
cache
logs
**/__pycache__
typings
**/.ruff_cache
.specstory
.venv

# 训练数据集与产物(materials/ 本地放数据集、output/ 放训练结果)
materials/

# ncnn 导出产物(构建产物,产出后拷贝到 huji-app assets)
src/resources/ncnn_models/
```

- [ ] **Step 4: 写 README.md**

```markdown
# Huji Train

乒乓球、羽毛球分类模型训练仓库(从 huji-algorithm 分离)。

## 环境

- Python 3.12+、FFmpeg(在 PATH 中)
- GPU 可选;Windows 上 PyTorch 若安装失败,按 [pytorch.org](https://pytorch.org) 选择 CUDA 版本后 `pip install`

## 快速开始

```bash
./setup.sh
source .venv/bin/activate

python main.py --train                                    # 训练
python main.py --gen-frames -v <视频> --sport ping_pong  # 生成训练帧
python main.py --export-ncnn                              # .pt → ncnn 导出
```

## 数据集

数据集放在 `materials/<sport>/<singles|doubles>/<match_type>/dataset/<类别>/` 下
(见 `src/resources/application.yml` 的 `large_model.models.*.total_dataset_path`),
每类一个目录,目录名即类别名。

## 模型流向

训练 → `output/models/.../best.pt` → 拷回 `src/resources/models/<sport>/<match_type>/`
→ `python main.py --export-ncnn` → `src/resources/ncnn_models/`(gitignore)
→ 拷贝到 `huji-algorithm/src/resources/ncnn_models/` 与 `huji-app/assets/models/`。

## 测试

```bash
python -m unittest discover -s src/test -p "test_*.py"
```
```

- [ ] **Step 5: 运行 setup.sh**

Run: `cd /home/hhoa/autoclip/huji-train && ./setup.sh`
Expected: venv 建立、依赖安装、pre-commit 安装、`pre-commit run --all-files` 通过(format-check 需要 .venv 内 ruff/pyright,setup.sh 已装)。若 ruff format 改动了文件,确认改动合理后保留。

- [ ] **Step 6: Commit**

```bash
cd /home/hhoa/autoclip/huji-train
git add -A
git commit -m "chore: repo scaffolding (requirements, setup, hooks, readme)"
```

### Task 4: 训练专用 main.py + 测试复制

**Files:**
- Create: `/home/hhoa/autoclip/huji-train/main.py`
- Create: `/home/hhoa/autoclip/huji-train/src/test/base/{__init__.py,test_base.py}`(复制)
- Create: `/home/hhoa/autoclip/huji-train/src/test/train/{__init__.py,test_train_helper.py}`(复制)
- Create: `/home/hhoa/autoclip/huji-train/src/test/service/{__init__.py,test_large_model_service.py}`(复制)
- Test: `python main.py --help`、unittest

**Interfaces:**
- Consumes: Task 2 的 `load_config`、`Config`;闭包内的 `LargeModelService`、`PingPongAutoClipper`、`BadmintonAutoClipper`、`create_classify_frames`、`ActionSegmentDetector` 实现
- Produces: CLI `--train` / `--gen-frames -v PATH --sport S --match-type M` / `--export-ncnn [--out DIR]`;`run_train(config: Config) -> None`、`run_gen_frames(args: argparse.Namespace, config: Config) -> None`、`run_export_ncnn() -> None`

- [ ] **Step 1: 写 main.py**

完整内容(基于 $ALGO/main.py 改写;`_check_runtime_deps`、`_venv_python`、`_apply_set_overrides` 原样保留;去掉 clip/serve):

```python
import argparse
import importlib.util
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any


def _venv_python() -> str | None:
    venv_dir = Path(__file__).resolve().parent / ".venv"
    if sys.platform == "win32":
        candidate = venv_dir / "Scripts" / "python.exe"
    else:
        candidate = venv_dir / "bin" / "python"
    return str(candidate) if candidate.is_file() else None


def _check_runtime_deps() -> None:
    if importlib.util.find_spec("ruamel.yaml") is None:
        print("未找到 Python 依赖,请先安装并激活虚拟环境:", file=sys.stderr)
        if sys.platform == "win32":
            print("  .\\setup.ps1", file=sys.stderr)
            print("  .venv\\Scripts\\activate", file=sys.stderr)
        else:
            print("  ./setup.sh", file=sys.stderr)
            print("  source .venv/bin/activate", file=sys.stderr)
        venv_python = _venv_python()
        if venv_python:
            print(f"  或直接: {venv_python} main.py ...", file=sys.stderr)
        sys.exit(1)


_check_runtime_deps()

from src import CONFIG_PATH
from src.main.config.config import Config, load_config
from src.main.constant.autoclip_constant import MatchType
from src.main.constant.common_constant import JobType
from src.main.core.action_segment_detector import ActionSegmentDetector
from src.main.core.badminton_action_segment_detector import BadmintonActionSegmentDetector
from src.main.core.badminton_auto_clipper import BadmintonAutoClipper
from src.main.core.ping_pong_action_segment_detector import PingPongActionSegmentDetector
from src.main.core.pingpong_auto_clipper import PingPongAutoClipper
from src.main.service.large_model_service import LargeModelService
from src.main.train.train_helper import create_classify_frames


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="乒乓球、羽毛球分类模型训练",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python main.py --train
  python main.py --gen-frames -v videos/demo.mp4 --sport ping_pong
  python main.py --export-ncnn
        """,
    )
    parser.add_argument(
        "--config",
        default=CONFIG_PATH,
        help=f"配置目录(含 application.yml),默认 {CONFIG_PATH}",
    )
    parser.add_argument(
        "--set",
        action="append",
        metavar="KEY=VALUE",
        default=[],
        help="覆盖任意配置项,等价于同名环境变量,可重复;"
        "KEY 为配置文件中的点号路径,如 --set large_model.debug=True",
    )
    parser.add_argument("--train", action="store_true", help="训练模型")
    parser.add_argument(
        "--gen-frames",
        action="store_true",
        help="从视频生成分类训练帧(create_classify_frames)",
    )
    parser.add_argument("--video-path", "-v", metavar="PATH", help="训练帧源视频路径")
    parser.add_argument(
        "--sport",
        choices=["ping_pong", "badminton"],
        help="运动类型(gen-frames 模式必填)",
    )
    parser.add_argument(
        "--match-type",
        choices=["singles", "doubles"],
        default="singles",
        help="羽毛球比赛类型,默认 singles",
    )
    parser.add_argument(
        "--base-dir",
        metavar="DIR",
        help="训练帧输出根目录,默认 $PROJECT_ROOT/output/train_frames",
    )
    parser.add_argument(
        "--export-ncnn",
        action="store_true",
        help="把 src/resources/models/ 的 best.pt 导出为 ncnn",
    )
    parser.add_argument(
        "--out",
        metavar="DIR",
        help="ncnn 导出目录,默认 src/resources/ncnn_models",
    )
    return parser


def _apply_set_overrides(args: argparse.Namespace) -> None:
    """将 --set KEY=VALUE 注入环境变量,复用配置层已有的 env 覆盖机制。"""
    for item in args.set:
        key, sep, value = item.partition("=")
        if not sep or not key.strip() or not value:
            print(f"--set 参数格式错误: {item},应为 KEY=VALUE", file=sys.stderr)
            sys.exit(1)
        env_key = key.strip().replace(".", "_")
        os.environ[env_key] = value


def _resolve_mode(args: argparse.Namespace) -> str:
    modes = [args.train, args.gen_frames, args.export_ncnn]
    if sum(bool(m) for m in modes) > 1:
        print("不能同时指定 --train、--gen-frames、--export-ncnn", file=sys.stderr)
        sys.exit(1)
    if args.train:
        return "train"
    if args.gen_frames:
        return "gen_frames"
    if args.export_ncnn:
        return "export_ncnn"
    return "config"


def run_train(config: Config) -> None:
    large_model_service = LargeModelService(config.large_model_service_config)
    large_model_service.train()


def run_gen_frames(args: argparse.Namespace, config: Config) -> None:
    if not args.video_path:
        print("gen-frames 模式需要指定 --video-path / -v", file=sys.stderr)
        sys.exit(1)
    if not args.sport:
        print("gen-frames 模式需要指定 --sport(ping_pong 或 badminton)", file=sys.stderr)
        sys.exit(1)
    video_path = os.path.abspath(args.video_path)
    if not os.path.isfile(video_path):
        print(f"视频文件不存在: {video_path}", file=sys.stderr)
        sys.exit(1)

    auto_clip_config = config.auto_clip_config
    common_options = auto_clip_config.common_options
    large_model_service = LargeModelService(config.large_model_service_config)
    base_dir = args.base_dir or os.path.join(
        os.environ.get("PROJECT_ROOT", os.getcwd()), "output", "train_frames"
    )

    if args.sport == "ping_pong":
        clipper = PingPongAutoClipper(
            auto_clip_config.ping_pong, common_options, large_model_service
        )
        detector: ActionSegmentDetector = PingPongActionSegmentDetector(
            is_ignore_playback=True,
            is_merge_fire_ball_and_play_ball=False,
        )
        classes_mapping = clipper._get_classes_mapping()  # noqa: SLF001
    else:
        clipper = BadmintonAutoClipper(
            auto_clip_config.badminton, common_options, large_model_service
        )
        detector = BadmintonActionSegmentDetector(is_ignore_playback=True)
        classes_mapping = clipper._get_classes_mapping()  # noqa: SLF001

    model_name = (
        auto_clip_config.ping_pong.singles_model
        if args.sport == "ping_pong"
        else auto_clip_config.badminton.singles_model
        if args.match_type == "singles"
        else auto_clip_config.badminton.doubles_model
    )

    action_points = create_classify_frames(
        auto_clipper=clipper,
        action_segment_detector=detector,
        video_path=video_path,
        model_name=model_name,
        class_mappings=classes_mapping,
        base_dir=base_dir,
    )
    print(f"generated frames under {base_dir}, {len(action_points)} action points")


def run_export_ncnn(args: argparse.Namespace) -> None:
    scripts_dir = Path(__file__).resolve().parent / "scripts" / "export_ncnn.py"
    cmd = [sys.executable, str(scripts_dir)]
    if args.out:
        cmd += ["--out", args.out]
    raise SystemExit(subprocess.call(cmd))


def main() -> None:
    parser = _build_parser()
    args = parser.parse_args()
    mode = _resolve_mode(args)

    if mode == "export_ncnn":
        run_export_ncnn(args)
        return

    _apply_set_overrides(args)
    config = load_config(args.config)

    if mode == "train":
        run_train(config)
    elif mode == "gen_frames":
        run_gen_frames(args, config)
    else:
        if config.job_type == JobType.TRAIN_MODEL:
            run_train(config)
        else:
            print(f"未知的 job_type: {config.job_type}", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()
```

**实现者注意**:写完后检查 `PingPongAutoClipper._get_classes_mapping` / `BadmintonAutoClipper._get_classes_mapping` 的真实签名(在 `$ALGO/src/main/core/auto_clipper.py:110`),若它们不是无参方法(例如需要 match_type 参数),按真实签名调整 `run_gen_frames` 里的调用;`MatchType`/`json` 若未使用则删除 import。

- [ ] **Step 2: 复制测试**

```bash
TRAIN=/home/hhoa/autoclip/huji-train
ALGO=/home/hhoa/git/hhoa/huji/huji-algorithm
cp $ALGO/src/test/base/{__init__.py,test_base.py} $TRAIN/src/test/base/
cp $ALGO/src/test/train/{__init__.py,test_train_helper.py} $TRAIN/src/test/train/
cp $ALGO/src/test/service/{__init__.py,test_large_model_service.py} $TRAIN/src/test/service/
```

`test_large_model_service.py` 保留 pose 实验测试(它验证 ultralytics 可用,且已 `@unittest.skip`)。

- [ ] **Step 3: 验证 main.py 可用**

Run:
```bash
cd /home/hhoa/autoclip/huji-train && source .venv/bin/activate
python main.py --help
python main.py   # config 模式 → job_type=train_model → 会开始训练并因缺数据集报错;用 Ctrl-C 验证到数据集检查即可
```
Expected: `--help` 打印三种模式;`python main.py` 能加载配置并进入训练逻辑(日志出现 `start to link dataset to ...`),因 `materials/` 不存在而失败属预期(Ctrl-C 退出)。

- [ ] **Step 4: 运行 unittest**

Run: `cd /home/hhoa/autoclip/huji-train && .venv/bin/python -m unittest discover -s src/test -p "test_*.py" -v 2>&1 | tail -20`
Expected: 全部 PASS 或 skip(需要本地数据的测试保持 skip),0 errors。

- [ ] **Step 5: Commit**

```bash
cd /home/hhoa/autoclip/huji-train
git add -A
git commit -m "feat(cli): training-only main.py (train / gen-frames / export-ncnn)"
```

### Task 5: 阶段一收尾 — ruff + 全量回归 + 推送

**Files:**
- Modify(如 ruff 报问题): huji-train 下相应文件

**Interfaces:**
- Consumes: Task 1-4 全部
- Produces: 已验证、已推送的 huji-train main 分支

- [ ] **Step 1: ruff 全量检查**

Run: `cd /home/hhoa/autoclip/huji-train && .venv/bin/ruff check . && .venv/bin/ruff format --check .`
Expected: 通过;有告警就修(复制代码应基本干净,新增 main.py 可能需要 format)。

- [ ] **Step 2: export-ncnn 入口冒烟**

Run: `cd /home/hhoa/autoclip/huji-train && .venv/bin/python main.py --export-ncnn --out /tmp/ncnn_smoke 2>&1 | tail -10`
Expected: 4 个 combo 全部 `[ok] ... -> /tmp/ncnn_smoke/...`(模型 .pt 已复制,ultralytics 已装;若本机无 GPU 也应能导出,CPU 即可)。检查产物:`ls /tmp/ncnn_smoke/ping_pong/normal/` 应有 `model.ncnn.param model.ncnn.bin metadata.yaml`。验证后 `rm -rf /tmp/ncnn_smoke`。

- [ ] **Step 3: 阶段一验证清单逐项确认**

对照规格 §"验证标准(阶段一)":setup.sh ✓(Task 3)、--help/--train ✓(Task 4)、unittest ✓(Task 4)、export-ncnn ✓(Step 2)、ruff ✓(Step 1)。任何一项不满足,回到对应任务修复。

- [ ] **Step 4: 推送 huji-train**

```bash
cd /home/hhoa/autoclip/huji-train
git push -u origin main
```

(这是外发动作,执行前与用户确认。)

---

## 阶段二:huji-algorithm 去训练化 + 推理切 ncnn

阶段二所有工作在 `$ALGO`(/home/hhoa/git/hhoa/huji/huji-algorithm,独立 git 仓库)进行;最后 Task 10 更新 huji 主仓库的 submodule 指针。

### Task 6: ncnn 版 ModelPredictor(TDD)

**Files:**
- Modify: `/home/hhoa/git/hhoa/huji/huji-algorithm/src/main/service/large_model_service.py`
- Test: `/home/hhoa/git/hhoa/huji/huji-algorithm/src/test/service/test_large_model_service.py`(改写)

**Interfaces:**
- Consumes: `LargeModelServiceConfig`/`ModelConfig`(config.py,本轮不改);ncnn 模型文件 `$ALGO/src/resources/ncnn_models/<sport>/<match_type>/model.ncnn.{param,bin}` + `metadata.yaml`(已存在,24MB,已进仓库)
- Produces: `class NcnnModelPredictor` 与 `ModelPredictor` 同接口:`__init__(self, param_path: str, debug: bool) -> None`、`predict(self, img_path: str, classes_mapping: dict[str, ActionType]) -> ActionType`;`LargeModelService.get_predictor(model_name: str) -> ModelPredictor` 行为不变(返回 ncnn 实现);新增模块级函数 `letterbox_image(img_path: str, size: int = 640) -> "np.ndarray"`(返回 CHW float32 /255)

- [ ] **Step 1: 写失败测试(用真模型对真图片)**

改写 `test_large_model_service.py` 全文:

```python
import tempfile
import unittest
from pathlib import Path

import cv2
import numpy as np

from src.main.constant.autoclip_constant import (
    ActionType,
    badminton_classes_mapping,
    ping_pong_classes_mapping,
)
from src.main.service.large_model_service import NcnnModelPredictor, letterbox_image
from src.test.base.test_base import TestCaseBase

RESOURCES = Path(__file__).resolve().parents[2] / "resources"
NCNN_ROOT = RESOURCES / "ncnn_models"


def _make_test_image() -> str:
    """随机 RGB 640x480 图,写为 png。"""
    img = np.random.default_rng(42).integers(0, 256, size=(480, 640, 3), dtype=np.uint8)
    f = Path(tempfile.gettempdir()) / "huji_ncnn_pred_test.png"
    cv2.imwrite(str(f), cv2.cvtColor(img, cv2.COLOR_RGB2BGR))
    return str(f)


class TestLetterbox(unittest.TestCase):
    def test_letterbox_shape_and_pad(self):
        arr = letterbox_image(_make_test_image(), size=640)
        self.assertEqual(arr.shape, (3, 640, 640))
        self.assertEqual(arr.dtype, np.float32)
        # 640x480 → scale=1.0? 不:短边 480 → scale=640/480=1.333,newH=640,newW=853>640 → scale 收敛为 640/640=1.0
        # 宽图:左右 pad 应为 114/255
        self.assertAlmostEqual(float(arr[:, : (640 - 480) // 2, :].mean()), 114 / 255, places=2)


class TestNcnnPredictor(TestCaseBase):
    def _setup_internal(self):
        pass

    def test_predict_returns_known_action(self):
        param = str(NCNN_ROOT / "ping_pong" / "normal" / "model.ncnn.param")
        predictor = NcnnModelPredictor(param, debug=False)
        action = predictor.predict(_make_test_image(), ping_pong_classes_mapping)
        self.assertIsInstance(action, ActionType)

    def test_predict_badminton(self):
        param = str(NCNN_ROOT / "badminton" / "singles" / "model.ncnn.param")
        predictor = NcnnModelPredictor(param, debug=False)
        action = predictor.predict(_make_test_image(), badminton_classes_mapping)
        self.assertIsInstance(action, ActionType)
```

注意:`test_predict_returns_known_action` 里随机图可能 argmax 到未知类别(模型 3 类都应能映射,fire_ball/pick_ball/play_ball 均在 mapping 中,断言 isinstance 即可);若 `ping_pong_classes_mapping` 不是超集(存在 `ignore` 类),把断言放宽为 "不抛 FileNotFoundError/ValueError"。先读 `$ALGO/src/main/constant/autoclip_constant.py:55-90` 确认 mapping 内容再定断言。

- [ ] **Step 2: 运行测试确认失败**

Run: `cd $ALGO && .venv/bin/python -m unittest src.test.service.test_large_model_service -v`
Expected: FAIL — `ImportError: cannot import name 'NcnnModelPredictor'`。

- [ ] **Step 3: 实现 letterbox_image + NcnnModelPredictor**

`large_model_service.py` 重写后的完整内容:

```python
from pathlib import Path

import cv2
import numpy as np
import ncnn
import ruamel.yaml

from src.main.config.config import LargeModelServiceConfig, ModelConfig
from src.main.constant.autoclip_constant import ActionType
from src.main.logger import LOG

INPUT_SIZE = 640
PAD_VALUE = 114
MEAN = [0.0, 0.0, 0.0]
NORM = [1 / 255.0, 1 / 255.0, 1 / 255.0]


def letterbox_image(img_path: str, size: int = INPUT_SIZE) -> np.ndarray:
    """YOLO classify letterbox:短边缩放到 size,pad 114 居中,/255,CHW。

    与 huji-app 的 ImagePreprocessor 行为一致。
    """
    img = cv2.imread(img_path, cv2.IMREAD_COLOR)
    if img is None:
        raise ValueError(f"Unable to read image: {img_path}")
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    h, w = img.shape[:2]
    scale = min(size / w, size / h)
    new_w, new_h = int(round(w * scale)), int(round(h * scale))
    new_w, new_h = max(1, min(new_w, size)), max(1, min(new_h, size))
    resized = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_CUBIC)
    canvas = np.full((size, size, 3), PAD_VALUE, dtype=np.uint8)
    x_off, y_off = (size - new_w) // 2, (size - new_h) // 2
    canvas[y_off : y_off + new_h, x_off : x_off + new_w] = resized
    return (canvas.astype(np.float32) / 255.0).transpose(2, 0, 1)


class NcnnModelPredictor:
    """ncnn 分类推理(替代 ultralytics YOLO),行为镜像 app 侧 Dart 实现。"""

    def __init__(self, param_path: str, debug: bool) -> None:
        self.debug = debug
        self.param_path = param_path
        self.bin_path = str(Path(param_path).with_suffix(".bin"))
        metadata_path = Path(param_path).parent / "metadata.yaml"
        yaml = ruamel.yaml.YAML(typ="safe", pure=True)
        with open(metadata_path) as f:
            metadata = yaml.load(f)
        self.names: dict[int, str] = {int(k): v for k, v in metadata["names"].items()}
        self._net: ncnn.Net | None = None

    def _get_net(self) -> ncnn.Net:
        if self._net is None:
            net = ncnn.Net()
            net.opt.use_vulkan_compute = False  # 与 parity 脚本一致,CPU 保证确定性
            net.load_param(self.param_path)
            net.load_model(self.bin_path)
            self._net = net
        return self._net

    def predict(self, img_path: str, classes_mapping: dict[str, ActionType]) -> ActionType:
        x = letterbox_image(img_path)
        mat = ncnn.Mat(np.ascontiguousarray(x))
        ex = self._get_net().create_extractor()
        ex.input("in0", mat)
        _, out = ex.extract("out0")
        logits = np.array(out)[0]
        top1 = self.names[int(np.argmax(logits))]
        if self.debug:
            LOG.info(f"ncnn predict {img_path}: top1={top1} logits={np.round(logits, 4).tolist()}")
        if top1 in classes_mapping:
            return classes_mapping[top1]
        raise ValueError(f"Unknown action type: {top1}")
```

`LargeModelService` 类保留(本轮不改名),修改两处:

```python
class LargeModelService:
    def __init__(self, large_model_service_config: LargeModelServiceConfig) -> None:
        self.models: dict[str, ModelConfig] = large_model_service_config.models
        self.debug = large_model_service_config.debug

    def get_predictor(self, model_name: str) -> NcnnModelPredictor:
        model_path = self.get_model_path(model_name)
        return NcnnModelPredictor(model_path, self.debug)

    def get_model_path(self, model_name: str) -> str:
        return self.models[model_name].predict_model_path
```

**同时删掉** `ModelPredictor` 旧类、`LargeModelService.train()`、`train_model_name`/`train_model_config` 字段、顶部 `import random`、`import shutil`、`from ultralytics import YOLO`。

检查引用:`grep -rn "ModelPredictor" $ALGO/src/main --include="*.py"` — `auto_clipper.py`/`frame_action_predictor.py` import 了 `ModelPredictor`(仅作类型注解/构造来源是 `LargeModelService.get_predictor`)。把这两处 import 从 `from src.main.service.large_model_service import LargeModelService, ModelPredictor` 改为 `from src.main.service.large_model_service import LargeModelService, NcnnModelPredictor as ModelPredictor`(保留类型注解可用,改动最小)。

- [ ] **Step 4: 运行测试确认通过**

Run: `cd $ALGO && .venv/bin/python -m unittest src.test.service.test_large_model_service -v`
Expected: PASS(letterbox 测试 + 2 个 ncnn 推理测试)。若 ncnn 包未装:`.venv/bin/pip install ncnn` 后重试(下一任务正式改 requirements)。

- [ ] **Step 5: Commit**

```bash
cd $ALGO
git add src/main/service/large_model_service.py src/main/core/auto_clipper.py src/main/core/frame_action_predictor.py src/test/service/test_large_model_service.py
git commit -m "feat(infer): ModelPredictor switches from ultralytics to ncnn"
```

### Task 7: 逐帧 parity 验证(旧 ultralytics vs 新 ncnn)

**Files:**
- Create(临时,验证完删除): `/home/hhoa/git/hhoa/huji/huji-algorithm/scripts/parity_frame_check.py`(不 commit)

**Interfaces:**
- Consumes: Task 6 的 `NcnnModelPredictor`;`$ALGO/src/resources/models/<combo>/best.pt`(旧权重,删除前还在)
- Produces: 4 模型 × 示例视频帧 argmax 一致性结论(合入门槛)

- [ ] **Step 1: 写临时对比脚本**

```python
#!/usr/bin/env python3
"""逐帧对比 ultralytics(.pt)与 ncnn 的 argmax,切换前的合入门槛。"""
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PT_ROOT = ROOT / "src" / "resources" / "models"
NCNN_ROOT = ROOT / "src" / "resources" / "ncnn_models"
VIDEO = ROOT / "src" / "resources" / "video" / "examples" / "test.mp4"
COMBOS = [
    ("ping_pong", "normal"),
    ("ping_pong", "profession"),
    ("badminton", "singles"),
    ("badminton", "doubles"),
]


def extract_frames() -> list[Path]:
    d = Path(tempfile.mkdtemp(prefix="parity_frames_"))
    subprocess.run(
        ["ffmpeg", "-y", "-i", str(VIDEO), "-vf", "fps=1", str(d / "f%03d.png")],
        check=True,
        capture_output=True,
    )
    return sorted(d.glob("*.png"))


def main() -> int:
    from ultralytics import YOLO

    sys.path.insert(0, str(ROOT))
    from src.main.service.large_model_service import NcnnModelPredictor  # noqa: E402

    frames = extract_frames()
    print(f"{len(frames)} frames from {VIDEO.name}")
    failures = 0
    for sport, match in COMBOS:
        yolo = YOLO(str(PT_ROOT / sport / match / "best.pt"))
        ncnn_pred = NcnnModelPredictor(str(NCNN_ROOT / sport / match / "model.ncnn.param"), False)
        mismatch = 0
        for f in frames:
            res = yolo.predict(str(f), verbose=False)
            yolo_top1 = res[0].names[res[0].probs.top1]
            logits = None  # ncnn 侧直接复用 predictor 内部逻辑
            x = ncnn_pred  # noqa
            # ncnn argmax
            import numpy as np

            from src.main.service.large_model_service import letterbox_image
            import ncnn as ncnn_lib

            mat = ncnn_lib.Mat(np.ascontiguousarray(letterbox_image(str(f))))
            ex = ncnn_pred._get_net().create_extractor()
            ex.input("in0", mat)
            _, out = ex.extract("out0")
            ncnn_top1 = ncnn_pred.names[int(np.argmax(np.array(out)[0]))]
            if yolo_top1 != ncnn_top1:
                mismatch += 1
        status = "PASS" if mismatch == 0 else "FAIL"
        print(f"{status} {sport}/{match}: {mismatch}/{len(frames)} mismatched")
        failures += mismatch
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
```

(脚本写得直白即可,不进仓库;实现者可按 `NcnnModelPredictor` 的真实私有方法名调整 `_get_net` 调用,或给 predictor 加一个 `predict_top1(img_path) -> str` 公开方法复用 —— 若加了这个方法,同步更新 Task 6 的 Produces 接口并在测试中补一条断言。)

- [ ] **Step 2: 运行对比**

Run: `cd $ALGO && .venv/bin/python scripts/parity_frame_check.py`
Expected: 4 行全部 PASS。

**若 FAIL**:不一致说明 letterbox ≠ ultralytics classify 默认预处理(Resize+CenterCrop)。此时不要合入 —— 改 `letterbox_image` 为复刻 ultralytics 预处理(读 `ultralytics.data.augment.classify_transforms`:Resize(int(size)) + CenterCrop(size),interpolation BILINEAR),并在 Task 6 测试里同步修正 `test_letterbox_shape_and_pad` 的 pad 断言(CenterCrop 无 pad)。重跑直至 PASS。**注意**:即使切换为 CenterCrop 复刻,也须在 huji-train 的 README 里记一笔"app 侧是 letterbox,两端帧分布一致的前提是输入视频帧 aspect ratio 接近 1:1"——实际上 app 端 letterbox 已上线且 parity 检查(verify_ncnn_parity)证明 letterbox 输入下模型数值与 onnx 一致,所以 CenterCrop 复刻只是兼容旧 .pt 服务端行为的兜底;优先保 PASS。

- [ ] **Step 3: 删除临时脚本**

```bash
rm $ALGO/scripts/parity_frame_check.py
```

(不入库;结论记录在提交信息里。)

### Task 8: 删除训练代码与训练产物

**Files:**
- Delete: `$ALGO/src/main/train/`(整个目录)
- Delete: `$ALGO/src/test/train/`(整个目录)
- Delete: `$ALGO/scripts/{export_ncnn.py,verify_ncnn_parity.py}`
- Delete: `$ALGO/yolo11n.pt`
- Delete: `$ALGO/src/resources/models/`(整个目录,.pt 权重)
- Modify: `$ALGO/main.py`
- Modify: `$ALGO/src/main/config/config.py`(ModelConfig 的 train 字段)
- Modify: `$ALGO/src/main/constant/common_constant.py`(JobType)
- Modify: `$ALGO/src/resources/application*.yml`(train 配置项)

**Interfaces:**
- Consumes: Task 6(推理已切 ncnn,`large_model_service.py` 已无 train 方法)
- Produces: huji-algorithm 无任何训练代码/权重;`JobType` 只剩 `SERVICE`;`ModelConfig` 只剩 `predict_model_path`

- [ ] **Step 1: 删除文件**

```bash
cd $ALGO
git rm -r src/main/train src/test/train scripts/export_ncnn.py scripts/verify_ncnn_parity.py yolo11n.pt src/resources/models
```

- [ ] **Step 2: 清 main.py 的 train 模式**

删除:`--train` argparse 项、`_resolve_mode` 里的 `args.train` 与 `"train"` 分支、`run_train` 函数、`run_from_config` 里的 TRAIN_MODEL 分支、epilog 示例里的 `python main.py --train` 行、`import json` 若仍被 `_build_auto_clip_config` 用则保留(它在,保留)。

`_resolve_mode` 改后:

```python
def _resolve_mode(args: argparse.Namespace) -> str:
    modes = [bool(args.video_path), args.serve]
    if sum(modes) > 1:
        LOG.error("不能同时指定 --video-path、--serve")
        sys.exit(1)
    if args.cleanup and args.no_cleanup:
        LOG.error("不能同时指定 --cleanup 与 --no-cleanup")
        sys.exit(1)
    if args.video_path:
        return "clip"
    if args.serve:
        return "serve"
    return "config"
```

`run_from_config` 改后:

```python
def run_from_config(config: Config) -> None:
    if config.job_type == JobType.SERVICE:
        run_serve(config)
    else:
        LOG.error(f"未知的 job_type: {config.job_type}")
        sys.exit(1)
```

`main()` 里 `elif mode == "train": run_train(config)` 行删除。

- [ ] **Step 3: 清 config.py 与 common_constant.py**

`ModelConfig` 改后(只剩 predict):

```python
class ModelConfig(SecurityConfig):
    def __init__(self, config_context: ConfigContext) -> None:
        super().__init__(config_context)
        self.predict_model_path: str = path_utils.get_project_path(
            self._get_value("predict_model_path")
        )
```

`LargeModelServiceConfig` 删除 `train_model_name` 字段(Task 6 已在 large_model_service.py 删了读取处,这里删配置定义):

```python
class LargeModelServiceConfig(SecurityConfig):
    def __init__(self, config_context: ConfigContext):
        super().__init__(config_context)
        self.models: dict[str, ModelConfig] = {}
        models: dict[str, object] = self._get_value("models")
        for model in models:
            self.models[model] = ModelConfig(ConfigContext(config=models[model]))
        self.debug = self._get_value("debug", False)
```

`common_constant.py` 的 `JobType` 删 `TRAIN_MODEL = "train_model"` 行。

- [ ] **Step 4: 清 application*.yml 的 train 项**

`application.yml`:`large_model` 段的每个模型只留 `predict_model_path`,值改为 ncnn 模型路径;删 `train_model_name`:

```yaml
large_model:
  models:
    ping_pong_singles_profession:
      predict_model_path: "$PROJECT_RESOURCES/ncnn_models/ping_pong/profession/model.ncnn.param"
    badminton_doubles:
      predict_model_path: "$PROJECT_RESOURCES/ncnn_models/badminton/doubles/model.ncnn.param"
    badminton_singles:
      predict_model_path: "$PROJECT_RESOURCES/ncnn_models/badminton/singles/model.ncnn.param"
```

`application_dev.yml` 删除 `#job_type: train_model` 注释行。`application_prod.yml` 无 train 项,不动。

- [ ] **Step 5: 全仓 grep 确认无残留**

Run: `cd $ALGO && grep -rn "train\|ultralytics\|YOLO" src/ main.py scripts/ --include="*.py" | grep -v __pycache__ | grep -iv "constraint\|training data"`
Expected: 无输出(或仅有 `preconditions` 等误匹配,逐条人工确认)。`.pt` 残留检查:`find $ALGO -name "*.pt" -not -path "*/.venv/*"` 应为空。

- [ ] **Step 6: 运行全量测试 + ruff**

Run: `cd $ALGO && .venv/bin/python -m unittest discover -s src/test -p "test_*.py" 2>&1 | tail -5 && .venv/bin/ruff check .`
Expected: 测试全绿(skip 除外)、ruff 通过。此时 ultralytics 还在 venv 里但代码已不引用(下一任务删依赖)。

- [ ] **Step 7: Commit**

```bash
cd $ALGO
git add -A
git commit -m "refactor!: remove training code — moved to huji-train; inference is ncnn-only"
```

### Task 9: 依赖瘦身 + 端到端验证

**Files:**
- Modify: `$ALGO/requirements.txt`
- Modify: `$ALGO/README.md`、`$ALGO/README.en.md`(训练相关段落改指 huji-train)

**Interfaces:**
- Consumes: Task 6-8(ncnn 推理已就位、训练代码已删)
- Produces: requirements 无 ultralytics/torch;README 指向 huji-train

- [ ] **Step 1: 改 requirements.txt**

删除一行 `ultralytics~=8.3.130`,新增一行 `ncnn~=1.0.20250514`(版本与 Task 3 保持一致,若 pip 解析出不同版本以实际为准回写)。其余不动(ray 仍是闭包依赖,惰性导入留后续)。

- [ ] **Step 2: 干净环境验证(重建 venv)**

Run:
```bash
cd $ALGO
rm -rf .venv
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/python -m unittest discover -s src/test -p "test_*.py" 2>&1 | tail -5
```
Expected: 全新 venv(无 ultralytics/torch)安装成功、测试全绿。**这一步同时验证了"只留轻量推理包"** — 安装体积显著缩小。

- [ ] **Step 3: 端到端剪辑冒烟**

Run: `cd $ALGO && .venv/bin/python main.py -v src/resources/video/examples/test.mp4 --sport badminton 2>&1 | tail -5`
Expected: 打印合并视频输出路径;`output/clipped/clipped/` 下有产物。(需要 FFmpeg 在 PATH;ncnn CPU 推理即可,无需 GPU。)

- [ ] **Step 4: 更新 README**

`README.md` / `README.en.md`:删除 `--train` 相关行(CLI 表格里的 `--train` 行、epilog 示例);在文末加一节:

```markdown
## 模型训练

训练与模型导出已分离到 [huji-train](https://github.com/hhoao/huji-train)。
本仓库只做推理(ncnn),模型位于 `src/resources/ncnn_models/`。
```

- [ ] **Step 5: Commit**

```bash
cd $ALGO
git add requirements.txt README.md README.en.md
git commit -m "chore(deps): drop ultralytics, add ncnn — inference-only dependency set"
```

### Task 10: 主仓库收尾(submodule 指针 + CLAUDE.md)

**Files:**
- Modify: `/home/hhoa/git/hhoa/huji/CLAUDE.md`(Local Inference 一节)
- Modify: `/home/hhoa/git/hhoa/huji/huji-algorithm`(submodule gitlink,由 `git add huji-algorithm` 更新)

**Interfaces:**
- Consumes: Task 8-9 完成的 huji-algorithm 新 HEAD

- [ ] **Step 1: 更新 CLAUDE.md 的再训练流程**

把 "Local Inference (ncnn / Vulkan)" 一节里 "Conversion + parity scripts: `huji-algorithm/scripts/export_ncnn.py` 和 `verify_ncnn_parity.py`" 及下面的 re-export 代码块改为:

```markdown
- 转换/校验脚本与训练代码在独立仓库 [huji-train](https://github.com/hhoao/huji-train)
  (`scripts/export_ncnn.py`、`verify_ncnn_parity.py`)。

重新训练并导出模型:

```bash
git clone https://github.com/hhoao/huji-train && cd huji-train
./setup.sh && source .venv/bin/activate
python main.py --train          # 训练
python main.py --export-ncnn    # 导出 ncnn
# 然后把 model.ncnn.{param,bin} + metadata.yaml 拷贝到:
#   huji-algorithm/src/resources/ncnn_models/<sport>/<match_type>/
#   huji-app/assets/models/<sport>/<match_type>/
```
```

同时把 Architecture 一节 "`huji-algorithm/` — Python ML pipeline (Git submodule; training + inference)" 改为 "(Git submodule; 剪辑 + ncnn 推理,训练在 huji-train)"。

- [ ] **Step 2: huji 主仓库提交 submodule 指针**

```bash
cd /home/hhoa/git/hhoa/huji
git add huji-algorithm CLAUDE.md
git commit -m "chore(submodule): bump huji-algorithm — training moved to huji-train, inference ncnn-only"
```

(submodule 需先推送到 origin:`cd $ALGO && git push` — 外发动作,执行前与用户确认。)

- [ ] **Step 3: 最终回归清单**

- [ ] huji-train:`unittest` 全绿、`main.py --train/--export-ncnn` 冒烟通过(Task 5)
- [ ] huji-algorithm:干净 venv `unittest` 全绿、`ruff` 通过、clip 冒烟通过(Task 9)
- [ ] huji 主仓库:`git submodule status` 显示新 commit 且与 origin 一致
- [ ] 规格验证标准(阶段一 §、§5.5)逐项勾对

全部通过后,向用户汇报两仓库最终状态与提交列表。
