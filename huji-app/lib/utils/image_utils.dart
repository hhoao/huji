import 'package:camerawesome/camerawesome_plugin.dart';

Future<JpegImage>? toJpeg(AnalysisImage image) {
  return image.when(
    jpeg: (JpegImage image) => Future.value(image),
    nv21: (Nv21Image image) => image.toJpeg(),
    bgra8888: (Bgra8888Image image) => image.toJpeg(),
    yuv420: (Yuv420Image image) => image.toJpeg(),
  );
}
