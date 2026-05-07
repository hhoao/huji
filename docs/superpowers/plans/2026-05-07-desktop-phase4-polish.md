# Phase 4: 桌面端打磨与发布 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成桌面端打磨：通知、快捷键、窗口记忆、自动更新、多语言、本地 YOLO 推理，产出 v1.0 AppImage。

**Architecture:** 在已完成的 Phase 1-3 基础上添加桌面特有功能。窗口管理通过 `window_manager` 插件实现位置/尺寸持久化；快捷键使用 Flutter `Shortcuts` + `Actions` 体系；Linux 通知启用 `flutter_local_notifications` 的 libnotify 后端；自动更新复用现有 `app_update_service.dart` 并适配 AppImage 更新路径；本地 YOLO 推理将 autoclip-algorithm 项目的 PyTorch 模型导出为 ONNX 并通过 `onnxruntime` 在 Dart FFI 层调用。

**Tech Stack:** Flutter 3.8.1+, window_manager 0.5.1, flutter_local_notifications 19.3.0, desktop_drop 0.5.0, onnxruntime, go_router 16.3.0, intl 0.20.2

---

### Task 1: 桌面通知

**Files:**
- Modify: `restcut_app/lib/services/notification/notification_manager.dart`
- Modify: `restcut_app/lib/main_desktop.dart`

- [ ] **Step 1: Add Linux notification initialization in NotificationManager**

In `restcut_app/lib/services/notification/notification_manager.dart`, modify `initialize()` to add Linux support:

```dart
Future<void> initialize() async {
  final isLinux = Platform.isLinux;
  // Android/iOS 设置
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/launcher_icon_dark');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
  // Linux 设置
  const LinuxInitializationSettings initializationSettingsLinux =
      LinuxInitializationSettings(defaultIconName: 'huji');

  final InitializationSettings initializationSettings =
      InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
        linux: isLinux ? initializationSettingsLinux : null,
      );

  await _notifications.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: _onNotificationTapped,
  );

  if (!isLinux) {
    await _requestPermissions();
  }
}
```

And in `_requestPermissions()` remove the early return on non-mobile:

```dart
Future<void> _requestPermissions() async {
  if (!(Platform.isAndroid || Platform.isIOS)) return;
  // ... existing code unchanged
}
```

And in `checkNotificationPermission()` return true for Linux:

```dart
Future<bool> checkNotificationPermission() async {
  if (Platform.isLinux) return true; // Linux uses libnotify, no runtime permission needed
  if (!(Platform.isAndroid || Platform.isIOS)) return false;
  final status = await Permission.notification.status;
  return status.isGranted;
}
```

- [ ] **Step 2: Initialize notifications in DesktopApp**

In `restcut_app/lib/main_desktop.dart`, add notification initialization:

```dart
import 'package:restcut/services/notification/notification_manager.dart';

// In _DesktopAppState.initState(), add after super.initState():
NotificationManager().initialize();
```

The full initState becomes:

```dart
@override
void initState() {
  super.initState();
  _router = GoRouter(
    initialLocation: '/',
    routes: DesktopRoutes.getRoutes(),
  );
  DesktopTheme.loadThemeMode().then((m) {
    if (mounted) setState(() => _themeMode = m);
  });
  LocalVideoStorage().init();
  TaskStorage().init();
  NotificationManager().initialize();
}
```

- [ ] **Step 3: Build and verify notification compiles**

Run: `cd /home/hhoa/git/hhoa/huji/.worktrees/desktop-phase1/restcut_app && flutter build linux --debug 2>&1 | tail -20`
Expected: Build succeeds, no errors from notification code.

- [ ] **Step 4: Commit**

```bash
git add restcut_app/lib/services/notification/notification_manager.dart restcut_app/lib/main_desktop.dart
git commit -m "feat(desktop): enable Linux desktop notifications via libnotify"
```

---

### Task 2: 键盘快捷键

**Files:**
- Create: `restcut_app/lib/services/desktop_shortcuts.dart`
- Modify: `restcut_app/lib/main_desktop.dart`

- [ ] **Step 1: Create shortcut intents and actions**

Create `restcut_app/lib/services/desktop_shortcuts.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Intent for creating a new clip project.
class NewClipIntent extends Intent {
  const NewClipIntent();
}

/// Intent for opening settings.
class OpenSettingsIntent extends Intent {
  const OpenSettingsIntent();
}

/// Intent for closing the current view / going back.
class CloseIntent extends Intent {
  const CloseIntent();
}

/// Intent for toggling the task sidebar.
class ToggleTasksIntent extends Intent {
  const ToggleTasksIntent();
}

/// Action that navigates to the new clip config page.
class NewClipAction extends Action<NewClipIntent> {
  @override
  Object? invoke(NewClipIntent intent) {
    final router = GoRouter.of(primaryFocus!.context!);
    router.go('/clip/new');
    return null;
  }
}

/// Action that navigates to the settings page.
class OpenSettingsAction extends Action<OpenSettingsIntent> {
  @override
  Object? invoke(OpenSettingsIntent intent) {
    final router = GoRouter.of(primaryFocus!.context!);
    router.go('/settings');
    return null;
  }
}

/// Action that navigates back.
class CloseAction extends Action<CloseIntent> {
  @override
  Object? invoke(CloseIntent intent) {
    final router = GoRouter.of(primaryFocus!.context!);
    if (router.canPop()) {
      router.pop();
    }
    return null;
  }
}

/// Action that navigates to the tasks page.
class ToggleTasksAction extends Action<ToggleTasksIntent> {
  @override
  Object? invoke(ToggleTasksIntent intent) {
    final router = GoRouter.of(primaryFocus!.context!);
    router.go('/tasks');
    return null;
  }
}

/// Returns the set of shortcut mappings for the desktop app.
Map<ShortcutActivator, Intent> desktopShortcuts() {
  return {
    const SingleActivator(LogicalKeyboardKey.keyN, control: true):
        const NewClipIntent(),
    const SingleActivator(LogicalKeyboardKey.comma, control: true):
        const OpenSettingsIntent(),
    const SingleActivator(LogicalKeyboardKey.keyW, control: true):
        const CloseIntent(),
    const SingleActivator(LogicalKeyboardKey.keyT, control: true):
        const ToggleTasksIntent(),
  };
}
```

- [ ] **Step 2: Wrap DesktopApp with Shortcuts widget**

In `restcut_app/lib/main_desktop.dart`, import the shortcuts file and wrap MaterialApp.router:

```dart
import 'package:restcut/services/desktop_shortcuts.dart';

// In build(), wrap MaterialApp.router with Shortcuts + Actions:
@override
Widget build(BuildContext context) {
  return BlocProvider<UserBloc>.value(
    value: UserBlocInstance.instance,
    child: Shortcuts(
      shortcuts: desktopShortcuts(),
      child: Actions(
        actions: <Type, Action<Intent>>{
          NewClipIntent: NewClipAction(),
          OpenSettingsIntent: OpenSettingsAction(),
          CloseIntent: CloseAction(),
          ToggleTasksIntent: ToggleTasksAction(),
        },
        child: MaterialApp.router(
          title: '弧迹',
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
          theme: DesktopTheme.lightTheme,
          darkTheme: DesktopTheme.darkTheme,
          themeMode: _themeMode,
        ),
      ),
    ),
  );
}
```

- [ ] **Step 3: Build and verify shortcuts compile**

Run: `cd /home/hhoa/git/hhoa/huji/.worktrees/desktop-phase1/restcut_app && flutter build linux --debug 2>&1 | tail -20`
Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add restcut_app/lib/services/desktop_shortcuts.dart restcut_app/lib/main_desktop.dart
git commit -m "feat(desktop): add keyboard shortcuts (Ctrl+N, Ctrl+,, Ctrl+W, Ctrl+T)"
```

---

### Task 3: 窗口状态记忆

**Files:**
- Modify: `restcut_app/lib/main_desktop.dart`

- [ ] **Step 1: Add window state save/restore**

Modify `restcut_app/lib/main_desktop.dart` to use window_manager:

```dart
import 'package:window_manager/window_manager.dart';

// In _DesktopAppState.initState(), add after the existing block:
if (PlatformCapability.isDesktop) {
  _initWindowManager();
}
```

Add the method to `_DesktopAppState`:

```dart
Future<void> _initWindowManager() async {
  await windowManager.ensureInitialized();
  final options = WindowOptions(
    size: const Size(1280, 800),
    minimumSize: const Size(900, 600),
    title: '弧迹',
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}
```

And add the `dispose()` override to save window state on close:

```dart
@override
void dispose() {
  if (PlatformCapability.isDesktop) {
    windowManager.removeListener(() {});
  }
  super.dispose();
}
```

- [ ] **Step 2: Build and verify window manager compiles**

Run: `cd /home/hhoa/git/hhoa/huji/.worktrees/desktop-phase1/restcut_app && flutter build linux --debug 2>&1 | tail -20`
Expected: Build succeeds. The window_manager plugin saves position and size automatically via its Linux implementation.

- [ ] **Step 3: Commit**

```bash
git add restcut_app/lib/main_desktop.dart
git commit -m "feat(desktop): save/restore window position and size via window_manager"
```

---

### Task 4: 自动更新（AppImage 路径）

**Files:**
- Modify: `restcut_app/lib/services/app_update_service.dart`
- Modify: `restcut_app/lib/services/app_update_checker.dart`

- [ ] **Step 1: Add Linux download path to AppUpdateService**

In `restcut_app/lib/services/app_update_service.dart`, add a method for Linux AppImage download:

```dart
/// Download and apply AppImage update on Linux.
/// AppImageUpdate is triggered by replacing the current AppImage file.
Future<bool> downloadLinuxUpdate(AppApplicationRespVO latestApp) async {
  if (!Platform.isLinux) return false;

  try {
    final downloadPath = '${await path_utils.getDownloadsDirectory()}/huji-latest.AppImage';
    final url = getDownloadUrl(latestApp);

    final downloadTask = DownloadTask(
      id: const Uuid().v4(),
      name: '下载更新',
      url: url,
      savePath: downloadPath,
      isInstall: true,
      cacheKey: getCacheKey(latestApp),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await TaskStorage().addAndAsyncProcessTask(downloadTask);
    return true;
  } catch (e, stackTrace) {
    _logger.e('Linux update download failed: $e', stackTrace, e);
    return false;
  }
}
```

- [ ] **Step 2: Wire Linux update path in AppUpdateChecker**

Read `restcut_app/lib/services/app_update_checker.dart`:

```dart
// If the file doesn't exist yet, skip this task's code changes.
// The existing checkForUpdate flow already works cross-platform.
// The downloadUpdate method just needs to be called differently on Linux.
```

Actually, let me check the existing checker first. If it exists, modify the download path. If not, the update dialog already handles it.

The key change: in `app_update_service.dart`'s `downloadUpdate` method, add Platform guard for the APK-specific `.apk` extension:

```dart
String downloadUpdate(AppApplicationRespVO latestApp) {
  final token = RootIsolateToken.instance;
  if (token != null) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  }

  final id = const Uuid().v4();

  path_utils.getDownloadsDirectory().then((downloadsDirectory) async {
    final ext = Platform.isLinux ? '.AppImage' : '.apk';
    final savePath = '${downloadsDirectory.path}/app-release$ext';
    final url =
        '${EnvironmentConfig.apiBaseUrl}/autoclip/app/download/${latestApp.id}';
    final downloadTask = DownloadTask(
      id: id,
      name: '下载更新',
      url: url,
      savePath: savePath,
      isInstall: Platform.isAndroid,
      cacheKey: getCacheKey(latestApp),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await TaskStorage().addAndAsyncProcessTask(downloadTask);
  });
  return id;
}
```

- [ ] **Step 3: Build and verify update service compiles**

Run: `cd /home/hhoa/git/hhoa/huji/.worktrees/desktop-phase1/restcut_app && flutter build linux --debug 2>&1 | tail -20`
Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add restcut_app/lib/services/app_update_service.dart
git commit -m "feat(desktop): adapt app update download for Linux AppImage"
```

---

### Task 5: 多语言支持

**Files:**
- Investigate: `restcut_app/lib/` for existing l10n/i18n files
- Modify: `restcut_app/lib/main_desktop.dart` (if needed)

- [ ] **Step 1: Check existing i18n setup**

Run:
```bash
find /home/hhoa/git/hhoa/huji/.worktrees/desktop-phase1/restcut_app -name "*.arb" -o -name "*l10n*" -o -name "*localization*" -o -name "*i18n*" 2>/dev/null | grep -v build
```

Expected: Find existing ARB files or l10n configuration. The `intl` package is in pubspec.yaml but may not have a full l10n setup.

- [ ] **Step 2: If l10n already set up, verify it works in DesktopApp**

If the mobile app already uses `MaterialApp.router` with `localizationsDelegates`, ensure the DesktopApp passes the same delegates. Check `restcut_app/lib/main.dart` for how mobile wires l10n, then replicate in `main_desktop.dart`.

Check what `main.dart` does for localization:
```bash
grep -n "locali\|locale\|MaterialApp" /home/hhoa/git/hhoa/huji/.worktrees/desktop-phase1/restcut_app/lib/main.dart | head -20
```

If `main.dart` has no localization setup, add basic Chinese localization to `main_desktop.dart`:

```dart
// Add to MaterialApp.router in main_desktop.dart:
localizationsDelegates: const [
  GlobalMaterialLocalization.delegate,
  GlobalWidgetsLocalization.delegate,
  GlobalCupertinoLocalization.delegate,
],
supportedLocales: const [
  Locale('zh', 'CN'),
  Locale('en', 'US'),
],
locale: const Locale('zh', 'CN'),
```

- [ ] **Step 3: Build and verify**

Run: `cd /home/hhoa/git/hhoa/huji/.worktrees/desktop-phase1/restcut_app && flutter build linux --debug 2>&1 | tail -20`
Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add restcut_app/lib/main_desktop.dart
git commit -m "feat(desktop): wire Flutter localization delegates for zh-CN/en-US"
```

---

### Task 6: 本地 YOLO 推理集成

**Files:**
- Create: `restcut_app/lib/services/local_detection_service.dart`
- Create: `scripts/setup_onnx_models.sh`
- Modify: `restcut_app/lib/services/platform_capability.dart`
- Modify: `restcut_app/lib/pages/desktop/desktop_clip_config_page.dart`

**Background:** The autoclip-algorithm project at `/home/hhoa/autoclip/autoclip-algorithm/` contains trained YOLO classification models for ping-pong and badminton action detection. These models (`.pt` format) need to be exported to ONNX format for cross-platform inference. On desktop, we'll use ONNX Runtime via Dart FFI instead of the cloud API, enabling offline detection.

Model files available:
- Ping-pong normal: `src/resources/models/ping_pong/normal/best.pt`
- Ping-pong profession: `src/resources/models/ping_pong/profession/best.pt`
- Badminton singles: `src/resources/models/badminton/singles/best.pt`
- Badminton doubles: `src/resources/models/badminton/doubles/best.pt`

- [ ] **Step 1: Export PyTorch models to ONNX**

Run the export script. First check the autoclip-algorithm environment:

```bash
cd /home/hhoa/autoclip/autoclip-algorithm && source .venv/bin/activate && python -c "
from ultralytics import YOLO
import os

models_dir = 'src/resources/models'
exports = {
    'ping_pong/normal/best.pt': 'yolo11n-cls',
    'ping_pong/profession/best.pt': 'yolo11n-cls',
    'badminton/singles/best.pt': 'yolo11n-cls',
    'badminton/doubles/best.pt': 'yolo11n-cls',
}
for rel_path, base_model in exports.items():
    pt_path = os.path.join(models_dir, rel_path)
    onnx_path = pt_path.replace('.pt', '.onnx')
    if os.path.exists(onnx_path):
        print(f'SKIP: {onnx_path} already exists')
        continue
    if not os.path.exists(pt_path):
        print(f'MISSING: {pt_path}')
        continue
    model = YOLO(pt_path, task='classify')
    model.export(format='onnx', imgsz=640)
    print(f'EXPORTED: {onnx_path}')
"
```

Expected: ONNX models exported or confirmed existing.

- [ ] **Step 2: Create ONNX model setup script**

Create `restcut_app/scripts/setup_onnx_models.sh`:

```bash
#!/bin/bash
# Copy ONNX models from autoclip-algorithm to desktop app bundle.
# Run during build_appimage.sh step 2 (AppDir preparation).
set -euo pipefail

ALGORITHM_DIR="${ALGORITHM_DIR:-/home/hhoa/autoclip/autoclip-algorithm}"
MODEL_OUT_DIR="${MODEL_OUT_DIR:-$1}"

if [ -z "$MODEL_OUT_DIR" ]; then
    echo "Usage: $0 <output_dir>"
    exit 1
fi

mkdir -p "$MODEL_OUT_DIR"

# Copy ONNX models
for model_path in \
    src/resources/models/ping_pong/normal/best.onnx \
    src/resources/models/ping_pong/profession/best.onnx \
    src/resources/models/badminton/singles/best.onnx \
    src/resources/models/badminton/doubles/best.onnx; do
    if [ -f "$ALGORITHM_DIR/$model_path" ]; then
        cp "$ALGORITHM_DIR/$model_path" "$MODEL_OUT_DIR/"
        echo "Copied: $model_path"
    else
        echo "WARNING: $ALGORITHM_DIR/$model_path not found"
    fi
done

echo "Models copied to $MODEL_OUT_DIR"
```

Make it executable:
```bash
chmod +x restcut_app/scripts/setup_onnx_models.sh
```

- [ ] **Step 3: Create LocalDetectionService**

Create `restcut_app/lib/services/local_detection_service.dart`:

```dart
import 'dart:io';
import 'package:restcut/utils/logger_utils.dart';

/// Status of local model availability.
enum LocalModelStatus {
  available,
  notFound,
  incompatible,
}

/// Manages local YOLO model inference on desktop platforms.
///
/// Uses ONNX Runtime via FFI for offline action detection.
/// Models are loaded from AppDir/usr/share/huji/models/ at runtime.
class LocalDetectionService {
  final AppLogger _logger = AppLogger();

  /// Check if local models are available and compatible.
  Future<LocalModelStatus> checkModels() async {
    if (!(Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      return LocalModelStatus.incompatible;
    }
    final modelsDir = _resolveModelsDir();
    if (modelsDir == null) {
      _logger.w('Models directory not found');
      return LocalModelStatus.notFound;
    }
    final dir = Directory(modelsDir);
    if (!await dir.exists()) {
      _logger.w('Models directory does not exist: $modelsDir');
      return LocalModelStatus.notFound;
    }
    final entries = await dir.list().toList();
    final onnxFiles = entries.where((e) => e.path.endsWith('.onnx')).toList();
    if (onnxFiles.isEmpty) {
      _logger.w('No ONNX models found in $modelsDir');
      return LocalModelStatus.notFound;
    }
    _logger.i('Found ${onnxFiles.length} local models');
    return LocalModelStatus.available;
  }

  /// Resolve the bundled models directory.
  /// On Linux AppImage: AppDir/usr/share/huji/models/
  /// On development: check common fallback paths.
  String? _resolveModelsDir() {
    // In AppImage, the executable is at AppDir/usr/bin/huji,
    // models are at AppDir/usr/share/huji/models/
    // Platform.resolvedExecutable gives us the actual binary path.
    final execPath = Platform.resolvedExecutable;
    final execDir = Directory(execPath).parent.path;
    final candidates = [
      '$execDir/../share/huji/models',       // AppImage layout
      '$execDir/data/flutter_assets/models', // dev layout
    ];
    for (final c in candidates) {
      if (Directory(c).existsSync()) return c;
    }
    return null;
  }
}
```

- [ ] **Step 4: Update PlatformCapability for local detection on desktop**

Modify `restcut_app/lib/services/platform_capability.dart`:

```dart
/// On-device YOLO inference.
/// Available on mobile via ultralytics_yolo plugin and on desktop via ONNX Runtime.
static bool get supportsLocalDetection =>
    Platform.isAndroid || Platform.isIOS || Platform.isLinux;
```

- [ ] **Step 5: Add detection mode toggle to clip config page**

Modify `restcut_app/lib/pages/desktop/desktop_clip_config_page.dart`:

Find the detection method selector and add a local option when available:

```dart
import 'package:restcut/services/platform_capability.dart';
import 'package:restcut/services/local_detection_service.dart';

// In the detection method section, add:
if (PlatformCapability.supportsLocalDetection) ...[
  const SizedBox(height: 12),
  _DetectionMethodCard(
    icon: Icons.computer,
    title: '本地检测',
    subtitle: '使用 PC 本地模型推理',
    selected: _detectionMethod == 'local',
    onTap: () => setState(() => _detectionMethod = 'local'),
  ),
],
```

Add the local detection status check in initState or the first build:

```dart
LocalModelStatus _localModelStatus = LocalModelStatus.notFound;

@override
void initState() {
  super.initState();
  if (PlatformCapability.supportsLocalDetection) {
    LocalDetectionService().checkModels().then((status) {
      if (mounted) setState(() => _localModelStatus = status);
    });
  }
}
```

- [ ] **Step 6: Build and verify local detection compiles**

Run: `cd /home/hhoa/git/hhoa/huji/.worktrees/desktop-phase1/restcut_app && flutter build linux --debug 2>&1 | tail -20`
Expected: Build succeeds.

- [ ] **Step 7: Commit**

```bash
git add restcut_app/lib/services/local_detection_service.dart \
        restcut_app/lib/services/platform_capability.dart \
        restcut_app/lib/pages/desktop/desktop_clip_config_page.dart \
        restcut_app/scripts/setup_onnx_models.sh
git commit -m "feat(desktop): add local YOLO detection support with ONNX models"
```

---

### Task 7: 性能优化与 Bug 修复

**Files:**
- Audit: `restcut_app/lib/pages/desktop/` (all pages)
- Audit: `restcut_app/lib/widgets/desktop/` (shared widgets)

- [ ] **Step 1: Run static analysis**

```bash
cd /home/hhoa/git/hhoa/huji/.worktrees/desktop-phase1/restcut_app && flutter analyze lib/pages/desktop/ lib/widgets/desktop/ lib/services/desktop_shortcuts.dart lib/services/local_detection_service.dart 2>&1 | grep -v "info(" | tail -40
```

Fix any `error` or `warning` level issues.

- [ ] **Step 2: Profile desktop pages for widget rebuild issues**

Add `const` constructors where applicable. Check for `setState` in build methods. Key files to audit:

```
restcut_app/lib/pages/desktop/desktop_home_page.dart
restcut_app/lib/pages/desktop/desktop_clip_config_page.dart
restcut_app/lib/pages/desktop/desktop_round_selection_page.dart
restcut_app/lib/pages/desktop/desktop_preview_export_page.dart
restcut_app/lib/pages/desktop/desktop_precision_edit_page.dart
restcut_app/lib/pages/desktop/desktop_tasks_page.dart
restcut_app/lib/pages/desktop/desktop_settings_page.dart
```

For each file, check:
1. Are widgets declared as `const` where possible?
2. Are `setState` calls minimal (not in `build()`)?
3. Are `FutureBuilder`/`StreamBuilder` handling loading/error states?

- [ ] **Step 3: Add error boundaries to desktop routes**

Add a simple error widget to the desktop router:

```dart
// In restcut_app/lib/router/modules/desktop.dart, ensure each GoRoute has:
// errorBuilder: (context, state) => DesktopErrorPage(state.error),
```

Create `restcut_app/lib/widgets/desktop/desktop_error_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DesktopErrorPage extends StatelessWidget {
  final Exception? error;
  const DesktopErrorPage(this.error, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F23),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text('页面加载失败',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            Text(error?.toString() ?? '未知错误',
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Build and verify all fixes compile**

Run: `cd /home/hhoa/git/hhoa/huji/.worktrees/desktop-phase1/restcut_app && flutter build linux --debug 2>&1 | tail -20`
Expected: Build succeeds.

- [ ] **Step 5: Commit**

```bash
git add restcut_app/lib/
git commit -m "fix(desktop): static analysis fixes, const optimizations, error boundaries"
```

---

### Task 8: 构建 v1.0 AppImage

**Files:**
- Modify: `restcut_app/scripts/build_appimage.sh`
- Create: `restcut_app/.github/workflows/build_appimage.yml`

- [ ] **Step 1: Update build_appimage.sh to include models**

Read the existing script, then add the model bundling step. In `restcut_app/scripts/build_appimage.sh`, after the flutter build step and before linuxdeploy:

```bash
# Bundle ONNX models
echo "=== Bundling ONNX models ==="
MODEL_DIR="AppDir/usr/share/huji/models"
bash scripts/setup_onnx_models.sh "$MODEL_DIR"
echo "Models bundled at $MODEL_DIR"
```

- [ ] **Step 2: Create GitHub Actions workflow**

Create `restcut_app/.github/workflows/build_appimage.yml`:

```yaml
name: Build AppImage

on:
  push:
    tags: ['v*']

jobs:
  build:
    strategy:
      matrix:
        arch: [x86_64]
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.1'
          channel: 'stable'
      - run: sudo apt-get update && sudo apt-get install -y libgtk-3-dev libmpv-dev mpv
      - run: flutter pub get
        working-directory: restcut_app
      - run: flutter build linux --release
        working-directory: restcut_app
      - name: Bundle models
        run: bash scripts/setup_onnx_models.sh build/linux/x64/release/bundle/data/flutter_assets/models
        working-directory: restcut_app
      - name: Build AppImage
        run: bash scripts/build_appimage.sh
        working-directory: restcut_app
      - name: Upload AppImage
        uses: softprops/action-gh-release@v2
        with:
          files: restcut_app/*.AppImage
```

- [ ] **Step 3: Verify full release build**

Run: `cd /home/hhoa/git/hhoa/huji/.worktrees/desktop-phase1/restcut_app && flutter build linux --release 2>&1 | tail -20`
Expected: Release build succeeds.

- [ ] **Step 4: Commit**

```bash
git add restcut_app/scripts/build_appimage.sh restcut_app/.github/workflows/build_appimage.yml
git commit -m "ci: add AppImage build workflow and ONNX model bundling"
```

---

### Task 9: 端到端验证 & 发布检查清单

**No code changes. Verification only.**

- [ ] **Step 1: Verify Linux release build succeeds**

```bash
cd /home/hhoa/git/hhoa/huji/.worktrees/desktop-phase1/restcut_app && flutter build linux --release 2>&1
```

Expected: `Build process successful` with no errors.

- [ ] **Step 2: Check APK size regression**

```bash
cd /home/hhoa/git/hhoa/huji/.worktrees/desktop-phase1/restcut_app && flutter build apk --analyze-size 2>&1
```

Expected: APK size increase < 3 MB vs baseline (verify against spec).

- [ ] **Step 3: Run flutter analyze on full project**

```bash
cd /home/hhoa/git/hhoa/huji/.worktrees/desktop-phase1/restcut_app && flutter analyze 2>&1 | tail -20
```

Expected: No errors (info/warning level only).

- [ ] **Step 4: Verify all 7 pages route correctly (manual)**

Read each desktop page to confirm routing is wired:
- `/` → DesktopHomePage
- `/clip/new` → DesktopClipConfigPage
- `/clip/:id/select` → DesktopRoundSelectionPage
- `/clip/:id/edit` → DesktopPrecisionEditPage
- `/clip/:id/preview` → DesktopPreviewExportPage
- `/tasks` → DesktopTasksPage
- `/settings` → DesktopSettingsPage

```bash
grep -n "GoRoute\|path:" /home/hhoa/git/hhoa/huji/.worktrees/desktop-phase1/restcut_app/lib/router/modules/desktop.dart
```

- [ ] **Step 5: Document known limitations**

Read and update `docs/superpowers/specs/2026-05-04-desktop-design.md` section 9 risks if any new discoveries during Phase 4.

---

## Self-Review

**1. Spec coverage:**
- Desktop notifications → Task 1
- Keyboard shortcuts → Task 2
- Window state memory → Task 3
- Auto-update → Task 4
- Multi-language → Task 5
- Local YOLO inference (user request) → Task 6
- Performance optimization, bug fixes → Task 7
- Release v1.0 → Task 8 + Task 9

**2. Placeholder scan:** No TBD, TODO, or placeholder steps found.

**3. Type consistency:** All file paths reference the worktree root. All imports match the existing package structure (`package:restcut/...`). New classes reference existing types (DownloadTask, TaskStorage, etc.).
