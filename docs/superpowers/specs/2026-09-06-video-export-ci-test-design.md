# 视频导出链路 CI 集成测试设计

日期：2026-09-06
状态：已批准

## 背景

`runConcatVideoExport`（`huji-app/lib/utils/video_export_utils.dart`）是导出功能的核心：ffmpeg concat 清单 + 单次 x264 编码 + `-progress pipe:1` 进度解析 + 进程取消。目前零测试覆盖。其中 ffmpeg stderr 排空（防 64KB 管道阻塞死锁）、`out_time_ms` 实为微秒的换算，都是历史上真实踩过的坑。

与检测 golden 测试不同，导出测试不依赖 ONNX native plugin——`flutter test` VM 里 `Process.start('ffmpeg')` 可正常工作，因此**可以放进每次 CI 必跑的默认测试集**（不打 `integration` tag）。

## 目标

每次 CI（`ci-verify.yml` 四平台矩阵）必跑导出集成测试，用真实样例视频 + 算法 golden 分段验证真实 ffmpeg 导出行为。

## 方案

### 测试文件

`huji-app/test/utils/video_export_utils_test.dart`，无 `@Tags(['integration'])`。

数据源：复用检测 golden 测试同一套 fixtures——

- 视频：`test/fixtures/video/test.mp4`（乒乓球样例，23.4s）
- 分段：`test/fixtures/autoclip/test_mp4_pingpong.json` 的 `all_match_segments`（3 段）

通过 `test/helpers/autoclip_fixtures.dart` 的 `loadGoldenJson` / `goldenAllMatchSegments` / `findAppRoot` 读取，转成 `SegmentInfo` 列表（`ActionType` 用 golden 的 `action` 字段经 `ActionType.fromString`）。

### 用例

| # | 用例 | 输入 | 断言 |
|---|------|------|------|
| 1 | golden 分段导出（original 档） | golden 3 分段 | 返回输出路径；文件存在；ffprobe 时长 ≈ Σ(end−start)，容差 ±1s；可正常解封装（有视频流） |
| 2 | 画质档位（720p 档） | golden 3 分段 | ffprobe 输出高度 = 720 |
| 3 | 进度回调 | golden 3 分段 | 收集的 onProgress 序列：首值为 0、末值为 1、单调不降、均在 [0,1] |
| 4 | 取消 | golden 分段 | `onProcessStarted` 回调内 kill 进程；最终抛异常；无完整输出文件（或残留文件 ≠ 正常完成路径语义） |
| 5 | 空片段 | `segments: []` | 抛含 `'No segments to export'` 的异常 |

超时：每个真跑 ffmpeg 的用例 `Timeout(Duration(minutes: 3))`。

### 环境守卫

`setUpAll` 探测 PATH 上的 `ffmpeg` 与 `ffprobe`（`Process.run('which'…)` / 直接 `-version`）。任一缺失 → 各用例 `markTestSkipped('ffmpeg not on PATH')`：

- 本地没装 ffmpeg 的开发者不红
- CI 里会安装（见下），所以必跑

### 辅助函数（测试文件内私有，不新增依赖）

- `ffprobeJson(String path)`: `Process.run('ffprobe', ['-v','error','-print_format','json','-show_format','-show_streams', path])` 解析 JSON
- `ffmpegAvailable()`: 探测两个二进制

### CI 改动（`.github/workflows/ci-verify.yml`）

- ubuntu-22.04 runner 自带 ffmpeg/ffprobe，不动
- Windows 矩阵：加一步 `choco install ffmpeg -y`（仅 `matrix.platform == 'windows'` 时）
- macOS 矩阵：runner 预装 ffmpeg；先验证，若实际缺失再补 `brew install ffmpeg`（实现时确认）

### 输出位置

测试输出写到 `Directory.systemTemp`（`huji_export_test_<ts>/`），测试结束后清理。

## 明确不做（YAGNI）

- 不测 `VideoExportTaskManager`（本次范围外）
- 不做检测→导出全链路（ONNX plugin 在 test VM 不可用，无法每次 CI 必跑）
- 不做输出文件哈希/golden 比对（x264 跨平台、跨 ffmpeg 版本不确定，会假红）
- 不 mock ffmpeg（测真实行为是本测试的存在意义）

## 影响与风险

- CI 单平台新增约 30–60s（Windows 装 ffmpeg + 两遍编码 23s 视频的 3 分段）
- 仓库无新增体积（fixtures 已存在）
- 风险：concat inpoint/outpoint 时长与期望和的偏差由 ±1s 容差吸收（concat 按关键帧对齐会引入误差）
