# 视频库统一注册（VideoLibraryRegistrar）设计

日期：2026-09-06
状态：已批准（brainstorming 完成）

## 背景与问题

应用内"视频库"（`LocalVideoStorage`，`video_records` 表）是视频列表（移动端
`loadSavedVideos()`、桌面端 `load()`）的唯一数据源。目前三条产出视频的链路
行为不一致：

| 链路 | 应用内视频库 | 系统相册 (Gal) |
|---|---|---|
| 保存片段 `VideoSaveProgressDialog` | ✅ | ✅ 仅移动端 |
| 压缩任务 `VideoCompressTaskManager` | ❌ | ✅ 仅移动端 |
| 导出任务 `VideoExportTaskManager` | ❌ | ❌ |

目标：压缩与导出结果也进入视频库；同时把三条链路的"落库 + 进相册"逻辑收敛
到单一入口，新增产出链路时零成本接入。

## 架构

新增领域服务 `VideoLibraryRegistrar`
（`huji-app/lib/services/video_library_registrar.dart`），无状态单例，作为
"任何 ffmpeg 产出的视频进入视频库"的唯一入口：

```
VideoSaveProgressDialog ─┐
VideoCompressTaskManager ─┼─→ registrar.register(entry)
VideoExportTaskManager  ─┘        │
                                  ├─ 幂等去重（findByFilePath）
                                  ├─ 探测元数据（VideoUtils.getVideoInfo / 文件大小）
                                  ├─ 生成缩略图（VideoUtils.generateVideoThumbnail）
                                  ├─ 解析 sportType（hint → 源视频库记录 → pingpong）
                                  ├─ 写入 LocalVideoStorage（SavedVideoRecord）
                                  └─ 移动端 Gal.putVideo（supportsGalleryAccess）
```

调用方传不可变描述符：

```dart
class VideoLibraryEntry {
  final String outputPath;            // 产出文件绝对路径
  final VideoProcessType processType; // greatMatch / allMatchMerged / compressed / exported
  final String? sourceVideoPath;      // 源视频路径：继承 sportType + 排查用
  final SportType? sportTypeHint;     // 调用方已知类型时直接给
}
```

设计原则：

- **注册永不导致任务失败**：所有副作用（缩略图、相册）失败只记 warning；
  注册是锦上添花，不应把已成功的导出/压缩任务标成 failed。
- **幂等**：按 `filePath` 先查库，已存在同路径记录则跳过（防御任务重跑或
  重复触发）。

## 数据模型变更

- `VideoProcessType`（`api/models/autoclip/video_models.dart:10`）新增：
  - `compressed(3, '压缩', Colors.orange)` — 压缩产物
  - `exported(4, '导出', Colors.teal)` — 高光导出产物
  - 老数据枚举值 0/1/2 不变；`@JsonEnum(valueField: 'value')` 按值序列化，
    向后兼容。标题/颜色文案在实现时按 l10n 情况对齐现有枚举写法。
- `SavedVideoRecord` 不加字段：`duration`/`fileSize`/`videoProcessType` 已
  存在（v3 迁移已铺路）。
- `sportType` 保持必填，由 registrar 解析：`sportTypeHint` → 按
  `sourceVideoPath` 查库 → 默认 `SportType.pingpong`（与现状
  `video_save_progress_dialog.dart:152` 一致）。
- 移动端视频列表过滤对新类型默认放行（显示在列表里）；如需隐藏属后续 UI
  策略，不在本次范围。

## 生产者链路改动

### 新增（核心诉求）

- `VideoCompressTaskManager.processTask` 的 `onSuccess`
  （`store/task/video_compress_task_manager.dart:46`）：删除现有
  `Gal.putVideo` 直调，改为 `registrar.register(entry)`，
  `processType: compressed`，`sourceVideoPath: currentTask.videoPath`。
  移动端进相册行为保持不变（由 registrar 统一决定）。
- `VideoExportTaskManager.processTask` 完成分支
  （`store/task/video_export_task_manager.dart:63`）：在任务状态更新为
  completed 之前调用 registrar，`processType: exported`，
  `sourceVideoPath: exportTask.videoPath`。注册在状态更新前，且失败被
  registrar 内部吞掉，不阻塞任务收尾。

### 收敛（既有链路）

- `VideoSaveProgressDialog._saveVideo`
  （`widgets/video_save_progress_dialog.dart:140-177`）：元数据探测 +
  缩略图 + `LocalVideoStorage.add` + `Gal.putVideo` 四段替换为一次
  registrar 调用（`processType: widget.videoProcessType ?? allMatchMerged`，
  `sourceVideoPath: widget.videoPath`，`sportTypeHint: widget.sportType`）。
  对话框保留自己的进度条 UI 与错误展示，只收敛"落库 + 进相册"。

### 不动

- `video_player_page.dart:1231` 的下载复制后 `Gal.putVideo`：这是"复制
  已有视频到外部目录"，非加工产出；进库会产生重复条目，语义不符。保持只
  进相册不进库。

## 错误处理

- registrar 内部各步骤独立 try/catch，失败仅 `AppLogger().w`：
  - 元数据/缩略图失败 → `duration=0` / `fileSize=0` / `thumbnailPath=null`
    落库；启动时 `repairMissingThumbnails()` 会自动补缩略图（现有机制兜底）。
  - `Gal.putVideo` 失败 → warning，注册仍算成功（与现状一致）。
- 仅"产出文件不存在"返回失败结果；调用方收到失败时任务仍标 completed
  （视频文件可能还在，只是无法注册元数据），并记入 `extraInfo`。
- `LocalVideoStorage` 新增 `findByFilePath(String path)` 供幂等查询。
  `add` 的 `ConflictAlgorithm.replace`（按 id 覆盖）保持不变。

## 测试

- `VideoLibraryRegistrar`：基于 sqflite_ffi 临时库的集成测试——注册写入
  正确 `SavedVideoRecord`；同路径重复注册只写一条；缩略图/元数据失败不
  影响落库；`processType` 与 `sportType` 解析（hint / 源记录 / 默认）正确。
- 两个 task manager：在现有测试基建上补"完成后 `LocalVideoStorage` 出现
  对应记录"断言（导出已有 ffmpeg concat 集成测试可挂）。
- 枚举兼容：`videoProcessType` 按值序列化对旧数据 0-2 的回归断言。

## 明确不做

- 不改移动端视频列表 UI/过滤交互（新类型默认放行显示）。
- 不动 `video_player_page.dart` 下载复制链路。
- 不为注册行为增加用户设置开关。
