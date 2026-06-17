import 'dart:convert';
import 'dart:io';

import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:path/path.dart' as p;

/// Relative paths under huji-app project root.
const pingPongTestVideoRel = 'test/fixtures/video/test.mp4';
const pingPongGoldenRel = 'test/fixtures/autoclip/test_mp4_pingpong.json';
const badmintonTestVideoRel = 'test/fixtures/video/blue.mp4';
const badmintonGoldenRel = 'test/fixtures/autoclip/blue_mp4_badminton.json';

/// Finds huji-app root (directory containing pubspec.yaml).
Directory findAppRoot({Directory? start}) {
  var dir = start ?? Directory.current;
  while (true) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      break;
    }
    dir = parent;
  }
  throw StateError(
    'Could not locate huji-app root (pubspec.yaml). cwd=${Directory.current.path}',
  );
}

File resolveFixtureFile(String relativePath, {Directory? appRoot}) {
  final root = appRoot ?? findAppRoot();
  final file = File(p.join(root.path, relativePath));
  if (!file.existsSync()) {
    throw StateError('Fixture not found: ${file.path}');
  }
  return file;
}

String resolvePingPongTestVideo({Directory? appRoot}) {
  final fromEnv = Platform.environment['HUJI_TEST_VIDEO'];
  if (fromEnv != null && fromEnv.isNotEmpty && File(fromEnv).existsSync()) {
    return File(fromEnv).resolveSymbolicLinksSync();
  }
  return resolveFixtureFile(pingPongTestVideoRel, appRoot: appRoot).path;
}

String resolveBadmintonTestVideo({Directory? appRoot}) {
  final fromEnv = Platform.environment['HUJI_BADMINTON_TEST_VIDEO'];
  if (fromEnv != null && fromEnv.isNotEmpty && File(fromEnv).existsSync()) {
    return File(fromEnv).resolveSymbolicLinksSync();
  }
  return resolveFixtureFile(badmintonTestVideoRel, appRoot: appRoot).path;
}

File resolvePingPongGoldenFile({Directory? appRoot}) {
  return resolveFixtureFile(pingPongGoldenRel, appRoot: appRoot);
}

File resolveBadmintonGoldenFile({Directory? appRoot}) {
  return resolveFixtureFile(badmintonGoldenRel, appRoot: appRoot);
}

Map<String, dynamic> loadGoldenJson(String relativePath, {Directory? appRoot}) {
  final text = resolveFixtureFile(relativePath, appRoot: appRoot).readAsStringSync();
  return json.decode(text) as Map<String, dynamic>;
}

Map<String, dynamic> loadPingPongGolden({Directory? appRoot}) {
  return loadGoldenJson(pingPongGoldenRel, appRoot: appRoot);
}

Map<String, dynamic> loadBadmintonGolden({Directory? appRoot}) {
  return loadGoldenJson(badmintonGoldenRel, appRoot: appRoot);
}

/// Algorithm-aligned clip config (see huji-algorithm application_dev.yml).
PingPongVideoClipConfigReqVo algorithmPingPongConfig() {
  return PingPongVideoClipConfigReqVo(
    greatBallEditing: true,
    removeReplay: true,
    mergeFireBallAndPlayBall: true,
    minimumDurationSingleRound: 2.0,
    minimumDurationGreatBall: 10.0,
    reserveTimeBeforeSingleRound: 0.0,
    reserveTimeAfterSingleRound: 1.0,
  );
}

/// Algorithm-aligned badminton singles config (BadmintonAutoClipOptions defaults).
BadmintonVideoClipConfigReqVo algorithmBadmintonConfig() {
  return BadmintonVideoClipConfigReqVo(
    greatBallEditing: true,
    removeReplay: true,
    minimumDurationSingleRound: 2.0,
    minimumDurationGreatBall: 10.0,
    reserveTimeBeforeSingleRound: 1.0,
    reserveTimeAfterSingleRound: 1.0,
  );
}

String normalizeActionName(String action) {
  return action.replaceAll('_', '').toLowerCase();
}

List<Map<String, dynamic>> goldenAllMatchSegments(Map<String, dynamic> golden) {
  return (golden['all_match_segments'] as List).cast<Map<String, dynamic>>();
}

String resolveGoldenVideoPath(Map<String, dynamic> golden, {Directory? appRoot}) {
  final raw = golden['video'] as String;
  final file = File(raw);
  if (file.isAbsolute && file.existsSync()) {
    return file.path;
  }
  return resolveFixtureFile(raw, appRoot: appRoot).path;
}
