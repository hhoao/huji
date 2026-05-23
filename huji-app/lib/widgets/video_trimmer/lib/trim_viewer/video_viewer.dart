import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoViewer extends StatelessWidget {
  final VideoPlayerController? videoPlayerController;

  final Color borderColor;

  final double borderWidth;

  final EdgeInsets padding;

  const VideoViewer({
    super.key,
    required this.videoPlayerController,
    this.borderColor = Colors.transparent,
    this.borderWidth = 0.0,
    this.padding = const EdgeInsets.all(0.0),
  });

  @override
  Widget build(BuildContext context) {
    final controller = videoPlayerController;
    return controller == null
        ? Container()
        : Padding(
            padding: const EdgeInsets.all(0.0),
            child: Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: controller.value.isInitialized
                    ? Container(
                        foregroundDecoration: BoxDecoration(
                          border: Border.all(
                            width: borderWidth,
                            color: borderColor,
                          ),
                        ),
                        child: VideoPlayer(controller),
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          backgroundColor: Colors.white,
                        ),
                      ),
              ),
            ),
          );
  }
}
