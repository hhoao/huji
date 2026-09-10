# 设计:huji-algorithm 训练分离(huji-train)+ 推理去 ultralytics 化

日期:2026-09-10
状态:已批准

## 背景与目标

huji-algorithm(git submodule,`github.com/hhoao/huji-algorithm`)目前混合了剪辑、推理、训练三种职责。目标:

1. 在 `~/autoclip/huji-train`(`github.com/hhoao/huji-train`,当前为空仓库)建立独立、可运行的训练仓库,**采用复制而非依赖**的方式(用户决策:先复制,慢慢删)。
2. huji-algorithm 删除全部训练代码,推理从 ultralytics(`.pt`)切换到 ncnn(`model.ncnn.{param,bin}`),移除 ultralytics/torch 依赖,只保留轻量推理包。
3. ncnn 是既定方向:app 侧(huji-app)已完成 ncnn 迁移,`verify_ncnn_parity.py` 证明过 4 个模型数值一致。

## 阶段顺序

**阶段一(先做)**:huji-train 复制建仓,验证可运行。huji-algorithm 不动。
**阶段二(后做)**:huji-algorithm 去训练化 + 推理切 ncnn。
顺序保证训练能力在任何时刻都存在。

---

## 阶段一:huji-train 训练仓库

### 边界

搬入 huji-train:

- 核心训练:`src/main/train/train_helper.py`、`LargeModelService.train()`(数据集切分 + YOLO train)、`--train` 入口、训练测试
- 训练帧生成:`create_classify_frames`(依赖推理闭包,见下)
- ncnn 导出脚本:`scripts/export_ncnn.py`、`scripts/verify_ncnn_parity.py`
- 模型权重:`src/resources/models/` 的 `.pt`(~48MB,训练起点)+ 根目录 `yolo11n.pt` 底模

不搬:示例视频(`src/resources/video/`,21MB)、docker(ray 镜像服务于分布式推理,训练用不上)。

### 目录结构(依赖闭包复制,保留 `src.main.*` 路径)

```
huji-train/
├── main.py                    # 训练专用入口(重写,见下)
├── requirements.txt           # 裁剪版
├── setup.sh / setup.ps1
├── pyproject.toml             # ruff 配置照搬
├── .pre-commit-config.yaml / .python-version / .env.example
├── yolo11n.pt                 # 预训练底模
├── scripts/
│   ├── export_ncnn.py
│   └── verify_ncnn_parity.py
├── src/
│   ├── __init__.py            # ROOT_PATH 等路径常量
│   ├── main/
│   │   ├── train/train_helper.py
│   │   ├── core/              # 全部 7 个文件(训练帧生成依赖推理闭包)
│   │   ├── service/{large_model_service, progress_handler}.py
│   │   ├── config/config.py   # 裁剪:只留 env/debug/job_type/large_model/autoclip_service_config
│   │   ├── constant/          # autoclip / common / error_codes / progress_constant / server_api
│   │   ├── pojo/video_clip_vo.py
│   │   ├── logger/
│   │   └── utils/             # path / video / cleanup / common / string / filesystem_utils / jasypt4py / stopit
│   ├── resources/
│   │   ├── application*.yml   # 裁剪:去掉 cos/service/kafka/internal/datasource 段
│   │   └── models/            # .pt 权重
│   └── test/
│       ├── base/
│       ├── train/             # test_train_helper
│       └── service/           # test_large_model_service(训练部分)
└── output/                    # gitignore(训练输出/数据集)
```

不复制:`http/`、`database/`、`dao/`、`filesystem/`、`message_service`、`video_edit_service`、`video_clip_helper`、`filesystem_service`、`json_utils`、`preconditions`、`docker/`。

闭包推导要点(import 必须可解析):

- `progress_handler` 被 `auto_clipper` 模块级 import,连带 httpx 依赖与 `server_api.py` 必须带上。
- `ray` 被 `auto_clipper`/`frame_action_predictor` 模块级 import,`ray[client]` 留在 requirements;标记为后续清理项(改惰性导入后可移除该重依赖)。

`ncnn_models/` 在 huji-train 里 gitignore:它是导出构建产物,最终归宿是 huji-app assets(产出后手工拷贝,与现有流程一致)。

`verify_ncnn_parity.py` 的 `ort` 模式需要 `best.onnx`:onnx 同样不进仓库,按需用 ultralytics 从 `.pt` 导出(`yolo.export(format="onnx")`,可由 export 脚本顺带提供 `--onnx` 选项)后再跑 parity。

### 入口(main.py,三种模式)

```
python main.py --train                                    # 训练(数据集切分 + YOLO train)
python main.py --gen-frames -v <video> --sport ping_pong  # 训练帧生成(create_classify_frames)
python main.py --export-ncnn                              # .pt → ncnn 导出
```

保留 `--set KEY=VALUE` 覆盖机制、`--config`,以及 `job_type: train_model` 走配置的路径。

### 配置裁剪

application.yml 保留:`logger_level / env / job_type / debug / large_model / autoclip_service_config`(帧生成需要模型映射)。删除:`filesystem.cos / service / kafka / internal / datasource`。

config.py 删除对应 Config 类:`ServiceConfig`、`FileSystemsConfig`、`DataSourcesConfig`、`KafkaConfig`、`InternalConfig`。

### requirements.txt(huji-train)

保留:setuptools、ruamel.yaml、pycryptodome、tenacity、loguru、opencv-python、ultralytics、tqdm、typing_extensions、numpy、pydantic、httpx、ray[client]。
新增:onnxruntime、ncnn(parity 脚本需要)。
删除:flask 系列、对象存储 SDK(cos/oss)、MySQL 系列(DBUtils/PyMySQL/mysql-connector/SQLAlchemy)、kafka、requests、pandas。

### 验证标准(阶段一)

1. `./setup.sh` 装依赖成功
2. `python main.py --help`、`--train` 配置加载 + 数据集切分逻辑走通(无数据集时至少 import 与参数解析全通)
3. `python -m unittest discover -s src/test -p "test_*.py"` 全绿(需要本地数据的测试保持原有 skip)
4. `python main.py --export-ncnn` import / 参数解析通过
5. `ruff check` 通过

---

## 阶段二:huji-algorithm 去训练化 + 推理切 ncnn

### 5.1 删除训练代码

- `src/main/train/`、`LargeModelService.train()`、`ModelConfig` 的 4 个 train 字段(`train_model_path/train_dataset_path/train_output_path/total_dataset_path`)、`main.py` 的 `--train`/`run_train`/`JobType.TRAIN_MODEL`、`src/test/train/`、`src/test/service/test_large_model_service.py`(全是训练/pose 实验)、`scripts/export_ncnn.py`、`scripts/verify_ncnn_parity.py`
- 权重清理:根目录 `yolo11n.pt`、`src/resources/models/` 的 `.pt`(推理不再用);推理模型只剩 `src/resources/ncnn_models/`(24MB)
- `application.yml`:删 `large_model.models.*` 的 train_* 字段与 `train_model_name`

### 5.2 推理切换:ultralytics → ncnn

`ModelPredictor` 重写为 ncnn 实现,镜像 app 侧 Dart 行为(`huji-app/lib/services/inference/`):

- 加载 `model.ncnn.{param,bin}` + `metadata.yaml` 的 `names` 表
- 预处理:与 app 相同的 letterbox(短边缩放至 640、pad 114 居中)→ `/255` → CHW → `in0` / `out0`,argmax → 类别名 → `classes_mapping` → `ActionType`
- `predict_model_path` 配置值改为指向 ncnn 模型(`.param` 路径,`.bin` 同目录推导)

预处理采用 letterbox(而非复刻 ultralytics 的 Resize+CenterCrop)的理由:app 端已上线验证的就是 letterbox,两端统一预处理更有价值。切换前做 **旧(ultralytics)vs 新(ncnn)逐帧 argmax 对比**:4 模型 × 示例视频帧全部一致才合入;不一致则暴露并修正预处理差异。

### 5.3 依赖与配置兼容

- `requirements.txt`:删 `ultralytics`(连带 torch),加 `ncnn`
- 不改 `large_model` 配置键名(线上 yml/环境变量覆盖兼容),只改值的指向
- `LargeModelService` 等类名本轮不改名(避免无谓涟漪,留给后续)

### 5.4 文档与流程

- huji 仓库 `CLAUDE.md`:模型再训练/导出流程改指 huji-train;ncnn 模型产出后需同时拷贝到 `huji-algorithm/src/resources/ncnn_models/` 与 `huji-app/assets/models/`
- 两个仓库 README 同步更新

### 5.5 验证标准(阶段二)

1. 逐帧 parity:4 模型 × 示例视频帧,旧(ultralytics)vs 新(ncnn)argmax 一致
2. 删除 ultralytics 后:`unittest` 全绿、`ruff check` 通过
3. `python main.py -v src/resources/video/examples/test.mp4 --sport badminton` 完整剪辑跑通,输出正常
4. huji-train 侧回归:unittest 全绿(确认未受影响)

---

## 后续轮次(不在本轮)

- 从 huji-train 里把 ray 改为惰性导入并移除依赖
- huji-train 里 core/ 推理闭包的进一步瘦身(用户:"慢慢删")
- `LargeModelService` 等命名调整

## 风险

- **逐帧 parity 可能不一致**:letterbox vs ultralytics 默认 classify 预处理(Resize+CenterCrop)存在差异的可能;缓解:切换前全模型对比,不一致则修预处理直至一致。
- **训练帧生成闭包较大**:core/ 7 个文件全部带过去;已在设计上接受(复制策略),后续慢慢删。
- ** submodule 指针**:huji-algorithm 是 submodule,阶段二完成后 huji 仓库需要更新 submodule 指针并提交。
