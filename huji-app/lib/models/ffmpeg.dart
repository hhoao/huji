import 'package:freezed_annotation/freezed_annotation.dart';

part 'ffmpeg.freezed.dart';
part 'ffmpeg.g.dart';

/// 视频压缩质量枚举
@JsonEnum(valueField: 'value')
enum VideoCompressQuality {
  ultraLow(0), // 超低质量 (最大压缩)
  low(1), // 低质量
  medium(2), // 中等质量
  high(3), // 高质量
  ultraHigh(4), // 超高质量
  custom(5); // 自定义

  const VideoCompressQuality(this.value);
  final int value;
}

/// 视频压缩预设
@JsonEnum(valueField: 'value')
enum VideoCompressPreset {
  ultrafast(0), // 最快速度
  superfast(1), // 超快速度
  veryfast(2), // 很快速度
  faster(3), // 更快速度
  fast(4), // 快速
  medium(5), // 中等速度
  slow(6), // 慢速
  slower(7), // 更慢速度
  veryslow(8); // 很慢速度

  const VideoCompressPreset(this.value);
  final int value;
}

/// 视频压缩配置
@freezed
@JsonSerializable()
class VideoCompressConfig with _$VideoCompressConfig {
  @override
  final VideoCompressQuality quality;
  @override
  final VideoCompressPreset preset;
  @override
  final int? customBitrate; // 自定义比特率 (kbps)
  @override
  final int? customWidth; // 自定义宽度
  @override
  final int? customHeight; // 自定义高度
  @override
  final bool includeAudio; // 是否包含音频
  @override
  final String? outputPath; // 输出路径
  @override
  final String? outputFileName; // 输出文件名
  @override
  final bool keepAspectRatio; // 保持宽高比
  @override
  final bool optimizeForWeb; // 优化网络播放
  @override
  final int? maxFileSize; // 最大文件大小 (MB)

  const VideoCompressConfig({
    this.quality = VideoCompressQuality.medium,
    this.preset = VideoCompressPreset.medium,
    this.customBitrate,
    this.customWidth,
    this.customHeight,
    this.includeAudio = true,
    this.outputPath,
    this.outputFileName,
    this.keepAspectRatio = true,
    this.optimizeForWeb = true,
    this.maxFileSize,
  });

  /// 根据质量获取默认预设
  /// 质量越高，使用越慢的预设以获得更好的压缩率
  VideoCompressPreset get defaultPreset {
    switch (quality) {
      case VideoCompressQuality.ultraLow:
        return VideoCompressPreset.fast; // 超低质量用快速预设
      case VideoCompressQuality.low:
        return VideoCompressPreset.fast; // 低质量用快速预设
      case VideoCompressQuality.medium:
        return VideoCompressPreset.medium; // 中等质量用中等预设
      case VideoCompressQuality.high:
        return VideoCompressPreset.slow; // 高质量用慢速预设
      case VideoCompressQuality.ultraHigh:
        return VideoCompressPreset.slower; // 超高质量用更慢预设
      case VideoCompressQuality.custom:
        return VideoCompressPreset.medium; // 自定义使用中等预设
    }
  }

  /// 创建配置，使用根据质量自动选择的预设
  factory VideoCompressConfig.fromQuality({
    VideoCompressQuality quality = VideoCompressQuality.medium,
    int? customWidth,
    int? customHeight,
    bool includeAudio = true,
    String? outputPath,
    String? outputFileName,
    bool keepAspectRatio = true,
    bool optimizeForWeb = true,
    int? maxFileSize,
  }) {
    final defaultPreset = _getDefaultPreset(quality);
    final defaultBitrate = _getDefaultBitrate(quality);
    return VideoCompressConfig(
      quality: quality,
      preset: defaultPreset,
      customBitrate: defaultBitrate,
      customWidth: customWidth,
      customHeight: customHeight,
      includeAudio: includeAudio,
      outputPath: outputPath,
      outputFileName: outputFileName,
      keepAspectRatio: keepAspectRatio,
      optimizeForWeb: optimizeForWeb,
      maxFileSize: maxFileSize,
    );
  }

  /// 根据质量获取默认预设（用于工厂方法）
  static VideoCompressPreset _getDefaultPreset(VideoCompressQuality quality) {
    switch (quality) {
      case VideoCompressQuality.ultraLow:
        return VideoCompressPreset.fast;
      case VideoCompressQuality.low:
        return VideoCompressPreset.fast;
      case VideoCompressQuality.medium:
        return VideoCompressPreset.medium;
      case VideoCompressQuality.high:
        return VideoCompressPreset.slow;
      case VideoCompressQuality.ultraHigh:
        return VideoCompressPreset.slower;
      case VideoCompressQuality.custom:
        return VideoCompressPreset.medium;
    }
  }

  factory VideoCompressConfig.fromJson(Map<String, dynamic> json) =>
      _$VideoCompressConfigFromJson(json);

  Map<String, dynamic> toJson() => _$VideoCompressConfigToJson(this);

  /// 获取压缩质量对应的CRF值
  int get crfValue {
    switch (quality) {
      case VideoCompressQuality.ultraLow:
        return 35;
      case VideoCompressQuality.low:
        return 28;
      case VideoCompressQuality.medium:
        return 23;
      case VideoCompressQuality.high:
        return 18;
      case VideoCompressQuality.ultraHigh:
        return 12;
      case VideoCompressQuality.custom:
        return 23; // 默认值，实际使用customBitrate
    }
  }

  /// 获取音频比特率
  int get audioBitrate {
    switch (quality) {
      case VideoCompressQuality.ultraLow:
        return 48;
      case VideoCompressQuality.low:
        return 64;
      case VideoCompressQuality.medium:
        return 128;
      case VideoCompressQuality.high:
        return 192;
      case VideoCompressQuality.ultraHigh:
        return 256;
      case VideoCompressQuality.custom:
        return customBitrate != null ? (customBitrate! / 8).round() : 128;
    }
  }

  /// 获取视频比特率（kbps）
  /// 用于硬件编码器（如 MediaCodec），不支持 CRF 时使用
  static int _getDefaultBitrate(VideoCompressQuality quality) {
    switch (quality) {
      case VideoCompressQuality.ultraLow:
        return 1000; // 1Mbps - 超低质量
      case VideoCompressQuality.low:
        return 2000; // 2Mbps - 低质量
      case VideoCompressQuality.medium:
        return 4000; // 4Mbps - 中等质量
      case VideoCompressQuality.high:
        return 8000; // 8Mbps - 高质量
      case VideoCompressQuality.ultraHigh:
        return 12000; // 12Mbps - 超高质量
      case VideoCompressQuality.custom:
        return 4000; // 默认值
    }
  }

  /// 获取预设字符串
  String get presetString {
    return preset.name;
  }
}

/// 视频压缩结果
@freezed
@JsonSerializable()
class VideoCompressResult with _$VideoCompressResult {
  @override
  final bool success;
  @override
  final String? outputPath;
  @override
  final String? errorMessage;
  @override
  final int? originalSize;
  @override
  final int? compressedSize;
  @override
  final double? compressionRatio;
  @override
  final double? originalDuration;
  @override
  final double? compressedDuration;
  @override
  final Map<String, dynamic>? originalInfo;
  @override
  final Map<String, dynamic>? compressedInfo;
  @override
  final double? processingTime;

  VideoCompressResult({
    required this.success,
    this.outputPath,
    this.errorMessage,
    this.originalSize,
    this.compressedSize,
    this.compressionRatio,
    this.originalDuration,
    this.compressedDuration,
    this.originalInfo,
    this.compressedInfo,
    this.processingTime,
  });

  factory VideoCompressResult.fromJson(Map<String, dynamic> json) =>
      _$VideoCompressResultFromJson(json);

  Map<String, dynamic> toJson() => _$VideoCompressResultToJson(this);

  factory VideoCompressResult.error(String errorMessage) =>
      VideoCompressResult(success: false, errorMessage: errorMessage);

  factory VideoCompressResult.success(
    String outputPath,
    int originalSize,
    int compressedSize,
    double? originalDuration,
    double? compressedDuration,
    Map<String, dynamic>? originalInfo,
    Map<String, dynamic>? compressedInfo,
    double? processingTime,
  ) => VideoCompressResult(
    success: true,
    outputPath: outputPath,
    originalSize: originalSize,
    compressedSize: compressedSize,
    originalDuration: originalDuration,
    compressedDuration: compressedDuration,
    originalInfo: originalInfo,
    compressedInfo: compressedInfo,
    processingTime: processingTime,
  );

  /// 获取压缩质量评估
  String get qualityAssessment {
    if (!success || compressionRatio == null) return '未知';

    if (compressionRatio! >= 80) return '极佳';
    if (compressionRatio! >= 60) return '优秀';
    if (compressionRatio! >= 40) return '良好';
    if (compressionRatio! >= 20) return '一般';
    return '较差';
  }
}

@freezed
@JsonSerializable()
class VideoInfo with _$VideoInfo {
  // seconds
  @override
  final double duration;
  @override
  final int width;
  @override
  final int height;
  @override
  final String videoCodec;
  @override
  final String? audioCodec;
  @override
  final int bitrate;
  @override
  final double fps;
  @override
  final int fileSize;
  @override
  final String format;

  VideoInfo({
    required this.duration,
    required this.width,
    required this.height,
    required this.videoCodec,
    this.audioCodec,
    required this.bitrate,
    required this.fps,
    required this.fileSize,
    required this.format,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) =>
      _$VideoInfoFromJson(json);

  Map<String, dynamic> toJson() => _$VideoInfoToJson(this);
}
