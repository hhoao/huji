// 配置项类型
import 'package:path/path.dart' as path;
import 'package:restcut/api/models/autoclip/clip_models.dart';
import 'package:restcut/services/storage_service.dart' show storage;
import 'package:restcut/api/models/autoclip/video_models.dart';
import 'package:restcut/models/video.dart';
import 'package:restcut/utils/video_utils.dart';
import 'package:uuid/uuid.dart';

enum ConfigItemType { select, toggle, slider }

Future<RawVideoRecord> createRawVideoRecord(
  String? videoPath,
  SportType sportType,
  VideoClipConfigReqVo configValues, {
  ClipMode clipMode = ClipMode.existingVideo,
}) async {
  String? thumbnailPath;

  // 只有在已有视频模式下才生成缩略图
  if (clipMode == ClipMode.existingVideo) {
    final appCacheDir = storage.getApplicationDocumentsDirectory();
    thumbnailPath = await VideoUtils.generateVideoThumbnail(
      videoPath!,
      dirPath: path.join(
        appCacheDir.path,
        'raw_${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
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
  ) {
    switch (sportType) {
      case SportType.pingpong:
        return _getPingPongConfigItems(
          configValues as PingPongVideoClipConfigReqVo,
        );
      case SportType.badminton:
        return _getBadmintonConfigItems(
          configValues as BadmintonVideoClipConfigReqVo,
        );
    }
  }

  List<ConfigItem> _getPingPongConfigItems(
    PingPongVideoClipConfigReqVo configValues,
  ) {
    return [
      // 比赛类型
      ConfigItem(
        key: 'matchType',
        label: '比赛类型',
        type: ConfigItemType.select,
        value: configValues.matchType ?? MatchType.singlesMatch,
        selectOptions: [
          ConfigOption(label: '单打比赛', value: MatchType.singlesMatch),
          ConfigOption(
            label: '双打比赛',
            value: MatchType.doublesMatch,
            disabled: true,
          ),
        ],
      ),

      // 剪辑模式
      ConfigItem(
        key: 'mode',
        label: '剪辑模式',
        type: ConfigItemType.select,
        value: configValues.mode ?? ModeEnum.backendClip,
        selectOptions: [
          ConfigOption(label: '后台剪辑', value: ModeEnum.backendClip),
          ConfigOption(
            label: '自定义剪辑',
            value: ModeEnum.customClip,
            disabled: true,
          ),
        ],
      ),

      // 精彩球剪辑
      ConfigItem(
        key: 'greatBallEditing',
        label: '精彩球剪辑',
        tooltip: '自动剪辑单局时间长的精彩球',
        type: ConfigItemType.toggle,
        value: configValues.greatBallEditing ?? true,
      ),

      // 精彩球最小时长
      ConfigItem(
        key: 'minimumDurationGreatBall',
        label: '精彩球最小时长(秒)',
        tooltip: '精彩球最小时长（秒）',
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
        label: '移除回放',
        tooltip: '一般专业比赛才有，例如wtt中的回放',
        type: ConfigItemType.toggle,
        value: configValues.removeReplay ?? true,
      ),

      // 获取比赛片段
      ConfigItem(
        key: 'getMatchSegments',
        label: '获取比赛片段',
        type: ConfigItemType.toggle,
        value: configValues.getMatchSegments ?? true,
      ),

      // 合并发球和击球
      ConfigItem(
        key: 'mergeFireBallAndPlayBall',
        label: '合并发球和击球',
        tooltip: '勾选后，只有发球的回合（发球下网和失误）以及练球片段也会被剪辑进去',
        type: ConfigItemType.toggle,
        value: configValues.mergeFireBallAndPlayBall ?? true,
      ),

      // 最大发球时长
      ConfigItem(
        key: 'maxFireBallTime',
        label: '最大发球时长',
        tooltip: '限制发球时长(秒)',
        type: ConfigItemType.slider,
        value: configValues.maxFireBallTime ?? 3.0,
        sliderConfig: SliderConfig(min: 1, max: 10, step: 0.1, divisions: 9),
        visibleOn: (values) => values['mergeFireBallAndPlayBall'] == false,
      ),

      // 单回合前保留时间
      ConfigItem(
        key: 'reserveTimeBeforeSingleRound',
        label: '单回合前保留时间',
        tooltip: '单回合比赛开始前预留的时间（秒）',
        type: ConfigItemType.slider,
        value: configValues.reserveTimeBeforeSingleRound ?? 0.0,
        sliderConfig: SliderConfig(min: 0, max: 5, step: 0.1, divisions: 10),
      ),

      // 单回合后保留时长
      ConfigItem(
        key: 'reserveTimeAfterSingleRound',
        label: '单回合后保留时长(秒)',
        tooltip: '单回合比赛结束后预留的时间（秒）',
        type: ConfigItemType.slider,
        value: configValues.reserveTimeAfterSingleRound ?? 1.0,
        sliderConfig: SliderConfig(min: 0, max: 5, step: 0.1, divisions: 10),
      ),

      // 单回合最小时长
      ConfigItem(
        key: 'minimumDurationSingleRound',
        label: '单回合最小时长(秒)',
        tooltip: '单回合最小时长（秒）',
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
  ) {
    return [
      // 比赛类型
      ConfigItem(
        key: 'matchType',
        label: '比赛类型',
        type: ConfigItemType.select,
        value: configValues.matchType ?? MatchType.singlesMatch,
        selectOptions: [
          ConfigOption(label: '单打比赛', value: MatchType.singlesMatch),
          ConfigOption(
            label: '双打比赛',
            value: MatchType.doublesMatch,
            disabled: true,
          ),
        ],
      ),

      // 剪辑模式
      ConfigItem(
        key: 'mode',
        label: '剪辑模式',
        type: ConfigItemType.select,
        value: configValues.mode ?? ModeEnum.backendClip,
        selectOptions: [
          ConfigOption(label: '后台剪辑', value: ModeEnum.backendClip),
          ConfigOption(label: '自定义剪辑', value: ModeEnum.customClip),
        ],
      ),

      // 精彩球剪辑
      ConfigItem(
        key: 'greatBallEditing',
        label: '精彩球剪辑',
        type: ConfigItemType.toggle,
        value: configValues.greatBallEditing ?? true,
      ),

      // 移除回放
      ConfigItem(
        key: 'removeReplay',
        label: '移除回放',
        tooltip: '一般专业比赛才有',
        type: ConfigItemType.toggle,
        value: configValues.removeReplay ?? true,
      ),

      // 获取比赛片段
      ConfigItem(
        key: 'getMatchSegments',
        label: '获取比赛片段',
        type: ConfigItemType.toggle,
        value: configValues.getMatchSegments ?? true,
      ),

      // 单回合前保留时间
      ConfigItem(
        key: 'reserveTimeBeforeSingleRound',
        label: '单回合前保留时间',
        tooltip: '单回合比赛开始前预留的时间（秒）',
        type: ConfigItemType.slider,
        value: configValues.reserveTimeBeforeSingleRound ?? 1.0,
        sliderConfig: SliderConfig(min: 0, max: 5, step: 0.1, divisions: 10),
      ),

      // 单回合后保留时长
      ConfigItem(
        key: 'reserveTimeAfterSingleRound',
        label: '单回合后保留时长(秒)',
        tooltip: '单回合比赛结束后预留的时间（秒）',
        type: ConfigItemType.slider,
        value: configValues.reserveTimeAfterSingleRound ?? 1.0,
        sliderConfig: SliderConfig(min: 0, max: 5, step: 0.1, divisions: 10),
      ),

      // 单回合最小时长
      ConfigItem(
        key: 'minimumDurationSingleRound',
        label: '单回合最小时长(秒)',
        tooltip: '单回合最小时长（秒）',
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
        label: '精彩球最小时长(秒)',
        tooltip: '精彩球最小时长（秒）',
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
