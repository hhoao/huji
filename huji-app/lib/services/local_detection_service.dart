import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:restcut/utils/logger_utils.dart';

enum LocalModelStatus { available, notFound, incompatible }

/// Result from local inference.
class LocalInferenceResult {
  final List<Map<String, dynamic>> matchSegments;
  final int frameCount;
  final Duration processingTime;

  const LocalInferenceResult({
    required this.matchSegments,
    required this.frameCount,
    required this.processingTime,
  });
}

/// Manages local YOLO model availability and inference on desktop platforms.
///
/// Uses a Python subprocess (scripts/local_inference.py) that wraps ONNX Runtime
/// for inference. This avoids the complexity of OrtApi struct FFI and works with
/// the pip-installed onnxruntime package already present on dev machines.
class LocalDetectionService {
  final AppLogger _logger = AppLogger();

  /// Check whether ONNX models are available on disk.
  Future<LocalModelStatus> checkModels() async {
    if (!(Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
      return LocalModelStatus.incompatible;
    }
    final modelsDir = _resolveModelsDir();
    if (modelsDir == null) {
      return LocalModelStatus.notFound;
    }
    final dir = Directory(modelsDir);
    if (!await dir.exists()) {
      return LocalModelStatus.notFound;
    }
    final entries = await dir.list(recursive: true).toList();
    final onnxFiles = entries.where((e) => e.path.endsWith('.onnx')).toList();
    if (onnxFiles.isEmpty) {
      return LocalModelStatus.notFound;
    }
    // Also check Python is available
    if (!await _checkPython()) {
      _logger.w('Python3 not found on PATH');
      return LocalModelStatus.notFound;
    }
    _logger.i('Found ${onnxFiles.length} local models');
    return LocalModelStatus.available;
  }

  Future<bool> _checkPython() async {
    try {
      final python = _resolvePython();
      final result = await Process.run(python, ['--version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Run local inference on a video file via Python ONNX Runtime subprocess.
  Future<LocalInferenceResult> runInference({
    required String videoPath,
    required String sportType,
    required String matchType,
    void Function(double progress, String stage)? onProgress,
  }) async {
    final modelsDir = _resolveModelsDir();
    if (modelsDir == null) {
      throw Exception('Models directory not found');
    }
    final modelPath = '$modelsDir/$sportType/$matchType/best.onnx';
    if (!File(modelPath).existsSync()) {
      throw Exception('Model not found: $modelPath');
    }

    final scriptPath = _resolveScriptPath();
    if (scriptPath == null) {
      throw Exception('local_inference.py script not found');
    }

    final pythonPath = _resolvePython();
    onProgress?.call(0.0, '启动本地推理...');

    final outputPath =
        '${Directory.systemTemp.path}/huji_inference_${DateTime.now().millisecondsSinceEpoch}.json';

    try {
      onProgress?.call(0.1, '正在分析视频...');

      final result = await Process.run(pythonPath, [
        scriptPath,
        modelPath,
        videoPath,
        outputPath,
        '--sport', sportType,
        '--match-type', matchType,
      ]);

      if (result.exitCode != 0) {
        final stderr = result.stderr?.toString() ?? '';
        throw Exception('Inference failed: $stderr');
      }

      onProgress?.call(0.9, '读取结果...');

      final outputFile = File(outputPath);
      if (!await outputFile.exists()) {
        throw Exception('Output file not created: $outputPath');
      }

      final jsonText = await outputFile.readAsString();
      final json = jsonDecode(jsonText) as Map<String, dynamic>;

      if (json['status'] != 'ok') {
        throw Exception(json['error'] ?? 'Unknown inference error');
      }

      final segments = (json['match_segments'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      final frameCount = (json['frame_count'] as int?) ?? 0;
      final processingTimeMs = (json['processing_time_ms'] as num?) ?? 0;

      onProgress?.call(1.0, '完成');

      return LocalInferenceResult(
        matchSegments: segments,
        frameCount: frameCount,
        processingTime: Duration(milliseconds: processingTimeMs.toInt()),
      );
    } finally {
      // Clean up output file
      try {
        final f = File(outputPath);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  /// Resolve the Python inference script path.
  String? _resolveScriptPath() {
    // 1. Explicit path
    final fromEnv = Platform.environment['HUJI_INFERENCE_SCRIPT'];
    if (fromEnv != null &&
        fromEnv.isNotEmpty &&
        File(fromEnv).existsSync()) {
      return fromEnv;
    }

    // 2. Relative to executable
    final execDir = File(Platform.resolvedExecutable).parent.path;
    final candidates = [
      '$execDir/../scripts/local_inference.py',
      '$execDir/../../scripts/local_inference.py',
      '$execDir/../../../../restcut_app/scripts/local_inference.py',
      '$execDir/../../../restcut_app/scripts/local_inference.py',
      // Absolute fallback
      '/home/hhoa/git/hhoa/huji/.worktrees/desktop-phase1/restcut_app/scripts/local_inference.py',
      '/home/hhoa/git/hhoa/huji/restcut_app/scripts/local_inference.py',
    ];
    for (final c in candidates) {
      if (File(c).existsSync()) return c;
    }

    return null;
  }

  /// Resolve a Python interpreter that has onnxruntime installed.
  String _resolvePython() {
    // 1. Explicit env override
    final fromEnv = Platform.environment['HUJI_PYTHON_PATH'];
    if (fromEnv != null && fromEnv.isNotEmpty && File(fromEnv).existsSync()) {
      return fromEnv;
    }

    // 2. autoclip-algorithm venv (has onnxruntime)
    const venvPython =
        '/home/hhoa/autoclip/autoclip-algorithm/.venv/bin/python3';
    if (File(venvPython).existsSync()) return venvPython;

    // 3. pyenv Python (has onnxruntime via pip)
    const pyenvPython =
        '/home/hhoa/.pyenv/versions/3.12.8/bin/python3';
    if (File(pyenvPython).existsSync()) return pyenvPython;

    // 4. System python3 (may or may not have onnxruntime)
    return 'python3';
  }

  /// Resolve the models directory.
  String? _resolveModelsDir() {
    final fromEnv = Platform.environment['HUJI_MODELS_DIR'];
    if (fromEnv != null &&
        fromEnv.isNotEmpty &&
        Directory(fromEnv).existsSync()) {
      return fromEnv;
    }

    final execDir = File(Platform.resolvedExecutable).parent.path;
    final candidates = [
      '$execDir/../share/huji/models',
      '$execDir/data/flutter_assets/models',
      '$execDir/../../../../autoclip/autoclip-algorithm/src/resources/models',
      '$execDir/../../../autoclip/autoclip-algorithm/src/resources/models',
      '/home/hhoa/autoclip/autoclip-algorithm/src/resources/models',
    ];
    for (final c in candidates) {
      if (Directory(c).existsSync()) return c;
    }

    final cwdPath = '../autoclip/autoclip-algorithm/src/resources/models';
    if (Directory(cwdPath).existsSync()) return cwdPath;

    return null;
  }
}
