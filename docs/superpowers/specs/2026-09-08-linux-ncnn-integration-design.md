# Linux ncnn 集成:测试可用性 + 全链路集成测试 设计文档

日期:2026-09-08
状态:已获用户批准的设计

## 背景

ncnn/Vulkan 推理在 `flutter run -d linux`(debug bundle)下已验证可用:
CMake 打包 bug(`huji_ncnn_bundled_libraries` 漏掉插件 .so、libncnn.so
是悬空符号链接)已修复,实机选中 RTX 4060,完整剪辑流程跑通。

剩余缺口:

1. **`flutter test` 环境下 ncnn 完全不可用**。`NcnnRuntime._openLibrary`
   在 Linux 用裸名 `DynamicLibrary.open('libhuji_ncnn_plugin.so')`;
   `flutter run` 会把 `bundle/lib` 加进进程库搜索路径,而 `flutter test`
   的 test VM 不会 → 6 个 FFI 集成测试失败,clip-flow 集成测试
   `markTestSkipped`,CI 从未跑过任何 ncnn 集成测试
   (`flutter test --exclude-tags integration`)。
2. **没有"检测 → 剪辑 → 导出"端到端测试**。现有
   `clip_flow_integration_test`(检测到 completed)与
   `video_export_library_registration_test`(固定 golden 段直接导出)
   互不相连,中间的"ncnn 检测结果驱动导出段"没有覆盖。
3. **`NcnnPredictorPool` 懒加载**:每个 predictor 在首个 chunk 到达时才
   `loadModel`,第一个 segment 承担全部模型加载延迟。

## 目标

- ncnn 集成测试在本地与 CI(Linux)都能真实跑起来(非 skip)
- 一条全链路集成测试:demo 视频 → ncnn 推理 → 段剪辑 → ffmpeg 导出 →
  产物入库
- 消除 pool 冷启动延迟
- 不引入实验性 Flutter 特性,不做向后兼容包袱

## 非目标

- 不迁移 native assets / build hooks(方案 B 已否决)
- 不改动 Windows helper 进程路径与 Android/macOS/iOS 分支
- 不重训模型、不改 ncnn shim C API

## 架构

### 1. 库解析层(`huji_ncnn` 包)

`NcnnRuntime` 新增静态注入入口:

```dart
/// Test/CI bootstrap: pin the directory holding libhuji_ncnn_plugin.so
/// before any NcnnRuntime use. Repeated calls with the same dir are
/// no-ops; throws if the library is already open or dir differs.
static void overrideLibraryDirectory(String dir);
```

Linux 加载优先级:**显式注入 > `HUJI_NCNN_LIB_DIR` env > 裸名**(现状)。
注入路径用绝对路径 `DynamicLibrary.open`;`libncnn.so.1` 依赖产物自带
的 RUNPATH(build 产物 `plugins/huji_ncnn/ncnn/lib`)解析。
Windows(`overrideLibraryDirectory` 同样落到已有的 `HUJI_NCNN_LIB_DIR`
语义)/Android 分支行为不变。

### 2. 测试基建(`test/helpers/ncnn_test_bootstrap.dart`)

从当前工作目录向上定位 repo 根,探测:

- `huji-app/build/linux/x64/debug/plugins/huji_ncnn/libhuji_ncnn_plugin.so`
- `huji-app/build/linux/x64/release/plugins/huji_ncnn/libhuji_ncnn_plugin.so`

找到第一个存在的目录 → `NcnnRuntime.overrideLibraryDirectory(dir)`。
都不存在时抛出**可操作错误**("先运行 `flutter build linux --debug`"),
不静默 skip。所有 ncnn 集成测试 `setUpAll` 统一调用。

### 3. 全链路集成测试

`test/integration/ncnn_clip_to_export_integration_test.dart`
(`@Tags(['integration'])`):

1. `ClipFlowTestHelper.setUp()`(现有 helper,复用)
2. bootstrap ncnn 库路径;探活失败 → fail 并给出修复指引
3. `ClipFlowTestHelper.startLocalClipFromDemo(demo)` 启动本地检测
4. `waitForTerminalStatus` → 断言 completed、`allMatchSegments` 非空
5. 用检测出的段构造 `VideoExportTask`(参照
   `video_export_library_registration_test.dart:97-107` 的必填字段)
6. `TaskStorage().addAndAsyncProcessTask` → 轮询至 completed
7. 断言:导出文件存在;ffprobe 时长 ≈ 段总时长(容差 1s/段);
   `LocalVideoStorage().loadSavedVideos()` 中登记为 exported
8. 超时 15 分钟(与 clip-flow 一致)

### 4. Pool 预热(`NcnnPredictorPool`)

`create()` 变为 `Future<NcnnPredictorPool>` 工厂:创建后并行加载所有
predictor 的模型,加载完成后才返回;`withPredictor` 借出的 predictor
必然已加载。`BatchActionSegmentDetector` 处改为
`pool = await NcnnPredictorPool.create(...)`。

### 5. CI(`.github/workflows/ci-verify.yml`)

Linux job 追加(在现有单测步骤后):

```yaml
- name: Build linux debug (produce ncnn plugin for integration tests)
  run: flutter build linux --debug
  working-directory: huji-app
- name: Install ffmpeg for integration tests
  run: sudo apt-get install -y ffmpeg
- name: Run integration tests (CPU fallback path — no GPU on runners)
  run: flutter test --tags integration
  working-directory: huji-app
```

GitHub runner 无 GPU → ncnn 走 CPU fallback,顺带验证该路径。

## 错误处理

- bootstrap 找不到产物:fail-fast,错误信息含构建命令
- `overrideLibraryDirectory` 在库已打开后调用:`StateError`
- pool 预热某个 predictor 加载失败:`create` 整体抛错(与现状
  "首帧失败" 相比更早暴露)
- 集成测试里 ffprobe 缺失:`markTestSkipped`(与现有 export 测试一致)

## 测试计划

- 新:全链路集成测试(上述第 3 节)
- 既有 `ncnn_plugin_test` / `ncnn_real_frame_test` /
  `clip_flow_integration_test`:bootstrap 后由失败/skip 变为真实通过
- pool 预热:单测 `create()` 完成后所有 predictor `isLoaded`

## 风险

- CI 上 `flutter build linux --debug` 增量 ~2-4 分钟(首次更多);
  接受,因为换来集成回归自动发现
- 集成测试总时长可能到分钟级(ncnn CPU 推理 test.mp4);15 分钟
  超时内可控,若超时再调 fixture
