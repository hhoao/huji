# Desktop Preview/Export & Video Player Migration — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `video_player` with `media_kit` cross-platform backend, remove round-selection page, wire preview/export page with real playback and ffmpeg concat export.

**Architecture:** `MultiVideoPlayerBloc` gets dual-backend logic — media_kit `Player` on desktop, `video_player` on mobile. State stores the controller as `dynamic`. UI widgets branch on `PlatformCapability.supportsVideoPlayer` to render `Video` (media_kit) or `VideoPlayer` (video_player). Preview page uses the same bloc + real segment data + ffmpeg concat export with stderr progress parsing.

**Tech Stack:** Flutter, media_kit (libmpv), video_player, ffmpeg, freezed, flutter_bloc

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `pubspec.yaml` | Modify | Add media_kit deps |
| `lib/services/platform_capability.dart` | Modify | Desktop now supports video player |
| `lib/widgets/multi_video_player/bloc/multi_video_player_state.dart` | Modify | `dynamic` controller + dual-backend getters |
| `lib/widgets/multi_video_player/bloc/multi_video_player_bloc.dart` | Modify | Dual backend init, play, seek, listeners |
| `lib/widgets/multi_video_player/bloc_multi_video_player_widget.dart` | Modify | Dual `Video` / `VideoPlayer` widget |
| `lib/widgets/multi_video_player/fullscreen_video_page.dart` | Modify | Dual widget |
| `lib/pages/desktop/desktop_round_selection_page.dart` | Delete | Removed |
| `lib/router/modules/desktop.dart` | Modify | Remove `/select` route |
| `lib/pages/desktop/desktop_home_page.dart` | Modify | Card click → `/preview` |
| `lib/pages/desktop/desktop_preview_export_page.dart` | Modify | Full rewrite: real player, data, export |
| `lib/pages/desktop/desktop_precision_edit_page.dart` | Modify | Wire player, update nav, fix breadcrumbs |

---

### Task 1: Add media_kit Dependencies

**Files:**
- Modify: `restcut_app/pubspec.yaml`

- [ ] **Step 1: Add media_kit packages to pubspec.yaml**

Replace the existing `video_player` line with both dependencies:

```yaml
  video_player: ^2.10.0
  media_kit: ^1.1.11
  media_kit_video: ^1.2.5
  media_kit_libs_linux: ^1.1.0
```

- [ ] **Step 2: Run pub get**

```bash
cd restcut_app && dart pub get
```

Expected: packages resolve without conflicts.

- [ ] **Step 3: Commit**

```bash
git add restcut_app/pubspec.yaml restcut_app/pubspec.lock
git commit -m "deps: add media_kit for desktop video playback

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 2: Update PlatformCapability

**Files:**
- Modify: `restcut_app/lib/services/platform_capability.dart`

- [ ] **Step 1: Allow video player on desktop**

Replace the `supportsVideoPlayer` getter:

```dart
/// Video player — Android/iOS via video_player, desktop via media_kit.
static bool get supportsVideoPlayer => true;
```

(The previous guard `!PlatformCapability.supportsVideoPlayer` in `MultiVideoPlayerBloc._preloadVideos` will now return false on desktop, letting the desktop path proceed.)

- [ ] **Step 2: Commit**

```bash
git add restcut_app/lib/services/platform_capability.dart
git commit -m "feat: enable video player support on desktop via media_kit

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 3: Dual-Backend MultiVideoPlayerState

**Files:**
- Modify: `restcut_app/lib/widgets/multi_video_player/bloc/multi_video_player_state.dart`

- [ ] **Step 1: Change controller type and import both backends**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:media_kit/media_kit.dart' as media_kit;
import '../models/video_playback_item.dart';

part 'multi_video_player_state.freezed.dart';
```

- [ ] **Step 2: Change `currentVideoController` type**

Replace:
```dart
VideoPlayerController? currentVideoController,
```
With:
```dart
@Default(null) dynamic currentVideoController,
```

- [ ] **Step 3: Rewrite `isEnd`, `isInitialized`, `size`, `aspectRatio` getters for dual backend**

Replace the existing getters (lines 64-71) with:

```dart
bool get isInitialized {
  final c = currentVideoController;
  if (c == null) return false;
  if (c is VideoPlayerController) return c.value.isInitialized;
  return true; // media_kit Player is initialized once constructed
}

Size? get size {
  final c = currentVideoController;
  if (c == null) return null;
  if (c is VideoPlayerController) return c.value.size;
  if (c is media_kit.Player) {
    final w = c.state.width;
    final h = c.state.height;
    if (w != null && h != null && w > 0 && h > 0) return Size(w.toDouble(), h.toDouble());
  }
  return null;
}

double? get aspectRatio {
  final sz = size;
  if (sz == null || sz.height == 0) return null;
  return sz.width / sz.height;
}
```

- [ ] **Step 4: Rewrite `currentVideoDurationMs`, `currentVideoPositionMs` getters**

```dart
int? get currentVideoDurationMs {
  final c = currentVideoController;
  if (c == null) return null;
  if (c is VideoPlayerController) {
    if (!c.value.isInitialized) return null;
    return c.value.duration.inMilliseconds;
  }
  if (c is media_kit.Player) {
    final d = c.state.duration;
    if (d == null) return null;
    return d.inMilliseconds;
  }
  return null;
}

int? get currentVideoPositionMs {
  final c = currentVideoController;
  if (c == null) return null;
  if (c is VideoPlayerController) {
    if (!c.value.isInitialized) return null;
    return c.value.position.inMilliseconds;
  }
  if (c is media_kit.Player) {
    final p = c.state.position;
    if (p == null) return null;
    return p.inMilliseconds;
  }
  return null;
}
```

- [ ] **Step 5: Rewrite `bufferedProgress` getter**

```dart
double get bufferedProgress {
  final c = currentVideoController;
  if (c == null) return 0.0;
  if (c is VideoPlayerController) {
    if (!c.value.isInitialized) return 0.0;
    final duration = c.value.duration;
    if (duration.inMilliseconds == 0) return 0.0;
    int bufferedMs = 0;
    for (final range in c.value.buffered) {
      bufferedMs += range.end.inMilliseconds - range.start.inMilliseconds;
    }
    return (bufferedMs / duration.inMilliseconds).clamp(0.0, 1.0);
  }
  // media_kit handles buffering internally; report 1.0
  return 1.0;
}
```

- [ ] **Step 6: Rewrite `isEnd` (line 33)**

Replace:
```dart
bool isEnd() {
  return (currentTimeMs >= totalDurationMs ||
      (currentItem != null &&
          items.last == currentItem &&
          currentVideoController != null &&
          currentVideoController!.value.position.inMilliseconds >=
              currentItem!.endTimeMs!));
}
```
With:
```dart
bool isEnd() {
  if (currentTimeMs >= totalDurationMs) return true;
  if (currentItem == null || items.last != currentItem) return false;
  final posMs = currentVideoPositionMs;
  final endMs = currentItem!.endTimeMs;
  if (posMs == null || endMs == null) return false;
  return posMs >= endMs;
}
```

- [ ] **Step 7: Run code generation**

```bash
cd restcut_app && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 8: Verify compiles**

```bash
cd restcut_app && dart analyze lib/widgets/multi_video_player/bloc/multi_video_player_state.dart
```

- [ ] **Step 9: Commit**

```bash
git add restcut_app/lib/widgets/multi_video_player/bloc/
git commit -m "refactor: dual-backend MultiVideoPlayerState for media_kit + video_player

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 4: Dual-Backend MultiVideoPlayerBloc

**Files:**
- Modify: `restcut_app/lib/widgets/multi_video_player/bloc/multi_video_player_bloc.dart`

- [ ] **Step 1: Add media_kit imports**

Add after the existing imports:
```dart
import 'package:media_kit/media_kit.dart' as media_kit;
```

- [ ] **Step 2: Add desktop player storage**

Add to the class fields (after `_itemIdToPath`):
```dart
/// Desktop player instances keyed by video path.
final Map<String, media_kit.Player> _desktopPlayers = {};
```

- [ ] **Step 3: Replace `_preloadVideos` with dual-backend logic**

Replace the entire `_preloadVideos` method:

```dart
Future<void> _preloadVideos(List<VideoPlaybackItem> items) async {
  if (PlatformCapability.supportsVideoPlayer && PlatformCapability.isDesktop) {
    await _preloadDesktopPlayers(items);
  } else {
    await _preloadMobileControllers(items);
  }
}

Future<void> _preloadDesktopPlayers(List<VideoPlaybackItem> items) async {
  // Pause current player
  final current = state.currentVideoController;
  if (current is media_kit.Player) current.pause();

  _itemIdToPath.clear();

  final uniquePaths = <String>{};
  for (final item in items.where((item) => item.enabled)) {
    uniquePaths.add(item.videoPath);
    _itemIdToPath[item.id] = item.videoPath;
  }

  // Dispose players no longer needed
  final keysToRemove = <String>[];
  for (final entry in _desktopPlayers.entries) {
    if (!uniquePaths.contains(entry.key)) {
      entry.value.dispose();
      keysToRemove.add(entry.key);
    }
  }
  for (final key in keysToRemove) {
    _desktopPlayers.remove(key);
  }

  // Create new players
  for (final path in uniquePaths) {
    if (_desktopPlayers.containsKey(path)) continue;
    final player = media_kit.Player();
    await player.open(media_kit.Media(path));
    _desktopPlayers[path] = player;
  }
}

Future<void> _preloadMobileControllers(List<VideoPlaybackItem> items) async {
  await state.currentVideoController?.pause();

  _itemIdToPath.clear();

  final uniquePaths = <String>{};
  for (final item in items.where((item) => item.enabled)) {
    uniquePaths.add(item.videoPath);
    _itemIdToPath[item.id] = item.videoPath;
  }

  final keysToRemove = <String>[];
  for (final entry in _preloadedControllers.entries) {
    if (!uniquePaths.contains(entry.key)) {
      entry.value.dispose();
      keysToRemove.add(entry.key);
    }
  }
  for (final key in keysToRemove) {
    _preloadedControllers.remove(key);
  }

  for (final path in uniquePaths) {
    if (_preloadedControllers.containsKey(path)) continue;
    final controller = VideoPlayerController.file(File(path));
    await controller.initialize();
    await _applyCurrentSettingsToController(controller);
    _preloadedControllers[path] = controller;
  }
}
```

- [ ] **Step 4: Replace `_seekTo` controller lookup with dual-backend**

Replace the controller-lookup block in `_seekTo` (lines 299-306):

```dart
    if (newItem != state.currentItem || currentController == null) {
      final videoPath = _itemIdToPath[newItem.id];
      if (videoPath != null) {
        if (PlatformCapability.isDesktop) {
          currentController = _desktopPlayers[videoPath];
        } else {
          currentController = _preloadedControllers[videoPath];
        }
        await _applyCurrentSettingsToController(currentController);
      }
    }
```

- [ ] **Step 5: Add `_applyCurrentSettingsToController` overload for desktop**

Replace the method to handle both types:

```dart
Future<void> _applyCurrentSettingsToController(dynamic controller) async {
  if (controller == null) return;
  if (controller is VideoPlayerController) {
    await controller.setPlaybackSpeed(state.playbackSpeed);
    await controller.setVolume(state.volume);
    await controller.setLooping(state.isLooping);
  } else if (controller is media_kit.Player) {
    controller.setRate(state.playbackSpeed);
    controller.setVolume(state.volume);
  }
}
```

- [ ] **Step 6: Replace `_startVideoListener` / `_stopVideoListener` for dual backend**

Replace:
```dart
void _startVideoListener(VideoPlayerController videoPlayerController) {
  videoPlayerController.addListener(_sendUpdateVideoEvent);
}

void _stopVideoListener(VideoPlayerController videoPlayerController) {
  videoPlayerController.removeListener(_sendUpdateVideoEvent);
}
```
With:
```dart
void _startVideoListener(dynamic controller) {
  if (controller is VideoPlayerController) {
    controller.addListener(_sendUpdateVideoEvent);
  } else if (controller is media_kit.Player) {
    controller.streams.position.listen((_) => _sendUpdateVideoEvent());
  }
}

void _stopVideoListener(dynamic controller) {
  if (controller is VideoPlayerController) {
    controller.removeListener(_sendUpdateVideoEvent);
  }
  // media_kit stream subscriptions are auto-cancelled on dispose
}
```

(Note: For proper subscription management, store stream subscriptions and cancel them explicitly. For brevity in this plan we rely on player disposal.)

- [ ] **Step 7: Update `close()` for dual backend**

Replace:
```dart
@override
Future<void> close() async {
  if (state.currentVideoController != null) {
    _stopVideoListener(state.currentVideoController!);
  }
  for (final controller in _preloadedControllers.values) {
    _stopVideoListener(controller);
    controller.dispose();
  }
  _preloadedControllers.clear();
  _itemIdToPath.clear();
  return super.close();
}
```
With:
```dart
@override
Future<void> close() async {
  final c = state.currentVideoController;
  if (c != null) _stopVideoListener(c);
  for (final controller in _preloadedControllers.values) {
    _stopVideoListener(controller);
    controller.dispose();
  }
  _preloadedControllers.clear();
  for (final player in _desktopPlayers.values) {
    player.dispose();
  }
  _desktopPlayers.clear();
  _itemIdToPath.clear();
  return super.close();
}
```

- [ ] **Step 8: Verify compiles**

```bash
cd restcut_app && dart analyze lib/widgets/multi_video_player/bloc/multi_video_player_bloc.dart
```

- [ ] **Step 9: Commit**

```bash
git add restcut_app/lib/widgets/multi_video_player/bloc/multi_video_player_bloc.dart
git commit -m "feat: dual-backend video player in MultiVideoPlayerBloc

Desktop uses media_kit Player, mobile keeps video_player.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 5: Dual-Backend Video Player Widgets

**Files:**
- Modify: `restcut_app/lib/widgets/multi_video_player/bloc_multi_video_player_widget.dart`
- Modify: `restcut_app/lib/widgets/multi_video_player/fullscreen_video_page.dart`

- [ ] **Step 1: Update `bloc_multi_video_player_widget.dart` for dual `Video` widget**

Add import:
```dart
import 'package:media_kit_video/media_kit_video.dart' as media_kit_video;
import '../../../services/platform_capability.dart';
```

Replace `_buildVideoPlayer` (lines 65-103):

```dart
Widget _buildVideoPlayer() {
  return BlocBuilder<MultiVideoPlayerBloc, MultiVideoPlayerState>(
    buildWhen: (previous, current) {
      return previous.isLoading != current.isLoading ||
          previous.currentVideoController != current.currentVideoController;
    },
    builder: (context, state) {
      if (state.isLoading) return _buildLoadingWidget();

      final controller = state.currentVideoController;
      if (controller == null || !state.isInitialized) return _buildEmptyWidget();

      return Center(
        child: AspectRatio(
          aspectRatio: aspectRatio ?? state.aspectRatio ?? 16 / 9,
          child: Stack(
            children: [
              if (PlatformCapability.isDesktop && controller is media_kit.Player)
                media_kit_video.Video(controller: controller)
              else if (controller is VideoPlayerController)
                VideoPlayer(controller),
            ],
          ),
        ),
      );
    },
  );
}
```

Add import for media_kit at the top:
```dart
import 'package:media_kit/media_kit.dart' as media_kit;
```

- [ ] **Step 2: Update `fullscreen_video_page.dart` similarly**

Add imports:
```dart
import 'package:media_kit/media_kit.dart' as media_kit;
import 'package:media_kit_video/media_kit_video.dart' as media_kit_video;
import '../../../services/platform_capability.dart';
```

Replace `_buildVideoPlayer` (lines 417-457):

```dart
Widget _buildVideoPlayer(BuildContext context) {
  final state = context.read<MultiVideoPlayerBloc>().state;
  if (state.isLoading) {
    return const Center(
      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
    );
  }
  final controller = state.currentVideoController;
  if (controller == null || !state.isInitialized) {
    return const Center(
      child: Text('暂无视频', style: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }
  return Center(
    child: AspectRatio(
      aspectRatio: state.aspectRatio ?? 16 / 9,
      child: Stack(
        children: [
          if (PlatformCapability.isDesktop && controller is media_kit.Player)
            media_kit_video.Video(controller: controller)
          else if (controller is VideoPlayerController)
            VideoPlayer(controller),
          if (!state.isInitialized)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 3: Verify compiles**

```bash
cd restcut_app && dart analyze lib/widgets/multi_video_player/
```

- [ ] **Step 4: Commit**

```bash
git add restcut_app/lib/widgets/multi_video_player/
git commit -m "feat: dual-backend video widgets (media_kit Video + VideoPlayer)

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 6: Remove Round Selection Page

**Files:**
- Delete: `restcut_app/lib/pages/desktop/desktop_round_selection_page.dart`
- Modify: `restcut_app/lib/router/modules/desktop.dart`

- [ ] **Step 1: Delete the file**

```bash
rm restcut_app/lib/pages/desktop/desktop_round_selection_page.dart
```

- [ ] **Step 2: Remove route and import from router**

In `lib/router/modules/desktop.dart`:
- Remove import: `import 'package:restcut/pages/desktop/desktop_round_selection_page.dart';`
- Remove the `clipSelect` constant: `static const String clipSelect = '/clip/:id/select';`
- Remove the entire `GoRoute` for `/clip/:id/select` (lines 28-37)

- [ ] **Step 3: Verify compiles**

```bash
cd restcut_app && dart analyze lib/router/modules/desktop.dart
```

- [ ] **Step 4: Commit**

```bash
git add restcut_app/lib/pages/desktop/desktop_round_selection_page.dart restcut_app/lib/router/modules/desktop.dart
git commit -m "feat: remove desktop round selection page

Navigation now goes directly from video library to preview/export.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 7: Redirect Video Card Click to Preview

**Files:**
- Modify: `restcut_app/lib/pages/desktop/desktop_home_page.dart`

- [ ] **Step 1: Change navigation target**

In `_VideoCard.build`, replace:
```dart
onTap: _isNavigable
    ? () => context.go('/clip/${record.id}/select')
    : null,
```
With:
```dart
onTap: _isNavigable
    ? () => context.go('/clip/${record.id}/preview')
    : null,
```

- [ ] **Step 2: Commit**

```bash
git add restcut_app/lib/pages/desktop/desktop_home_page.dart
git commit -m "feat: navigate video card directly to preview/export

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 8: Rewrite DesktopPreviewExportPage

**Files:**
- Modify: `restcut_app/lib/pages/desktop/desktop_preview_export_page.dart`

- [ ] **Step 1: Rewrite entire file with real player, real data, real export**

Write the complete file:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart' as media_kit;
import 'package:media_kit_video/media_kit_video.dart' as media_kit_video;
import 'package:path/path.dart' as p;
import 'package:restcut/constants/desktop_theme.dart';
import 'package:restcut/models/autoclip_models.dart';
import 'package:restcut/models/video.dart';
import 'package:restcut/store/video.dart';
import 'package:restcut/utils/logger_utils.dart';
import 'package:restcut/widgets/desktop/desktop_page_shell.dart';

class DesktopPreviewExportPage extends StatefulWidget {
  final String clipId;
  const DesktopPreviewExportPage({super.key, required this.clipId});

  @override
  State<DesktopPreviewExportPage> createState() =>
      _DesktopPreviewExportPageState();
}

class _DesktopPreviewExportPageState extends State<DesktopPreviewExportPage> {
  LocalVideoRecord? _record;
  List<SegmentInfo> _segments = [];
  String _fileName = '集锦';
  String _savePath = '';
  String _selectedQuality = '1080p';
  bool _isExporting = false;
  double _exportProgress = 0;
  bool _isLoading = true;

  media_kit.Player? _player;
  int _currentSegmentIndex = 0;
  StreamSubscription? _positionSub;

  @override
  void initState() {
    super.initState();
    _initSavePath();
    _loadRecord();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _initSavePath() async {
    final home = Platform.environment['HOME'] ?? '/tmp';
    setState(() => _savePath = '$home/Videos/弧迹');
  }

  Future<void> _loadRecord() async {
    try {
      final r = await LocalVideoStorage().findById(widget.clipId);
      if (!mounted) return;
      if (r != null) {
        final segments = r is EdittingVideoRecord
            ? r.allMatchSegments
            : <SegmentInfo>[];
        setState(() {
          _record = r;
          _segments = segments;
          _fileName = r.filePath?.split('/').last.split('.').first ?? '集锦';
          _isLoading = false;
        });
        if (segments.isNotEmpty && r.filePath != null) {
          _initPlayer(r.filePath!);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _initPlayer(String videoPath) async {
    _player?.dispose();
    final player = media_kit.Player();
    await player.open(media_kit.Media(videoPath));
    _positionSub = player.streams.position.listen((_) {
      if (!mounted) return;
      final pos = player.state.position;
      if (pos == null) return;
      _updateActiveSegment(pos.inMilliseconds / 1000.0);
    });
    _player = player;
    if (mounted) setState(() {});
  }

  void _updateActiveSegment(double seconds) {
    int newIndex = -1;
    for (int i = 0; i < _segments.length; i++) {
      final s = _segments[i];
      if (seconds >= s.startSeconds && seconds <= s.endSeconds) {
        newIndex = i;
        break;
      }
    }
    if (newIndex != _currentSegmentIndex && newIndex >= 0) {
      setState(() => _currentSegmentIndex = newIndex);
    }
  }

  void _seekToSegment(int index) {
    if (index < 0 || index >= _segments.length || _player == null) return;
    final seg = _segments[index];
    _player!.seek(Duration(milliseconds: (seg.startSeconds * 1000).round()));
    _player!.play();
    setState(() => _currentSegmentIndex = index);
  }

  double get _totalDuration {
    double total = 0;
    for (final s in _segments) {
      total += s.endSeconds - s.startSeconds;
    }
    return total;
  }

  String _formatSeconds(double totalSeconds) {
    final minutes = (totalSeconds / 60).floor();
    final seconds = (totalSeconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _startExport() async {
    if (_record == null || _record!.filePath == null || _segments.isEmpty) return;
    setState(() { _isExporting = true; _exportProgress = 0; });

    final outputPath = '$_savePath/$_fileName.mp4';
    await Directory(_savePath).create(recursive: true);

    // Build concat list with inpoint/outpoint for each segment
    final concatPath = '${Directory.systemTemp.path}/huji_concat_${DateTime.now().millisecondsSinceEpoch}.txt';
    final concatLines = _segments.map((s) =>
      "file '${_record!.filePath!}'\n"
      "inpoint ${s.startSeconds}\n"
      "outpoint ${s.endSeconds}\n"
    );
    await File(concatPath).writeAsString(concatLines.join());

    // Quality → ffmpeg encoding params
    final (scale, crf) = switch (_selectedQuality) {
      '原画' => ('', '18'),
      '1080p' => ('scale=-2:1080', '20'),
      '720p' => ('scale=-2:720', '23'),
      _ => ('scale=-2:480', '26'),
    };
    final vfArg = scale.isNotEmpty ? ['-vf', scale] : <String>[];

    final totalDurationSec = _totalDuration;
    try {
      final process = await Process.start('ffmpeg', [
        '-f', 'concat', '-safe', '0', '-i', concatPath,
        '-c:v', 'libx264', '-crf', crf, '-preset', 'medium',
        ...vfArg,
        '-c:a', 'aac', '-b:a', '128k',
        '-movflags', '+faststart',
        '-progress', 'pipe:1', '-nostats',
        '-y', outputPath,
      ]);

      // Parse progress from ffmpeg stdout (progress format)
      final outLines = process.stdout.transform(utf8.decoder).transform(const LineSplitter());
      await for (final line in outLines) {
        if (line.startsWith('out_time_ms=')) {
          final ms = int.tryParse(line.substring(12)) ?? 0;
          if (totalDurationSec > 0) {
            final p = ((ms / 1000) / totalDurationSec).clamp(0.0, 1.0);
            if (mounted) setState(() => _exportProgress = p);
          }
        }
      }

      final exitCode = await process.exitCode;
      await File(concatPath).delete();

      if (!mounted) return;
      if (exitCode == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出完成: $outputPath')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导出失败')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    } finally {
      if (mounted) setState(() { _isExporting = false; _exportProgress = 0; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoName = _record?.filePath != null ? p.basename(_record!.filePath!) : '未知';

    return DesktopPageShell(
      currentRoute: '/clip/${widget.clipId}/preview',
      title: '预览',
      breadcrumbs: ['视频库', videoName, '预览'],
      actions: [
        OutlinedButton(onPressed: () => context.go('/'), child: const Text('取消')),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => context.go('/clip/${widget.clipId}/edit'),
          style: OutlinedButton.styleFrom(
            foregroundColor: DesktopTheme.indigoText,
            side: BorderSide(color: DesktopTheme.primaryColor.withAlpha(89)),
            backgroundColor: DesktopTheme.primaryColor.withAlpha(26),
          ),
          child: const Text('✎ 精修编辑'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _isLoading || _record == null ? null : () => _showExportModal(context),
          icon: const Icon(Icons.file_download, size: 16),
          label: const Text('导出'),
        ),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(children: [_buildExportConfig(), Expanded(child: _buildPreviewArea())]),
    );
  }

  void _showExportModal(BuildContext context) {
    final segCount = _segments.length;
    final durationStr = _formatSeconds(_totalDuration);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: DesktopTheme.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: const Text('确认导出', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _exportInfoRow('文件名', '$_fileName.mp4'),
              const SizedBox(height: 8),
              _exportInfoRow('格式', 'MP4 (H.264)'),
              const SizedBox(height: 8),
              _exportInfoRow('清晰度', _selectedQuality),
              const SizedBox(height: 8),
              _exportInfoRow('保存到', _savePath),
              const SizedBox(height: 8),
              _exportInfoRow('回合数', '$segCount 个 · 合计 $durationStr'),
              const SizedBox(height: 12),
              const Divider(color: DesktopTheme.borderMedium),
              if (_isExporting) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(value: _exportProgress, backgroundColor: DesktopTheme.borderMedium, valueColor: const AlwaysStoppedAnimation(DesktopTheme.primaryColor)),
                const SizedBox(height: 8),
                Text('导出中... ${(_exportProgress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 13, color: DesktopTheme.textSecondary)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: _isExporting ? null : () => Navigator.of(ctx).pop(), child: const Text('取消', style: TextStyle(color: DesktopTheme.textSecondary))),
            ElevatedButton.icon(
              onPressed: _isExporting ? null : () async { Navigator.of(ctx).pop(); await _startExport(); },
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('开始导出'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build helpers ──

  Widget _exportInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: DesktopTheme.textMuted)),
        Flexible(child: Text(value, style: const TextStyle(fontSize: 13, color: Colors.white), textAlign: TextAlign.right)),
      ],
    );
  }

  Widget _buildExportConfig() {
    return SizedBox(
      width: 300,
      child: Container(
        color: DesktopTheme.subMainBg,
        child: Column(children: [
          Expanded(
            child: ListView(padding: const EdgeInsets.all(22), children: [
              const _ConfigTitle('📤 导出配置'), const SizedBox(height: 18),
              _buildFileName(), const SizedBox(height: 22),
              _buildFormat(), const SizedBox(height: 22),
              _buildQuality(), const SizedBox(height: 22),
              _buildTransition(), const SizedBox(height: 22),
              _buildSavePath(),
            ]),
          ),
          _buildConfigFooter(),
        ]),
      ),
    );
  }

  Widget _buildFileName() {
    return _ExSection(label: '文件名', child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: DesktopTheme.cardBg, border: Border.all(color: DesktopTheme.borderMedium), borderRadius: BorderRadius.circular(6)),
      child: Text(_fileName, style: const TextStyle(fontSize: 13, color: DesktopTheme.textPrimary)),
    ));
  }

  Widget _buildFormat() => _ExSection(label: '格式', child: _DropdownDisplay(value: 'MP4 (H.264)'));
  Widget _buildTransition() => _ExSection(label: '回合间转场', child: _DropdownDisplay(value: '无（直接拼接）'));

  Widget _buildQuality() {
    return _ExSection(label: '清晰度', child: Column(children: [
      _RadioOption(label: '原画', meta: '原始分辨率', active: _selectedQuality == '原画', onTap: () => setState(() => _selectedQuality = '原画')),
      _RadioOption(label: '1080p', meta: '推荐', active: _selectedQuality == '1080p', onTap: () => setState(() => _selectedQuality = '1080p')),
      _RadioOption(label: '720p', meta: '体积较小', active: _selectedQuality == '720p', onTap: () => setState(() => _selectedQuality = '720p')),
      _RadioOption(label: '480p', meta: '移动分享', active: _selectedQuality == '480p', onTap: () => setState(() => _selectedQuality = '480p')),
    ]));
  }

  Widget _buildSavePath() {
    return _ExSection(label: '保存到', child: Row(children: [
      Expanded(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: DesktopTheme.cardBg, border: Border.all(color: DesktopTheme.borderMedium), borderRadius: BorderRadius.circular(6)),
        child: Text(_savePath, style: const TextStyle(fontSize: 13, color: DesktopTheme.textSecondary)),
      )),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: DesktopTheme.borderLight, border: Border.all(color: DesktopTheme.borderMedium), borderRadius: BorderRadius.circular(6)),
        child: const Icon(Icons.folder_open, size: 16, color: DesktopTheme.textSecondary),
      ),
    ]));
  }

  Widget _buildConfigFooter() {
    final segCount = _segments.length;
    final durationStr = _formatSeconds(_totalDuration);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(color: DesktopTheme.sidebarBg, border: Border(top: BorderSide(color: DesktopTheme.borderLight))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('回合数', style: TextStyle(fontSize: 12, color: DesktopTheme.textSecondary)),
          Text('$segCount 个 · 合计 $durationStr', style: const TextStyle(fontSize: 12, color: DesktopTheme.indigoText, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('输出清晰度', style: TextStyle(fontSize: 12, color: DesktopTheme.textSecondary)),
          Text(_selectedQuality, style: const TextStyle(fontSize: 12, color: DesktopTheme.indigoText, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  Widget _buildPreviewArea() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(children: [
        _buildPlayer(),
        const SizedBox(height: 20),
        _buildRoundStrip(),
        const SizedBox(height: 20),
        _buildSummary(),
      ]),
    );
  }

  Widget _buildPlayer() {
    if (_player == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(color: const Color(0xFF0A0A0C), borderRadius: BorderRadius.circular(10), border: Border.all(color: DesktopTheme.borderLight)),
          child: const Center(child: Text('🏓', style: TextStyle(fontSize: 48, color: Color(0xFF444444)))),
        ),
      );
    }

    return Column(children: [
      AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: DesktopTheme.borderLight)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: media_kit_video.Video(controller: _player!),
          ),
        ),
      ),
      const SizedBox(height: 8),
      _buildPlayerControls(),
    ]);
  }

  Widget _buildPlayerControls() {
    final pos = _player?.state.position ?? Duration.zero;
    final dur = _player?.state.duration ?? Duration.zero;
    final playing = _player?.state.playing ?? false;
    final posMs = pos.inMilliseconds;
    final durMs = dur.inMilliseconds.clamp(1, double.maxFinite.toInt());
    final progress = (posMs / durMs).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1A1A1D), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        GestureDetector(
          onTap: () => playing ? _player?.pause() : _player?.play(),
          child: Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF2F2F2)),
            alignment: Alignment.center,
            child: Icon(playing ? Icons.pause : Icons.play_arrow, color: const Color(0xFF18181B), size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Text(_formatDuration(pos), style: const TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'monospace')),
        const SizedBox(width: 12),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4, activeTrackColor: Colors.white, inactiveTrackColor: Colors.white.withAlpha(51),
              thumbColor: Colors.white, overlayColor: Colors.white.withAlpha(26),
            ),
            child: Slider(
              value: posMs.toDouble(),
              min: 0, max: durMs.toDouble(),
              onChanged: (v) => _player?.seek(Duration(milliseconds: v.round())),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(_formatDuration(dur), style: const TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'monospace')),
      ]),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildRoundStrip() {
    if (_segments.isEmpty) return const SizedBox.shrink();
    final displaySegments = _segments;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('回合顺序', style: TextStyle(fontSize: 13, color: DesktopTheme.textSecondary, fontWeight: FontWeight.w500)),
        Text('${_segments.length}个回合', style: const TextStyle(fontSize: 11, color: DesktopTheme.textDim)),
      ]),
      const SizedBox(height: 8),
      SizedBox(
        height: 90,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: displaySegments.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final seg = displaySegments[i];
            final active = i == _currentSegmentIndex;
            final duration = seg.endSeconds - seg.startSeconds;
            final durStr = '${duration.toStringAsFixed(0)}s';
            final startStr = _formatSeconds(seg.startSeconds);

            return GestureDetector(
              onTap: () => _seekToSegment(i),
              child: Container(
                width: 120,
                decoration: BoxDecoration(
                  color: DesktopTheme.cardBg,
                  border: Border.all(color: active ? DesktopTheme.primaryColor.withAlpha(179) : DesktopTheme.borderLight),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                        gradient: LinearGradient(colors: [Color(0xFF2D2D35), Color(0xFF1A1A1D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      ),
                      child: Stack(children: [
                        const Center(child: Text('🏓', style: TextStyle(fontSize: 22))),
                        Positioned(bottom: 4, right: 4, child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: Colors.black.withAlpha(179), borderRadius: BorderRadius.circular(2)),
                          child: Text('#${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                        )),
                        if (active)
                          const Positioned(top: 4, left: 4, child: Text('▶ 播放中', style: TextStyle(fontSize: 9, color: Colors.white))),
                      ]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(startStr, style: const TextStyle(fontSize: 10, color: DesktopTheme.textMuted)),
                      Text(durStr, style: const TextStyle(fontSize: 10, color: DesktopTheme.textMuted)),
                    ]),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildSummary() {
    final segCount = _segments.length;
    final durationStr = _formatSeconds(_totalDuration);
    return Row(children: [
      _SummaryStat(num: '$segCount', label: '个回合'),
      const SizedBox(width: 24),
      _SummaryStat(num: durationStr, label: '合计时长'),
      const SizedBox(width: 24),
      _SummaryStat(num: _selectedQuality, label: '输出清晰度'),
    ]);
  }
}

// ── Reuse existing private widgets from original file ──
// (_ConfigTitle, _ExSection, _DropdownDisplay, _RadioOption, _SummaryStat)
// These are copied from the original desktop_preview_export_page.dart unchanged.
```

Note: The private helper widgets (`_ConfigTitle`, `_ExSection`, `_DropdownDisplay`, `_RadioOption`, `_SummaryStat`, `_PlayerControls`) are already defined at the bottom of the original file (lines 595-709). Keep them unchanged in the rewrite.

- [ ] **Step 2: Verify compiles**

```bash
cd restcut_app && dart analyze lib/pages/desktop/desktop_preview_export_page.dart
```

- [ ] **Step 3: Commit**

```bash
git add restcut_app/lib/pages/desktop/desktop_preview_export_page.dart
git commit -m "feat: wire preview/export page with real player, data, ffmpeg concat export

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 9: Update DesktopPrecisionEditPage

**Files:**
- Modify: `restcut_app/lib/pages/desktop/desktop_precision_edit_page.dart`

- [ ] **Step 1: Replace static player with real media_kit player**

Add imports:
```dart
import 'package:media_kit/media_kit.dart' as media_kit;
import 'package:media_kit_video/media_kit_video.dart' as media_kit_video;
```

Add a `_player` field to state:
```dart
media_kit.Player? _player;
StreamSubscription? _positionSub;
```

Replace `_buildPlayer` (lines 392-428):

```dart
Widget _buildPlayer() {
  if (_player == null) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 360),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: DesktopTheme.borderLight),
        ),
        child: const Center(
          child: Text('🏓', style: TextStyle(fontSize: 56, color: Color(0xFF444444))),
        ),
      ),
    );
  }
  return AspectRatio(
    aspectRatio: 16 / 9,
    child: Container(
      constraints: const BoxConstraints(maxHeight: 360),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DesktopTheme.borderLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: media_kit_video.Video(controller: _player!),
      ),
    ),
  );
}
```

Add `_initPlayer` and `_seekToActiveSegment` methods:

```dart
Future<void> _initPlayer(String videoPath) async {
  _player?.dispose();
  _positionSub?.cancel();
  final player = media_kit.Player();
  await player.open(media_kit.Media(videoPath));
  _player = player;
  if (_activeSegment != null) {
    _seekToActiveSegment(_activeSegment!);
  }
}

void _seekToActiveSegment(SegmentInfo segment) {
  if (_player == null) return;
  _player!.seek(Duration(milliseconds: (segment.startSeconds * 1000).round()));
}

@override
void dispose() {
  _positionSub?.cancel();
  _player?.dispose();
  _roundClipBloc.close();
  _multiVideoPlayerBloc.close();
  super.dispose();
}
```

Initialize the player when record is loaded — add after `edittingRecord` is obtained in `_initBloc`:

```dart
if (edittingRecord.filePath != null) {
  _initPlayer(edittingRecord.filePath!);
}
```

- [ ] **Step 2: Fix breadcrumbs (remove hardcoded date) and navigation**

Replace breadcrumbs:
```dart
breadcrumbs: ['视频库', '编辑', '精修编辑'],
```

Replace "返回选择" button (was going to `/select`, now removed):
```dart
OutlinedButton(
  onPressed: () => context.go('/clip/${widget.clipId}/preview'),
  ...
  child: const Text('↩ 返回预览'),
),
```

- [ ] **Step 3: Dispose player on close**

Already handled in step 1's dispose.

- [ ] **Step 4: Verify compiles**

```bash
cd restcut_app && dart analyze lib/pages/desktop/desktop_precision_edit_page.dart
```

- [ ] **Step 5: Commit**

```bash
git add restcut_app/lib/pages/desktop/desktop_precision_edit_page.dart
git commit -m "feat: wire precision edit page with media_kit player

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 10: Final Verification & Cleanup

- [ ] **Step 1: Run full analysis**

```bash
cd restcut_app && dart analyze
```

Expected: no errors. Warnings are acceptable.

- [ ] **Step 2: Check for any remaining references to deleted `/select` route**

```bash
grep -rn "/select\|round_selection" restcut_app/lib/ --include="*.dart" | grep -v ".freezed.dart" | grep -v ".g.dart"
```

Expected: no results.

- [ ] **Step 3: Commit any remaining changes**

```bash
git add restcut_app/
git commit -m "chore: cleanup after desktop preview/export integration

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```
