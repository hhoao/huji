# Linux ncnn Integration: Test Discoverability + Clip-to-Export E2E Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make ncnn integration tests actually run in `flutter test` (local + CI), add one end-to-end test covering ncnn detection → clip segments → ffmpeg export → library registration, and eliminate the predictor-pool cold-start.

**Architecture:** A static `NcnnRuntime.overrideLibraryDirectory()` pins the plugin `.so` directory before first use (priority: injection > `HUJI_NCNN_LIB_DIR` env > bare name). A test bootstrap helper locates the built plugin under `build/linux/x64/{debug,release}/plugins/huji_ncnn/` and fails fast with actionable guidance when absent. `NcnnPredictorPool.create` becomes an async factory that preloads all predictors concurrently. CI builds linux debug then runs `flutter test --tags integration` (CPU fallback path on GPU-less runners).

**Tech Stack:** Flutter (Dart 3), dart:ffi, ncnn + Vulkan, ffmpeg/ffprobe (CLI), GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-08-linux-ncnn-integration-design.md`

## Global Constraints

- Windows (helper process), Android, macOS/iOS library-resolution branches must not change behavior
- No experimental Flutter features (no native-assets migration)
- Tests must fail loudly (actionable error), never silently skip, when the plugin build is missing
- Integration tests keep the `@Tags(['integration'])` library annotation
- All test files live under `huji-app/test/`; commands run from `huji-app/` unless noted
- Prerequisite for local integration tests: `flutter build linux --debug` has produced `build/linux/x64/debug/plugins/huji_ncnn/libhuji_ncnn_plugin.so` (already true on this machine)

---

### Task 1: `NcnnRuntime.overrideLibraryDirectory`

**Files:**
- Modify: `packages/huji_ncnn/lib/huji_ncnn.dart` (class `NcnnRuntime`, lines ~48-91, and `_pluginPath` at ~136-142)
- Test: `test/integration/ncnn_plugin_test.dart` (only touched indirectly by Task 2; this task's unit-level verification is the new test file below)
- Test: Create `test/ncnn_runtime_override_test.dart` — NOT tagged integration (runs in every `flutter test` invocation; on CI without a build it must skip gracefully — see step 1)

**Interfaces:**
- Produces: `static void NcnnRuntime.overrideLibraryDirectory(String dir)` — same-dir repeat is a no-op; different dir after the library is open throws `StateError`; setting before first use pins the Linux/Windows resolution directory.
- Consumes: existing `_pluginPath(String name)` and `_openLibrary()` internals.

- [ ] **Step 1: Write the failing test**

The contract testable WITHOUT the native library is the state machine on the static pin: pinning different dirs before first use re-pins silently; same-dir repeats are no-ops. (The "different dir after open throws" branch requires an opened library — covered by Task 2's integration run order.) Create `test/ncnn_runtime_override_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_ncnn/huji_ncnn.dart';

/// overrideLibraryDirectory state machine checks that don't need the
/// native plugin. The "already open" rejection is exercised in
/// test/integration/ncnn_plugin_test.dart after bootstrap + library use.
void main() {
  test('pinning a different directory before first use re-pins silently',
      () {
    NcnnRuntime.overrideLibraryDirectory('/tmp/a');
    NcnnRuntime.overrideLibraryDirectory('/tmp/b');
  });

  test('pinning the same directory twice is a no-op', () {
    NcnnRuntime.overrideLibraryDirectory('/tmp/b');
    NcnnRuntime.overrideLibraryDirectory('/tmp/b');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ncnn_runtime_override_test.dart`
Expected: FAIL — `overrideLibraryDirectory` is not defined (compile error: method doesn't exist).

- [ ] **Step 3: Implement**

In `packages/huji_ncnn/lib/huji_ncnn.dart`, inside `class NcnnRuntime` add a static field and method (place near `_instance`):

```dart
static String? _overriddenLibDir;

/// Test/CI bootstrap: pin the directory holding the plugin library
/// (huji_ncnn_plugin.dll / libhuji_ncnn_plugin.so) before any
/// [NcnnRuntime] use.
///
/// Resolution priority on Windows/Linux: this override >
/// HUJI_NCNN_LIB_DIR env > bare name (app bundle rpath).
///
/// Repeated calls with the same dir are no-ops. A different dir after
/// the native library has been opened throws [StateError] (the process
/// already holds the old library). Pinning a different directory before
/// first use simply replaces the pin.
static void overrideLibraryDirectory(String dir) {
  final current = _overriddenLibDir;
  if (current == dir) return;
  if (_instance != null) {
    throw StateError(
      'ncnn native library already opened from "$current"; '
      'cannot override to "$dir"',
    );
  }
  _overriddenLibDir = dir;
}
```

Then change `_pluginPath` (line ~136) to consult the override first:

```dart
/// Override pin > HUJI_NCNN_LIB_DIR env > bare name.
static String _pluginPath(String name) {
  final dir = _overriddenLibDir ?? Platform.environment['HUJI_NCNN_LIB_DIR'];
  if (dir == null || dir.isEmpty) return name;
  return '$dir${Platform.pathSeparator}$name';
}
```

And in `_openLibrary`'s Windows `HUJI_NCNN_LIB_DIR` branch (line ~62): replace `Platform.environment['HUJI_NCNN_LIB_DIR']` with a resolution through the same override:

```dart
final dir = _overriddenLibDir ?? Platform.environment['HUJI_NCNN_LIB_DIR'];
```

(The rest of that branch — `_applyIntelIcdWorkaround()`, pre-loading `ncnn.dll`, opening `huji_ncnn_plugin.dll` — stays byte-identical; only the env read line changes.)

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ncnn_runtime_override_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add packages/huji_ncnn/lib/huji_ncnn.dart test/ncnn_runtime_override_test.dart
git commit -m "feat(ncnn): NcnnRuntime.overrideLibraryDirectory for test/CI bootstrap"
```

---

### Task 2: Test bootstrap helper

**Files:**
- Create: `test/helpers/ncnn_test_bootstrap.dart`
- Modify: `test/integration/ncnn_plugin_test.dart` (add bootstrap to `setUpAll`)
- Modify: `test/integration/ncnn_real_frame_test.dart` (add bootstrap to `main`)
- Modify: `test/integration/clip_flow_integration_test.dart` (replace `_ncnnPluginAvailable` path-only probe with bootstrap + probe)

**Interfaces:**
- Consumes: `NcnnRuntime.overrideLibraryDirectory(String dir)` from Task 1; `findAppRoot()` from `test/helpers/autoclip_fixtures.dart`.
- Produces:

```dart
/// Locates the built huji_ncnn plugin and pins its directory in
/// NcnnRuntime. Call from setUpAll of every ncnn integration test.
///
/// Throws StateError with build instructions when no build artifact
/// exists — tests must fail loudly, not skip.
Future<void> bootstrapNcnnLibrary();

/// True when the native library opened successfully (probe).
/// Exposed for tests that want to differentiate "not built" from
/// "library broken".
bool get ncnnLibraryBootstrapped;
```

- [ ] **Step 1: Write the failing test (new integration run)**

The helper is test infra; its test is the existing `ncnn_plugin_test` suite going from FAIL to PASS. First, wire it in and observe the current failure (which the bootstrap will fix).

Modify `test/integration/ncnn_plugin_test.dart` — add import and bootstrap as the FIRST statement of `setUpAll` (before `NcnnModelAssetResolver.resolve`):

```dart
import '../helpers/ncnn_test_bootstrap.dart';

// inside group setUpAll:
setUpAll(() async {
  await bootstrapNcnnLibrary();
  spec = await NcnnModelAssetResolver.resolve(
    sportType: 'ping_pong',
    matchType: 'profession',
  );
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/integration/ncnn_plugin_test.dart`
Expected: FAIL — `../helpers/ncnn_test_bootstrap.dart` does not exist (compile error).

- [ ] **Step 3: Implement the bootstrap**

Create `test/helpers/ncnn_test_bootstrap.dart`:

```dart
import 'dart:io';

import 'package:huji_ncnn/huji_ncnn.dart';
import 'package:path/path.dart' as p;

import 'autoclip_fixtures.dart';

/// Library file name per platform (Linux + Windows are the platforms
/// with a dynamically resolved plugin; macOS/iOS link statically).
const _pluginFileNames = <String>[
  'libhuji_ncnn_plugin.so',
  'huji_ncnn_plugin.dll',
];

bool _bootstrapped = false;

/// True after [bootstrapNcnnLibrary] succeeded.
bool get ncnnLibraryBootstrapped => _bootstrapped;

/// Locates the built huji_ncnn plugin under
/// build/linux/x64/{debug,release}/plugins/huji_ncnn/ and pins the
/// directory via NcnnRuntime.overrideLibraryDirectory.
///
/// Fail-fast: no artifact → StateError with the build command. Never
/// silently skip — a skipped ncnn test is a silently broken pipeline.
Future<void> bootstrapNcnnLibrary() async {
  if (_bootstrapped) return;

  final appRoot = findAppRoot();
  final candidates = <String>[
    p.join(appRoot.path, 'build', 'linux', 'x64', 'debug',
        'plugins', 'huji_ncnn'),
    p.join(appRoot.path, 'build', 'linux', 'x64', 'release',
        'plugins', 'huji_ncnn'),
    p.join(appRoot.path, 'build', 'windows', 'x64', 'Debug',
        'plugins', 'huji_ncnn'),
  ];

  for (final dir in candidates) {
    final plugin = _findPluginIn(dir);
    if (plugin != null) {
      NcnnRuntime.overrideLibraryDirectory(dir);
      _bootstrapped = true;
      return;
    }
  }

  throw StateError(
    'huji_ncnn plugin not found under any build directory of '
    '${appRoot.path}.\n'
    'Build first:  cd huji-app && flutter build linux --debug\n'
    '(or flutter build windows --debug on Windows)',
  );
}

String? _findPluginIn(String dir) {
  for (final name in _pluginFileNames) {
    final file = File(p.join(dir, name));
    if (file.existsSync()) return file.path;
  }
  return null;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/integration/ncnn_plugin_test.dart`
Expected: PASS (6 tests, ~seconds — the debug build artifact exists on this machine at `build/linux/x64/debug/plugins/huji_ncnn/libhuji_ncnn_plugin.so`; its RUNPATH resolves `libncnn.so.1`).

- [ ] **Step 5: Wire the remaining two integration tests**

`test/integration/ncnn_real_frame_test.dart` — add at the top of `main()`:

```dart
import '../helpers/ncnn_test_bootstrap.dart';
// ...
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await bootstrapNcnnLibrary();
  });
  // ... existing test unchanged
}
```

(If the file already has a `setUpAll`, put the bootstrap call first inside it.)

`test/integration/clip_flow_integration_test.dart` — inside the group's `setUp`, bootstrap before the availability probe (so the probe actually tests the library instead of always failing on load):

```dart
import '../helpers/ncnn_test_bootstrap.dart';
// in group setUp:
setUp(() async {
  await ClipFlowTestHelper.setUp();
  await bootstrapNcnnLibrary();
  final demo = demoVideos.first;
  ncnnAvailable = await _ncnnPluginAvailable(
    demo.sportTypeKey,
    demo.matchType,
  );
});
```

- [ ] **Step 6: Run all three**

Run: `flutter test test/integration/ncnn_plugin_test.dart test/integration/ncnn_real_frame_test.dart test/integration/clip_flow_integration_test.dart`
Expected: ncnn_plugin + ncnn_real_frame PASS. clip_flow may take up to 15 min (real inference over test.mp4) — on this machine expect PASS in ~1-3 min with GPU. All previously-skipped tests now actually run.

- [ ] **Step 7: Commit**

```bash
git add test/helpers/ncnn_test_bootstrap.dart test/integration/ncnn_plugin_test.dart test/integration/ncnn_real_frame_test.dart test/integration/clip_flow_integration_test.dart
git commit -m "test(ncnn): bootstrap helper pins built plugin dir in test VMs"
```

---

### Task 3: Predictor pool eager warm-up

**Files:**
- Modify: `lib/services/inference/ncnn_predictor_pool.dart` (factory → async, preload)
- Modify: `lib/core/batch/batch_action_segment_detector.dart:236-241` (`pool = NcnnPredictorPool.create(...)` → `await`)
- Test: Create `test/services/inference/ncnn_predictor_pool_test.dart` (integration-tagged — needs the native library)

**Interfaces:**
- Consumes: `bootstrapNcnnLibrary()` (Task 2), `NcnnModelAssetResolver.resolve` (existing).
- Produces: `static Future<NcnnPredictorPool> NcnnPredictorPool.create({required String paramFilePath, required String binFilePath, required List<String> fallbackClassNames, required int size})` — all predictors fully loaded before the future completes. `withPredictor` / `dispose` signatures unchanged.

- [ ] **Step 1: Write the failing test**

Create `test/services/inference/ncnn_predictor_pool_test.dart`:

```dart
@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/services/inference/ncnn_model_asset_resolver.dart';
import 'package:huji_app/services/inference/ncnn_model_predictor.dart';
import 'package:huji_app/services/inference/ncnn_predictor_pool.dart';

import '../../helpers/ncnn_test_bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NcnnPredictorPool warm-up', () {
    late var spec;

    setUpAll(() async {
      await bootstrapNcnnLibrary();
      spec = await NcnnModelAssetResolver.resolve(
        sportType: 'ping_pong',
        matchType: 'profession',
      );
    });

    test('create() returns with every predictor loaded', () async {
      final pool = await NcnnPredictorPool.create(
        paramFilePath: spec.paramFilePath,
        binFilePath: spec.binFilePath,
        fallbackClassNames: spec.classNames,
        size: 2,
      );
      addTearDown(pool.dispose);

      // Every borrowed predictor must be usable without any lazy load
      // happening: predict immediately (a garbage frame still exercises
      // the full FFI path).
      final frame = List<int>.filled(640 * 640 * 3, 114);
      final results = await Future.wait([
        pool.withPredictor((p) => p.predictRgb24ForResult(
              frame,
              640,
              640,
              {},
            )),
        pool.withPredictor((p) => p.predictRgb24ForResult(
              frame,
              640,
              640,
              {},
            )),
      ]);
      expect(results.length, 2);
      // empty classMappings: _mapClassName throws for the top class —
      // assert on the RESULT object rather than ActionType: the result
      // carries classification.topClass which is one of the 4 classes.
      expect(spec.classNames, contains(results.first.classification.topClass));
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
```

Note on the empty-map assert: `predictRgb24ForResult` returns `ClassifierResult` whose `classification.topClass` comes from `engine.classNames` (fallback list), independent of `classMappings` — with `{}` no mapping is needed to build the result. This is the reason for asserting on `topClass` membership instead of an `ActionType`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/inference/ncnn_predictor_pool_test.dart`
Expected: FAIL — `NcnnPredictorPool.create` is currently a synchronous factory; `await` on its result still compiles (await on non-Future is allowed) but the "loaded before return" contract fails: with current lazy loading, `withPredictor` + predict still works so the assert may pass. The failure to observe: add a temporary assertion OR rely on the compile-level check. Concretely, the observable failure at this step: the test file references `NcnnPredictorPool.create(...)` with `await` — compiles fine — so the real check is behavioral: the current implementation cannot guarantee "loaded at create() return". To make TDD meaningful, assert through a new public getter that the old code lacks:

Add to the test (before `Future.wait`):

```dart
      expect(pool.allLoaded, isTrue,
          reason: 'create() must return with every predictor loaded');
```

Expected: FAIL — `allLoaded` getter does not exist (compile error).

- [ ] **Step 3: Implement**

In `lib/services/inference/ncnn_predictor_pool.dart`:

Replace the factory with an async one that preloads via a new public warm-up hook on the predictor, and add `allLoaded`:

```dart
/// True when every predictor's model is loaded and ready.
bool get allLoaded => _all.every((p) => p.isLoaded);

/// Create [size] predictors that all load the same on-disk model.
///
/// All models load CONCURRENTLY; the returned future completes only
/// after every predictor is ready — borrowers never hit a lazy load.
static Future<NcnnPredictorPool> create({
  required String paramFilePath,
  required String binFilePath,
  required List<String> fallbackClassNames,
  required int size,
}) async {
  if (size < 1) {
    throw ArgumentError.value(size, 'size', 'must be >= 1');
  }
  final predictors = List<NcnnModelPredictor>.generate(
    size,
    (_) => NcnnModelPredictor(
      paramFilePath: paramFilePath,
      binFilePath: binFilePath,
      fallbackClassNames: fallbackClassNames,
    ),
  );
  // Parallel load — each predictor owns its own engine/net.
  await Future.wait(predictors.map((p) => p.warmUp()));
  return NcnnPredictorPool._(predictors);
}
```

In `lib/services/inference/ncnn_model_predictor.dart` add (near `_ensureLoaded`):

```dart
/// True after the model finished loading (eager or lazy).
bool get isLoaded => _engine != null;

/// Eagerly load the model (pool warm-up). Safe to call repeatedly.
Future<void> warmUp() async {
  await _ensureLoaded();
}
```

In `lib/core/batch/batch_action_segment_detector.dart` (~line 236) change:

```dart
      pool = NcnnPredictorPool.create(
        paramFilePath: seedPredictor.paramFilePath,
        binFilePath: seedPredictor.binFilePath,
        fallbackClassNames: seedPredictor.fallbackClassNames,
        size: workerCount,
      );
```

to:

```dart
      pool = await NcnnPredictorPool.create(
        paramFilePath: seedPredictor.paramFilePath,
        binFilePath: seedPredictor.binFilePath,
        fallbackClassNames: seedPredictor.fallbackClassNames,
        size: workerCount,
      );
```

(`pool` is a local `NcnnPredictorPool?`; `await` before assignment is fine inside the async method. The `finally { await pool?.dispose(); }` remains valid.)

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/inference/ncnn_predictor_pool_test.dart`
Expected: PASS.

- [ ] **Step 5: Run the full non-integration suite for regressions**

Run: `flutter test --exclude-tags integration`
Expected: PASS (pool change compiles; no unit test referenced the old sync factory).

Also: `flutter analyze --no-fatal-infos --no-fatal-warnings`
Expected: no new issues.

- [ ] **Step 6: Commit**

```bash
git add lib/services/inference/ncnn_predictor_pool.dart lib/services/inference/ncnn_model_predictor.dart lib/core/batch/batch_action_segment_detector.dart test/services/inference/ncnn_predictor_pool_test.dart
git commit -m "perf(ncnn): predictor pool preloads models concurrently"
```

---

### Task 4: Clip-to-export end-to-end integration test

**Files:**
- Create: `test/integration/ncnn_clip_to_export_integration_test.dart`

**Interfaces:**
- Consumes: `bootstrapNcnnLibrary()` (Task 2); `ClipFlowTestHelper.setUp()`, `ClipFlowTestHelper.startLocalClipFromDemo(demo)`, `ClipFlowTestHelper.waitForTerminalStatus(taskId)` (existing, `test/helpers/clip_flow_test_helper.dart`); `TaskStorage()`, `LocalVideoStorage()`, `VideoExportTask` (existing); `VideoUtils.getVideoInfo(path)` for the duration assertion.
- Produces: nothing (leaf test).

- [ ] **Step 1: Write the failing test**

Create `test/integration/ncnn_clip_to_export_integration_test.dart`:

```dart
@Tags(['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/constants/demo_videos.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/services/storage_service.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/utils/video_utils.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../helpers/clip_flow_test_helper.dart';
import '../helpers/ncnn_test_bootstrap.dart';

Future<bool> _ffmpegAvailable() async {
  for (final bin in ['ffmpeg', 'ffprobe']) {
    try {
      final result = await Process.run(bin, ['-version']);
      if (result.exitCode != 0) return false;
    } catch (_) {
      return false;
    }
  }
  return true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ncnn detection → clip segments → ffmpeg export → library entry',
      () async {
    if (!PlatformCapability.isDesktop) {
      return;
    }
    await bootstrapNcnnLibrary();
    if (!await _ffmpegAvailable()) {
      // Same convention as video_export_library_registration_test.
      failTestOrSkip('ffmpeg/ffprobe not on PATH');
      return;
    }

    await ClipFlowTestHelper.setUp();

    // --- Phase 1: ncnn local detection over the demo video ---
    final demo = demoVideos.first;
    final taskId = await ClipFlowTestHelper.startLocalClipFromDemo(demo);
    final detected = await ClipFlowTestHelper.waitForTerminalStatus(taskId);
    expect(detected.status, TaskStatusEnum.completed,
        reason: 'detection task failed: ${detected.extraInfo}');

    final libraryRecords = await LocalVideoStorage().load();
    final editing = libraryRecords.whereType<EdittingVideoRecord>().toList();
    expect(editing, isNotEmpty, reason: 'detection must register a record');
    final segments =
        editing.last.allMatchSegments.cast<SegmentInfo>().toList();
    expect(segments, isNotEmpty,
        reason: 'ncnn detection must produce clip segments');

    // --- Phase 2: export exactly what ncnn detected ---
    final tempDir =
        await Directory.systemTemp.createTemp('huji_e2e_export_');
    addTearDown(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });
    final saveDir = Directory(p.join(tempDir.path, 'save'));
    await saveDir.create(recursive: true);
    final fileName = 'e2e_${const Uuid().v4()}';

    final exportTask = VideoExportTask(
      id: const Uuid().v4(),
      name: '$fileName.mp4',
      videoPath: editing.last.filePath,
      savePath: saveDir.path,
      fileName: fileName,
      quality: 'high',
      segments: segments,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await TaskStorage().addAndAsyncProcessTask(exportTask);

    final exported = await ClipFlowTestHelper.waitForTerminalStatus(
      exportTask.id,
      timeout: const Duration(minutes: 10),
    );
    expect(exported.status, TaskStatusEnum.completed,
        reason: 'export task failed: ${exported.extraInfo}');

    // --- Phase 3: verify the artifact ---
    final outputPath = p.join(saveDir.path, '$fileName.mp4');
    expect(File(outputPath).existsSync(), isTrue,
        reason: 'exported file must exist');

    final expectedSeconds = segments.fold<double>(
        0, (sum, s) => sum + (s.endSeconds - s.startSeconds));
    expect(expectedSeconds, greaterThan(0));
    final info = await VideoUtils.getVideoInfo(outputPath);
    // Per-segment 1s tolerance: ffmpeg concat/intro rounding.
    expect(
      (info.duration - expectedSeconds).abs(),
      lessThan(segments.length * 1.0 + 0.5),
      reason: 'exported duration ${info.duration}s vs segments '
          '$expectedSeconds (${segments.length} segments)',
    );

    final saved = await LocalVideoStorage().loadSavedVideos();
    final registered =
        saved.where((r) => r.filePath == outputPath).toList();
    expect(registered, hasLength(1),
        reason: 'export must be registered in the video library');
    expect(registered.single.videoProcessType, VideoProcessType.exported);
  }, timeout: const Timeout(Duration(minutes: 20)));
}

// failTestOrSkip: prefer loud failure — spec mandates no silent skip for
// ncnn problems, but a missing ffmpeg binary is an environment gap, so
// skip mirrors the existing export test convention.
void failTestOrSkip(String reason) {
  // Integrated as markTestSkipped below — see note.
  throw StateError(reason);
}
```

Corrections to apply when writing the file (do not type the placeholder helper into the committed test): drop `failTestOrSkip` entirely and use `markTestSkipped('ffmpeg/ffprobe not on PATH')` inline, exactly like `video_export_library_registration_test.dart` does. Also remove the unused `import 'package:huji_app/services/storage_service.dart';` — the import list ends at `package:uuid/uuid.dart` plus the two helper imports. Final shape of the guard:

```dart
    if (!await _ffmpegAvailable()) {
      markTestSkipped('ffmpeg/ffprobe not on PATH');
      return;
    }
```

and the import list ends at `package:uuid/uuid.dart` plus the two helpers (no storage_service import).

- [ ] **Step 2: Run test to verify it fails-or-incompletes**

Run: `flutter test test/integration/ncnn_clip_to_export_integration_test.dart`
Expected behavior at this point: the test RUNS (ncnn bootstrapped, detection proceeds) — this is the first time the whole chain executes in a test VM. Any failure is a real integration defect discovered by the new test; capture the output. If it fails at detection (status != completed), the extraInfo carries the root cause — surface it, fix the pipeline issue (not the test), and re-run. Do NOT weaken assertions to make it pass.

- [ ] **Step 3: Fix pipeline defects surfaced (if any)**

Only if step 2 failed. Likely candidates (from code reading, not certainty):
- `VideoExportTask.segments` serialization: `SegmentInfo` is freezed+json_serializable — already handled by `segmentListToJsonStr` in `Task` (`lib/models/task.dart:638`).
- `LocalVideoStorage().load()` returning records from prior tests in the same VM: `ClipFlowTestHelper.setUp()` calls `resetDatabase()` in its `setUp` path (verify in helper; if not, filter records by `taskId`/file path instead of `editing.last`).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/integration/ncnn_clip_to_export_integration_test.dart`
Expected: PASS, ~1-4 min on this machine (GPU inference; CPU-only hosts proportionally slower — CI budget).

- [ ] **Step 5: Commit**

```bash
git add test/integration/ncnn_clip_to_export_integration_test.dart
git commit -m "test(ncnn): end-to-end detection → clip → export → library"
```

---

### Task 5: CI wiring

**Files:**
- Modify: `.github/workflows/ci-verify.yml` (repo root; steps appended after "Unit and widget tests", guarded to Linux matrix only)

**Interfaces:**
- Consumes: all previous tasks (bootstrap + integration suite).
- Produces: CI coverage of the integration suite on the CPU-fallback path.

- [ ] **Step 1: Add CI steps**

In `.github/workflows/ci-verify.yml`, after the existing

```yaml
      - name: Unit and widget tests
        run: flutter test --exclude-tags integration
```

append (indentation matches the surrounding steps — they are at 6 spaces under `steps:`; `working-directory` is already the job default `huji-app`, so no per-step override needed):

```yaml
      - name: Install ffmpeg (Linux integration tests)
        if: matrix.platform == 'linux'
        run: sudo apt-get install -y ffmpeg

      - name: Build linux debug (ncnn plugin for integration tests)
        if: matrix.platform == 'linux'
        run: flutter build linux --debug

      - name: Integration tests (CPU fallback — no GPU on runners)
        if: matrix.platform == 'linux'
        run: flutter test --tags integration
```

Note: the Linux matrix entry already installs build deps (`clang cmake ninja-build ... libmpv-dev mpv`) at `install_linux_deps`, and `submodules: recursive` checkout is already present. The ncnn CMake step downloads the official prebuilt archive at configure time — network on GH runners is fine.

- [ ] **Step 2: Local validation of the exact CI commands**

```bash
cd /home/hhoa/git/hhoa/huji/huji-app
flutter build linux --debug   # already built; should be a fast no-op/incremental
flutter test --tags integration
```

Expected: all integration tests PASS locally (GPU path here — CI exercises CPU fallback; both are the supported matrix).

- [ ] **Step 3: Commit**

```bash
cd /home/hhoa/git/hhoa/huji
git add .github/workflows/ci-verify.yml
git commit -m "ci: run ncnn integration tests on Linux (CPU fallback path)"
```

---

### Task 6: Final verification sweep

**Files:** none (verification only)

- [ ] **Step 1: Full local suite**

```bash
cd huji-app
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test --exclude-tags integration
flutter test --tags integration
```

Expected: analyze clean; both test invocations fully PASS, nothing skipped on this machine (ffmpeg + GPU + debug build all present).

- [ ] **Step 2: Real-app smoke (manual, per CLAUDE.md)**

```bash
cd huji-app && flutter run -d linux
```

Drive one clip flow in the running app (the earlier session proved this path; confirm the warm-up didn't regress startup). Exit cleanly (window close → exit 0 — the ncnn atexit contract from `ncnn_plugin_test.dart:62`).

- [ ] **Step 3: Report**

Summarize: tasks completed, test counts before/after (6 failing → 0), pool warm-up effect (first-segment latency), CI delta. Surface any discovered-but-unfixed pipeline defects honestly.
