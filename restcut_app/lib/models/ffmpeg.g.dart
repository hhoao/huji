// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ffmpeg.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoCompressConfig _$VideoCompressConfigFromJson(Map<String, dynamic> json) =>
    VideoCompressConfig(
      quality:
          $enumDecodeNullable(_$VideoCompressQualityEnumMap, json['quality']) ??
          VideoCompressQuality.medium,
      preset:
          $enumDecodeNullable(_$VideoCompressPresetEnumMap, json['preset']) ??
          VideoCompressPreset.medium,
      customBitrate: (json['customBitrate'] as num?)?.toInt(),
      customWidth: (json['customWidth'] as num?)?.toInt(),
      customHeight: (json['customHeight'] as num?)?.toInt(),
      includeAudio: json['includeAudio'] as bool? ?? true,
      outputPath: json['outputPath'] as String?,
      outputFileName: json['outputFileName'] as String?,
      keepAspectRatio: json['keepAspectRatio'] as bool? ?? true,
      optimizeForWeb: json['optimizeForWeb'] as bool? ?? true,
      maxFileSize: (json['maxFileSize'] as num?)?.toInt(),
    );

Map<String, dynamic> _$VideoCompressConfigToJson(
  VideoCompressConfig instance,
) => <String, dynamic>{
  'quality': _$VideoCompressQualityEnumMap[instance.quality]!,
  'preset': _$VideoCompressPresetEnumMap[instance.preset]!,
  'customBitrate': instance.customBitrate,
  'customWidth': instance.customWidth,
  'customHeight': instance.customHeight,
  'includeAudio': instance.includeAudio,
  'outputPath': instance.outputPath,
  'outputFileName': instance.outputFileName,
  'keepAspectRatio': instance.keepAspectRatio,
  'optimizeForWeb': instance.optimizeForWeb,
  'maxFileSize': instance.maxFileSize,
};

const _$VideoCompressQualityEnumMap = {
  VideoCompressQuality.ultraLow: 0,
  VideoCompressQuality.low: 1,
  VideoCompressQuality.medium: 2,
  VideoCompressQuality.high: 3,
  VideoCompressQuality.ultraHigh: 4,
  VideoCompressQuality.custom: 5,
};

const _$VideoCompressPresetEnumMap = {
  VideoCompressPreset.ultrafast: 0,
  VideoCompressPreset.superfast: 1,
  VideoCompressPreset.veryfast: 2,
  VideoCompressPreset.faster: 3,
  VideoCompressPreset.fast: 4,
  VideoCompressPreset.medium: 5,
  VideoCompressPreset.slow: 6,
  VideoCompressPreset.slower: 7,
  VideoCompressPreset.veryslow: 8,
};

VideoCompressResult _$VideoCompressResultFromJson(Map<String, dynamic> json) =>
    VideoCompressResult(
      success: json['success'] as bool,
      outputPath: json['outputPath'] as String?,
      errorMessage: json['errorMessage'] as String?,
      originalSize: (json['originalSize'] as num?)?.toInt(),
      compressedSize: (json['compressedSize'] as num?)?.toInt(),
      compressionRatio: (json['compressionRatio'] as num?)?.toDouble(),
      originalDuration: (json['originalDuration'] as num?)?.toDouble(),
      compressedDuration: (json['compressedDuration'] as num?)?.toDouble(),
      originalInfo: json['originalInfo'] as Map<String, dynamic>?,
      compressedInfo: json['compressedInfo'] as Map<String, dynamic>?,
      processingTime: (json['processingTime'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$VideoCompressResultToJson(
  VideoCompressResult instance,
) => <String, dynamic>{
  'success': instance.success,
  'outputPath': instance.outputPath,
  'errorMessage': instance.errorMessage,
  'originalSize': instance.originalSize,
  'compressedSize': instance.compressedSize,
  'compressionRatio': instance.compressionRatio,
  'originalDuration': instance.originalDuration,
  'compressedDuration': instance.compressedDuration,
  'originalInfo': instance.originalInfo,
  'compressedInfo': instance.compressedInfo,
  'processingTime': instance.processingTime,
};

VideoInfo _$VideoInfoFromJson(Map<String, dynamic> json) => VideoInfo(
  duration: (json['duration'] as num).toDouble(),
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
  videoCodec: json['videoCodec'] as String,
  audioCodec: json['audioCodec'] as String?,
  bitrate: (json['bitrate'] as num).toInt(),
  fps: (json['fps'] as num).toDouble(),
  fileSize: (json['fileSize'] as num).toInt(),
  format: json['format'] as String,
);

Map<String, dynamic> _$VideoInfoToJson(VideoInfo instance) => <String, dynamic>{
  'duration': instance.duration,
  'width': instance.width,
  'height': instance.height,
  'videoCodec': instance.videoCodec,
  'audioCodec': instance.audioCodec,
  'bitrate': instance.bitrate,
  'fps': instance.fps,
  'fileSize': instance.fileSize,
  'format': instance.format,
};
