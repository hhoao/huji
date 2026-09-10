# ncnn — Dart/Flutter 通用 ncnn（Vulkan）推理绑定：拆仓与发布设计

日期：2026-09-10
状态：已确认（用户全权委托质量决策）

## 背景与目标

`huji-app/packages/huji_ncnn` 是一个瘦 C shim + dart:ffi 的 ncnn 插件（5 平台
ffiPlugin、Vulkan 加速、官方预编译库构建期下载）。当前 API 烧死了 YOLO
classify 约定（blob 名 `in0`/`out0`、预处理 x/255、输出即类别分数、
`maxClasses=64` 硬编码），且以 `publish_to: none` 内嵌于 huji 仓库。

目标：将其拆出为独立仓库 `github.com/hhoao/ncnn`，包名 `ncnn`，泛化为通用
ncnn 图像推理绑定，达到 pub.dev 发布质量（0.1.0），huji-app 经 git submodule
无损接入（4 个模型 parity 继续 bit-exact）。

## 已确认决策

| 决策点 | 结论 |
|---|---|
| API 泛化程度 | 完整泛化（通用图像推理绑定，非 Mat 级全量绑定） |
| YOLO 解码位置 | 包内纯 Dart 工具类（classify top-k / detect grid+NMS） |
| 仓库历史 | 全新仓库，包在仓库根，无历史迁移 |
| huji-app 接入 | git submodule 挂 `huji-app/packages/ncnn` + path 依赖 |
| Windows helper 进程 | 迁入包内（Windows GPU 加速对外可用） |
| 发布时机 | 改造 + 回归全部完成后一次性发 0.1.0 |
| 许可证 | BSD-3-Clause（附 ncnn BSD-3、MoltenVK Apache-2.0 声明） |
| 初始版本 | 0.1.0（API 全新面世，1.0 前留演进空间） |

## 1. 包定位与命名

- pub 包名 `ncnn`；Dart 导入 `package:ncnn/ncnn.dart`
- Dart 类名保留 `NcnnRuntime` / `NcnnNet` / `NcnnGpuDevice` / `NcnnInferenceEngine`
- 原生标识统一：
  - C shim：`src/ncnn_api.{h,cpp}`，符号保持 `hn_*` 前缀（与库名解耦，避免
    与 `ncnn::` 混淆；C 面符号名不改，绑定层不感知）
  - CMake：`PROJECT_NAME ncnn`、`PLUGIN_NAME ncnn_plugin`（产物
    `libncnn_plugin.so` / `ncnn_plugin.dll`）
  - podspec：`s.name = "ncnn"`（ios/macos 两个）
  - Android：`namespace dev.hhoao.ncnn`（修正现有 `com.hhuoao` 拼写错误）
  - helper 可执行：`ncnn_helper`（Windows）
- 环境变量重命名（避免与 ncnn 本身的潜在环境变量冲突）：
  - `HUJI_NCNN_LIB_DIR` → `NCNN_DART_LIB_DIR`
  - `HUJI_NCNN_ENABLE_VK` → `NCNN_DART_ENABLE_VK`
  - Intel ICD 过滤相关 `HUJI_NCNN_VK_ICD` / `HUJI_NCNN_ALLOW_INTEL_VK` →
    `NCNN_DART_VK_ICD` / `NCNN_DART_ALLOW_INTEL_VK`
  - marker 文件名 `huji_ncnn_lib_dir.txt` → `ncnn_dart_lib_dir.txt`

## 2. C API（`src/ncnn_api.h`）

设计原则：图像推理全覆盖 + 两个前瞻性逃生口（版本化选项结构体、float
tensor 输入），C 面只增不改。

```c
// 版本化选项结构体（Win32 惯例）：首成员 struct_size，
// 未来加字段不破坏二进制兼容；旧绑定传旧结构体照常工作。
typedef struct {
    uint32_t struct_size;   // 必须为 sizeof(hn_options_t)
    int      use_vulkan;    // 0/1
    int      device_index;  // Vulkan 设备；-1 = ncnn 默认
    float    mean[3];       // 预处理 mean；全 0 = 不减
    float    norm[3];       // 预处理 norm；全 1 = 不除（YOLO = 1/255）
    int      pixel_format;  // HN_PIX_RGB / BGR / RGBA / BGRA / GRAY
    const char* input_blob; // NULL = "in0"（ultralytics 约定）
} hn_options_t;             // 新增字段只能追加在尾部
// mean/norm 按 pixel_format 的实际通道数取前 N 个元素（GRAY 取 [0]）。

hn_net_t hn_create(const hn_options_t* opts);   // opts=NULL = 全默认
int  hn_load(hn_net_t, const char* param_path, const char* bin_path);

// load 后输出查询（消除 maxClasses=64 硬编码的根）
int  hn_output_count(hn_net_t);
int  hn_output_shape(hn_net_t, int out_index, int32_t shape[4]);  // 返回 dims

// 推理（图像输入）：所有输出 blob 按序拼接写入 out（容量由 shape 查询得出），
// shapes 同行写出供 Dart 侧切分。返回写入的 float 总数，负数为错误码。
int  hn_extract(hn_net_t, const uint8_t* pixels, int w, int h,
                float* out, int out_cap, int32_t* shapes, int shape_cap);

// 推理（float tensor 输入）：非图像模型的逃生口。data 为 NCHW 布局的
// 已预处理 float，shape/dims 由调用方给出。
int  hn_extract_f32(hn_net_t, const float* data, const int32_t* shape,
                    int dims, float* out, int out_cap,
                    int32_t* shapes, int shape_cap);

void hn_destroy(hn_net_t);
int  hn_gpu_count(void);
int  hn_gpu_devices(hn_gpu_device_t*, char (*names)[HN_NAME_MAX], int n);
```

错误码约定统一（负数）：`-1` 参数/状态非法、`-2` param 加载失败、
`-3` bin 加载失败、`-4` 输入 blob 不存在、`-5` 提取失败、`-6` 输出
shape 异常、`-7` out 容量不足、`-8` C++ 异常被屏障捕获。

同步修复评审发现的三处 shim 缺陷：

1. **异常屏障**：所有 `extern "C"` 入口包 `try { } catch (...) { return -8; }`
   ——损坏的 param/bin 文件触发 ncnn 内部 C++ 异常时不再穿越 C 边界（UB）。
2. **删除非 Windows 的 200ms magic sleep**：ncnn `get_gpu_count` /
   `create_extractor` 内部幂等初始化 GPU instance 且有锁，detached 线程 +
   sleep 的预热既多余又和 Windows 侧"detached 线程有竞态崩溃"的证据矛盾。
   Windows 的同步 `call_once` 保留（有 dump 证据）。
3. **删除 Dart 侧 `_applyIntelIcdWorkaround` 死代码**：Intel ICD 过滤只在
   native 侧保留（权威实现），Dart 侧只留文档注释。

预处理语义注意（迁移自现有代码的证据注释）：`substract_mean_normalize` 的
norm 参数按通道读取 3 个元素——传 1 个元素的数组会越界并破坏 G/B 平面。

## 3. Dart API 与 YOLO 工具

```
lib/
├── ncnn.dart                    # 导出全部公开 API
└── src/
    ├── bindings.g.dart          # ffigen 重生成（不再手维护；ffigen.yaml 随迁）
    ├── runtime.dart             # NcnnRuntime：库解析链（override/env/marker/
    │                            #   bare name）、GPU 枚举缓存——原逻辑平移改名
    ├── net.dart                 # NcnnNet：load() 后经 hn_output_shape 查询
    │                            #   输出并自动分配（硬编码消除）；extract()
    │                            #   返回 List<Float32List>（按 blob 切分）
    ├── helper_process.dart      # Windows ncnn_helper 子进程（stdin/stdout
    │                            #   二进制协议，从 huji-app 迁入）
    ├── inference_engine.dart    # NcnnInferenceEngine 高层封装：后端选择
    │                            #   （Windows helper / 其他平台 FFI）、GPU→CPU
    │                            #   回退、isolate 使用说明与 runInIsolate 便捷
    │                            #   封装（Isolate.run）
    └── yolo/
        ├── classify.dart        # topK(logits)、softmax（可选）、argmax
        └── detect.dart          # ultralytics ncnn 导出格式的 grid 解码 +
                                #   NMS + 置信度/类别过滤，纯 Dart
```

- `NcnnNet.extract` 保持同步 FFI（能力而非缺陷），文档明确"勿在 UI isolate
  直接调用"；`NcnnInferenceEngine` 提供 `Isolate.run` 封装
- detect 解码以 `huji-algorithm` 导出的 detect 测试模型对拍 Python 侧
  （ultralytics 推理结果）验证数值正确性
- `NcnnMetadata`（ultralytics metadata.yaml 类名解析）随迁，正则放宽支持
  引号与含空格类名（`"fire ball"`、`'pick ball'`）

## 4. Windows helper 迁入

- `src/ncnn_helper_main.cpp`（现 `huji-app/packages/huji_ncnn/src/
  huji_ncnn_helper_main.cpp` 平移改名）作为 Windows CMake 的附加可执行目标
  `ncnn_helper`，与插件同构建目录输出
- Dart 侧从插件库同目录定位 `ncnn_helper.exe`；未找到 → 进程内 CPU 回退
  （现行为）；helper 崩溃 → 进程内 CPU 回退（现行为）
- 协议不变（stdin/stdout 定长二进制帧），仅符号/库名随改名更新
- 其他平台不构建 helper 目标；README 的 Windows Vulkan 崩溃分析
  （engine 进程内 nvoglv64 access violation 的 dump 证据）随迁

## 5. huji-app 迁移

- 删除 `huji-app/packages/huji_ncnn`；新仓作为 submodule 挂
  `huji-app/packages/ncnn`（`.gitmodules` 追加）
- `huji-app/pubspec.yaml`：`ncnn: {path: packages/ncnn}`
- 全局 import 重写 `package:huji_ncnn/` → `package:ncnn/`
- 代码归属：
  - **迁入包**：`ncnn_inference_engine.dart`、`ncnn_helper_process.dart`
    （改造为包内 `inference_engine.dart` / `helper_process.dart`）
  - **留在 app**（业务层）：`ncnn_model_predictor.dart`（类名映射 /
    ActionType 耦合）、`ncnn_predictor_pool.dart`、`image_preprocessor.dart`、
    `gpu_device_selector.dart`、`inference_model_registry.dart`、
    `inference_spec.dart`、`ncnn_model_asset_resolver.dart`
- 测试归属：
  - **随包迁移**：`test/integration/ncnn_plugin_test.dart`、
    `ncnn_real_frame_test.dart`、`helpers/ncnn_test_bootstrap.dart`、
    `test/ncnn_stale_marker_test.dart`（marker 机制属包）
  - **留在 app**：`ncnn_predictor_pool_test.dart`、
    `ncnn_clip_to_export_integration_test.dart`（业务流）
- **验收硬标准**：
  1. `huji-algorithm/scripts/verify_ncnn_parity.py` 4 个模型继续 bit-exact
  2. huji-app 现有测试全绿（迁移后路径修正）
  3. Linux `flutter run -d linux` 真实推理冒烟（Vulkan + CPU 回退两路）

## 6. 发布卫生

- `LICENSE`：BSD-3-Clause + `THIRD_PARTY_NOTICES.md`（ncnn BSD-3、
  MoltenVK Apache-2.0、构建期下载的官方预编译产物声明）
- `CHANGELOG.md`：0.1.0 条目
- `README.md` 重写：定位（通用 ncnn 图像推理绑定、全平台 Vulkan）、安装、
  平台矩阵（含各平台依赖：Linux Vulkan loader、Windows helper 说明、
  Apple MoltenVK 自动 vendored）、快速上手（classify + detect）、
  ultralytics 导出约定（in0/x/255 默认值的由来）、进阶（自定义 blob 名/
  预处理/float 输入）、Windows Vulkan 引擎内崩溃的证据与规避策略
- `example/`：最小 classify demo（加载模型 + 单帧推理 + GPU 设备展示）；
  一个 example 让五平台徽章亮起
- `.gitignore` 补齐：`.cxx/`、`build/`、`*.iml` 等；删除包内 `pubspec.lock`
- symlink 打包风险：`ios/src`、`macos/src` 的文件 symlink 先经
  `dart pub publish --dry-run` 验证 tarball 行为；若 pub 不保真则改为
  构建期复制脚本（submodule 消费路径两种方案都工作，pub 路径必须保真）
- ffigen 绑定 CI 校验：`dart run ffigen` diff 为空，防止头文件与绑定漂移

## 7. CI 与发布流（新仓）

`.github/workflows/`：

- `ci.yml`（push/PR）：
  - `flutter analyze` + `dart format --set-exit-if-changed`
  - Dart 单测（解码工具、metadata 解析——纯 Dart 不依赖原生库）
  - ffigen 漂移检查
  - Linux example `flutter build linux`（顺带验证 CMake 下载链）
- `publish.yml`（tag `v*` 手动触发）：`dart pub publish`（pub token secret）

发布顺序：改造完成 → submodule 接回 huji-app 全量回归（parity + 测试 +
冒烟）→ `dart pub publish --dry-run` 验证（文件清单/symlink/大小）→
发 0.1.0 → 新仓打 `v0.1.0` tag。huji-app 维持 submodule 依赖，未来切
pub 版本依赖随时可换。

## 风险与对策

| 风险 | 对策 |
|---|---|
| pub tarball 不保真 symlink | dry-run 验证；失败改构建期复制脚本 |
| `ncnn` 名被抢注 | 名字当前空闲；改造完成即发布，窗口期短 |
| 改名遗漏（CMake/gradle/podspec 残留 huji 标识） | 全仓 grep `huji` 清零检查 + 五平台构建验证 |
| 泛化后 classify 数值漂移 | parity 脚本 bit-exact 为硬验收；默认 options 语义与旧路径逐位一致 |
| Windows helper 迁移后定位失败 | 保留进程内 CPU 回退；example 在 Windows CI 构建（后续可选） |
