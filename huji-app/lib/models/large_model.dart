import 'package:freezed_annotation/freezed_annotation.dart';

part 'large_model.freezed.dart';
part 'large_model.g.dart';

@freezed
abstract class ClassifierResult with _$ClassifierResult {
  const factory ClassifierResult({
    // ignore: invalid_annotation_target
    @JsonKey(fromJson: ImageSize.fromObjectJson) required ImageSize imageSize,
    // ignore: invalid_annotation_target
    @JsonKey(fromJson: Classification._convertClassification)
    required Classification classification,
    required double speed,
    required List<Detection> detections,
  }) = _ClassifierResult;

  factory ClassifierResult.fromJson(Map<String, dynamic> json) =>
      _$ClassifierResultFromJson(json);
}

@freezed
abstract class ImageSize with _$ImageSize {
  const factory ImageSize({required int width, required int height}) =
      _ImageSize;

  factory ImageSize.fromJson(Map<String, dynamic> json) =>
      _$ImageSizeFromJson(json);

  static ImageSize fromObjectJson(Map<Object?, Object?> json) {
    return ImageSize.fromJson(Map<String, dynamic>.from(json));
  }
}

@freezed
abstract class Classification with _$Classification {
  const factory Classification({
    required String topClass,
    required double topConfidence,
    required List<String> top5Classes,
    required List<double> top5Confidences,
  }) = _Classification;

  factory Classification.fromJson(Map<String, dynamic> json) =>
      _$ClassificationFromJson(json);

  static Classification _convertClassification(Map<Object?, Object?> json) {
    return Classification.fromJson(Map<String, dynamic>.from(json));
  }
}

@freezed
abstract class Detection with _$Detection {
  const factory Detection({
    required int classIndex,
    required String className,
    required double confidence,
    required BoundingBox boundingBox,
    required BoundingBox normalizedBox,
  }) = _Detection;

  factory Detection.fromJson(Map<String, dynamic> json) =>
      _$DetectionFromJson(json);
}

@freezed
abstract class BoundingBox with _$BoundingBox {
  const factory BoundingBox({
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) = _BoundingBox;

  factory BoundingBox.fromJson(Map<String, dynamic> json) =>
      _$BoundingBoxFromJson(json);
}
