// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'large_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClassifierResult _$ClassifierResultFromJson(Map<String, dynamic> json) =>
    _ClassifierResult(
      imageSize: ImageSize.fromObjectJson(json['imageSize'] as Map),
      classification: Classification._convertClassification(
        json['classification'] as Map,
      ),
      speed: (json['speed'] as num).toDouble(),
      detections: (json['detections'] as List<dynamic>)
          .map((e) => Detection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ClassifierResultToJson(_ClassifierResult instance) =>
    <String, dynamic>{
      'imageSize': instance.imageSize,
      'classification': instance.classification,
      'speed': instance.speed,
      'detections': instance.detections,
    };

_ImageSize _$ImageSizeFromJson(Map<String, dynamic> json) => _ImageSize(
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
);

Map<String, dynamic> _$ImageSizeToJson(_ImageSize instance) =>
    <String, dynamic>{'width': instance.width, 'height': instance.height};

_Classification _$ClassificationFromJson(Map<String, dynamic> json) =>
    _Classification(
      topClass: json['topClass'] as String,
      topConfidence: (json['topConfidence'] as num).toDouble(),
      top5Classes: (json['top5Classes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      top5Confidences: (json['top5Confidences'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
    );

Map<String, dynamic> _$ClassificationToJson(_Classification instance) =>
    <String, dynamic>{
      'topClass': instance.topClass,
      'topConfidence': instance.topConfidence,
      'top5Classes': instance.top5Classes,
      'top5Confidences': instance.top5Confidences,
    };

_Detection _$DetectionFromJson(Map<String, dynamic> json) => _Detection(
  classIndex: (json['classIndex'] as num).toInt(),
  className: json['className'] as String,
  confidence: (json['confidence'] as num).toDouble(),
  boundingBox: BoundingBox.fromJson(
    json['boundingBox'] as Map<String, dynamic>,
  ),
  normalizedBox: BoundingBox.fromJson(
    json['normalizedBox'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$DetectionToJson(_Detection instance) =>
    <String, dynamic>{
      'classIndex': instance.classIndex,
      'className': instance.className,
      'confidence': instance.confidence,
      'boundingBox': instance.boundingBox,
      'normalizedBox': instance.normalizedBox,
    };

_BoundingBox _$BoundingBoxFromJson(Map<String, dynamic> json) => _BoundingBox(
  left: (json['left'] as num).toDouble(),
  top: (json['top'] as num).toDouble(),
  right: (json['right'] as num).toDouble(),
  bottom: (json['bottom'] as num).toDouble(),
);

Map<String, dynamic> _$BoundingBoxToJson(_BoundingBox instance) =>
    <String, dynamic>{
      'left': instance.left,
      'top': instance.top,
      'right': instance.right,
      'bottom': instance.bottom,
    };
