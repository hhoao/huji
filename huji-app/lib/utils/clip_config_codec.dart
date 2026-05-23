import 'dart:convert';

import 'package:restcut/api/models/autoclip/clip_models.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';

class ClipConfigCodec {
  static VideoClipConfigReqVo? decode(Object? raw, SportType? sportType) {
    if (raw == null) return null;
    if (raw is VideoClipConfigReqVo) {
      return normalize(raw, sportType);
    }

    if (raw is String) {
      return decode(jsonDecode(raw), sportType);
    }

    if (raw is Map<String, dynamic>) {
      return _decodeFromMap(raw, sportType);
    }

    if (raw is Map) {
      return _decodeFromMap(Map<String, dynamic>.from(raw), sportType);
    }

    return null;
  }

  static VideoClipConfigReqVo? normalize(
    VideoClipConfigReqVo? config,
    SportType? sportType,
  ) {
    if (config == null) return null;

    switch (sportType) {
      case SportType.pingpong:
        if (config is PingPongVideoClipConfigReqVo) {
          return config;
        }
        return PingPongVideoClipConfigReqVo(
          mode: config.mode,
          matchType: config.matchType,
          greatBallEditing: config.greatBallEditing,
          removeReplay: config.removeReplay,
          getMatchSegments: config.getMatchSegments,
          reserveTimeBeforeSingleRound: config.reserveTimeBeforeSingleRound,
          reserveTimeAfterSingleRound: config.reserveTimeAfterSingleRound,
          minimumDurationSingleRound: config.minimumDurationSingleRound,
          minimumDurationGreatBall: config.minimumDurationGreatBall,
        );
      case SportType.badminton:
        if (config is BadmintonVideoClipConfigReqVo) {
          return config;
        }
        return BadmintonVideoClipConfigReqVo(
          mode: config.mode,
          matchType: config.matchType,
          greatBallEditing: config.greatBallEditing,
          removeReplay: config.removeReplay,
          getMatchSegments: config.getMatchSegments,
          reserveTimeBeforeSingleRound: config.reserveTimeBeforeSingleRound,
          reserveTimeAfterSingleRound: config.reserveTimeAfterSingleRound,
          minimumDurationSingleRound: config.minimumDurationSingleRound,
          minimumDurationGreatBall: config.minimumDurationGreatBall,
        );
      case null:
        return config;
    }
  }

  static VideoClipConfigReqVo? _decodeFromMap(
    Map<String, dynamic> map,
    SportType? sportType,
  ) {
    switch (sportType) {
      case SportType.pingpong:
        return PingPongVideoClipConfigReqVo.fromJson(map);
      case SportType.badminton:
        return BadmintonVideoClipConfigReqVo.fromJson(map);
      case null:
        return VideoClipConfigReqVo.fromJson(map);
    }
  }
}
