import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/shortcuts/command_ids.dart';
import 'package:huji_app/shortcuts/command_tooltip_label.dart';
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
import 'package:shared_ui/shared_ui.dart';

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
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          // 浅色主题下状态栏图标用深色，避免系统默认黑底状态栏压在浅色顶栏上
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                trimmerTheme.scaffoldBackground.computeLuminance() > 0.5
                    ? Brightness.dark
                    : Brightness.light,
            statusBarBrightness:
                trimmerTheme.scaffoldBackground.computeLuminance() > 0.5
                    ? Brightness.light
                    : Brightness.dark,
          ),
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
          // 内容比较；引用比较恒真会让选中变化等无关更新也触发
          // onSegmentsChanged（下游是落库和播放项重建）
          listenWhen: (previous, current) =>
              !previous.sameActiveSegments(current),
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
              Expanded(child: _buildVideoPreview(context)),
              if (!PlatformCapability.isDesktop)
                _buildSegmentOverview(context),
              _buildControls(context),
              SizedBox(
                height: context.trimmerLayout.timelineContentHeight,
                child: _buildTrimViewer(context),
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
            child: _buildPlayOverlay(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayOverlay(BuildContext context) {
    final trimmerTheme = context.trimmerTheme;
    final l10n = context.hujiL10n;
    final tooltip = PlatformCapability.isDesktop
        ? commandTooltipLabel(
            context,
            label: l10n.shortcutsCommandPrecisionPlayPause,
            commandId: CommandIds.precisionPlayPause,
          )
        : null;

    Widget overlay = BlocBuilder<TrimmerBloc, TrimmerState>(
      buildWhen: (previous, current) =>
          previous.isPlaying != current.isPlaying,
      builder: (context, state) {
        final icon = Icon(
          state.isPlaying ? Icons.pause : Icons.play_arrow,
          color: trimmerTheme.onToolbar,
          size: 40,
        );
        final circle = Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: trimmerTheme.playOverlayBackground,
            shape: BoxShape.circle,
          ),
          child: Center(child: icon),
        );
        if (!PlatformCapability.isDesktop) {
          return GestureDetector(
            onTap: () {
              if (context.mounted) {
                context.read<TrimmerBloc>().add(TrimmerTogglePlayPause());
              }
            },
            child: circle,
          );
        }
        return TpHover(
          shape: TpPressableShape.circle,
          width: 80,
          height: 80,
          hoverColor: trimmerTheme.onToolbar.withValues(alpha: 0.12),
          onTap: () {
            if (context.mounted) {
              context.read<TrimmerBloc>().add(TrimmerTogglePlayPause());
            }
          },
          child: circle,
        );
      },
    );

    if (tooltip != null) {
      overlay = Tooltip(message: tooltip, child: overlay);
    }
    return overlay;
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
    final layout = context.trimmerLayout;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: layout.toolbarHeight,
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
                    fontSize: layout.segmentLabelFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  formatTime(state.totalDuration / 1000),
                  style: textTheme.labelSmall?.copyWith(
                    color: trimmerTheme.onToolbarMuted,
                    fontSize: layout.segmentLabelFontSize,
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
    final layout = context.trimmerLayout;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: layout.toolbarHeight,
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
                  return _buildSlowMotionControl(context, state);
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
                  if (PlatformCapability.isDesktop) {
                    return TpIconButton(
                      icon: state.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: trimmerTheme.onToolbar,
                      tooltip: commandTooltipLabel(
                        context,
                        label: context
                            .hujiL10n
                            .shortcutsCommandPrecisionPlayPause,
                        commandId: CommandIds.precisionPlayPause,
                      ),
                      onTap: () {
                        if (context.mounted) {
                          context.read<TrimmerBloc>().add(
                            TrimmerTogglePlayPause(),
                          );
                        }
                      },
                    );
                  }
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
    final layout = context.trimmerLayout;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: layout.segmentOverviewHeight,
      color: trimmerTheme.scaffoldBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: BlocBuilder<ClipSegmentBloc, ClipSegmentState>(
              // 片段内容或选中态变化时才重建；引用比较恒真，
              // 会让拖拽外的所有状态更新都重建整条片段条
              buildWhen: (previous, current) =>
                  !previous.sameActiveSegments(current) ||
                  previous.selectedSegment != current.selectedSegment,
              builder: (context, state) => ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: state.activeSegments.length + 1,
                itemBuilder: (context, index) {
                  final activeSegments = state.activeSegments;
                  if (index == activeSegments.length) {
                    return Container(
                      width: layout.segmentChipMinWidth,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: trimmerTheme.segmentBorder),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: PlatformCapability.isDesktop
                          ? TpIconButton(
                              icon: Icons.add,
                              color: trimmerTheme.onToolbar,
                              tooltip: commandTooltipLabel(
                                context,
                                label: context.hujiL10n.addClipSegmentLabel,
                                commandId: CommandIds.precisionAddSegment,
                              ),
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
                            )
                          : IconButton(
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
                              icon: Icon(
                                Icons.add,
                                color: trimmerTheme.onToolbar,
                              ),
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
                                        fontSize: layout.segmentLabelFontSize,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: layout.segmentChipFooterHeight,
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
                                      fontSize: layout.segmentLabelFontSize,
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
                commandId: CommandIds.precisionSplit,
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
            commandId: CommandIds.precisionAddSegment,
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
                    commandId: CommandIds.precisionPlaySelectedOnly,
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
                commandId: CommandIds.precisionDeleteSegment,
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

  Widget _buildSlowMotionControl(BuildContext context, TrimmerState state) {
    final trimmerTheme = context.trimmerTheme;
    final layout = context.trimmerLayout;
    final textTheme = Theme.of(context).textTheme;
    final label = context.hujiL10n.shortcutsCommandPrecisionToggleSlowMotion;
    final onTap = () {
      if (context.mounted) {
        context.read<TrimmerBloc>().add(TrimmerToggleSlowMotion());
      }
    };
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.slow_motion_video,
          color: state.isSlowMotion
              ? trimmerTheme.active
              : trimmerTheme.onToolbar,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: state.isSlowMotion
                ? trimmerTheme.active
                : trimmerTheme.onToolbar,
            fontSize: layout.segmentLabelFontSize,
          ),
        ),
      ],
    );

    if (!PlatformCapability.isDesktop) {
      return GestureDetector(onTap: onTap, child: content);
    }

    return Tooltip(
      message: commandTooltipLabel(
        context,
        label: label,
        commandId: CommandIds.precisionToggleSlowMotion,
      ),
      child: TpHover(
        borderRadius: BorderRadius.circular(8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        backgroundColor: state.isSlowMotion
            ? trimmerTheme.active.withValues(alpha: 0.16)
            : null,
        hoverColor: trimmerTheme.onToolbar.withValues(alpha: 0.1),
        onTap: onTap,
        child: content,
      ),
    );
  }

  Widget _buildSpeedMenu(BuildContext context, TrimmerState state) {
    final trimmerTheme = context.trimmerTheme;
    final button = PopupMenuButton<bool>(
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

    if (!PlatformCapability.isDesktop) return button;

    return TpHover(
      borderRadius: BorderRadius.circular(8),
      hoverColor: trimmerTheme.onToolbar.withValues(alpha: 0.1),
      child: button,
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
    String? commandId,
    bool isEnabled = true,
    Color? color,
  }) {
    final trimmerTheme = context.trimmerTheme;
    final layout = context.trimmerLayout;
    final textTheme = Theme.of(context).textTheme;
    final iconColor =
        isEnabled ? (color ?? trimmerTheme.onToolbar) : trimmerTheme.disabled;
    final textColor =
        isEnabled ? trimmerTheme.onToolbar : trimmerTheme.disabled;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: textColor,
              fontSize: layout.segmentLabelFontSize,
            ),
          ),
        ],
      ),
    );

    if (!PlatformCapability.isDesktop) {
      return GestureDetector(
        onTap: isEnabled ? onTap : null,
        child: content,
      );
    }

    final tooltip = commandId != null
        ? commandTooltipLabel(context, label: label, commandId: commandId)
        : label;

    return Tooltip(
      message: tooltip,
      child: TpHover(
        enabled: isEnabled,
        borderRadius: BorderRadius.circular(8),
        backgroundColor: color == trimmerTheme.active
            ? trimmerTheme.active.withValues(alpha: 0.16)
            : null,
        hoverColor: trimmerTheme.onToolbar.withValues(alpha: 0.1),
        onTap: isEnabled ? onTap : null,
        child: content,
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
