// 配置项类型
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:huji_app/services/storage_service.dart' show storage;
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/utils/clip_config_codec.dart';
import 'package:huji_app/utils/video_utils.dart';
import 'package:huji_app/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

enum ConfigItemType { select, toggle, slider }

Future<RawVideoRecord> createRawVideoRecord(
  String? videoPath,
  SportType sportType,
  VideoClipConfigReqVo configValues, {
  ClipMode clipMode = ClipMode.existingVideo,
  required HujiLocalizations l10n,
}) async {
  String? thumbnailPath;

  // 只有在已有视频模式下才生成缩略图
  if (clipMode == ClipMode.existingVideo) {
    if (videoPath == null || videoPath.isEmpty) {
      throw Exception(l10n.selectVideoFileFirst);
    }
    if (!await File(videoPath).exists()) {
      throw Exception(l10n.videoFileNotFound(videoPath));
    }
    final appCacheDir = storage.getApplicationDocumentsDirectory();
    try {
      thumbnailPath = await VideoUtils.generateVideoThumbnail(
        videoPath,
        dirPath: path.join(
          appCacheDir.path,
          'raw_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
    } catch (e) {
      throw Exception(l10n.generateThumbnailFailed(videoPath, e.toString()));
    }
  }

  final rawRecord = RawVideoRecord(
    id: Uuid().v4(),
    processStatus: LocalVideoProcessStatusEnum.pending,
    sportType: sportType,
    filePath: clipMode == ClipMode.existingVideo ? videoPath : null,
    thumbnailPath: thumbnailPath,
    clipMode: clipMode,
    videoClipConfigReqVo: configValues,
  );

  return rawRecord;
}

VideoClipConfigReqVo getDefaultConfig(SportType sportType) {
  if (sportType == SportType.pingpong) {
    return PingPongVideoClipConfigReqVo(
      mode: ModeEnum.backendClip,
      matchType: MatchType.singlesMatch,
      greatBallEditing: true,
      removeReplay: true,
      getMatchSegments: true,
      reserveTimeBeforeSingleRound: 0.0,
      reserveTimeAfterSingleRound: 1.0,
      minimumDurationSingleRound: 2.0,
      minimumDurationGreatBall: 10.0,
      maxFireBallTime: 2.0,
      mergeFireBallAndPlayBall: true,
    );
  } else {
    return BadmintonVideoClipConfigReqVo(
      mode: ModeEnum.backendClip,
      matchType: MatchType.singlesMatch,
      greatBallEditing: true,
      removeReplay: true,
      getMatchSegments: true,
      reserveTimeBeforeSingleRound: 1.0,
      reserveTimeAfterSingleRound: 1.0,
      minimumDurationSingleRound: 3.0,
      minimumDurationGreatBall: 20.0,
    );
  }
}

// 配置项定义
class ConfigItem {
  final String key;
  final String label;
  final String? tooltip;
  final ConfigItemType type;
  final dynamic value;
  final List<ConfigOption>? selectOptions;
  final SliderConfig? sliderConfig;
  final bool Function(Map<String, dynamic>)? visibleOn;

  ConfigItem({
    required this.key,
    required this.label,
    this.tooltip,
    required this.type,
    required this.value,
    this.selectOptions,
    this.sliderConfig,
    this.visibleOn,
  });
}

// 选择项配置
class ConfigOption {
  final String label;
  final dynamic value;
  final bool disabled;

  ConfigOption({
    required this.label,
    required this.value,
    this.disabled = false,
  });
}

// 滑块配置
class SliderConfig {
  final double min;
  final double max;
  final double step;
  final int? divisions;

  SliderConfig({
    required this.min,
    required this.max,
    required this.step,
    this.divisions,
  });
}

class ConfigItems {
  List<ConfigItem> getConfigItems(
    SportType sportType,
    VideoClipConfigReqVo configValues,
    HujiLocalizations l10n,
  ) {
    final normalizedConfig = ClipConfigCodec.normalize(configValues, sportType);
    switch (sportType) {
      case SportType.pingpong:
        return _getPingPongConfigItems(
          normalizedConfig as PingPongVideoClipConfigReqVo,
          l10n,
        );
      case SportType.badminton:
        return _getBadmintonConfigItems(
          normalizedConfig as BadmintonVideoClipConfigReqVo,
          l10n,
        );
    }
  }

  List<ConfigItem> _getPingPongConfigItems(
    PingPongVideoClipConfigReqVo configValues,
    HujiLocalizations l10n,
  ) {
    return [
      // 比赛类型
      ConfigItem(
        key: 'matchType',
        label: l10n.matchType,
        type: ConfigItemType.select,
        value: configValues.matchType ?? MatchType.singlesMatch,
        selectOptions: [
          ConfigOption(label: l10n.matchTypeSingles, value: MatchType.singlesMatch),
          ConfigOption(
            label: l10n.matchTypeDoubles,
            value: MatchType.doublesMatch,
            disabled: true,
          ),
        ],
      ),

      // 剪辑模式
      ConfigItem(
        key: 'mode',
        label: l10n.clipMode,
        type: ConfigItemType.select,
        value: configValues.mode ?? ModeEnum.backendClip,
        selectOptions: [
          ConfigOption(label: l10n.backendClip, value: ModeEnum.backendClip),
          ConfigOption(
            label: l10n.customClip,
            value: ModeEnum.customClip,
            disabled: true,
          ),
        ],
      ),

      // 精彩球剪辑
      ConfigItem(
        key: 'greatBallEditing',
        label: l10n.highlightClip,
        tooltip: l10n.highlightClipTooltip,
        type: ConfigItemType.toggle,
        value: configValues.greatBallEditing ?? true,
      ),

      // 精彩球最小时长
      ConfigItem(
        key: 'minimumDurationGreatBall',
        label: l10n.minHighlightDurationSeconds,
        tooltip: l10n.minHighlightDurationTooltip,
        type: ConfigItemType.slider,
        value: configValues.minimumDurationGreatBall ?? 10.0,
        sliderConfig: SliderConfig(
          min: 5.0,
          max: 60.0,
          step: 0.1,
          divisions: 55,
        ),
        visibleOn: (values) => values['greatBallEditing'] == true,
      ),

      // 移除回放
      ConfigItem(
        key: 'removeReplay',
        label: l10n.removeReplay,
        tooltip: l10n.removeReplayTooltipPro,
        type: ConfigItemType.toggle,
        value: configValues.removeReplay ?? true,
      ),

      // 获取比赛片段
      ConfigItem(
        key: 'getMatchSegments',
        label: l10n.getMatchSegments,
        type: ConfigItemType.toggle,
        value: configValues.getMatchSegments ?? true,
      ),

      // 合并发球和击球
      ConfigItem(
        key: 'mergeFireBallAndPlayBall',
        label: l10n.mergeServeAndHit,
        tooltip: l10n.mergeServeAndHitTooltip,
        type: ConfigItemType.toggle,
        value: configValues.mergeFireBallAndPlayBall ?? true,
      ),

      // 最大发球时长
      ConfigItem(
        key: 'maxFireBallTime',
        label: l10n.maxServeDuration,
        tooltip: l10n.maxServeDurationTooltip,
        type: ConfigItemType.slider,
        value: configValues.maxFireBallTime ?? 3.0,
        sliderConfig: SliderConfig(min: 1, max: 10, step: 0.1, divisions: 9),
        visibleOn: (values) => values['mergeFireBallAndPlayBall'] == false,
      ),

      // 单回合前保留时间
      ConfigItem(
        key: 'reserveTimeBeforeSingleRound',
        label: l10n.reserveBeforeRound,
        tooltip: l10n.reserveBeforeRoundTooltip,
        type: ConfigItemType.slider,
        value: configValues.reserveTimeBeforeSingleRound ?? 0.0,
        sliderConfig: SliderConfig(min: 0, max: 5, step: 0.1, divisions: 10),
      ),

      // 单回合后保留时长
      ConfigItem(
        key: 'reserveTimeAfterSingleRound',
        label: l10n.reserveAfterRound,
        tooltip: l10n.reserveAfterRoundTooltip,
        type: ConfigItemType.slider,
        value: configValues.reserveTimeAfterSingleRound ?? 1.0,
        sliderConfig: SliderConfig(min: 0, max: 5, step: 0.1, divisions: 10),
      ),

      // 单回合最小时长
      ConfigItem(
        key: 'minimumDurationSingleRound',
        label: l10n.minRoundDuration,
        tooltip: l10n.minRoundDurationTooltip,
        type: ConfigItemType.slider,
        value: configValues.minimumDurationSingleRound ?? 3.0,
        sliderConfig: SliderConfig(
          min: 1.0,
          max: 10.0,
          step: 0.1,
          divisions: 9,
        ),
      ),
    ];
  }

  List<ConfigItem> _getBadmintonConfigItems(
    BadmintonVideoClipConfigReqVo configValues,
    HujiLocalizations l10n,
  ) {
    return [
      // 比赛类型
      ConfigItem(
        key: 'matchType',
        label: l10n.matchType,
        type: ConfigItemType.select,
        value: configValues.matchType ?? MatchType.singlesMatch,
        selectOptions: [
          ConfigOption(label: l10n.matchTypeSingles, value: MatchType.singlesMatch),
          ConfigOption(
            label: l10n.matchTypeDoubles,
            value: MatchType.doublesMatch,
            disabled: true,
          ),
        ],
      ),

      // 剪辑模式
      ConfigItem(
        key: 'mode',
        label: l10n.clipMode,
        type: ConfigItemType.select,
        value: configValues.mode ?? ModeEnum.backendClip,
        selectOptions: [
          ConfigOption(label: l10n.backendClip, value: ModeEnum.backendClip),
          ConfigOption(label: l10n.customClip, value: ModeEnum.customClip),
        ],
      ),

      // 精彩球剪辑
      ConfigItem(
        key: 'greatBallEditing',
        label: l10n.highlightClip,
        type: ConfigItemType.toggle,
        value: configValues.greatBallEditing ?? true,
      ),

      // 移除回放
      ConfigItem(
        key: 'removeReplay',
        label: l10n.removeReplay,
        tooltip: l10n.removeReplayTooltipShort,
        type: ConfigItemType.toggle,
        value: configValues.removeReplay ?? true,
      ),

      // 获取比赛片段
      ConfigItem(
        key: 'getMatchSegments',
        label: l10n.getMatchSegments,
        type: ConfigItemType.toggle,
        value: configValues.getMatchSegments ?? true,
      ),

      // 单回合前保留时间
      ConfigItem(
        key: 'reserveTimeBeforeSingleRound',
        label: l10n.reserveBeforeRound,
        tooltip: l10n.reserveBeforeRoundTooltip,
        type: ConfigItemType.slider,
        value: configValues.reserveTimeBeforeSingleRound ?? 1.0,
        sliderConfig: SliderConfig(min: 0, max: 5, step: 0.1, divisions: 10),
      ),

      // 单回合后保留时长
      ConfigItem(
        key: 'reserveTimeAfterSingleRound',
        label: l10n.reserveAfterRound,
        tooltip: l10n.reserveAfterRoundTooltip,
        type: ConfigItemType.slider,
        value: configValues.reserveTimeAfterSingleRound ?? 1.0,
        sliderConfig: SliderConfig(min: 0, max: 5, step: 0.1, divisions: 10),
      ),

      // 单回合最小时长
      ConfigItem(
        key: 'minimumDurationSingleRound',
        label: l10n.minRoundDuration,
        tooltip: l10n.minRoundDurationTooltip,
        type: ConfigItemType.slider,
        value: configValues.minimumDurationSingleRound ?? 5.0,
        sliderConfig: SliderConfig(
          min: 3.0,
          max: 15.0,
          step: 0.1,
          divisions: 12,
        ),
      ),

      // 精彩球最小时长
      ConfigItem(
        key: 'minimumDurationGreatBall',
        label: l10n.minHighlightDurationSeconds,
        tooltip: l10n.minHighlightDurationTooltip,
        type: ConfigItemType.slider,
        value: configValues.minimumDurationGreatBall ?? 10.0,
        sliderConfig: SliderConfig(
          min: 5.0,
          max: 60.0,
          step: 0.1,
          divisions: 55,
        ),
      ),
    ];
  }
}
