import 'package:media_kit/media_kit.dart' as media_kit;

import 'package:huji_app/shortcuts/command_bus.dart';

Future<void> seekMediaKitPlayerBySeconds(
  media_kit.Player player,
  int deltaSeconds,
) async {
  final duration = player.state.duration;
  if (duration == Duration.zero) return;
  final stepMs = CommandInvocationScope.instance.isRepeat ? 5000 : 1000;
  final position = player.state.position;
  final nextMs = (position.inMilliseconds + deltaSeconds * stepMs)
      .clamp(0, duration.inMilliseconds);
  await player.seek(Duration(milliseconds: nextMs));
}
