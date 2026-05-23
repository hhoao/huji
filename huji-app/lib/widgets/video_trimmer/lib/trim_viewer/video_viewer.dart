import 'package:flutter/material.dart';
import 'package:huji_app/widgets/video_trimmer/lib/services/universal_video_controller.dart';

class VideoViewer extends StatelessWidget {
  final UniversalVideoController? videoPlayerController;

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
                aspectRatio: controller.aspectRatio,
                child: controller.isInitialized
                    ? Container(
                        foregroundDecoration: BoxDecoration(
                          border: Border.all(
                            width: borderWidth,
                            color: borderColor,
                          ),
                        ),
                        child: controller.buildVideoWidget(),
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
