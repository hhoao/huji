import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
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
import 'package:huji_app/widgets/video_trimmer/lib/trim_viewer/thumbnail_viewer.dart';
import 'package:huji_app/widgets/video_trimmer/lib/trim_viewer/video_viewer.dart';
import 'package:huji_app/widgets/video_trimmer/theme/trimmer_layout.dart';
import 'package:huji_app/widgets/video_trimmer/theme/trimmer_theme.dart';

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
    final trimmerTheme = context.trimmerTheme;
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
            backgroundColor: trimmerTheme.scaffoldBackground,
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
    final trimmerTheme = context.trimmerTheme;
    return Container(
      height: 80,
      color: trimmerTheme.scaffoldBackground,
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
                      icon: Icon(Icons.close, color: trimmerTheme.onToolbar),
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
                            color: isFavorite
                                ? trimmerTheme.favorite
                                : trimmerTheme.onToolbar,
                          ),
                          tooltip: context.hujiL10n.favoriteSegment,
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
            return Center(
              child: CircularProgressIndicator(
                color: context.trimmerTheme.active,
              ),
            );
          }

          return Column(
            children: [
              Expanded(flex: 3, child: _buildVideoPreview(context)),
              _buildSegmentOverview(context),
              _buildControls(context),
              Expanded(
                flex: 2,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: context.trimmerLayout.timelineContentHeight,
                  ),
                  child: _buildTrimViewer(context),
                ),
              ),
              _buildVideoProgressControl(context),
              _buildBottomToolbar(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVideoPreview(BuildContext context) {
    final trimmerTheme = context.trimmerTheme;
    return Container(
      width: double.infinity,
      color: trimmerTheme.previewBackground,
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
                decoration: BoxDecoration(
                  color: trimmerTheme.playOverlayBackground,
                  shape: BoxShape.circle,
                ),
                child: BlocBuilder<TrimmerBloc, TrimmerState>(
                  buildWhen: (previous, current) =>
                      previous.isPlaying != current.isPlaying,
                  builder: (context, state) => Icon(
                    state.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: trimmerTheme.onToolbar,
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

  Widget _buildTrimViewer(BuildContext context) {
    final trimmerTheme = context.trimmerTheme;
    return ColoredBox(
      color: trimmerTheme.timelineBackground,
      child: const ScrollableTrimViewer(),
    );
  }

  Widget _buildVideoProgressControl(BuildContext context) {
    final trimmerTheme = context.trimmerTheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: 56,
      color: trimmerTheme.toolbarBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: BlocBuilder<TrimmerBloc, TrimmerState>(
        buildWhen: (previous, current) =>
            previous.currentMilliseconds != current.currentMilliseconds ||
            previous.totalDuration != current.totalDuration ||
            previous.isDragging != current.isDragging,
        builder: (context, state) => Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatTime(state.currentMilliseconds / 1000),
                  style: textTheme.labelSmall?.copyWith(
                    color: trimmerTheme.onToolbar,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  formatTime(state.totalDuration / 1000),
                  style: textTheme.labelSmall?.copyWith(
                    color: trimmerTheme.onToolbarMuted,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2),
            _TrimmerProgressSlider(
              totalDurationMs: state.totalDuration.round(),
              currentMs: state.currentMilliseconds,
              isDragging: state.isDragging,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final trimmerTheme = context.trimmerTheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: 60,
      color: trimmerTheme.toolbarBackground,
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
                style: textTheme.bodyMedium?.copyWith(
                  color: trimmerTheme.onToolbar,
                ),
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
                              ? trimmerTheme.active
                              : trimmerTheme.onToolbar,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '慢放',
                          style: textTheme.labelSmall?.copyWith(
                            color: state.isSlowMotion
                                ? trimmerTheme.active
                                : trimmerTheme.onToolbar,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(width: 8),
              BlocBuilder<TrimmerBloc, TrimmerState>(
                buildWhen: (previous, current) =>
                    previous.playbackSpeed != current.playbackSpeed,
                builder: (context, state) {
                  return _buildSpeedMenu(context, state);
                },
              ),
              SizedBox(width: 8),
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
                      color: trimmerTheme.onToolbar,
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
    final trimmerTheme = context.trimmerTheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: 60,
      color: trimmerTheme.scaffoldBackground,
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
                        border: Border.all(color: trimmerTheme.segmentBorder),
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
                        icon: Icon(Icons.add, color: trimmerTheme.onToolbar),
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
                                  ? trimmerTheme.segmentSelectedBorder
                                  : trimmerTheme.segmentBorder,
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
                                      style: textTheme.labelSmall?.copyWith(
                                        color: trimmerTheme.onToolbar,
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
                                      ? trimmerTheme
                                          .segmentChipSelectedBackground
                                      : trimmerTheme.segmentChipBackground,
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(7),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    ' ${formatSegmentDuration(segment.startTime / 1000, precision: 0)} - ${formatSegmentDuration(segment.endTime / 1000, precision: 0)}',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: isSelected
                                          ? trimmerTheme.onActive
                                          : trimmerTheme.onToolbar,
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
    final trimmerTheme = context.trimmerTheme;
    return Container(
      height: 80,
      color: trimmerTheme.toolbarBackground,
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
                context: context,
                icon: Icons.content_cut,
                label: context.hujiL10n.trimSplitLabel,
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
            context: context,
            icon: Icons.add,
            label: context.hujiL10n.addClipSegmentLabel,
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
                    context: context,
                    icon: Icons.play_arrow,
                    label: context.hujiL10n.playSelectedSegmentOnly,
                    onTap: () {
                      if (context.mounted && hasActiveSegments) {
                        context.read<TrimmerBloc>().add(
                          TrimmerTogglePlaySelectedSegmentOnly(),
                        );
                      }
                    },
                    color: trimmerState.playSelectedSegmentOnly
                        ? trimmerTheme.active
                        : trimmerTheme.onToolbar,
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
                context: context,
                icon: Icons.delete,
                label: context.hujiL10n.actionDelete,
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
    final trimmerTheme = context.trimmerTheme;
    return StatefulBuilder(
      builder: (context, setState) {
        return PopupMenuButton<bool>(
          icon: Icon(Icons.speed, color: trimmerTheme.onToolbar, size: 20),
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          color: trimmerTheme.popupSurface,
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
    final trimmerTheme = context.trimmerTheme;
    final textTheme = Theme.of(context).textTheme;
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
          color: isSelected
              ? trimmerTheme.active
              : trimmerTheme.popupSurface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? trimmerTheme.active
                : trimmerTheme.segmentBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: isSelected ? trimmerTheme.onActive : trimmerTheme.onToolbar,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isEnabled = true,
    Color? color,
  }) {
    final trimmerTheme = context.trimmerTheme;
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isEnabled ? (color ?? trimmerTheme.onToolbar) : trimmerTheme.disabled,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: isEnabled ? trimmerTheme.onToolbar : trimmerTheme.disabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrimmerProgressSlider extends StatefulWidget {
  final int totalDurationMs;
  final int currentMs;
  final bool isDragging;

  const _TrimmerProgressSlider({
    required this.totalDurationMs,
    required this.currentMs,
    required this.isDragging,
  });

  @override
  State<_TrimmerProgressSlider> createState() => _TrimmerProgressSliderState();
}

class _TrimmerProgressSliderState extends State<_TrimmerProgressSlider> {
  bool _scrubbing = false;
  double? _scrubFraction;
  int _pendingSeekMs = 0;

  @override
  Widget build(BuildContext context) {
    final trimmerTheme = context.trimmerTheme;
    final total = widget.totalDurationMs;
    final fraction = total > 0
        ? (_scrubbing
                ? (_scrubFraction ??
                    (widget.currentMs / total).clamp(0.0, 1.0))
                : (widget.currentMs / total).clamp(0.0, 1.0))
        : 0.0;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: trimmerTheme.sliderActiveTrack,
        inactiveTrackColor: trimmerTheme.sliderInactiveTrack,
        thumbColor: trimmerTheme.sliderThumb,
        overlayColor: trimmerTheme.sliderOverlay,
        thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: widget.isDragging || _scrubbing ? 8 : 6,
        ),
        trackHeight: 2,
        overlayShape: RoundSliderOverlayShape(
          overlayRadius: widget.isDragging || _scrubbing ? 16 : 12,
        ),
        trackShape: const RoundedRectSliderTrackShape(),
        valueIndicatorColor: trimmerTheme.active,
        valueIndicatorTextStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: trimmerTheme.onActive,
          fontWeight: FontWeight.w500,
        ),
        showValueIndicator: widget.isDragging || _scrubbing
            ? ShowValueIndicator.always
            : ShowValueIndicator.never,
      ),
      child: Slider(
        value: fraction,
        onChangeStart: (_) {
          setState(() => _scrubbing = true);
          context.read<TrimmerBloc>().add(const TrimmerScrubStart());
        },
        onChanged: (value) {
          setState(() => _scrubFraction = value);
          _pendingSeekMs = (value * total).round();
          Throttles.throttle(
            'trimmer_scrub_seek',
            const Duration(milliseconds: 200),
            () {
              if (context.mounted) {
                context.read<TrimmerBloc>().add(
                  TrimmerSeekTo(Duration(milliseconds: _pendingSeekMs)),
                );
              }
            },
          );
        },
        onChangeEnd: (value) {
          Throttles.cancel('trimmer_scrub_seek');
          setState(() {
            _scrubbing = false;
            _scrubFraction = null;
          });
          if (context.mounted) {
            context.read<TrimmerBloc>().add(
              TrimmerScrubEnd((value * total).round()),
            );
          }
        },
      ),
    );
  }
}
