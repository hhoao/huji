import 'dart:io';

import 'package:flutter/material.dart';
import 'package:restcut/utils/logger_utils.dart';
import 'package:restcut/models/ffmpeg.dart';
import 'package:restcut/widgets/file_picker/file_selection_page.dart';

import '../../utils/ffmpeg_manager.dart';
import '../../utils/video_compress_utils.dart';
import '../../widgets/video_player/video_player_page.dart';

/// FFmpeg工具测试页面
class FFmpegTestPage extends StatefulWidget {
  const FFmpegTestPage({super.key});

  @override
  State<FFmpegTestPage> createState() => _FFmpegTestPageState();
}

class _FFmpegTestPageState extends State<FFmpegTestPage> {
  bool _isLoading = false;
  String _status = '准备就绪';
  final List<String> _logs = [];
  String? _selectedVideoPath;
  double _progress = 0.0;
  bool _showProgress = false;

  // 新增：存储压缩结果
  VideoCompressResult? _lastCompressResult;

  @override
  void initState() {
    super.initState();
    _checkFFmpegStatus();
  }

  /// 播放视频
  void _playVideo(String? videoPath) {
    if (videoPath == null) {
      setState(() {
        _logs.add('没有可播放的视频文件');
      });
      return;
    }

    final file = File(videoPath);
    if (!file.existsSync()) {
      setState(() {
        _logs.add('视频文件不存在: $videoPath');
      });
      return;
    }

    // 导航到视频播放页面
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoPlayerPage(
          videoUrl: videoPath,
          fileName: file.path.split('/').last,
        ),
      ),
    );
  }

  /// 播放输入视频
  void _playInputVideo() {
    _playVideo(_selectedVideoPath);
  }

  /// 播放输出视频
  void _playOutputVideo() {
    if (_lastCompressResult?.outputPath != null) {
      _playVideo(_lastCompressResult!.outputPath);
    } else {
      setState(() {
        _logs.add('没有可播放的输出视频，请先进行压缩测试');
      });
    }
  }

  /// 查看所有输出视频
  Future<void> _viewAllOutputVideos() async {
    try {
      final dir = Directory.current;
      final files = dir
          .listSync()
          .where(
            (file) =>
                file is File &&
                file.path.contains('compressed_') &&
                (file.path.endsWith('.mp4') ||
                    file.path.endsWith('.avi') ||
                    file.path.endsWith('.mov')),
          )
          .toList();

      if (files.isEmpty) {
        setState(() {
          _logs.add('没有找到输出视频文件');
        });
        return;
      }

      // 显示文件选择对话框
      final selectedFile = await showDialog<File>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('选择要播放的输出视频'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index] as File;
                final fileName = file.path.split('/').last;
                final fileSize = _formatFileSize(file.lengthSync());
                final modifiedTime = DateTime.fromMillisecondsSinceEpoch(
                  file.lastModifiedSync().millisecondsSinceEpoch,
                ).toString().substring(0, 19);

                return ListTile(
                  title: Text(fileName),
                  subtitle: Text('$fileSize • $modifiedTime'),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () => Navigator.of(context).pop(file),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ],
        ),
      );

      if (selectedFile != null) {
        _playVideo(selectedFile.path);
      }
    } catch (e) {
      setState(() {
        _logs.add('查看输出视频失败: $e');
      });
    }
  }

  /// 比较输入和输出视频
  Future<void> _compareVideos() async {
    if (_selectedVideoPath == null || _lastCompressResult?.outputPath == null) {
      setState(() {
        _logs.add('需要输入视频和输出视频才能进行比较');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = '比较视频信息...';
    });

    try {
      final inputInfo = await FFmpegManager.getMediaInfo(_selectedVideoPath!);
      final outputInfo = await FFmpegManager.getMediaInfo(
        _lastCompressResult!.outputPath!,
      );

      setState(() {
        _status = '视频比较完成';
        _logs.add('=== 视频比较结果 ===');
        _logs.add('输入视频:');
        _logs.add('  文件名: ${_selectedVideoPath!.split('/').last}');
        _logs.add(
          '  大小: ${_formatFileSize(_lastCompressResult!.originalSize ?? 0)}',
        );
        _logs.add('  时长: ${inputInfo?.durationString ?? "未知"}');
        _logs.add('  分辨率: ${inputInfo?.resolution ?? "未知"}');
        _logs.add('  视频编码: ${inputInfo?.videoCodec ?? "未知"}');
        _logs.add('  音频编码: ${inputInfo?.audioCodec ?? "未知"}');
        _logs.add('  比特率: ${inputInfo?.bitrate ?? "未知"} kbps');
        _logs.add('  帧率: ${inputInfo?.fps ?? "未知"} fps');
        _logs.add('');
        _logs.add('输出视频:');
        _logs.add('  文件名: ${_lastCompressResult!.outputPath!.split('/').last}');
        _logs.add(
          '  大小: ${_formatFileSize(_lastCompressResult!.compressedSize ?? 0)}',
        );
        _logs.add('  时长: ${outputInfo?.durationString ?? "未知"}');
        _logs.add('  分辨率: ${outputInfo?.resolution ?? "未知"}');
        _logs.add('  视频编码: ${outputInfo?.videoCodec ?? "未知"}');
        _logs.add('  音频编码: ${outputInfo?.audioCodec ?? "未知"}');
        _logs.add('  比特率: ${outputInfo?.bitrate ?? "未知"} kbps');
        _logs.add('  帧率: ${outputInfo?.fps ?? "未知"} fps');
        _logs.add('');
        _logs.add('压缩效果:');
        _logs.add(
          '  压缩比例: ${_lastCompressResult!.compressionRatio?.toStringAsFixed(1) ?? "未知"}%',
        );
        if (inputInfo?.bitrate != null && outputInfo?.bitrate != null) {
          final bitrateRatio =
              (1 - outputInfo!.bitrate! / inputInfo!.bitrate!) * 100;
          _logs.add('  比特率减少: ${bitrateRatio.toStringAsFixed(1)}%');
        }
        _logs.add('=== 比较完成 ===');
      });
    } catch (e) {
      setState(() {
        _status = '视频比较失败: $e';
        _logs.add('错误: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 检查FFmpeg状态
  Future<void> _checkFFmpegStatus() async {
    setState(() {
      _isLoading = true;
      _status = '检查FFmpeg状态...';
    });

    try {
      final isAvailable = await FFmpegManager.isAvailable();
      final version = await FFmpegManager.getVersion();

      setState(() {
        _status = isAvailable ? 'FFmpeg可用' : 'FFmpeg不可用';
        _logs.add('FFmpeg状态: ${isAvailable ? "可用" : "不可用"}');
        if (version != null) {
          _logs.add('版本信息: ${version.split('\n').first}');
        }
      });
    } catch (e) {
      setState(() {
        _status = '检查失败: $e';
        _logs.add('错误: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 测试获取支持的编码器
  Future<void> _testCodecs() async {
    setState(() {
      _isLoading = true;
      _status = '获取编码器列表...';
    });

    try {
      final codecs = await FFmpegManager.getSupportedCodecs();
      final commonCodecs = ['h264', 'h265', 'aac', 'mp3', 'libx264', 'libx265'];

      setState(() {
        _status = '获取编码器完成';
        _logs.add('支持的编码器数量: ${codecs.length}');
        _logs.add('常用编码器检查:');
        for (final codec in commonCodecs) {
          final supported = codecs.any((c) => c.toLowerCase().contains(codec));
          _logs.add('  $codec: ${supported ? "✓ 支持" : "✗ 不支持"}');
        }
      });
    } catch (e) {
      setState(() {
        _status = '获取编码器失败: $e';
        _logs.add('错误: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 测试获取支持的格式
  Future<void> _testFormats() async {
    setState(() {
      _isLoading = true;
      _status = '获取格式列表...';
    });

    try {
      final formats = await FFmpegManager.getSupportedFormats();
      final commonFormats = ['mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv', 'webm'];

      setState(() {
        _status = '获取格式完成';
        _logs.add('支持的格式数量: ${formats.length}');
        _logs.add('常用格式检查:');
        for (final format in commonFormats) {
          final supported = formats.any(
            (f) => f.toLowerCase().contains(format),
          );
          _logs.add('  $format: ${supported ? "✓ 支持" : "✗ 不支持"}');
        }
      });
    } catch (e) {
      setState(() {
        _status = '获取格式失败: $e';
        _logs.add('错误: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 测试获取FFmpeg配置信息
  Future<void> _testConfiguration() async {
    setState(() {
      _isLoading = true;
      _status = '获取FFmpeg配置信息...';
    });

    try {
      final config = await FFmpegManager.getConfiguration();
      if (config != null) {
        setState(() {
          _status = '获取配置完成';
          _logs.add('FFmpeg配置信息:');
          _logs.add(config);
        });
      } else {
        setState(() {
          _status = '获取配置失败';
          _logs.add('无法获取FFmpeg配置信息');
        });
      }
    } catch (e) {
      setState(() {
        _status = '获取配置失败: $e';
        _logs.add('错误: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 测试检查特定功能
  Future<void> _testFeatures() async {
    setState(() {
      _isLoading = true;
      _status = '检查FFmpeg功能...';
    });

    try {
      final features = ['libx264', 'libx265', 'aac', 'mp3', 'h264', 'h265'];
      setState(() {
        _status = '功能检查完成';
        _logs.add('FFmpeg功能检查:');
      });

      for (final feature in features) {
        final hasFeature = await FFmpegManager.hasFeature(feature);
        setState(() {
          _logs.add('  $feature: ${hasFeature ? "✓ 支持" : "✗ 不支持"}');
        });
      }
    } catch (e) {
      setState(() {
        _status = '功能检查失败: $e';
        _logs.add('错误: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 选择视频文件
  Future<void> _selectVideoFile() async {
    try {
      final result = await FileSelection.selectVideos(
        context: context,
        allowMultiple: false,
      );

      if (result != null && result.isNotEmpty) {
        setState(() {
          _selectedVideoPath = result.first.path;
          _logs.add('已选择视频文件: ${result.first.path.split('/').last}');
        });
      }
    } catch (e) {
      setState(() {
        _logs.add('选择文件失败: $e');
      });
    }
  }

  /// 测试获取媒体信息
  Future<void> _testMediaInfo() async {
    if (_selectedVideoPath == null) {
      setState(() {
        _logs.add('请先选择视频文件');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = '获取媒体信息...';
    });

    try {
      final mediaInfo = await FFmpegManager.getMediaInfo(_selectedVideoPath!);
      if (mediaInfo != null) {
        setState(() {
          _status = '获取媒体信息完成';
          _logs.add('媒体信息:');
          _logs.add('  时长: ${mediaInfo.durationString}');
          _logs.add('  分辨率: ${mediaInfo.resolution}');
          _logs.add('  视频编码: ${mediaInfo.videoCodec ?? "未知"}');
          _logs.add('  音频编码: ${mediaInfo.audioCodec ?? "未知"}');
          _logs.add('  比特率: ${mediaInfo.bitrate ?? "未知"} kbps');
          _logs.add('  帧率: ${mediaInfo.fps ?? "未知"} fps');
        });
      } else {
        setState(() {
          _status = '获取媒体信息失败';
          _logs.add('无法获取媒体信息');
        });
      }
    } catch (e) {
      setState(() {
        _status = '获取媒体信息失败: $e';
        _logs.add('错误: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 测试视频压缩
  Future<void> _testVideoCompress() async {
    if (_selectedVideoPath == null) {
      setState(() {
        _logs.add('请先选择视频文件');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showProgress = true;
      _progress = 0.0;
      _status = '开始视频压缩...';
    });

    try {
      await VideoCompressUtils.quickCompress(
        _selectedVideoPath!,
        onProgress: (progress) {
          AppLogger().i('FFmpeg进度更新: $progress'); // 添加调试信息
          setState(() {
            _progress = progress;
          });
        },
        onSuccess: (result) {
          setState(() {
            _status = '视频压缩完成';
            _logs.add('压缩结果:');
            _logs.add('  原始大小: ${_formatFileSize(result.originalSize ?? 0)}');
            _logs.add(
              '  压缩后大小: ${_formatFileSize(result.compressedSize ?? 0)}',
            );
            _logs.add(
              '  压缩比例: ${result.compressionRatio?.toStringAsFixed(1) ?? "未知"}%',
            );
            _logs.add('  输出路径: ${result.outputPath}');
            _lastCompressResult = result; // 存储压缩结果
          });
        },
        onError: (result) {
          setState(() {
            _status = '视频压缩失败';
            _logs.add('压缩失败: ${result.errorMessage}');
          });
        },
      );
    } catch (e) {
      setState(() {
        _status = '视频压缩异常: $e';
        _logs.add('错误: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
        _showProgress = false;
        _progress = 0.0;
      });
    }
  }

  /// 测试高质量压缩
  Future<void> _testHighQualityCompress() async {
    if (_selectedVideoPath == null) {
      setState(() {
        _logs.add('请先选择视频文件');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showProgress = true;
      _progress = 0.0;
      _status = '开始高质量压缩...';
    });

    try {
      await VideoCompressUtils.compressVideo(
        _selectedVideoPath!,
        config: const VideoCompressConfig(
          quality: VideoCompressQuality.high,
          preset: VideoCompressPreset.medium,
        ),
        onProgress: (progress) {
          AppLogger().i('FFmpeg进度更新: $progress'); // 添加调试信息
          setState(() {
            _progress = progress;
          });
        },
        onSuccess: (result) {
          setState(() {
            _status = '高质量压缩完成';
            _logs.add('高质量压缩结果:');
            _logs.add('  原始大小: ${_formatFileSize(result.originalSize ?? 0)}');
            _logs.add(
              '  压缩后大小: ${_formatFileSize(result.compressedSize ?? 0)}',
            );
            _logs.add(
              '  压缩比例: ${result.compressionRatio?.toStringAsFixed(1) ?? "未知"}%',
            );
            _logs.add('  输出路径: ${result.outputPath}');
            _lastCompressResult = result; // 存储压缩结果
          });
        },
        onError: (result) {
          setState(() {
            _status = '高质量压缩失败';
            _logs.add('压缩失败: ${result.errorMessage}');
          });
        },
      );
    } catch (e) {
      setState(() {
        _status = '高质量压缩异常: $e';
        _logs.add('错误: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
        _showProgress = false;
        _progress = 0.0;
      });
    }
  }

  /// 测试自定义压缩
  Future<void> _testCustomCompress() async {
    if (_selectedVideoPath == null) {
      setState(() {
        _logs.add('请先选择视频文件');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showProgress = true;
      _progress = 0.0;
      _status = '开始自定义压缩...';
    });

    try {
      await VideoCompressUtils.compressVideo(
        _selectedVideoPath!,
        config: VideoCompressConfig(
          quality: VideoCompressQuality.custom,
          preset: VideoCompressPreset.medium,
          customBitrate: 1000,
          customWidth: 1280,
          customHeight: 720,
          includeAudio: true,
        ),
        onProgress: (progress) {
          AppLogger().i('FFmpeg进度更新: $progress'); // 添加调试信息
          setState(() {
            _progress = progress;
          });
        },
        onSuccess: (result) {
          setState(() {
            _status = '自定义压缩完成';
            _logs.add('自定义压缩结果 (1280x720, 1Mbps):');
            _logs.add('  原始大小: ${_formatFileSize(result.originalSize ?? 0)}');
            _logs.add(
              '  压缩后大小: ${_formatFileSize(result.compressedSize ?? 0)}',
            );
            _logs.add(
              '  压缩比例: ${result.compressionRatio?.toStringAsFixed(1) ?? "未知"}%',
            );
            _logs.add('  输出路径: ${result.outputPath}');
            _lastCompressResult = result; // 存储压缩结果
          });
        },
        onError: (result) {
          setState(() {
            _status = '自定义压缩失败';
            _logs.add('压缩失败: ${result.errorMessage}');
          });
        },
      );
    } catch (e) {
      setState(() {
        _status = '自定义压缩异常: $e';
        _logs.add('错误: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
        _showProgress = false;
        _progress = 0.0;
      });
    }
  }

  /// 测试超低质量压缩
  Future<void> _testUltraLowQualityCompress() async {
    if (_selectedVideoPath == null) {
      setState(() {
        _logs.add('请先选择视频文件');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showProgress = true;
      _progress = 0.0;
      _status = '开始超低质量压缩...';
    });

    try {
      await VideoCompressUtils.compressVideo(
        _selectedVideoPath!,
        config: const VideoCompressConfig(
          quality: VideoCompressQuality.ultraLow,
          preset: VideoCompressPreset.ultrafast,
        ),
        onProgress: (progress) {
          AppLogger().i('FFmpeg进度更新: $progress'); // 添加调试信息
          setState(() {
            _progress = progress;
          });
        },
        onSuccess: (result) {
          setState(() {
            _status = '超低质量压缩完成';
            _logs.add('超低质量压缩结果:');
            _logs.add('  原始大小: ${_formatFileSize(result.originalSize ?? 0)}');
            _logs.add(
              '  压缩后大小: ${_formatFileSize(result.compressedSize ?? 0)}',
            );
            _logs.add(
              '  压缩比例: ${result.compressionRatio?.toStringAsFixed(1) ?? "未知"}%',
            );
            _logs.add('  质量评估: ${result.qualityAssessment}');
            _logs.add('  处理时间: ${result.processingTime}秒');
            _logs.add('  输出路径: ${result.outputPath}');
            _lastCompressResult = result; // 存储压缩结果
          });
        },
        onError: (result) {
          setState(() {
            _status = '超低质量压缩失败';
            _logs.add('压缩失败: ${result.errorMessage}');
          });
        },
      );
    } catch (e) {
      setState(() {
        _status = '超低质量压缩异常: $e';
        _logs.add('错误: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
        _showProgress = false;
        _progress = 0.0;
      });
    }
  }

  /// 测试获取压缩建议
  Future<void> _testCompressionSuggestion() async {
    if (_selectedVideoPath == null) {
      setState(() {
        _logs.add('请先选择视频文件');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = '分析视频并获取压缩建议...';
    });

    try {
      final videoInfo = await VideoCompressUtils.getVideoInfo(
        _selectedVideoPath!,
      );
      if (videoInfo != null) {
        // 获取不同目标大小的压缩建议
        final suggestions = <String, VideoCompressConfig>{};

        // 10MB目标
        suggestions['10MB'] = VideoCompressUtils.getCompressionSuggestion(
          videoInfo,
          targetFileSize: 10,
        );

        // 50MB目标
        suggestions['50MB'] = VideoCompressUtils.getCompressionSuggestion(
          videoInfo,
          targetFileSize: 50,
        );

        // 100MB目标
        suggestions['100MB'] = VideoCompressUtils.getCompressionSuggestion(
          videoInfo,
          targetFileSize: 100,
        );

        setState(() {
          _status = '压缩建议分析完成';
          _logs.add('视频信息:');
          _logs.add(
            '  时长: ${videoInfo.duration ~/ 60}分${videoInfo.duration % 60}秒',
          );
          _logs.add('  分辨率: ${videoInfo.width}x${videoInfo.height}');
          _logs.add('  文件大小: ${_formatFileSize(videoInfo.fileSize)}');
          _logs.add('  视频编码: ${videoInfo.videoCodec}');
          _logs.add('  音频编码: ${videoInfo.audioCodec ?? "无"}');
          _logs.add('  比特率: ${videoInfo.bitrate} kbps');
          _logs.add('  帧率: ${videoInfo.fps} fps');
          _logs.add('');
          _logs.add('压缩建议:');

          suggestions.forEach((target, config) {
            _logs.add('  $target 目标:');
            _logs.add('    质量: ${config.quality.name}');
            _logs.add('    预设: ${config.preset.name}');
            _logs.add('    CRF值: ${config.crfValue}');
            _logs.add('    音频比特率: ${config.audioBitrate} kbps');
          });
        });
      } else {
        setState(() {
          _status = '无法获取视频信息';
          _logs.add('无法获取视频信息');
        });
      }
    } catch (e) {
      setState(() {
        _status = '获取压缩建议失败: $e';
        _logs.add('错误: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 测试批量压缩
  Future<void> _testBatchCompress() async {
    if (_selectedVideoPath == null) {
      setState(() {
        _logs.add('请先选择视频文件');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showProgress = true;
      _progress = 0.0;
      _status = '开始批量压缩测试...';
    });

    try {
      // 使用同一个文件进行多次压缩测试
      final testFiles = [_selectedVideoPath!];
      final configs = [
        const VideoCompressConfig(
          quality: VideoCompressQuality.ultraLow,
          preset: VideoCompressPreset.ultrafast,
        ),
        const VideoCompressConfig(
          quality: VideoCompressQuality.low,
          preset: VideoCompressPreset.fast,
        ),
        const VideoCompressConfig(
          quality: VideoCompressQuality.medium,
          preset: VideoCompressPreset.medium,
        ),
      ];

      final results = <VideoCompressResult>[];

      for (int i = 0; i < configs.length; i++) {
        setState(() {
          _status = '批量压缩测试 - ${i + 1}/${configs.length}';
        });

        await VideoCompressUtils.compressVideo(
          testFiles[0],
          config: configs[i],
          onProgress: (progress) {
            setState(() {
              _progress = (i + progress) / configs.length;
            });
          },
          onError: (result) {
            setState(() {
              results.add(result);
            });
          },
          onSuccess: (result) {
            setState(() {
              results.add(result);
            });
          },
        );
      }
    } catch (e) {
      setState(() {
        _status = '批量压缩测试失败: $e';
        _logs.add('错误: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
        _showProgress = false;
        _progress = 0.0;
      });
    }
  }

  /// 测试编码器支持
  Future<void> _testCodecSupport() async {
    setState(() {
      _isLoading = true;
      _status = '检查编码器支持...';
    });

    try {
      final codecs = await VideoCompressUtils.getSupportedCodecs();
      final testCodecs = ['h264', 'h265', 'aac', 'mp3', 'vp9', 'av1'];

      setState(() {
        _status = '编码器支持检查完成';
        _logs.add('支持的编码器数量: ${codecs.length}');
        _logs.add('常用编码器检查:');
      });

      for (final codec in testCodecs) {
        final supported = await VideoCompressUtils.isCodecSupported(codec);
        setState(() {
          _logs.add('  $codec: ${supported ? "✓ 支持" : "✗ 不支持"}');
        });
      }
    } catch (e) {
      setState(() {
        _status = '编码器支持检查失败: $e';
        _logs.add('错误: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 测试编码器和格式检查
  Future<void> _testCodecFormatCheck() async {
    setState(() {
      _isLoading = true;
      _status = '检查编码器和格式支持...';
    });

    try {
      final codecs = ['h264', 'h265', 'aac', 'mp3'];
      final formats = ['mp4', 'avi', 'mov', 'mkv'];

      setState(() {
        _status = '编码器和格式检查完成';
        _logs.add('编码器支持检查:');
      });

      for (final codec in codecs) {
        final supported = await FFmpegManager.isCodecSupported(codec);
        setState(() {
          _logs.add('  $codec: ${supported ? "✓ 支持" : "✗ 不支持"}');
        });
      }

      setState(() {
        _logs.add('格式支持检查:');
      });

      for (final format in formats) {
        final supported = await FFmpegManager.isFormatSupported(format);
        setState(() {
          _logs.add('  $format: ${supported ? "✓ 支持" : "✗ 不支持"}');
        });
      }
    } catch (e) {
      setState(() {
        _status = '检查失败: $e';
        _logs.add('错误: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 清理临时文件
  Future<void> _cleanupTempFiles() async {
    setState(() {
      _isLoading = true;
      _status = '清理临时文件...';
    });

    try {
      await VideoCompressUtils.cleanupTempFiles();
      setState(() {
        _status = '临时文件清理完成';
        _logs.add('临时文件已清理');
      });
    } catch (e) {
      setState(() {
        _status = '清理失败: $e';
        _logs.add('错误: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 生成测试视频
  Future<void> _generateTestVideo() async {
    setState(() {
      _isLoading = true;
      _showProgress = true;
      _progress = 0.0;
      _status = '生成测试视频...';
    });

    try {
      // 使用FFmpeg生成一个简单的测试视频
      final result = await FFmpegManager.executeCommand(
        '-f lavfi -i testsrc=duration=10:size=1280x720:rate=30 -f lavfi -i sine=frequency=1000:duration=10 -c:v libx264 -c:a aac -shortest -y test_video.mp4',
        onProgress: (progress) {
          AppLogger().i('FFmpeg进度更新: $progress'); // 添加调试信息
          setState(() {
            _progress = progress;
          });
        },
      );

      if (result.success) {
        final testVideoPath = 'test_video.mp4';
        final testFile = File(testVideoPath);
        if (await testFile.exists()) {
          setState(() {
            _selectedVideoPath = testVideoPath;
            _status = '测试视频生成完成';
            _logs.add('测试视频已生成: $testVideoPath');
            _logs.add('视频时长: 10秒');
            _logs.add('分辨率: 1280x720');
            _logs.add('帧率: 30fps');
            _logs.add('音频: 1000Hz正弦波');
          });
        } else {
          setState(() {
            _status = '测试视频生成失败';
            _logs.add('测试视频文件未找到');
          });
        }
      } else {
        setState(() {
          _status = '测试视频生成失败';
          _logs.add('生成失败: ${result.errorMessage}');
        });
      }
    } catch (e) {
      setState(() {
        _status = '测试视频生成异常: $e';
        _logs.add('错误: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
        _showProgress = false;
        _progress = 0.0;
      });
    }
  }

  /// 测试自定义FFmpeg命令
  Future<void> _testCustomCommand() async {
    final TextEditingController commandController = TextEditingController();
    commandController.text = '-version';

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('执行FFmpeg命令'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请输入FFmpeg命令:'),
            const SizedBox(height: 8),
            TextField(
              controller: commandController,
              decoration: const InputDecoration(
                hintText: '例如: -version, -codecs, -formats',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(commandController.text),
            child: const Text('执行'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _status = '执行FFmpeg命令...';
      });

      try {
        final commandResult = await FFmpegManager.executeCommand(result);

        setState(() {
          if (commandResult.success) {
            _status = '命令执行成功';
            _logs.add('执行命令: $result');
            _logs.add('执行结果:');
            if (commandResult.output != null) {
              _logs.add(commandResult.output!);
            }
            if (commandResult.logs != null) {
              _logs.add('日志:');
              _logs.add(commandResult.logs!);
            }
          } else {
            _status = '命令执行失败';
            _logs.add('执行命令: $result');
            _logs.add('错误: ${commandResult.errorMessage}');
          }
        });
      } catch (e) {
        setState(() {
          _status = '命令执行异常: $e';
          _logs.add('错误: $e');
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 批量测试
  Future<void> _runBatchTest() async {
    setState(() {
      _isLoading = true;
      _status = '开始批量测试...';
      _logs.add('=== 开始批量测试 ===');
    });

    try {
      // 1. 检查FFmpeg状态
      setState(() {
        _status = '批量测试 - 检查FFmpeg状态...';
      });
      final isAvailable = await FFmpegManager.isAvailable();
      setState(() {
        _logs.add('✓ FFmpeg状态检查: ${isAvailable ? "可用" : "不可用"}');
      });

      if (!isAvailable) {
        setState(() {
          _status = '批量测试失败 - FFmpeg不可用';
          _logs.add('✗ FFmpeg不可用，停止测试');
        });
        return;
      }

      // 2. 获取版本信息
      setState(() {
        _status = '批量测试 - 获取版本信息...';
      });
      final version = await FFmpegManager.getVersion();
      setState(() {
        _logs.add('✓ 版本信息获取: ${version != null ? "成功" : "失败"}');
        if (version != null) {
          _logs.add('  版本: ${version.split('\n').first}');
        }
      });

      // 3. 检查编码器
      setState(() {
        _status = '批量测试 - 检查编码器...';
      });
      final codecs = await FFmpegManager.getSupportedCodecs();
      final commonCodecs = ['h264', 'h265', 'aac', 'mp3'];
      setState(() {
        _logs.add('✓ 编码器检查: 支持 ${codecs.length} 个编码器');
        for (final codec in commonCodecs) {
          final supported = codecs.any((c) => c.toLowerCase().contains(codec));
          _logs.add('  $codec: ${supported ? "✓" : "✗"}');
        }
      });

      // 4. 检查格式
      setState(() {
        _status = '批量测试 - 检查格式...';
      });
      final formats = await FFmpegManager.getSupportedFormats();
      final commonFormats = ['mp4', 'avi', 'mov', 'mkv'];
      setState(() {
        _logs.add('✓ 格式检查: 支持 ${formats.length} 个格式');
        for (final format in commonFormats) {
          final supported = formats.any(
            (f) => f.toLowerCase().contains(format),
          );
          _logs.add('  $format: ${supported ? "✓" : "✗"}');
        }
      });

      // 5. 检查功能
      setState(() {
        _status = '批量测试 - 检查功能...';
      });
      final features = ['libx264', 'libx265', 'aac'];
      setState(() {
        _logs.add('✓ 功能检查:');
      });
      for (final feature in features) {
        final hasFeature = await FFmpegManager.hasFeature(feature);
        setState(() {
          _logs.add('  $feature: ${hasFeature ? "✓" : "✗"}');
        });
      }

      setState(() {
        _status = '批量测试完成';
        _logs.add('=== 批量测试完成 ===');
      });
    } catch (e) {
      setState(() {
        _status = '批量测试失败: $e';
        _logs.add('✗ 批量测试异常: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 测试进度条显示
  Future<void> _testProgressBar() async {
    setState(() {
      _isLoading = true;
      _showProgress = true;
      _progress = 0.0;
      _status = '测试进度条显示...';
    });

    // 模拟进度更新
    for (int i = 0; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      setState(() {
        _progress = i / 100.0;
        _status = '测试进度条显示... $i%';
      });
    }

    setState(() {
      _status = '进度条测试完成';
      _logs.add('进度条测试完成');
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
      _showProgress = false;
      _progress = 0.0;
    });
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// 清理日志
  void _clearLogs() {
    setState(() {
      _logs.clear();
      _status = '日志已清理';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // 状态显示
        Container(
          padding: const EdgeInsets.all(16),
          color: _status.contains('可用') || _status.contains('完成')
              ? Colors.green.shade100
              : Colors.red.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '状态: $_status',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
              if (_showProgress) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(value: _progress),
                Text('进度: ${(_progress * 100).toStringAsFixed(1)}%'),
              ],
            ],
          ),
        ),

        // 文件选择
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '视频文件:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedVideoPath ?? '未选择文件',
                      style: TextStyle(
                        color: _selectedVideoPath != null
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _selectVideoFile,
                    child: const Text('选择文件'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '或者生成一个测试视频进行测试',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _generateTestVideo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('生成测试视频'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 视频播放
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '视频播放:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '输入视频: ${_selectedVideoPath?.split('/').last ?? '未选择'}',
                          style: TextStyle(
                            color: _selectedVideoPath != null
                                ? Colors.black
                                : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        if (_selectedVideoPath != null)
                          Text(
                            '大小: ${_formatFileSize(File(_selectedVideoPath!).lengthSync())}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading || _selectedVideoPath == null
                        ? null
                        : _playInputVideo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('播放输入视频'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '输出视频: ${_lastCompressResult?.outputPath?.split('/').last ?? '未生成'}',
                          style: TextStyle(
                            color: _lastCompressResult?.outputPath != null
                                ? Colors.black
                                : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        if (_lastCompressResult?.compressedSize != null)
                          Text(
                            '大小: ${_formatFileSize(_lastCompressResult!.compressedSize!)} (压缩率: ${_lastCompressResult!.compressionRatio?.toStringAsFixed(1)}%)',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed:
                        _isLoading || _lastCompressResult?.outputPath == null
                        ? null
                        : _playOutputVideo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('播放输出视频'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '查看所有输出视频文件',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _viewAllOutputVideos,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('查看所有输出视频'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed:
                        _isLoading ||
                            _selectedVideoPath == null ||
                            _lastCompressResult?.outputPath == null
                        ? null
                        : _compareVideos,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('比较视频'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 基础测试按钮
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '基础功能测试:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _checkFFmpegStatus,
                    child: const Text('检查状态'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _testCodecs,
                    child: const Text('测试编码器'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _testFormats,
                    child: const Text('测试格式'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _testConfiguration,
                    child: const Text('获取配置'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _testFeatures,
                    child: const Text('功能检查'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _testCodecFormatCheck,
                    child: const Text('编码器格式检查'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _testCustomCommand,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('自定义命令'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _runBatchTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('批量测试'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _testProgressBar,
                    child: const Text('测试进度条'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 媒体信息测试按钮
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '媒体信息测试:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _testMediaInfo,
                    child: const Text('获取媒体信息'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 视频压缩测试按钮
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '视频压缩测试:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _testVideoCompress,
                    child: const Text('快速压缩'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _testHighQualityCompress,
                    child: const Text('高质量压缩'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _testCustomCompress,
                    child: const Text('自定义压缩'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _testUltraLowQualityCompress,
                    child: const Text('超低质量压缩'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _testCompressionSuggestion,
                    child: const Text('获取压缩建议'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _testBatchCompress,
                    child: const Text('批量压缩'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _testCodecSupport,
                    child: const Text('检查编码器支持'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _cleanupTempFiles,
                    child: const Text('清理临时文件'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 日志显示
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '测试日志:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton(onPressed: _clearLogs, child: const Text('清理')),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _logs.map((log) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          log,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
