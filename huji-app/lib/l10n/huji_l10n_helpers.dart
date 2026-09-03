import 'package:huji_app/models/video.dart';
import 'package:huji_app/l10n/app_localizations.dart';
import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/models/task.dart';
import 'package:permission_handler/permission_handler.dart';

/// Localized labels for [TaskTypeEnum] and [TaskStatusEnum].
extension HujiTaskL10n on HujiLocalizations {
  String taskTypeLabel(TaskTypeEnum type) => switch (type) {
    TaskTypeEnum.videoClip => taskTypeVideoClip,
    TaskTypeEnum.videoCompress => taskTypeVideoCompress,
    TaskTypeEnum.imageCompress => taskTypeImageCompress,
    TaskTypeEnum.videoUpload => taskTypeVideoUpload,
    TaskTypeEnum.download => taskTypeDownload,
    TaskTypeEnum.videoSegmentDetect => taskTypeVideoSegmentDetect,
    TaskTypeEnum.videoExport => taskTypeVideoExport,
  };

  String taskStatusLabel(TaskStatusEnum status) => switch (status) {
    TaskStatusEnum.pending => taskStatusPending,
    TaskStatusEnum.processing => taskStatusProcessing,
    TaskStatusEnum.completed => taskStatusCompleted,
    TaskStatusEnum.failed => taskStatusFailed,
    TaskStatusEnum.paused => taskStatusPaused,
    TaskStatusEnum.cancelled => taskStatusCancelledShort,
  };
}

extension TaskTypeEnumL10n on TaskTypeEnum {
  String localizedName(HujiLocalizations l10n) => l10n.taskTypeLabel(this);
}

extension TaskStatusEnumL10n on TaskStatusEnum {
  String localizedName(HujiLocalizations l10n) => l10n.taskStatusLabel(this);
}

extension HujiActionTypeL10n on HujiLocalizations {
  String actionTypeLabel(ActionType type) => switch (type) {
    ActionType.playBall => actionTypePlayBall,
    ActionType.fireBall => actionTypeFireBall,
    ActionType.pickBall => actionTypePickBall,
    ActionType.transition => actionTypeTransition,
    ActionType.playback => actionTypePlayback,
  };
}

extension ActionTypeL10n on ActionType {
  String localizedName(HujiLocalizations l10n) => l10n.actionTypeLabel(this);
}

extension HujiVideoRecordL10n on HujiLocalizations {
  String processStatusLabel(ProcessStatus status) => switch (status) {
    ProcessStatus.preparing => processStatusPreparing,
    ProcessStatus.processing => taskStatusProcessing,
    ProcessStatus.completed => taskStatusCompleted,
    ProcessStatus.failed => taskStatusFailed,
  };

  String sportTypeLabel(SportType type) => switch (type) {
    SportType.pingpong => sportTypePingpong,
    SportType.badminton => sportTypeBadminton,
  };

  String videoProcessTypeLabel(VideoProcessType type) => switch (type) {
    VideoProcessType.raw => videoProcessTypeRaw,
    VideoProcessType.greatMatch => videoProcessTypeGreatMatch,
    VideoProcessType.allMatchMerged => videoProcessTypeAllMatchMerged,
  };

  String matchTypeLabel(MatchType type) => switch (type) {
    MatchType.doublesMatch => matchTypeDoubles,
    MatchType.singlesMatch => matchTypeSingles,
  };

  String modeLabel(ModeEnum mode) => switch (mode) {
    ModeEnum.backendClip => backendClip,
    ModeEnum.customClip => customClip,
  };

  String booleanLabel(bool value) => value ? booleanYes : booleanNo;

  String localVideoProcessStatusLabel(LocalVideoProcessStatusEnum status) =>
      switch (status) {
        LocalVideoProcessStatusEnum.pending => localVideoStatusPending,
        LocalVideoProcessStatusEnum.processing => localVideoStatusProcessing,
        LocalVideoProcessStatusEnum.completed => taskStatusCompleted,
      };

  String permissionNameLabel(Permission permission) => switch (permission) {
    Permission.notification => permissionNameNotification,
    Permission.storage => permissionNameStorage,
    Permission.camera => permissionNameCamera,
    Permission.microphone => permissionNameMicrophone,
    Permission.photos => permissionNamePhotos,
    Permission.videos => permissionNameVideos,
    Permission.audio => permissionNameAudio,
    _ => permissionNameUnknown,
  };

  String permissionDetailLabel(Permission permission) => switch (permission) {
    Permission.notification => permissionDetailNotification,
    Permission.storage => permissionDetailStorage,
    Permission.camera => permissionDetailCamera,
    Permission.microphone => permissionDetailMicrophone,
    Permission.photos => permissionDetailPhotos,
    Permission.videos => permissionDetailVideos,
    Permission.audio => permissionDetailAudio,
    _ => permissionDetailDefault,
  };

  String permissionStatusLabel(PermissionStatus status) => switch (status) {
    PermissionStatus.granted => permissionStatusGranted,
    PermissionStatus.denied => permissionStatusDenied,
    PermissionStatus.restricted => permissionStatusRestricted,
    PermissionStatus.limited => permissionStatusLimited,
    PermissionStatus.permanentlyDenied => permissionStatusPermanentlyDenied,
    _ => permissionStatusUnknown,
  };

  String permissionSuggestionLabel(
    Permission permission,
    PermissionStatus status,
  ) =>
      switch (status) {
        PermissionStatus.denied => permissionSuggestionDenied,
        PermissionStatus.permanentlyDenied => permissionSuggestionPermanentlyDenied,
        PermissionStatus.restricted => permissionSuggestionRestricted,
        PermissionStatus.limited => permissionSuggestionLimited,
        _ => '',
      };
}
