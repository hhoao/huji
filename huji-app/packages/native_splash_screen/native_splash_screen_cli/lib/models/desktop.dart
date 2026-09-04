import 'package:image/image.dart' show Color;

class DesktopSplashConfig {
  final bool withAnimation;
  final int windowWidth;
  final int windowHeight;
  final String windowTitle;
  final String windowClass;
  final Color windowColor;
  final String imagePath;
  final int imageWidth;
  final int imageHeight;
  final double imageBorderRadius;
  final double imageBlurRadius;
  final bool imageScaling;
  final Color backgroundColor;
  final int backgroundWidth;
  final int backgroundHeight;
  final double backgroundBorderRadius;
  DesktopSplashConfig({
    required this.windowWidth,
    required this.windowHeight,
    required this.windowTitle,
    required this.windowClass,
    required this.windowColor,
    required this.imagePath,
    required this.imageWidth,
    required this.imageHeight,
    required this.imageBorderRadius,
    required this.imageScaling,
    required this.backgroundColor,
    required this.backgroundWidth,
    required this.backgroundHeight,
    required this.backgroundBorderRadius,
    required this.withAnimation,
    required this.imageBlurRadius,
  });
  DesktopSplashConfig copyWith({
    int? windowWidth,
    int? windowHeight,
    String? windowTitle,
    String? windowClass,
    Color? windowColor,
    String? imagePath,
    int? imageWidth,
    int? imageHeight,
    double? imageBorderRadius,
    double? imageBlurRadius,
    bool? imageScaling,
    Color? backgroundColor,
    int? backgroundWidth,
    int? backgroundHeight,
    double? backgroundBorderRadius,
    bool? withAnimation,
  }) {
    return DesktopSplashConfig(
      windowWidth: windowWidth ?? this.windowWidth,
      windowHeight: windowHeight ?? this.windowHeight,
      windowTitle: windowTitle ?? this.windowTitle,
      windowClass: windowClass ?? this.windowClass,
      windowColor: windowColor ?? this.windowColor,
      imagePath: imagePath ?? this.imagePath,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      imageBorderRadius: imageBorderRadius ?? this.imageBorderRadius,
      imageScaling: imageScaling ?? this.imageScaling,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundWidth: backgroundWidth ?? this.backgroundWidth,
      backgroundHeight: backgroundHeight ?? this.backgroundHeight,
      backgroundBorderRadius:
          backgroundBorderRadius ?? this.backgroundBorderRadius,
      withAnimation: withAnimation ?? this.withAnimation,
      imageBlurRadius: imageBlurRadius ?? this.imageBlurRadius,
    );
  }
}
