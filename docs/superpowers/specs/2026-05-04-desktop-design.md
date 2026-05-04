# 弧迹桌面端（Linux AppImage）设计方案

**日期**：2026-05-04
**作者**：hhoa（与 Claude 协作脑暴产出）
**状态**：草案，等待评审

## 1. 概述

### 1.1 目标

在现有的弧迹（Restcut）Flutter 项目内，新增 Linux 桌面平台支持，并以 **AppImage** 格式分发。桌面版与移动端共用业务逻辑（API、bloc、剪辑流程、ffmpeg 调用），UI 完全独立设计，针对桌面交互优化。

### 1.2 范围（Scope B）

**包含**：
- 已有视频导入（拖拽 + 文件选择器）
- **云端**智能检测（不含本地 YOLO 推理）
- 回合选择、预览、精修编辑（入/出点、排序）
- 视频导出（ffmpeg 自包含）
- 任务管理、设置（含主题切换、预设管理）
- 自动更新（AppImageUpdate / zsync）

**不包含**（v1）：
- 录制 / 边拍边剪辑
- 相册访问
- 本地 YOLO 推理
- 系统托盘
- 自定义 title bar
- 顶部菜单栏（File/Edit/Help）

### 1.3 非目标

- 不替代专业视频编辑软件（Davinci/Premiere）
- 不做完整时间轴编辑（multi-track、关键帧、特效等）
- 不在 v1 阶段支持 macOS/Windows（架构上预留可能性，但本次只交付 Linux）

## 2. 架构决策

### 2.1 单一仓库 + 单一分支

继续在现有 `restcut_app/` 目录下开发，**不**新建仓库或长期分支。理由：
- 代码已有 `Platform.isLinux` 分支（`storage_service`、`telemetry_service` 等）
- Flutter 单代码库多端是核心价值主张
- 移动端的业务逻辑、API、bloc、剪辑流程可直接复用

### 2.2 入口分离 + 页面文件夹分离

```
lib/
├── main.dart              # 入口分发：判平台 → runApp(MobileApp | DesktopApp)
├── main_mobile.dart       # 移动端 App widget
├── main_desktop.dart      # 桌面端 App widget
├── pages/
│   ├── mobile/            # 移动端独有页面（现有页面迁入）
│   └── desktop/           # 桌面端独有页面（新写）
├── widgets/
│   ├── shared/            # 跨端通用组件
│   ├── mobile/
│   └── desktop/
├── services/              # 共享：API、ffmpeg、存储、状态管理
├── store/                 # 共享：bloc
├── models/                # 共享：数据模型
├── api/                   # 共享：HTTP 客户端、retrofit
└── core/                  # 共享：路由、错误处理
```

**Tree-shaking 验证**：完成迁移后用 `flutter build apk --analyze-size` 量化 Android APK 增量。预期 ≤ 3 MB。

### 2.3 资源管理

桌面专属资源（如桌面用图标、AppImage 桌面文件等）放在 `assets/desktop/`，**不**列入 `pubspec.yaml` 的默认 `flutter.assets`，避免污染 APK。打包脚本单独注入。

### 2.4 主题策略

**双主题**：默认深色（参考 Penpot 风格）+ 浅色（与现有 Web 版一致）+ 跟随系统。在设置页 → 外观切换。

## 3. 用户工作流

### 3.1 主流程

```
视频库 (Home)
   │
   ├─ 点击视频卡片  ─┐
   └─ "+ 新建剪辑"  ─┴─> 智能剪辑配置页
                              │
                              ├─ 拖拽 / 选择文件
                              └─ 配置参数（比赛类型、检测方式、剪辑选项、预设）
                              │
                              ▼ "▶ 开始检测剪辑"
                         检测进行中
                              │
                              ▼
                         回合选择页（粗剪辑：批量勾选）
                              │
              ┌───────────────┴───────────────┐
              │                               │
              ▼                               ▼
       "✎ 进入精修编辑"                  "→ 预览"
              │                               │
              ▼                               │
         精修编辑页                            │
       (Davinci 风格：时间轴 + 入出点)         │
              │                               │
              └───────────"→ 预览"────────────┤
                                              ▼
                                       预览/导出页
                                       (合成预览 + 拖拽顺序 + 导出参数)
                                              │
                                              ▼ "▶ 导出"
                                       导出选项确认 modal
                                              │
                                              ▼ "开始导出"
                                       ffmpeg 真正执行
```

### 3.2 安全网设计

- "完成 / 导出" 按钮**永远不会**直接触发文件写操作
- 至少要经过：选择 → 预览 → 导出 modal 三道关卡
- 真正的 ffmpeg 执行只在最终 modal 的"开始导出"后发生

## 4. UI 设计

### 4.1 整体结构（参考 Penpot）

- **左侧栏**（200px 固定）：账户区 + 搜索 + 主导航（视频库 / 任务）+ 分类（乒乓球 / 羽毛球）+ 状态（处理中 / 已完成）+ 底部（设置 / 帮助 / 关于）
- **主区**：根据当前路由切换
- **顶部页头**：面包屑 + 右侧操作按钮（取消 / 主操作）

### 4.2 七个核心页面

| 页面 | 路由 | 主要交互 | Mockup |
|---|---|---|---|
| 视频库（首页）| `/` | 卡片网格 + tab + 顶部筛选 | `home-mockup.html` |
| 智能剪辑配置 | `/clip/new` | 双面板：左配置 + 右上传 | `smart-edit-v3.html` |
| 回合选择 | `/clip/:id/select` | 时间轴 + 卡片网格 + 工具栏 | `round-selection-v3.html` |
| 预览/导出 | `/clip/:id/preview` | 双面板：左导出配置 + 右合成预览 | `preview-export.html` |
| 精修编辑 | `/clip/:id/edit` | 三栏：左回合列表 + 中编辑器 + 时间轴 | `precision-edit.html` |
| 任务列表 | `/tasks` | 行列表 + 进度条 + tab 筛选 | `task-and-settings.html` |
| 设置 | `/settings` | 左 section 导航 + 右内容 | `task-and-settings.html` |

完整 mockup 路径：`.superpowers/brainstorm/1108476-1777886500/content/`

### 4.3 视觉语言

- 字体：系统默认（`-apple-system, BlinkMacSystemFont, "Segoe UI", "PingFang SC", sans-serif`）
- 主色：`#6366f1`（indigo-500）
- 背景层级：`#171719`（titlebar）/ `#18181b`（侧栏）/ `#1a1a1d`（次主区）/ `#1f1f23`（主区）/ `#232328`（卡片）
- 边框：`rgba(255,255,255,0.04 ~ 0.08)`
- 圆角：6-10px

## 5. 平台兼容性

### 5.1 插件兼容性矩阵

| 插件 | Android | Linux | 处理方式 |
|---|---|---|---|
| `ffmpeg_kit_flutter_new` | ✓ | ✗ | Linux：`Process.run('ffmpeg', ...)` 调用 AppDir 内捆绑的静态 ffmpeg |
| `camera` / `camerawesome` | ✓ | ✗ | Linux：禁用录制功能（v1 不在 scope） |
| `photo_manager` | ✓ | ✗ | Linux：禁用相册访问（v1 不在 scope） |
| `image_picker` | ✓ | ✓ | Linux：通过 file_picker fallback |
| `gal` / `gal_linux` | ✓ | ✓ | 已有 `gal_linux` 兜底 |
| `workmanager` | ✓ | ✗ | Linux：用 Dart Isolate 替代后台任务 |
| `flutter_background_service` | ✓ | ✗ | Linux：N/A，桌面应用窗口可保持运行 |
| `ultralytics_yolo` | ✓ | ✗ | Linux：仅云端检测 |
| `flutter_native_video_trimmer` | ✓ | ✗ | Linux：用 ffmpeg 实现 trimming |
| `android_package_installer` | ✓ | ✗ | Linux：N/A，更新走 AppImageUpdate |
| `permission_handler` | ✓ | △ | Linux：大部分 N/A，仅文件系统权限 |
| `flutter_local_notifications` | ✓ | ✓ | 直接可用（libnotify） |
| `device_info_plus` / `package_info_plus` | ✓ | ✓ | 直接可用 |
| `path_provider` | ✓ | ✓ | 直接可用，遵循 XDG |
| `file_picker` | ✓ | ✓ | 直接可用 |
| `url_launcher` | ✓ | ✓ | 直接可用（xdg-open） |
| `shared_preferences` | ✓ | ✓ | 直接可用 |
| `sqflite` 系列 | ✓ | ✓ | Linux 用 `sqflite_common_ffi` |

### 5.2 平台守护

调用 Android-only API 之前必须 `if (Platform.isAndroid) { ... }` 守护。建议引入一个 `lib/services/platform_capability.dart` 集中管理：

```dart
class PlatformCapability {
  static bool get supportsRecording => Platform.isAndroid || Platform.isIOS;
  static bool get supportsLocalDetection => Platform.isAndroid || Platform.isIOS;
  static bool get supportsGalleryAccess => Platform.isAndroid || Platform.isIOS;
  // ...
}
```

UI 层根据这些能力决定是否渲染入口。

## 6. 技术实现

### 6.1 ffmpeg 集成

**来源**：[johnvansickle.com/ffmpeg/](https://johnvansickle.com/ffmpeg/) 静态链接构建（GPL 版含 libx264/libx265）

**架构**：x86_64 + aarch64 各一份

**位置**：`AppDir/usr/bin/ffmpeg`（构建时下载并放入）

**调用层重构**：现有 `lib/services/utils/ffmpeg_manager.dart` 和 `lib/utils/ffmpeg_manager.dart` 是中央封装。需要抽象出 `FFmpegRunner` 接口：

```dart
abstract class FFmpegRunner {
  Future<int> run(List<String> args, {void Function(double)? onProgress});
}

class MobileFFmpegRunner implements FFmpegRunner { /* 用 ffmpeg_kit */ }
class DesktopFFmpegRunner implements FFmpegRunner { /* 用 Process.run */ }
```

通过 `Platform.isLinux` 选择实现。

### 6.2 桌面原生集成（A 标配）

| 功能 | 实现 |
|---|---|
| 原生窗口装饰 | Flutter 默认即是 |
| 文件拖拽 | `desktop_drop` 插件 |
| 桌面通知 | `flutter_local_notifications`（Linux 后端使用 libnotify） |
| 基础快捷键 | Flutter `Shortcuts` widget + `Actions`，绑定 Ctrl+N / Ctrl+, / Ctrl+W |
| 窗口大小记忆 | `window_manager` 插件 + `shared_preferences` 存储 |

### 6.3 数据存储路径（XDG 规范）

| 类型 | 路径 |
|---|---|
| 配置 | `~/.config/huji/` |
| 缓存（视频缩略图、临时 ffmpeg 文件）| `~/.cache/huji/` |
| 数据（数据库、用户视频元信息）| `~/.local/share/huji/` |
| 用户视频导出默认目录 | `~/Videos/弧迹/` |

实现：`path_provider` 已经返回 XDG 路径，验证 `getApplicationSupportDirectory()` 等返回值正确。

### 6.4 云端检测（Linux 唯一可用）

复用现有 `lib/api/` 下的检测客户端。在配置页强制锁定"检测方式 = 云端"，UI 层禁用本地检测选项。

## 7. 构建与发布

### 7.1 本地构建脚本

`scripts/build_appimage.sh`：

1. `flutter build linux --release --target-platform=linux-x64`（或 `linux-arm64`）
2. 准备 `AppDir/` 结构：
   ```
   AppDir/
   ├── usr/
   │   ├── bin/
   │   │   ├── huji          # Flutter 产物
   │   │   └── ffmpeg        # 静态二进制（构建时下载）
   │   ├── lib/              # Flutter runtime 依赖
   │   └── share/
   │       └── huji/data/    # Flutter assets
   ├── huji.desktop          # 桌面文件
   ├── huji.svg              # 应用图标
   └── AppRun                # 启动脚本
   ```
3. 用 `linuxdeploy` + `linuxdeploy-plugin-gtk` 收集依赖
4. 用 `appimagetool` 打包成 `.AppImage`
5. 嵌入 update-information（zsync URL）

### 7.2 GitHub Actions CI

文件：`.github/workflows/build_appimage.yml`

触发：推送 tag `v*`

矩阵：
- `ubuntu-22.04` x `[x86_64, aarch64]`
- aarch64 用 QEMU 跨平台构建（或 GitHub 的 ARM runner，2026 年应已普及）

输出：上传到 GitHub Releases，文件名格式 `huji-${VERSION}-${ARCH}.AppImage`

### 7.3 自动更新（AppImageUpdate）

在 AppImage 中嵌入 `update-information`：
```
gh-releases-zsync|hhoao|huji|latest|huji-*-x86_64.AppImage.zsync
```

应用启动时调用 `appimageupdatetool --check-for-update`（或自实现），发现新版本则提示用户。

跟现有 `app_update_service.dart` 整合：在 Linux 上走 AppImage 更新链路而非 APK 安装链路。

## 8. 实施阶段

### Phase 1：构建骨架（1-2 周）

- 验证 `flutter build linux` 出包
- 编写 `scripts/build_appimage.sh`
- 设置 GitHub Actions workflow
- 出第一个能启动的 AppImage（即使只显示空页面）

### Phase 2：UI 脚手架（2-3 周）

- 入口分发（`main.dart` 判平台）
- 桌面 App widget + 路由
- 七个页面的空壳（导航能跑通，但功能未连）
- 主题切换、侧栏、基础组件

### Phase 3：功能集成（3-4 周）

- 视频导入（拖拽 + 文件选择器）
- ffmpeg 调用层重构（`FFmpegRunner` 接口）
- 云端检测对接
- 回合选择 / 预览 / 精修编辑功能实现
- 任务管理、导出

### Phase 4：打磨与发布（1-2 周）

- 桌面通知
- 快捷键
- 窗口状态记忆
- 自动更新
- 多语言（如已支持）
- 性能优化、bug 修复
- 发布 v1.0

## 9. 风险与权衡

| 风险 | 影响 | 缓解 |
|---|---|---|
| ffmpeg 静态二进制许可（GPL）| 法律风险 | 项目本身是 Apache 2.0，加 ffmpeg 后整体变成 GPL 兼容；在 README 标注 |
| Tree-shaking 失败导致 APK 膨胀 | Android 包变大 | Phase 2 完成时跑 `--analyze-size` 验证；超过 3MB 增量需查找原因 |
| aarch64 构建 CI 时间翻倍 | 发版变慢 | 接受；多架构发版本是用户价值 |
| Linux 不同发行版兼容性 | 部分用户用不了 | AppImage 自包含设计已最大化兼容；针对 glibc 版本测试 Ubuntu 20.04+ |
| 现有插件 API 在 Linux 上行为差异 | 隐藏 bug | Phase 2 在 Linux 上跑 e2e 流程，发现问题就地修 |

## 10. 待验证假设

文档完成后实施时需要现场验证：

1. **`flutter build linux` 在当前 Flutter 版本（3.8.1+）下能否成功**
   - 现有 `linux/` 目录已经脚手架，但未实测
2. **`ffmpeg_kit_flutter_new` 在不引入 Linux 实现的前提下，是否会破坏 Linux 构建**
   - 如果会，需要把它替换为条件依赖
3. **`sqflite_common_ffi` 在 Linux 上能否直接工作**
   - 应该可以，但需 Phase 1 测试
4. **GitHub Actions 的 ARM runner 在 2026 年的可用性 / 价格**
   - 如不可用就用 QEMU 跨编译

## 11. 参考资料

- Mockup 文件：`.superpowers/brainstorm/1108476-1777886500/content/`
- 现有移动端回合剪辑实现：`restcut_app/lib/pages/clip/round_clip_page.dart`
- 现有 ffmpeg 中央封装：`restcut_app/lib/services/utils/ffmpeg_manager.dart`
- AppImage 官方文档：https://docs.appimage.org/
- linuxdeploy：https://github.com/linuxdeploy/linuxdeploy
- ffmpeg 静态构建：https://johnvansickle.com/ffmpeg/
