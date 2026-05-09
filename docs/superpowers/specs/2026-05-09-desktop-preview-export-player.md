# Desktop Preview/Export & Video Player Migration

**Date:** 2026-05-09
**Status:** approved

## Overview

Replace `video_player` (mobile-only) with `media_kit` (cross-platform via libmpv) across all
desktop pages. Remove the Phase 2 scaffold round-selection page. Wire the preview/export page
with real video playback, segment data, and ffmpeg concat export with progress.

## Scope

1. `MultiVideoPlayerBloc` gains dual-backend: `media_kit` on desktop, `video_player` on mobile
2. Remove `DesktopRoundSelectionPage` and its route
3. Video library card click navigates directly to preview/export
4. `DesktopPreviewExportPage` — real player, real data, real export
5. `DesktopPrecisionEditPage` — player migration to media_kit

## Detailed Design

### 1. Dual-Backend Video Player in MultiVideoPlayerBloc

`MultiVideoPlayerBloc` keeps the same public API (events, state, methods). Internally it
branches on `PlatformCapability.supportsVideoPlayer`:

- **Mobile path** (existing): `VideoPlayerController` from `package:video_player`
- **Desktop path** (new): `Player` from `package:media_kit`

**Dependencies to add** (`pubspec.yaml`):
```yaml
media_kit: ^1.1.11
media_kit_video: ^1.2.5
media_kit_libs_linux: ^1.1.0
```

**Key API mappings:**

| Operation | video_player | media_kit |
|-----------|-------------|-----------|
| create | `VideoPlayerController.file(File(path))` | `Player()` + `player.open(Media(path))` |
| dispose | `controller.dispose()` | `player.dispose()` |
| play | `controller.play()` | `player.play()` |
| pause | `controller.pause()` | `player.pause()` |
| seek | `controller.seekTo(position)` | `player.seek(position)` |
| position | `controller.value.position` | `player.state.position` |
| duration | `controller.value.duration` | `player.state.duration` |
| speed | `controller.setPlaybackSpeed(s)` | `player.setRate(s)` |
| volume | `controller.setVolume(v)` | `player.setVolume(v)` |
| playing | `controller.value.isPlaying` | `player.state.playing` |
| listen | `controller.addListener(cb)` | `player.streams.position.listen(cb)` |

**State changes:** `MultiVideoPlayerState.currentVideoController` changes from
`VideoPlayerController?` to `Object?`. Callers that cast to `VideoPlayerController`
must be updated.

**File changes:**
- `pubspec.yaml`
- `lib/services/platform_capability.dart` — remove `supportsVideoPlayer: false` for desktop
- `lib/widgets/multi_video_player/bloc/multi_video_player_bloc.dart`
- `lib/widgets/multi_video_player/bloc/multi_video_player_state.dart`
- `lib/widgets/multi_video_player/bloc_multi_video_player_widget.dart` (if any)

### 2. Remove DesktopRoundSelectionPage

- Delete `lib/pages/desktop/desktop_round_selection_page.dart`
- Remove route `/clip/:id/select` from `lib/router/modules/desktop.dart`
- Remove import from router

### 3. Video Card → Preview/Export

In `lib/pages/desktop/desktop_home_page.dart` `_VideoCard.build`:
```dart
onTap: _isNavigable ? () => context.go('/clip/${record.id}/preview') : null,
```

In `DesktopClipConfigPage` ("新建剪辑" page), the success snackbar "查看任务" button
already goes to `/tasks`. No change needed.

In any other navigation references to `/clip/:id/select`, update to `/preview`.

### 4. DesktopPreviewExportPage — Real Implementation

**Player area:**
- Replace static emoji with `media_kit` `Video` widget
- Real playback controls (play/pause, seek bar, time display)
- Play the full source video; seek to segment start when a segment card is tapped

**Round strip:**
- Show all segments from `_record.allMatchSegments`
- Tap a segment → seek player to `segment.startSeconds`
- Currently-playing segment is highlighted (track via player position)
- Show segment number, start time, duration

**Data:**
- Breadcrumbs: use `_fileName` instead of hardcoded "2026-05-04 比赛"
- Segment count and total duration from `_segments`

**Export:**
- Confirm modal → create ffmpeg concat file → run ffmpeg → show progress
- ffmpeg command uses concat demuxer:
  ```
  ffmpeg -f concat -safe 0 -i concat_list.txt -c:v libx264 -c:a aac output.mp4
  ```
- Each segment in concat list uses `inpoint`/`outpoint`:
  ```
  file '/path/to/video.mp4'
  inpoint 0.33
  outpoint 2.33
  file '/path/to/video.mp4'
  inpoint 13.0
  outpoint 15.0
  ```
- Progress: parse ffmpeg stderr `time=HH:MM:SS.ms` lines, calculate percentage from total duration
- Quality selection: map `原画/1080p/720p/480p` to ffmpeg scale + crf parameters

### 5. DesktopPrecisionEditPage — Player Migration

- Replace `VideoPlayerController` references with media_kit equivalents
- The page already has the structure for in/out point editing
- Player position listener drives the timeline scrubber

## Data Flow

```
Video file on disk
    │
    ▼
media_kit Player ──► Video widget (preview)
    │
    ▼
Player position ──► Round strip highlight
    │
    ▼
Selected segments ──► ffmpeg concat ──► output.mp4
```

## Error Handling

- Media file not found → show error state in player area
- ffmpeg not available → disable export button, show tooltip
- Export directory not writable → show error snackbar
- Segment list empty → show "暂无检测到的回合片段"

## Testing

- Unit test: `MultiVideoPlayerBloc` desktop path initialization
- Widget test: preview page with mock segments
- Manual: load test.mp4, verify player works, verify export produces correct output

## Out of Scope

- Mobile video_player behavior (unchanged)
- Round selection page features (page removed)
- Transition effects between segments (future)
- Background export / notification (future)
