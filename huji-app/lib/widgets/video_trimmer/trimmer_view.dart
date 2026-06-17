import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart' hide Preview;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/utils/time_utils.dart';
import 'package:huji_app/widgets/video_trimmer/lib/managers/video_clip_segment.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/clip_segment_bloc.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/clip_segment_event.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/clip_segment_state.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/trimmer_bloc.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/trimmer_event.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/trimmer_state.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/video_trimmer_bloc_manager.dart';
import 'package:huji_app/widgets/video_trimmer/lib/trim_viewer/trim_editor_properties.dart';
import 'package:huji_app/widgets/video_trimmer/lib/trim_viewer/thumbnail_viewer.dart';
import 'package:huji_app/widgets/video_trimmer/lib/trim_viewer/video_viewer.dart';

/// Full-screen video trimmer page (mobile).
class TrimmerView extends StatefulWidget {
  final File file;
  final List<VideoClipSegment>? initialSegments;
  final void Function(List<VideoClipSegment>)? onSegmentsChanged;

  const TrimmerView(
    this.file, {
    super.key,
    this.initialSegments,
    this.onSegmentsChanged,
  });

  @override
  State<TrimmerView> createState() => _TrimmerViewState();
}

class _TrimmerViewState extends State<TrimmerView> {
  late final VideoTrimmerBlocManager _videoTrimmerBlocManager;

  @override
  void initState() {
    super.initState();
    _videoTrimmerBlocManager = VideoTrimmerBlocManager(
      file: widget.file,
      initialSegments: widget.initialSegments,
    );
  }

  @override
  void dispose() {
    _videoTrimmerBlocManager.clipSegmentBloc.close();
    _videoTrimmerBlocManager.trimmerBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ClipSegmentBloc>.value(
          value: _videoTrimmerBlocManager.clipSegmentBloc,
        ),
        BlocProvider<TrimmerBloc>.value(
          value: _videoTrimmerBlocManager.trimmerBloc,
        ),
      ],
      child: PopScope(
        canPop: !Navigator.of(context).userGestureInProgress,
        child: SafeArea(
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: TrimmerEditor(
                    onSegmentsChanged: widget.onSegmentsChanged,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 80,
      color: Colors.black,
      child: Column(
        children: [
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                Row(
                  children: [
                    BlocBuilder<ClipSegmentBloc, ClipSegmentState>(
                      buildWhen: (previous, current) =>
                          previous.selectedSegment != current.selectedSegment ||
                          (previous.selectedSegment?.isFavorite !=
                              current.selectedSegment?.isFavorite),
                      builder: (context, state) {
                        final isFavorite =
                            state.selectedSegment?.isFavorite ?? false;
                        return IconButton(
                          onPressed: state.selectedSegment != null
                              ? () {
                                  if (context.mounted) {
                                    context.read<ClipSegmentBloc>().add(
                                      ClipSegmentToggleFavorite(
                                        state.selectedSegment!,
                                      ),
                                    );
                                  }
                                }
                              : null,
                          icon: Icon(
                            isFavorite ? Icons.star : Icons.star_border,
                            color: isFavorite ? Colors.amber : Colors.white,
                          ),
                          tooltip: '收藏片段',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Embeddable trimmer editor widget.
///
/// Requires [ClipSegmentBloc] and [TrimmerBloc] provided by ancestors.
/// Use this directly in desktop layouts, or wrap in [TrimmerView] for
/// full-screen mobile editing.
class TrimmerEditor extends StatelessWidget {
  final void Function(List<VideoClipSegment>)? onSegmentsChanged;

  const TrimmerEditor({super.key, this.onSegmentsChanged});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ClipSegmentBloc, ClipSegmentState>(
          listenWhen: (previous, current) =>
              previous.activeSegments != current.activeSegments,
          listener: (context, state) {
            if (onSegmentsChanged != null) {
              onSegmentsChanged!(state.activeSegments);
            }
          },
        ),
      ],
      child: BlocBuilder<TrimmerBloc, TrimmerState>(
        buildWhen: (previous, current) =>
            previous.isLoading != current.isLoading,
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          return Column(
            children: [
              Expanded(flex: 3, child: _buildVideoPreview(context)),
              _buildSegmentOverview(context),
              _buildControls(context),
              _buildTrimViewer(),
              _buildVideoProgressControl(context),
              _buildBottomToolbar(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVideoPreview(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          Center(
            child: VideoViewer(
              videoPlayerController: context
                  .read<TrimmerBloc>()
                  .state
                  .videoPlayerController,
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: () {
                if (context.mounted) {
                  context.read<TrimmerBloc>().add(TrimmerTogglePlayPause());
                }
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: BlocBuilder<TrimmerBloc, TrimmerState>(
                  buildWhen: (previous, current) =>
                      previous.isPlaying != current.isPlaying,
                  builder: (context, state) => Icon(
                    state.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrimViewer() {
    return Container(
      height: 160,
      width: double.infinity,
      color: Colors.grey[900],
      child: ScrollableTrimViewer(
        editorProperties: TrimEditorProperties(
          backgroundColor: Colors.grey[900]!,
        ),
      ),
    );
  }

  Widget _buildVideoProgressControl(BuildContext context) {
    return Container(
      height: 56,
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: BlocBuilder<TrimmerBloc, TrimmerState>(
        buildWhen: (previous, current) =>
            previous.currentMilliseconds != current.currentMilliseconds ||
            previous.totalDuration != current.totalDuration,
        builder: (context, state) => Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatTime(state.currentMilliseconds / 1000),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  formatTime(state.totalDuration / 1000),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 2),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.grey[700],
                thumbColor: Colors.white,
                overlayColor: Colors.white.withValues(alpha: 0.2),
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: state.isDragging ? 8 : 6,
                ),
                trackHeight: 2,
                overlayShape: RoundSliderOverlayShape(
                  overlayRadius: state.isDragging ? 16 : 12,
                ),
                trackShape: const RoundedRectSliderTrackShape(),
                valueIndicatorColor: Colors.white,
                valueIndicatorTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                showValueIndicator: state.isDragging
                    ? ShowValueIndicator.always
                    : ShowValueIndicator.never,
              ),
              child: Slider(
                value: state.totalDuration > 0
                    ? (state.currentMilliseconds / state.totalDuration)
                        .clamp(0.0, 1.0)
                    : 0.0,
                onChanged: (value) {
                  final targetTime = (value * state.totalDuration).round();
                  if ((targetTime - state.currentMilliseconds).abs() > 100) {
                    if (context.mounted) {
                      context.read<TrimmerBloc>().add(
                        TrimmerSeekTo(Duration(milliseconds: targetTime)),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Container(
      height: 60,
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BlocBuilder<TrimmerBloc, TrimmerState>(
            buildWhen: (previous, current) =>
                previous.currentMilliseconds != current.currentMilliseconds ||
                previous.totalDuration != current.totalDuration,
            builder: (context, state) {
              return Text(
                '${formatTime(state.currentMilliseconds / 1000)} / ${formatTime(state.totalDuration / 1000)}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              );
            },
          ),
          Row(
            children: [
              BlocBuilder<TrimmerBloc, TrimmerState>(
                buildWhen: (previous, current) =>
                    previous.isSlowMotion != current.isSlowMotion,
                builder: (context, state) {
                  return GestureDetector(
                    onTap: () {
                      if (context.mounted) {
                        context.read<TrimmerBloc>().add(
                          TrimmerToggleSlowMotion(),
                        );
                      }
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.slow_motion_video,
                          color: state.isSlowMotion
                              ? Colors.blue
                              : Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '慢放',
                          style: TextStyle(
                            color: state.isSlowMotion
                                ? Colors.blue
                                : Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              BlocBuilder<TrimmerBloc, TrimmerState>(
                buildWhen: (previous, current) =>
                    previous.playbackSpeed != current.playbackSpeed,
                builder: (context, state) {
                  return _buildSpeedMenu(context, state);
                },
              ),
              const SizedBox(width: 8),
              BlocBuilder<TrimmerBloc, TrimmerState>(
                buildWhen: (previous, current) =>
                    previous.isPlaying != current.isPlaying,
                builder: (context, state) {
                  return IconButton(
                    onPressed: () {
                      if (context.mounted) {
                        context.read<TrimmerBloc>().add(
                          TrimmerTogglePlayPause(),
                        );
                      }
                    },
                    icon: Icon(
                      state.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentOverview(BuildContext context) {
    return Container(
      height: 60,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: BlocBuilder<ClipSegmentBloc, ClipSegmentState>(
              buildWhen: (previous, current) {
                final activeSegments = previous.activeSegments;
                final activeSegments2 = current.activeSegments;
                return activeSegments != activeSegments2 ||
                    activeSegments.length != activeSegments2.length;
              },
              builder: (context, state) => ListView.builder(
                controller: ScrollController(),
                scrollDirection: Axis.horizontal,
                itemCount: state.activeSegments.length + 1,
                itemBuilder: (context, index) {
                  final activeSegments = state.activeSegments;
                  if (index == activeSegments.length) {
                    return Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[600]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () {
                          if (context.mounted) {
                            context.read<ClipSegmentBloc>().add(
                              ClipSegmentAddAt(
                                startTimeMs: context
                                    .read<TrimmerBloc>()
                                    .state
                                    .currentMilliseconds,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                      ),
                    );
                  }

                  final segment = activeSegments[index];
                  return GestureDetector(
                    onTap: () {
                      if (context.mounted) {
                        context.read<ClipSegmentBloc>().add(
                          ClipSegmentSelect(
                            segment: segment,
                            isScrollToSegment: true,
                          ),
                        );
                      }
                    },
                    child: BlocBuilder<ClipSegmentBloc, ClipSegmentState>(
                      buildWhen: (previous, current) =>
                          previous.selectedSegment != current.selectedSegment &&
                          (current.selectedSegment == segment ||
                              previous.selectedSegment == segment),
                      builder: (context, state) {
                        final isSelected = state.selectedSegment == segment;
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey[600]!,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(7),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      formatSegmentDuration(
                                        (segment.endTime - segment.startTime) /
                                            1000,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: 20,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.grey[600],
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(7),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    ' ${formatSegmentDuration(segment.startTime / 1000, precision: 0)} - ${formatSegmentDuration(segment.endTime / 1000, precision: 0)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar(BuildContext context) {
    return Container(
      height: 80,
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          BlocBuilder<ClipSegmentBloc, ClipSegmentState>(
            buildWhen: (previous, current) =>
                previous.activeSegments.isNotEmpty !=
                current.activeSegments.isNotEmpty,
            builder: (context, state) {
              return _buildToolButton(
                icon: Icons.content_cut,
                label: '分割',
                onTap: () {
                  if (context.mounted) {
                    context.read<ClipSegmentBloc>().add(
                      ClipSegmentSplitAt(
                        context.read<TrimmerBloc>().state.currentMilliseconds,
                      ),
                    );
                  }
                },
                isEnabled: state.activeSegments.isNotEmpty,
              );
            },
          ),
          _buildToolButton(
            icon: Icons.add,
            label: '添加片段',
            onTap: () {
              if (context.mounted) {
                context.read<ClipSegmentBloc>().add(
                  ClipSegmentAddAt(
                    startTimeMs: context
                        .read<TrimmerBloc>()
                        .state
                        .currentMilliseconds,
                  ),
                );
              }
            },
            isEnabled: true,
          ),
          BlocBuilder<ClipSegmentBloc, ClipSegmentState>(
            buildWhen: (previous, current) =>
                previous.activeSegments.length != current.activeSegments.length,
            builder: (context, segmentState) {
              return BlocBuilder<TrimmerBloc, TrimmerState>(
                buildWhen: (previous, current) =>
                    previous.playSelectedSegmentOnly !=
                    current.playSelectedSegmentOnly,
                builder: (context, trimmerState) {
                  final hasActiveSegments =
                      segmentState.activeSegments.isNotEmpty;
                  return _buildToolButton(
                    icon: Icons.play_arrow,
                    label: '只播放片段',
                    onTap: () {
                      if (context.mounted && hasActiveSegments) {
                        context.read<TrimmerBloc>().add(
                          TrimmerTogglePlaySelectedSegmentOnly(),
                        );
                      }
                    },
                    color: trimmerState.playSelectedSegmentOnly
                        ? Colors.blue
                        : Colors.white,
                    isEnabled: hasActiveSegments,
                  );
                },
              );
            },
          ),
          BlocBuilder<ClipSegmentBloc, ClipSegmentState>(
            buildWhen: (previous, current) =>
                previous.selectedSegment != current.selectedSegment,
            builder: (context, state) {
              return _buildToolButton(
                icon: Icons.delete,
                label: '删除',
                onTap: () {
                  Throttles.throttle(
                    'trimmer_delete_segment',
                    const Duration(milliseconds: 500),
                    () {
                      if (context.mounted) {
                        context.read<ClipSegmentBloc>().add(
                          ClipSegmentDeleteSelected(),
                        );
                      }
                    },
                  );
                },
                isEnabled: state.selectedSegment != null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedMenu(BuildContext context, TrimmerState state) {
    return StatefulBuilder(
      builder: (context, setState) {
        return PopupMenuButton<bool>(
          icon: const Icon(Icons.speed, color: Colors.white, size: 20),
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          color: Colors.black.withValues(alpha: 0.9),
          elevation: 8,
          onSelected: (value) {},
          menuPadding: EdgeInsets.zero,
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: false,
              child: Container(
                padding: const EdgeInsets.all(0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSpeedMenuItem(context, state, '0.5x', 0.5),
                    _buildSpeedMenuItem(context, state, '1x', 1.0),
                    _buildSpeedMenuItem(context, state, '2x', 2.0),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpeedMenuItem(
    BuildContext context,
    TrimmerState state,
    String label,
    double speed,
  ) {
    final isSelected = state.playbackSpeed == speed;
    return GestureDetector(
      onTap: () {
        if (context.mounted) {
          try {
            context.read<TrimmerBloc>().add(TrimmerSetPlaybackSpeed(speed));
            Navigator.of(context).pop();
          } catch (e) {
            // ignore errors when page is exiting
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.blue
                : Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isEnabled = true,
    Color? color,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isEnabled ? (color ?? Colors.white) : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isEnabled ? Colors.white : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
