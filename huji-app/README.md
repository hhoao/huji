# 弧迹 (Restcut)

智能视频剪辑应用，面向羽毛球、乒乓球等比赛场景，提供 AI 自动识别精彩片段、回合编辑与边拍边剪等功能。

## 功能概览

- **AI 比赛自动剪辑**：自动识别精彩回合，剔除休息、捡球等无效片段，支持羽毛球、乒乓球。
- **边拍边剪辑**：实时录制并标记片段，现场即可完成粗剪。
- **已有视频剪辑**：选择本地或云端视频，智能片段识别与批量处理，支持云端与本地剪辑。
- **回合剪辑**：按回合浏览、编辑，支持收藏/删除回合、拖拽调整回合顺序、可选导出清晰度。
- **实用工具**：图片压缩、视频压缩。

## 技术栈

- **框架**：Flutter（Material）
- **状态与路由**：flutter_bloc、go_router
- **媒体**：FFmpeg（ffmpeg_kit_flutter_new）、视频修剪与播放（video_player、chewie）、动作检测（ultralytics_yolo）
- **网络与存储**：Retrofit、Dio、SQLite（sqflite）、后台任务（workmanager、flutter_background_service）

## 运行要求

- Flutter SDK ^3.8.1
- 见 `pubspec.yaml` 中各平台约束（如 Android minSdk 等）

## 本地运行

```bash
cd restcut_app
flutter pub get
flutter run
```

指定设备示例：`flutter run -d linux` / `-d windows` / `-d chrome` 等。

## 项目结构摘要

- `lib/pages/`：首页、剪辑（autoclip/回合/边拍边剪）、视频列表、任务、用户与系统页。
- `lib/router/`：go_router 路由模块（clip、video、task、profile、tools 等）。
- `lib/core/`：羽毛球/乒乓球等动作片段检测逻辑。
- `lib/widgets/`：视频播放、修剪器、多视频播放等通用组件。
- `lib/api/`、`lib/store/`：接口与状态（用户、任务、下载等）。
