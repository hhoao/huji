# Phase 1: Build Skeleton Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `flutter build linux` succeed for the existing Restcut Flutter project, package the output as a launchable AppImage with bundled ffmpeg, and set up a GitHub Actions CI pipeline that builds AppImages for x86_64 + aarch64 on tag pushes — all while not breaking the existing Android build.

**Architecture:** Add platform abstraction (`PlatformCapability` flags + `FFmpegRunner` interface), wrap Android-only plugin calls behind `Platform.is*` guards, create a minimal `main_desktop.dart` entry that gets dispatched from `main.dart`. Build script downloads ffmpeg static binary, assembles AppDir using `linuxdeploy` and packages with `appimagetool`. GitHub Actions builds on Ubuntu 22.04 with QEMU for aarch64 cross-build.

**Tech Stack:** Flutter 3.32.5, Dart 3.8.1, linuxdeploy + linuxdeploy-plugin-gtk, appimagetool, johnvansickle.com static ffmpeg, GitHub Actions, QEMU.

**Project root:** `/home/hhoa/git/hhoa/huji/`
**Flutter project:** `/home/hhoa/git/hhoa/huji/restcut_app/` (referred to as `$FLUTTER_DIR` below)
**Internal app name:** `restcut` (from pubspec.yaml `name:` field — keep this; the binary will be named `restcut`)
**Public/file name:** `huji` (matches repo and Chinese display name 弧迹)

---

## File Structure

### New files

```
restcut_app/
├── lib/
│   ├── main_desktop.dart                       # NEW: minimal desktop App widget
│   └── services/
│       ├── platform_capability.dart            # NEW: feature flags by platform
│       └── ffmpeg/
│           ├── ffmpeg_runner.dart              # NEW: abstract interface
│           ├── mobile_ffmpeg_runner.dart       # NEW: wraps existing ffmpeg_kit
│           └── desktop_ffmpeg_runner.dart      # NEW: Process.run-based
├── scripts/
│   ├── install_appimage_tools.sh               # NEW: downloads linuxdeploy/appimagetool
│   ├── build_appimage.sh                       # NEW: main build entry
│   └── appimage/
│       ├── AppRun                              # NEW: AppImage launcher script
│       ├── huji.desktop                        # NEW: XDG desktop entry
│       └── huji.svg                            # NEW: app icon (will copy from existing assets)
└── test/
    └── services/
        └── platform_capability_test.dart       # NEW: unit test
```

```
.github/workflows/
└── build_appimage.yml                          # NEW: CI workflow
```

### Modified files

- `restcut_app/lib/main.dart` — add platform dispatcher
- `restcut_app/lib/init.dart` — guard Android-only init steps with `Platform.isLinux` checks
- All files that directly use `FFmpegKit` — replace with `FFmpegRunner.instance` indirection (audited in Task 2; expected files include `lib/services/utils/ffmpeg_manager.dart`, `lib/utils/ffmpeg_manager.dart`, `lib/store/task/video_compress_task_manager.dart`, `lib/utils/video_compress_utils.dart`, `lib/utils/video_utils.dart`, `lib/widgets/screenshot_progress_dialog.dart`, `lib/utils/app_error_utils.dart`, `lib/utils/ffmpeg_error_utils.dart`, `lib/pages/tools/video_compress_page.dart`)
- `restcut_app/pubspec.yaml` — no dependency changes expected if ffmpeg_kit gracefully no-ops on Linux (verified in Task 1); if not, mark as conditional

---

## Conventions

- **Working directory:** All `flutter` commands run from `restcut_app/`. All `git` commands run from repository root.
- **Commit message format:** Match existing repo style (see `git log --oneline -5`): `<type>: <imperative description>` where type ∈ `{feat, fix, chore, docs, refactor}`. Add `Co-Authored-By` footer if pair-programming.
- **Branching:** Per spec section 2.1, work directly on `main` (or short-lived feature branch). No long-lived branch.

---

## Task 1: Recon — probe baseline `flutter build linux --debug`

**Files:**
- Create: `docs/superpowers/plans/phase1-recon-notes.md` (scratch notes, not committed)

**Why this task:** Before any code changes, we need to know what actually fails when we try to build for Linux. The plan after this task assumes specific failure modes; Task 1 validates them.

- [ ] **Step 1: Verify Flutter Linux desktop is enabled**

Run from `$FLUTTER_DIR`:
```bash
flutter config --enable-linux-desktop
flutter doctor -v 2>&1 | grep -A 5 "Linux toolchain"
```

Expected output: a section confirming Linux toolchain. If items are missing (e.g., `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`, `liblzma-dev`), install via:
```bash
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libsecret-1-dev libjsoncpp-dev libstdc++-12-dev
```

Re-run `flutter doctor -v` until Linux toolchain is fully green.

- [ ] **Step 2: Try a debug Linux build and capture the error**

```bash
cd "$FLUTTER_DIR"
flutter pub get
flutter build linux --debug 2>&1 | tee /tmp/flutter-linux-debug.log
```

Three possible outcomes:
- **A. Build succeeds** → great, jump to Task 6 (verify executable). Skip 2-5 except review/audit.
- **B. Build fails at Dart/pub level** (e.g., a plugin's pubspec excludes Linux and breaks resolution) → record exact error, then proceed to Task 2.
- **C. Build fails at native compile level** (CMake errors, missing native plugin .so) → record exact error, then proceed to Task 2.

- [ ] **Step 3: Document findings in scratch notes**

Write to `/tmp/phase1-recon.md` (NOT committed):
```markdown
# Phase 1 Recon Notes (2026-05-04)

## flutter doctor result
[paste output]

## flutter build linux --debug result
- Outcome: [A/B/C]
- First failing log line:
  [paste]
- Suspected cause:
  [your interpretation]

## Plugins suspected to be problematic
- ffmpeg_kit_flutter_new: [reason]
- camera/camerawesome: [reason]
- ...
```

This is a scratchpad to inform the next tasks. Do NOT commit it.

- [ ] **Step 4: No commit (recon only)**

If the build succeeded (case A), skip to Task 6. Otherwise continue with Task 2.

---

## Task 2: Audit Android-only plugin call sites

**Files:**
- No code changes; produces a list used by Tasks 4-6.

**Why this task:** We need to know exactly which files import which Android-only APIs before we can wrap them.

- [ ] **Step 1: List call sites for known Android/iOS-only plugins**

Run from `$FLUTTER_DIR`:
```bash
for plugin in ffmpeg_kit_flutter_new camera camerawesome photo_manager workmanager flutter_background_service ultralytics_yolo flutter_native_video_trimmer android_package_installer permission_handler gal; do
  echo "=== $plugin ==="
  grep -rln "package:$plugin" lib/ 2>/dev/null
  echo
done
```

- [ ] **Step 2: List explicit `FFmpegKit` symbol usage (most important)**

```bash
grep -rln "FFmpegKit\|ffmpeg_kit_flutter_new" lib/
```

- [ ] **Step 3: Save the audit to scratch notes**

Append to `/tmp/phase1-recon.md`:
```markdown

## Plugin call sites audit
### ffmpeg_kit
[file paths]

### camera/camerawesome
[file paths]

[... etc ...]
```

This list will guide Tasks 4 and 5.

- [ ] **Step 4: No commit (audit only)**

---

## Task 3: Create `PlatformCapability` feature flags

**Files:**
- Create: `restcut_app/lib/services/platform_capability.dart`
- Create: `restcut_app/test/services/platform_capability_test.dart`

**Why this task:** Centralize platform-feature decisions so UI and services can ask "can I record?" / "can I do local detection?" without scattering `Platform.isAndroid` checks everywhere.

- [ ] **Step 1: Write the failing test**

Create `restcut_app/test/services/platform_capability_test.dart`:
```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:restcut/services/platform_capability.dart';

void main() {
  group('PlatformCapability', () {
    test('Linux: no recording, no local detection, no gallery, no background service', () {
      if (!Platform.isLinux) return; // skip on other platforms
      expect(PlatformCapability.supportsRecording, isFalse);
      expect(PlatformCapability.supportsLocalDetection, isFalse);
      expect(PlatformCapability.supportsGalleryAccess, isFalse);
      expect(PlatformCapability.supportsBackgroundService, isFalse);
      expect(PlatformCapability.supportsCloudDetection, isTrue);
      expect(PlatformCapability.supportsFFmpegKit, isFalse);
    });

    test('Android: full feature support', () {
      if (!Platform.isAndroid) return; // skip on other platforms
      expect(PlatformCapability.supportsRecording, isTrue);
      expect(PlatformCapability.supportsLocalDetection, isTrue);
      expect(PlatformCapability.supportsGalleryAccess, isTrue);
      expect(PlatformCapability.supportsBackgroundService, isTrue);
      expect(PlatformCapability.supportsCloudDetection, isTrue);
      expect(PlatformCapability.supportsFFmpegKit, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd "$FLUTTER_DIR"
flutter test test/services/platform_capability_test.dart
```

Expected: failure with "Couldn't resolve the package 'restcut/services/platform_capability.dart'" or similar.

- [ ] **Step 3: Implement `PlatformCapability`**

Create `restcut_app/lib/services/platform_capability.dart`:
```dart
import 'dart:io';

/// Centralized feature flags by platform.
///
/// Use these instead of scattering `Platform.isAndroid` checks throughout
/// the codebase. UI layers call these to decide whether to render entries
/// for unsupported features.
class PlatformCapability {
  PlatformCapability._();

  /// Recording / continuous shooting (uses camera + camerawesome).
  static bool get supportsRecording => Platform.isAndroid || Platform.isIOS;

  /// On-device YOLO inference (ultralytics_yolo).
  static bool get supportsLocalDetection => Platform.isAndroid || Platform.isIOS;

  /// Cloud-based detection (HTTP/WebSocket to backend).
  static bool get supportsCloudDetection => true;

  /// System gallery access (photo_manager / gal).
  static bool get supportsGalleryAccess => Platform.isAndroid || Platform.isIOS;

  /// Long-running background service (workmanager + flutter_background_service).
  static bool get supportsBackgroundService => Platform.isAndroid || Platform.isIOS;

  /// FFmpegKit Flutter plugin (Android/iOS only). On desktop we use Process.run.
  static bool get supportsFFmpegKit => Platform.isAndroid || Platform.isIOS;

  /// Native video trimmer plugin (Android/iOS). Desktop falls back to ffmpeg.
  static bool get supportsNativeTrimmer => Platform.isAndroid || Platform.isIOS;

  /// Native APK installer (Android only, used for self-update on mobile).
  static bool get supportsApkInstaller => Platform.isAndroid;

  /// Whether the platform is a desktop OS.
  static bool get isDesktop =>
      Platform.isLinux || Platform.isMacOS || Platform.isWindows;
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/services/platform_capability_test.dart
```

Expected: PASS (the Linux or Android branch matching the host runs; the other is skipped).

- [ ] **Step 5: Commit**

```bash
cd /home/hhoa/git/hhoa/huji
git add restcut_app/lib/services/platform_capability.dart restcut_app/test/services/platform_capability_test.dart
git commit -m "feat: add PlatformCapability feature flags"
```

---

## Task 4: Add `FFmpegRunner` abstraction with mobile/desktop implementations

**Files:**
- Create: `restcut_app/lib/services/ffmpeg/ffmpeg_runner.dart`
- Create: `restcut_app/lib/services/ffmpeg/mobile_ffmpeg_runner.dart`
- Create: `restcut_app/lib/services/ffmpeg/desktop_ffmpeg_runner.dart`

**Why this task:** `ffmpeg_kit_flutter_new` has no Linux native build. We need an interface that mobile uses with FFmpegKit and desktop uses with `Process.run('ffmpeg', ...)`. This task only adds the abstraction; existing call sites are migrated in Task 5.

- [ ] **Step 1: Define the abstract interface**

Create `restcut_app/lib/services/ffmpeg/ffmpeg_runner.dart`:
```dart
import 'dart:io';
import 'package:restcut/services/platform_capability.dart';
import 'mobile_ffmpeg_runner.dart';
import 'desktop_ffmpeg_runner.dart';

/// Result of an ffmpeg execution.
class FFmpegResult {
  final int returnCode;
  final String? output;
  final String? failStackTrace;

  const FFmpegResult({
    required this.returnCode,
    this.output,
    this.failStackTrace,
  });

  bool get isSuccess => returnCode == 0;
}

/// Abstract ffmpeg runner. Concrete impl chosen by platform at startup.
///
/// Mobile (Android/iOS): wraps `ffmpeg_kit_flutter_new`.
/// Desktop (Linux): runs bundled static `ffmpeg` binary via `Process.run`.
abstract class FFmpegRunner {
  static FFmpegRunner? _instance;

  /// Singleton accessor. First call constructs the platform-appropriate impl.
  static FFmpegRunner get instance {
    _instance ??= PlatformCapability.supportsFFmpegKit
        ? MobileFFmpegRunner()
        : DesktopFFmpegRunner();
    return _instance!;
  }

  /// For tests.
  static set instance(FFmpegRunner runner) {
    _instance = runner;
  }

  /// Execute ffmpeg with the given arguments (without the leading `ffmpeg`).
  ///
  /// `onProgress` receives a value in [0, 1] when progress can be parsed.
  Future<FFmpegResult> execute(
    List<String> arguments, {
    void Function(double progress)? onProgress,
  });

  /// Cancel any running execution (best-effort).
  Future<void> cancel();
}
```

- [ ] **Step 2: Implement `MobileFFmpegRunner` (wraps existing FFmpegKit usage)**

Create `restcut_app/lib/services/ffmpeg/mobile_ffmpeg_runner.dart`:
```dart
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'ffmpeg_runner.dart';

class MobileFFmpegRunner implements FFmpegRunner {
  FFmpegSession? _currentSession;

  @override
  Future<FFmpegResult> execute(
    List<String> arguments, {
    void Function(double progress)? onProgress,
  }) async {
    final cmd = arguments.join(' ');
    _currentSession = await FFmpegKit.executeAsync(
      cmd,
      null,
      null,
      onProgress == null
          ? null
          : (statistics) {
              // Time-based progress reporting needs total duration; if caller
              // wants progress they should pass it via context. For now we just
              // forward elapsed time as a fraction of 1 (capped) — callers that
              // need precise progress pass their own callback wrapping this.
              final timeMs = statistics.getTime();
              if (timeMs > 0) {
                onProgress(0.5); // placeholder; refine in Task 5 callers
              }
            },
    );

    final returnCode = await _currentSession!.getReturnCode();
    final output = await _currentSession!.getOutput();
    final failStackTrace = await _currentSession!.getFailStackTrace();

    final code = ReturnCode.isSuccess(returnCode)
        ? 0
        : ReturnCode.isCancel(returnCode)
            ? -1
            : 1;

    return FFmpegResult(
      returnCode: code,
      output: output,
      failStackTrace: failStackTrace,
    );
  }

  @override
  Future<void> cancel() async {
    await FFmpegKit.cancel();
    _currentSession = null;
  }
}
```

- [ ] **Step 3: Implement `DesktopFFmpegRunner` (Process.run-based)**

Create `restcut_app/lib/services/ffmpeg/desktop_ffmpeg_runner.dart`:
```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'ffmpeg_runner.dart';

class DesktopFFmpegRunner implements FFmpegRunner {
  Process? _currentProcess;

  /// Resolve the ffmpeg binary path.
  ///
  /// Order:
  /// 1. `HUJI_FFMPEG_PATH` env (for tests/dev)
  /// 2. AppDir-relative path (when running from AppImage, $APPDIR/usr/bin/ffmpeg)
  /// 3. Fall back to `ffmpeg` on PATH (development on dev machine)
  String _resolveFFmpegPath() {
    final fromEnv = Platform.environment['HUJI_FFMPEG_PATH'];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

    final appDir = Platform.environment['APPDIR'];
    if (appDir != null && appDir.isNotEmpty) {
      final bundled = '$appDir/usr/bin/ffmpeg';
      if (File(bundled).existsSync()) return bundled;
    }

    return 'ffmpeg';
  }

  @override
  Future<FFmpegResult> execute(
    List<String> arguments, {
    void Function(double progress)? onProgress,
  }) async {
    final path = _resolveFFmpegPath();
    // Force progress reporting via stderr time= field; caller can parse.
    final args = ['-hide_banner', '-nostdin', '-y', ...arguments];

    _currentProcess = await Process.start(path, args, runInShell: false);

    final stdoutBuf = StringBuffer();
    final stderrBuf = StringBuffer();

    _currentProcess!.stdout.transform(utf8.decoder).listen(stdoutBuf.write);
    _currentProcess!.stderr.transform(utf8.decoder).listen((line) {
      stderrBuf.write(line);
      if (onProgress != null) {
        // ffmpeg writes "time=HH:MM:SS.xx" to stderr; total duration must come
        // from the caller. As a placeholder we only emit progress on each line.
        // Callers wanting precise progress should pass a custom wrapper.
        onProgress(0.5);
      }
    });

    final exitCode = await _currentProcess!.exitCode;
    _currentProcess = null;

    return FFmpegResult(
      returnCode: exitCode,
      output: stdoutBuf.toString() + stderrBuf.toString(),
      failStackTrace: exitCode == 0 ? null : stderrBuf.toString(),
    );
  }

  @override
  Future<void> cancel() async {
    _currentProcess?.kill(ProcessSignal.sigterm);
    _currentProcess = null;
  }
}
```

- [ ] **Step 4: Verify the new files compile (without integrating yet)**

```bash
cd "$FLUTTER_DIR"
flutter analyze lib/services/ffmpeg/
```

Expected: `No issues found!` (or only `info` level).

If `import 'package:ffmpeg_kit_flutter_new/...'` fails on Linux, that means the plugin's Dart pub-spec excludes Linux entirely. In that case, conditional import is needed; replace `mobile_ffmpeg_runner.dart`'s top-level imports with:
```dart
// Imports active only when ffmpeg_kit is available; on Linux this file is
// never loaded (DesktopFFmpegRunner is selected by the factory).
```
The factory in `ffmpeg_runner.dart` already guards via `PlatformCapability.supportsFFmpegKit`, so the mobile file is unreachable on Linux. Re-run analyze; if errors persist about FFmpegKit import on Linux, add the file to a conditional import via:
```dart
// In ffmpeg_runner.dart, replace the two top imports with:
import 'mobile_ffmpeg_runner.dart'
    if (dart.library.io) 'mobile_ffmpeg_runner.dart';
```
(`dart.library.io` matches all platforms with `dart:io`, including Linux. If the actual issue is per-OS, use `dart.library.html` style conditionals — but Flutter's standard is `dart.library.ui` which does not differ between OSes. The cleanest fallback is keeping the FFmpegKit import unconditional but the factory-guard prevents runtime call.)

- [ ] **Step 5: Commit**

```bash
cd /home/hhoa/git/hhoa/huji
git add restcut_app/lib/services/ffmpeg/
git commit -m "feat: add FFmpegRunner abstraction (mobile + desktop impls)"
```

---

## Task 5: Migrate existing `FFmpegKit` callers to use `FFmpegRunner`

**Files (modify):** Files identified in Task 2's audit. Expected:
- `restcut_app/lib/services/utils/ffmpeg_manager.dart`
- `restcut_app/lib/utils/ffmpeg_manager.dart`
- `restcut_app/lib/store/task/video_compress_task_manager.dart`
- `restcut_app/lib/utils/video_compress_utils.dart`
- `restcut_app/lib/utils/video_utils.dart`
- `restcut_app/lib/widgets/screenshot_progress_dialog.dart`
- `restcut_app/lib/utils/app_error_utils.dart`
- `restcut_app/lib/utils/ffmpeg_error_utils.dart`
- `restcut_app/lib/pages/tools/video_compress_page.dart`

**Why this task:** Direct `FFmpegKit.executeAsync(...)` calls fail at link time on Linux. After this task, no file outside `lib/services/ffmpeg/mobile_ffmpeg_runner.dart` imports `package:ffmpeg_kit_flutter_new/...`.

- [ ] **Step 1: For each file, replace direct FFmpegKit usage with FFmpegRunner**

The pattern: replace `FFmpegKit.executeAsync(cmdString, ...)` with `await FFmpegRunner.instance.execute(args, onProgress: ...)`.

For each file in the audit list, do the following:

a. Change imports:
```dart
// REMOVE
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
// ... etc.

// ADD
import 'package:restcut/services/ffmpeg/ffmpeg_runner.dart';
```

b. Replace call patterns. Mobile pattern:
```dart
final session = await FFmpegKit.executeAsync(commandString, callback);
final returnCode = await session.getReturnCode();
if (ReturnCode.isSuccess(returnCode)) {
  // success path
}
```

Becomes:
```dart
final result = await FFmpegRunner.instance.execute(
  argsList,
  onProgress: (p) => /* existing progress callback */,
);
if (result.isSuccess) {
  // success path
}
```

**Note:** `FFmpegKit.executeAsync` takes a single command string; `FFmpegRunner.execute` takes `List<String>`. You need to split the command string into args. Add this helper to `restcut_app/lib/services/ffmpeg/ffmpeg_runner.dart` (top-level, after imports):
```dart
/// Splits a shell-style ffmpeg command string into args.
/// Respects double-quoted segments. Single quotes are NOT treated as quoting
/// (intentional — ffmpeg paths usually only need double-quote handling).
List<String> splitFFmpegCommand(String cmd) {
  final result = <String>[];
  final current = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < cmd.length; i++) {
    final c = cmd[i];
    if (c == '"') {
      inQuotes = !inQuotes;
    } else if (c == ' ' && !inQuotes) {
      if (current.isNotEmpty) {
        result.add(current.toString());
        current.clear();
      }
    } else {
      current.write(c);
    }
  }
  if (current.isNotEmpty) result.add(current.toString());
  return result;
}
```

c. Cancellation: replace `FFmpegKit.cancel()` with `FFmpegRunner.instance.cancel()`.

- [ ] **Step 2: Verify no remaining direct FFmpegKit imports outside the runner**

```bash
cd "$FLUTTER_DIR"
grep -rln "ffmpeg_kit_flutter_new" lib/ | grep -v "lib/services/ffmpeg/"
```

Expected: empty output. Each remaining hit is a file that still needs migration.

- [ ] **Step 3: Run `flutter analyze`**

```bash
flutter analyze lib/
```

Expected: 0 errors. Warnings/info OK.

- [ ] **Step 4: Run existing tests to confirm no regressions**

```bash
flutter test
```

Expected: tests that exist continue to pass. Tests that exercise ffmpeg may have been mocking `FFmpegKit` directly — those will need updating to mock `FFmpegRunner` instead. If any test fails for this reason, update the test to:
```dart
// In test setUp:
FFmpegRunner.instance = FakeFFmpegRunner(); // implement a fake/mock
```

- [ ] **Step 5: Commit**

```bash
cd /home/hhoa/git/hhoa/huji
git add restcut_app/lib/
git commit -m "refactor: migrate FFmpegKit callers to FFmpegRunner abstraction"
```

---

## Task 6: Guard remaining Android-only plugin call sites with platform checks

**Files (modify):** Files from Task 2's audit, excluding ffmpeg_kit (Task 5 already handled).

**Why this task:** Other plugins (`camera`, `photo_manager`, `workmanager`, `flutter_background_service`, `ultralytics_yolo`, `flutter_native_video_trimmer`, `android_package_installer`) have native code that may fail on Linux. Wrap their call sites with `if (PlatformCapability.supportsX) { ... }` so the codepath is dead on Linux.

- [ ] **Step 1: Guard `lib/init.dart`**

Read the file and identify Android-specific init steps. Wrap each with the appropriate `PlatformCapability` flag:

```dart
// Before:
await initializeBackgroundService(); // calls flutter_background_service

// After:
if (PlatformCapability.supportsBackgroundService) {
  await initializeBackgroundService();
}
```

Apply to: workmanager init, background service init, permission init for Android-only perms (notifications, storage), photo_manager scanning, etc.

- [ ] **Step 2: Guard call sites for camera, photo_manager, gal, workmanager, etc.**

For each file in the audit list (other than ffmpeg ones):
- Wrap the call site with `if (PlatformCapability.supports<Feature>) { ... }`
- For widgets/pages whose entire purpose is unsupported on desktop (e.g., `record_and_clip_page`), add an early return: `if (!PlatformCapability.supportsRecording) return const _UnsupportedOnDesktopPage();`

For now we don't need to render `_UnsupportedOnDesktopPage` (Phase 1 only opens an empty desktop UI), but defensively wrap the imports/initialization paths.

- [ ] **Step 3: Verify guards**

```bash
cd "$FLUTTER_DIR"
flutter analyze lib/
```

Expected: 0 errors.

- [ ] **Step 4: Re-run Android build to make sure mobile is not broken**

```bash
flutter build apk --debug
```

Expected: APK build still succeeds (we did not change Android behavior, only added `if` checks that resolve true on Android).

- [ ] **Step 5: Commit**

```bash
cd /home/hhoa/git/hhoa/huji
git add restcut_app/lib/
git commit -m "refactor: guard Android-only plugin call sites with PlatformCapability"
```

---

## Task 7: Achieve successful `flutter build linux --release`

**Files:** none directly; this is a verification gate.

**Why this task:** Tasks 1-6 should have addressed the known issues. Now we confirm the Linux build succeeds.

- [ ] **Step 1: Clean and rebuild**

```bash
cd "$FLUTTER_DIR"
flutter clean
flutter pub get
flutter build linux --release 2>&1 | tee /tmp/flutter-linux-release.log
```

Expected: build succeeds and produces:
- `build/linux/x64/release/bundle/restcut` (executable)
- `build/linux/x64/release/bundle/data/` (Flutter assets)
- `build/linux/x64/release/bundle/lib/` (shared libraries)

If it fails, read `/tmp/flutter-linux-release.log` for the error and:
1. If a plugin's CMakeLists fails, that plugin doesn't support Linux. Either:
   a. Wrap its usage further (Task 6 may have missed a site), or
   b. Remove from Linux build via conditional import / pubspec exclusion (last resort).
2. If a Dart compile error, look for an unguarded reference to an Android-only API.

Iterate fixes until build succeeds. Each fix should be small enough to commit independently.

- [ ] **Step 2: Smoke-test the executable**

```bash
./build/linux/x64/release/bundle/restcut &
APP_PID=$!
sleep 3
ps -p $APP_PID > /dev/null && echo "OK: process running" || echo "FAIL: process exited"
kill $APP_PID 2>/dev/null || true
```

Expected: "OK: process running". The window may show the existing mobile UI (this is fine for Phase 1 — Task 8 replaces it).

- [ ] **Step 3: Commit only if any code changes were needed**

```bash
cd /home/hhoa/git/hhoa/huji
git status # check whether anything new
# If yes:
git add restcut_app/
git commit -m "fix: resolve remaining Linux build errors"
```

---

## Task 8: Create minimal `main_desktop.dart` placeholder

**Files:**
- Create: `restcut_app/lib/main_desktop.dart`

**Why this task:** Replace the mobile UI (which renders on desktop right now) with a minimal placeholder so we can confirm the desktop entry path works. Real UI comes in Phase 2.

- [ ] **Step 1: Create the file**

Create `restcut_app/lib/main_desktop.dart`:
```dart
import 'package:flutter/material.dart';

/// Minimal placeholder for the desktop app.
///
/// Phase 1 only verifies the build pipeline. Phase 2 replaces this with
/// the full desktop UI (sidebar + library + workflow pages).
class DesktopApp extends StatelessWidget {
  const DesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '弧迹',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1F1F23),
      ),
      home: const _DesktopPlaceholderHome(),
    );
  }
}

class _DesktopPlaceholderHome extends StatelessWidget {
  const _DesktopPlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '弧迹',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '桌面版 · Phase 1 占位',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 32),
            Text(
              '构建管线已就绪。完整 UI 在 Phase 2 实现。',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it analyzes**

```bash
cd "$FLUTTER_DIR"
flutter analyze lib/main_desktop.dart
```

Expected: 0 issues.

- [ ] **Step 3: Commit**

```bash
cd /home/hhoa/git/hhoa/huji
git add restcut_app/lib/main_desktop.dart
git commit -m "feat: add minimal DesktopApp placeholder"
```

---

## Task 9: Refactor `lib/main.dart` to dispatch by platform

**Files:**
- Modify: `restcut_app/lib/main.dart`

**Why this task:** When running on Linux, `main()` should run `DesktopApp` instead of `MyApp`. Mobile behavior must be unchanged.

- [ ] **Step 1: Update main.dart**

Modify `restcut_app/lib/main.dart`:

Add to the imports at the top:
```dart
import 'package:restcut/main_desktop.dart';
import 'package:restcut/services/platform_capability.dart';
```

Change the `runApp(const MyApp());` line in `main()` to:
```dart
if (PlatformCapability.isDesktop) {
  runApp(const DesktopApp());
} else {
  runApp(const MyApp());
}
```

Final relevant block in `main()`:
```dart
void main(List<String> args) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await preInit();
    await postInit();
    if (PlatformCapability.isDesktop) {
      runApp(const DesktopApp());
    } else {
      runApp(const MyApp());
    }
  } catch (e, stack) {
    await ErrorLogService.instance.recordError(
      e,
      stack,
      module: 'App Initialization',
    );
    showInitErrorApp(error: "App Initialization Error: $e", stackTrace: stack);
  }
}
```

- [ ] **Step 2: Rebuild and verify**

```bash
cd "$FLUTTER_DIR"
flutter build linux --release
./build/linux/x64/release/bundle/restcut &
APP_PID=$!
sleep 3
ps -p $APP_PID > /dev/null && echo "OK: process running"
# Visually confirm window shows "弧迹 / 桌面版 · Phase 1 占位"
kill $APP_PID 2>/dev/null || true
```

Expected: Linux app shows the placeholder DesktopApp.

- [ ] **Step 3: Verify Android still uses MyApp**

```bash
flutter build apk --debug
```

Expected: APK build succeeds. (We don't smoke-test the running app here; the build succeeding plus unchanged code paths gives sufficient confidence.)

- [ ] **Step 4: Commit**

```bash
cd /home/hhoa/git/hhoa/huji
git add restcut_app/lib/main.dart
git commit -m "feat: dispatch to DesktopApp on Linux from main.dart"
```

---

## Task 10: Create AppDir resources (.desktop, AppRun, icon)

**Files:**
- Create: `restcut_app/scripts/appimage/AppRun`
- Create: `restcut_app/scripts/appimage/huji.desktop`
- Create: `restcut_app/scripts/appimage/huji.svg` (copy/derive from existing icon)

**Why this task:** AppImage requires these three files at the root of the AppDir. They're checked into the repo so CI can use them.

- [ ] **Step 1: Create AppRun launcher**

Create `restcut_app/scripts/appimage/AppRun`:
```bash
#!/bin/bash
# AppRun for 弧迹 (huji) AppImage
# Runs at AppImage launch; sets up environment then execs the Flutter binary.

set -e

# Resolve $APPDIR (set automatically by AppImage runtime)
HERE="$(dirname "$(readlink -f "${0}")")"
export APPDIR="${APPDIR:-$HERE}"

# Make bundled libraries findable
export LD_LIBRARY_PATH="$APPDIR/usr/lib:$APPDIR/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"

# Make bundled ffmpeg findable
export PATH="$APPDIR/usr/bin:$PATH"

# Optional: GDK / GTK environment for some distros
export GDK_BACKEND="${GDK_BACKEND:-x11}"

# Launch the Flutter app
exec "$APPDIR/usr/bin/restcut" "$@"
```

Make it executable:
```bash
chmod +x restcut_app/scripts/appimage/AppRun
```

- [ ] **Step 2: Create the .desktop file**

Create `restcut_app/scripts/appimage/huji.desktop`:
```ini
[Desktop Entry]
Type=Application
Name=弧迹
Name[en]=Huji
GenericName=Smart Sports Video Editor
GenericName[zh_CN]=智能体育视频剪辑
Comment=Automatically detect and clip highlights from table tennis / badminton matches
Comment[zh_CN]=自动识别乒乓球、羽毛球比赛中的精彩回合
Exec=restcut
Icon=huji
Terminal=false
Categories=AudioVideo;Video;
Keywords=video;edit;sports;table-tennis;badminton;
StartupWMClass=restcut
```

- [ ] **Step 3: Provide an SVG icon**

Check the existing icon assets:
```bash
ls restcut_app/assets/icons/
```

If `logo_bg.png` exists but no SVG, generate a minimal placeholder SVG that can be replaced later. Create `restcut_app/scripts/appimage/huji.svg`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
  <rect width="256" height="256" rx="48" fill="#1F1F23"/>
  <text x="128" y="160" font-family="-apple-system,BlinkMacSystemFont,sans-serif"
        font-size="120" font-weight="bold" fill="#6366F1"
        text-anchor="middle">弧</text>
</svg>
```

(In Phase 4 we'll replace with a designed icon. For Phase 1, this is enough to satisfy AppImage's icon requirement.)

- [ ] **Step 4: Commit**

```bash
cd /home/hhoa/git/hhoa/huji
git add restcut_app/scripts/appimage/
git commit -m "feat: add AppImage resources (AppRun, .desktop, icon)"
```

---

## Task 11: Create `install_appimage_tools.sh` helper

**Files:**
- Create: `restcut_app/scripts/install_appimage_tools.sh`

**Why this task:** `linuxdeploy` and `appimagetool` are distributed as standalone AppImage binaries. This script downloads them to a local cache so the build script doesn't have to re-download every run.

- [ ] **Step 1: Create the install script**

Create `restcut_app/scripts/install_appimage_tools.sh`:
```bash
#!/bin/bash
# Downloads linuxdeploy, linuxdeploy-plugin-gtk, and appimagetool to ./tools/.
# Idempotent: re-running checks for existence and skips if present.

set -e

ARCH="${ARCH:-$(uname -m)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOLS_DIR="$PROJECT_DIR/tools/appimage"

mkdir -p "$TOOLS_DIR"

declare -A URLS=(
  [linuxdeploy-x86_64]="https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
  [linuxdeploy-aarch64]="https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-aarch64.AppImage"
  [linuxdeploy-plugin-gtk-x86_64]="https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/master/linuxdeploy-plugin-gtk.sh"
  [linuxdeploy-plugin-gtk-aarch64]="https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/master/linuxdeploy-plugin-gtk.sh"
  [appimagetool-x86_64]="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
  [appimagetool-aarch64]="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-aarch64.AppImage"
)

download() {
  local name="$1"
  local target="$2"
  local url="${URLS[$name]}"
  if [[ -f "$target" ]]; then
    echo "[skip] $name already exists at $target"
    return 0
  fi
  echo "[download] $url -> $target"
  curl -fL "$url" -o "$target"
  chmod +x "$target"
}

download "linuxdeploy-${ARCH}" "$TOOLS_DIR/linuxdeploy-${ARCH}.AppImage"
download "linuxdeploy-plugin-gtk-${ARCH}" "$TOOLS_DIR/linuxdeploy-plugin-gtk.sh"
download "appimagetool-${ARCH}" "$TOOLS_DIR/appimagetool-${ARCH}.AppImage"

# Symlink to architecture-agnostic names for convenience
ln -sf "linuxdeploy-${ARCH}.AppImage" "$TOOLS_DIR/linuxdeploy.AppImage"
ln -sf "appimagetool-${ARCH}.AppImage" "$TOOLS_DIR/appimagetool.AppImage"

echo "[done] tools installed to $TOOLS_DIR"
```

- [ ] **Step 2: Make executable and verify it runs**

```bash
chmod +x restcut_app/scripts/install_appimage_tools.sh
cd "$FLUTTER_DIR"
./scripts/install_appimage_tools.sh
ls -la tools/appimage/
```

Expected output includes:
- `linuxdeploy-x86_64.AppImage` (or aarch64)
- `linuxdeploy-plugin-gtk.sh`
- `appimagetool-x86_64.AppImage`
- `linuxdeploy.AppImage` (symlink)
- `appimagetool.AppImage` (symlink)

- [ ] **Step 3: Add `tools/` to .gitignore (downloaded artifacts shouldn't be committed)**

Modify `restcut_app/.gitignore`:
```
# AppImage build artifacts
tools/
*.AppImage
```

- [ ] **Step 4: Commit**

```bash
cd /home/hhoa/git/hhoa/huji
git add restcut_app/scripts/install_appimage_tools.sh restcut_app/.gitignore
git commit -m "feat: add install_appimage_tools.sh helper"
```

---

## Task 12: Create the main `build_appimage.sh` script

**Files:**
- Create: `restcut_app/scripts/build_appimage.sh`

**Why this task:** Single-command end-to-end AppImage build for local development. CI re-uses the same script.

- [ ] **Step 1: Create the script**

Create `restcut_app/scripts/build_appimage.sh`:
```bash
#!/bin/bash
# Builds 弧迹 (huji) AppImage for Linux.
#
# Usage:
#   ./scripts/build_appimage.sh                 # build for host arch
#   ARCH=aarch64 ./scripts/build_appimage.sh    # cross/QEMU build
#
# Env vars:
#   ARCH                  Target architecture (default: $(uname -m))
#   FFMPEG_VERSION        ffmpeg static build version (default: release)
#   SKIP_FLUTTER_BUILD    1 = use existing build/linux output, don't rebuild

set -e

# === Constants ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ARCH="${ARCH:-$(uname -m)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build/appimage"
APPDIR="$BUILD_DIR/AppDir"
TOOLS_DIR="$PROJECT_DIR/tools/appimage"
APPIMAGE_RES="$SCRIPT_DIR/appimage"

# Map uname arch to flutter --target-platform format
case "$ARCH" in
  x86_64)  FLUTTER_TARGET=linux-x64 ;;
  aarch64|arm64) FLUTTER_TARGET=linux-arm64; ARCH=aarch64 ;;
  *) echo "${RED}Unsupported ARCH: $ARCH${NC}"; exit 1 ;;
esac

VERSION=$(grep "^version:" "$PROJECT_DIR/pubspec.yaml" | sed 's/version: //' | tr -d ' ' | tr -d '"')

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}弧迹 AppImage Builder${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Version:          ${GREEN}$VERSION${NC}"
echo -e "Architecture:     ${GREEN}$ARCH${NC}"
echo -e "Flutter target:   ${GREEN}$FLUTTER_TARGET${NC}"
echo -e "Output dir:       ${GREEN}$BUILD_DIR${NC}"
echo

# === 1. Ensure tools are installed ===
echo -e "${BLUE}[1/6] Installing AppImage tools...${NC}"
ARCH="$ARCH" "$SCRIPT_DIR/install_appimage_tools.sh"

# === 2. Build Flutter Linux release ===
if [[ "${SKIP_FLUTTER_BUILD:-0}" != "1" ]]; then
  echo -e "${BLUE}[2/6] Building Flutter Linux release...${NC}"
  cd "$PROJECT_DIR"
  flutter pub get
  flutter build linux --release --target-platform "$FLUTTER_TARGET"
fi

# === 3. Prepare AppDir ===
echo -e "${BLUE}[3/6] Preparing AppDir...${NC}"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/256x256/apps"

# Copy Flutter build output
FLUTTER_OUT="$PROJECT_DIR/build/linux/${FLUTTER_TARGET#linux-}/release/bundle"
# Note: $FLUTTER_TARGET=linux-x64 → bundle is at build/linux/x64/release/bundle
# linux-arm64 → build/linux/arm64/release/bundle
case "$FLUTTER_TARGET" in
  linux-x64)   FLUTTER_OUT="$PROJECT_DIR/build/linux/x64/release/bundle" ;;
  linux-arm64) FLUTTER_OUT="$PROJECT_DIR/build/linux/arm64/release/bundle" ;;
esac
cp -r "$FLUTTER_OUT/"* "$APPDIR/usr/bin/"
# Move .so files to usr/lib so linuxdeploy can find them
if [[ -d "$APPDIR/usr/bin/lib" ]]; then
  mv "$APPDIR/usr/bin/lib"/* "$APPDIR/usr/lib/" 2>/dev/null || true
  rmdir "$APPDIR/usr/bin/lib" 2>/dev/null || true
fi

# Copy AppImage resources
cp "$APPIMAGE_RES/AppRun" "$APPDIR/AppRun"
chmod +x "$APPDIR/AppRun"
cp "$APPIMAGE_RES/huji.desktop" "$APPDIR/huji.desktop"
cp "$APPIMAGE_RES/huji.desktop" "$APPDIR/usr/share/applications/huji.desktop"
cp "$APPIMAGE_RES/huji.svg" "$APPDIR/huji.svg"
cp "$APPIMAGE_RES/huji.svg" "$APPDIR/usr/share/icons/hicolor/256x256/apps/huji.svg"

# === 4. Bundle ffmpeg static binary ===
echo -e "${BLUE}[4/6] Downloading and bundling ffmpeg...${NC}"
FFMPEG_DIR="$BUILD_DIR/ffmpeg"
mkdir -p "$FFMPEG_DIR"
case "$ARCH" in
  x86_64)   FFMPEG_URL="https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz" ;;
  aarch64)  FFMPEG_URL="https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-arm64-static.tar.xz" ;;
esac
if [[ ! -f "$FFMPEG_DIR/ffmpeg" ]]; then
  curl -fL "$FFMPEG_URL" -o "$FFMPEG_DIR/ffmpeg.tar.xz"
  tar -xJf "$FFMPEG_DIR/ffmpeg.tar.xz" -C "$FFMPEG_DIR" --strip-components=1
fi
cp "$FFMPEG_DIR/ffmpeg" "$APPDIR/usr/bin/ffmpeg"
chmod +x "$APPDIR/usr/bin/ffmpeg"

# === 5. Run linuxdeploy to bundle Linux libraries ===
echo -e "${BLUE}[5/6] Running linuxdeploy...${NC}"
cd "$BUILD_DIR"
LDPLUGIN_GTK="$TOOLS_DIR/linuxdeploy-plugin-gtk.sh" \
"$TOOLS_DIR/linuxdeploy.AppImage" \
  --appdir "$APPDIR" \
  --plugin gtk \
  --executable "$APPDIR/usr/bin/restcut" \
  --desktop-file "$APPDIR/huji.desktop" \
  --icon-file "$APPDIR/huji.svg" \
  --output appimage \
  --custom-apprun "$APPDIR/AppRun" 2>&1 | tail -40

# linuxdeploy with --output appimage already produces the .AppImage file.
# It is named based on the .desktop's Name field — find and rename:
GENERATED=$(ls "$BUILD_DIR"/*.AppImage 2>/dev/null | head -1)
if [[ -z "$GENERATED" ]]; then
  echo -e "${RED}AppImage generation failed: no .AppImage in $BUILD_DIR${NC}"
  exit 1
fi
FINAL="$BUILD_DIR/huji-${VERSION}-${ARCH}.AppImage"
mv "$GENERATED" "$FINAL"

# === 6. Done ===
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}AppImage built successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}File:${NC} $FINAL"
echo -e "${GREEN}Size:${NC} $(du -h "$FINAL" | cut -f1)"
echo
echo -e "Test by running:"
echo -e "  ${YELLOW}$FINAL${NC}"
```

- [ ] **Step 2: Make executable**

```bash
chmod +x restcut_app/scripts/build_appimage.sh
```

- [ ] **Step 3: Run the script**

```bash
cd "$FLUTTER_DIR"
./scripts/build_appimage.sh
```

Expected: ends with "AppImage built successfully!" and shows path to `build/appimage/huji-2.3.1-x86_64.AppImage`. Build time ~2-5 minutes (first run, due to ffmpeg download ~80MB).

If errors occur:
- "linuxdeploy not found" → re-run `install_appimage_tools.sh`
- "GLIB error" or similar GTK errors → ensure `linuxdeploy-plugin-gtk` is installed and the env var `LDPLUGIN_GTK` points to it
- Empty output dir from linuxdeploy → check the .desktop file is valid and the executable exists at `AppDir/usr/bin/restcut`

- [ ] **Step 4: Commit**

```bash
cd /home/hhoa/git/hhoa/huji
git add restcut_app/scripts/build_appimage.sh
git commit -m "feat: add build_appimage.sh end-to-end build script"
```

---

## Task 13: Verify the locally-built AppImage launches

**Files:** none

**Why this task:** Build success doesn't guarantee runtime success. The AppImage may have unbundled dependencies that fail at launch.

- [ ] **Step 1: Make AppImage executable and run it**

```bash
cd "$FLUTTER_DIR"
chmod +x build/appimage/huji-*-x86_64.AppImage
./build/appimage/huji-*-x86_64.AppImage &
APP_PID=$!
sleep 5
ps -p $APP_PID > /dev/null && echo "OK: AppImage running" || echo "FAIL"
```

Expected: window opens showing "弧迹 / 桌面版 · Phase 1 占位".

If it fails:
- Run with verbose output:
  ```bash
  ./build/appimage/huji-*-x86_64.AppImage --appimage-extract-and-run 2>&1 | head -50
  ```
- Common errors and fixes:
  - "libgtk-3.so not found" → `linuxdeploy-plugin-gtk` did not run; re-check Task 12 step 1.
  - "libsecret-1.so.0 not found" → install `libsecret-1-dev` on the build host (already in Task 1 list); re-build.
  - "version GLIBC_2.34 not found" → AppImage built on a newer glibc than the runtime host. Build on Ubuntu 22.04 (`glibc 2.35`) for max compatibility.

- [ ] **Step 2: Test ffmpeg is discoverable from inside the AppImage**

```bash
./build/appimage/huji-*-x86_64.AppImage --appimage-extract > /dev/null 2>&1
ls squashfs-root/usr/bin/ffmpeg && echo "OK: ffmpeg bundled"
./squashfs-root/usr/bin/ffmpeg -version | head -1
rm -rf squashfs-root
```

Expected: ffmpeg version banner.

- [ ] **Step 3: No commit (verification only)**

If anything required a code/script change to fix, commit it as `fix: <description>` with a separate commit per logical fix.

---

## Task 14: Write GitHub Actions workflow for x86_64

**Files:**
- Create: `.github/workflows/build_appimage.yml`

**Why this task:** Automated builds on tag push, uploaded to GitHub Releases.

- [ ] **Step 1: Create the workflow**

Create `.github/workflows/build_appimage.yml`:
```yaml
name: Build AppImage

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch: {}

jobs:
  build-x86_64:
    name: Build x86_64
    runs-on: ubuntu-22.04
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install Linux build dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y \
            clang cmake ninja-build pkg-config \
            libgtk-3-dev liblzma-dev libsecret-1-dev \
            libjsoncpp-dev libstdc++-12-dev \
            file fuse libfuse2

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.5'
          channel: 'stable'

      - name: Build AppImage
        working-directory: restcut_app
        run: |
          flutter config --enable-linux-desktop
          ./scripts/build_appimage.sh

      - name: Get version
        id: version
        working-directory: restcut_app
        run: |
          VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
          echo "version=$VERSION" >> "$GITHUB_OUTPUT"

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: huji-${{ steps.version.outputs.version }}-x86_64
          path: restcut_app/build/appimage/huji-*-x86_64.AppImage
          if-no-files-found: error

      - name: Upload to release
        if: startsWith(github.ref, 'refs/tags/v')
        uses: softprops/action-gh-release@v2
        with:
          files: restcut_app/build/appimage/huji-*-x86_64.AppImage
          fail_on_unmatched_files: true
```

- [ ] **Step 2: Validate YAML syntax**

```bash
# Quick local sanity check (uses Python/PyYAML if available)
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/build_appimage.yml'))" && echo OK
```

Expected: "OK".

- [ ] **Step 3: Commit**

```bash
cd /home/hhoa/git/hhoa/huji
git add .github/workflows/build_appimage.yml
git commit -m "ci: add GitHub Actions workflow for AppImage builds (x86_64)"
```

- [ ] **Step 4: Test via workflow_dispatch**

Push the commit and trigger the workflow manually:
```bash
git push origin main
gh workflow run build_appimage.yml
gh run watch
```

Expected: workflow completes successfully, artifact uploaded. Download and test:
```bash
gh run download <run-id> --name huji-2.3.1-x86_64
chmod +x huji-2.3.1-x86_64.AppImage
./huji-2.3.1-x86_64.AppImage
```

If the workflow fails, fix and commit. The workflow run log shows exact failure.

---

## Task 15: Add aarch64 to CI matrix (QEMU)

**Files:**
- Modify: `.github/workflows/build_appimage.yml`

**Why this task:** Per spec section 7.2, support both x86_64 and aarch64. GitHub-hosted Ubuntu runners are x86_64; we use QEMU + aarch64 cross-compile.

- [ ] **Step 1: Update workflow to add aarch64 matrix entry**

Modify `.github/workflows/build_appimage.yml`. Replace the existing single `build-x86_64` job with a matrix-based job:
```yaml
name: Build AppImage

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch: {}

jobs:
  build:
    name: Build ${{ matrix.arch }}
    runs-on: ubuntu-22.04
    strategy:
      fail-fast: false
      matrix:
        include:
          - arch: x86_64
            flutter_target: linux-x64
            qemu_arch: ''
          - arch: aarch64
            flutter_target: linux-arm64
            qemu_arch: arm64
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup QEMU (aarch64 only)
        if: matrix.qemu_arch != ''
        uses: docker/setup-qemu-action@v3
        with:
          platforms: ${{ matrix.qemu_arch }}

      - name: Install Linux build dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y \
            clang cmake ninja-build pkg-config \
            libgtk-3-dev liblzma-dev libsecret-1-dev \
            libjsoncpp-dev libstdc++-12-dev \
            file fuse libfuse2

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.5'
          channel: 'stable'

      - name: Build AppImage (native ${{ matrix.arch }})
        if: matrix.qemu_arch == ''
        working-directory: restcut_app
        env:
          ARCH: ${{ matrix.arch }}
        run: |
          flutter config --enable-linux-desktop
          ./scripts/build_appimage.sh

      - name: Build AppImage (cross ${{ matrix.arch }} via Docker+QEMU)
        if: matrix.qemu_arch != ''
        run: |
          docker run --rm --platform linux/${{ matrix.qemu_arch }} \
            -v "${{ github.workspace }}":/workspace -w /workspace/restcut_app \
            ubuntu:22.04 bash -c '
              apt-get update
              apt-get install -y clang cmake ninja-build pkg-config \
                libgtk-3-dev liblzma-dev libsecret-1-dev \
                libjsoncpp-dev libstdc++-12-dev \
                file fuse libfuse2 curl unzip xz-utils git
              # Install Flutter inside the container
              git clone --depth 1 -b stable https://github.com/flutter/flutter.git /opt/flutter
              export PATH="/opt/flutter/bin:$PATH"
              flutter config --enable-linux-desktop
              flutter pub get
              ARCH=${{ matrix.arch }} ./scripts/build_appimage.sh
            '

      - name: Get version
        id: version
        working-directory: restcut_app
        run: |
          VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
          echo "version=$VERSION" >> "$GITHUB_OUTPUT"

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: huji-${{ steps.version.outputs.version }}-${{ matrix.arch }}
          path: restcut_app/build/appimage/huji-*-${{ matrix.arch }}.AppImage
          if-no-files-found: error

      - name: Upload to release
        if: startsWith(github.ref, 'refs/tags/v')
        uses: softprops/action-gh-release@v2
        with:
          files: restcut_app/build/appimage/huji-*-${{ matrix.arch }}.AppImage
          fail_on_unmatched_files: true
```

- [ ] **Step 2: Validate YAML syntax**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/build_appimage.yml'))" && echo OK
```

- [ ] **Step 3: Commit**

```bash
cd /home/hhoa/git/hhoa/huji
git add .github/workflows/build_appimage.yml
git commit -m "ci: add aarch64 build matrix via QEMU"
```

- [ ] **Step 4: Trigger workflow and verify both architectures build**

```bash
git push origin main
gh workflow run build_appimage.yml
gh run watch
```

Expected: both `build (x86_64)` and `build (aarch64)` jobs complete successfully. The aarch64 job will be slow (~30-60 min due to QEMU emulation); be patient.

If the aarch64 job fails:
- Check the docker run inner script's logs for the specific error
- Common issue: Flutter clone too slow → use a Flutter Docker base image instead. Replace `ubuntu:22.04` with `cirrusci/flutter:stable` and skip the apt-get/git steps for Flutter.

---

## Task 16: Embed AppImage update-information for zsync auto-update

**Files:**
- Modify: `restcut_app/scripts/build_appimage.sh`

**Why this task:** Per spec section 7.3, embed an `update-information` field in the AppImage header so `AppImageUpdate` tools can fetch zsync delta updates from GitHub Releases.

- [ ] **Step 1: Update build_appimage.sh to embed update-information**

In `restcut_app/scripts/build_appimage.sh`, locate the `linuxdeploy` invocation in step 5. Add the `--updateinformation` argument to the call:
```bash
"$TOOLS_DIR/linuxdeploy.AppImage" \
  --appdir "$APPDIR" \
  --plugin gtk \
  --executable "$APPDIR/usr/bin/restcut" \
  --desktop-file "$APPDIR/huji.desktop" \
  --icon-file "$APPDIR/huji.svg" \
  --output appimage \
  --custom-apprun "$APPDIR/AppRun" \
  --updateinformation "gh-releases-zsync|hhoao|huji|latest|huji-*-${ARCH}.AppImage.zsync" \
  2>&1 | tail -40
```

(Replace `hhoao` with the actual GitHub username/org if it differs. Verify with `git remote get-url origin`.)

- [ ] **Step 2: Verify update-information is embedded**

```bash
cd "$FLUTTER_DIR"
./scripts/build_appimage.sh
# Inspect the AppImage header for update-info
strings build/appimage/huji-*-x86_64.AppImage | grep -A 1 "gh-releases-zsync" | head -5
```

Expected: a line like `gh-releases-zsync|hhoao|huji|latest|huji-*-x86_64.AppImage.zsync`.

- [ ] **Step 3: Verify the .zsync file is generated alongside**

```bash
ls build/appimage/*.zsync
```

Expected: `huji-*-x86_64.AppImage.zsync` exists. linuxdeploy auto-generates this when `--updateinformation` is set.

- [ ] **Step 4: Update workflow to also upload the .zsync file**

Edit `.github/workflows/build_appimage.yml` — in both upload steps (artifact and release), include the `.zsync` file:
```yaml
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: huji-${{ steps.version.outputs.version }}-${{ matrix.arch }}
          path: |
            restcut_app/build/appimage/huji-*-${{ matrix.arch }}.AppImage
            restcut_app/build/appimage/huji-*-${{ matrix.arch }}.AppImage.zsync
          if-no-files-found: error

      - name: Upload to release
        if: startsWith(github.ref, 'refs/tags/v')
        uses: softprops/action-gh-release@v2
        with:
          files: |
            restcut_app/build/appimage/huji-*-${{ matrix.arch }}.AppImage
            restcut_app/build/appimage/huji-*-${{ matrix.arch }}.AppImage.zsync
          fail_on_unmatched_files: true
```

- [ ] **Step 5: Commit**

```bash
cd /home/hhoa/git/hhoa/huji
git add restcut_app/scripts/build_appimage.sh .github/workflows/build_appimage.yml
git commit -m "feat: embed AppImageUpdate info for zsync delta updates"
```

---

## Task 17: End-to-end verification with a test tag release

**Files:** none

**Why this task:** Confirm the entire pipeline (tag push → CI builds → artifact uploaded → AppImage launches → ready for users) works.

- [ ] **Step 1: Create a test pre-release tag**

```bash
cd /home/hhoa/git/hhoa/huji
git tag v2.3.1-phase1-test
git push origin v2.3.1-phase1-test
```

- [ ] **Step 2: Watch the CI build**

```bash
gh run watch
```

Expected: both `build (x86_64)` and `build (aarch64)` complete successfully. AppImages uploaded as a draft release.

- [ ] **Step 3: Download and smoke-test the released AppImages**

```bash
mkdir -p /tmp/huji-test && cd /tmp/huji-test
gh release download v2.3.1-phase1-test
ls -la
chmod +x huji-*-x86_64.AppImage
./huji-*-x86_64.AppImage &
sleep 5
echo "If a window with '弧迹 桌面版 · Phase 1 占位' is visible, this Phase succeeded."
```

- [ ] **Step 4: Clean up the test tag**

```bash
cd /home/hhoa/git/hhoa/huji
gh release delete v2.3.1-phase1-test --yes
git tag -d v2.3.1-phase1-test
git push origin :refs/tags/v2.3.1-phase1-test
```

- [ ] **Step 5: No commit needed (testing only).**

Phase 1 is complete. Mark these off in the spec's Phase 1 section. Phase 2 (UI scaffolding) is the next plan to write.
