import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:restcut/constants/autoclip_constants.dart';
import 'package:restcut/constants/file_extensions.dart';

import '../../models/autoclip_models.dart';
import '../../services/large_model_service.dart';
import '../../widgets/file_picker/file_selection_page.dart';

/// 大模型服务测试页面
class LargeModelServiceTestTab extends StatefulWidget {
  const LargeModelServiceTestTab({super.key});

  @override
  State<LargeModelServiceTestTab> createState() =>
      _LargeModelServiceTestTabState();
}

class _LargeModelServiceTestTabState extends State<LargeModelServiceTestTab> {
  bool _isLoading = false;
  String _status = '准备就绪';
  final List<String> _logs = [];

  // 模型相关
  String? _selectedModelPath;
  String? _selectedModelName;
  bool _isModelInitialized = false;
  ModelPredictor? _currentPredictor;

  // 测试相关
  String? _selectedImagePath;
  ActionType? _lastPredictionResult;
  double _predictionConfidence = 0.0;

  // 模型列表
  final List<String> _availableModels = AutoclipConstants.modelNames;

  @override
  void initState() {
    super.initState();
    _initializeDefaultModel();
  }

  /// 初始化默认模型
  void _initializeDefaultModel() {
    setState(() {
      _selectedModelName = _availableModels.first;
      _selectedModelPath =
          AutoclipConstants.modelNamePathMapping[_selectedModelName]!;
    });
  }

  /// 选择测试图片
  Future<void> _selectTestImage() async {
    try {
      final result = await FileSelection.selectImages(context: context);

      if (result != null && result.isNotEmpty) {
        final file = result.first;
        if (file is File && FileExtensions.isImage(path.extension(file.path))) {
          setState(() {
            _selectedImagePath = file.path;
            _logs.add('已选择测试图片: ${path.basename(file.path)}');
          });
        } else {
          setState(() {
            _logs.add('请选择有效的图片文件');
          });
        }
      }
    } catch (e) {
      setState(() {
        _logs.add('选择测试图片失败: ${e.toString()}');
      });
    }
  }

  /// 初始化模型
  Future<void> _initializeModel() async {
    if (_selectedModelPath == null || _selectedModelName == null) {
      setState(() {
        _logs.add('请先选择模型文件');
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _status = '初始化模型...';
        _logs.add('开始初始化模型: $_selectedModelName');
      });

      // 对于模型文件，tflite_flutter插件会自动处理assets路径
      setState(() {
        _logs.add('使用模型文件: $_selectedModelPath');
      });

      // 获取模型预测器
      final largeModelService = LargeModelService.instance;
      _currentPredictor = largeModelService.getPredictor(_selectedModelName!);

      setState(() {
        _isModelInitialized = true;
        _status = '模型初始化完成';
        _logs.add('模型初始化完成');
      });
    } catch (e) {
      setState(() {
        _status = '模型初始化失败: ${e.toString()}';
        _logs.add('模型初始化失败: ${e.toString()}');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 执行预测测试
  Future<void> _runPredictionTest() async {
    if (_currentPredictor == null) {
      setState(() {
        _logs.add('请先初始化模型');
      });
      return;
    }

    if (_selectedImagePath == null) {
      setState(() {
        _logs.add('请先选择测试图片');
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _status = '执行预测...';
        _logs.add('开始执行预测测试');
      });

      // 检查图片文件是否存在（支持File路径和assets路径）
      if (_selectedImagePath!.startsWith('/') ||
          _selectedImagePath!.contains('storage')) {
        // 这是一个文件系统路径
        final imageFile = File(_selectedImagePath!);
        if (!await imageFile.exists()) {
          setState(() {
            _status = '图片文件不存在';
            _logs.add('图片文件不存在: $_selectedImagePath');
          });
          return;
        }
      } else {
        // 这是一个assets路径或相对路径
        setState(() {
          _logs.add('使用模型路径: $_selectedImagePath');
        });
      }

      // 执行预测
      final startTime = DateTime.now();
      final classifierResult = await _currentPredictor!.predictForResult(
        _selectedImagePath!,
        ClassMappings.pingPongClassesMapping,
      );
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;

      setState(() {
        _lastPredictionResult = ClassMappings
            .pingPongClassesMapping[classifierResult.classification.topClass];
        _predictionConfidence = classifierResult.classification.topConfidence;
        _status = '预测完成';
        _logs.add('预测结果: ${_getActionTypeText(_lastPredictionResult!)}');
        _logs.add('预测耗时: ${duration}ms');
        _logs.add('置信度: ${(_predictionConfidence * 100).toStringAsFixed(1)}%');
      });
    } catch (e) {
      setState(() {
        _status = '预测失败: ${e.toString()}';
        _logs.add('预测失败: ${e.toString()}');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 批量预测测试
  Future<void> _runBatchPredictionTest() async {
    if (_currentPredictor == null) {
      setState(() {
        _logs.add('请先初始化模型');
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _status = '执行批量预测...';
        _logs.add('开始执行批量预测测试');
      });

      // 模拟批量预测
      final testImages = <String>[];
      final testDir = Directory(
        path.join(Directory.current.path, 'test_images'),
      );
      if (await testDir.exists()) {
        await for (final file in testDir.list()) {
          if (file is File &&
              FileExtensions.isImage(path.extension(file.path))) {
            testImages.add(file.path);
          }
        }
      }

      if (testImages.isEmpty) {
        setState(() {
          _logs.add('没有找到测试图片，请将测试图片放在 test_images 目录下');
        });
        return;
      }

      final results = <ActionType>[];
      final startTime = DateTime.now();

      for (int i = 0; i < testImages.length; i++) {
        final imagePath = testImages[i];
        try {
          final prediction = await _currentPredictor!.predict(
            imagePath,
            ClassMappings.pingPongClassesMapping,
          );
          results.add(prediction);

          setState(() {
            _logs.add('图片 ${i + 1}: ${_getActionTypeText(prediction)}');
          });
        } catch (e) {
          setState(() {
            _logs.add('图片 ${i + 1}: 预测失败 - ${e.toString()}');
          });
        }
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;

      // 统计结果
      final actionCounts = <ActionType, int>{};
      for (final result in results) {
        actionCounts[result] = (actionCounts[result] ?? 0) + 1;
      }

      setState(() {
        _status = '批量预测完成';
        _logs.add('批量预测完成，共处理 ${testImages.length} 张图片');
        _logs.add('总耗时: ${duration}ms');
        _logs.add(
          '平均耗时: ${(duration / testImages.length).toStringAsFixed(1)}ms/张',
        );
        _logs.add('预测结果统计:');
        for (final entry in actionCounts.entries) {
          _logs.add('  ${_getActionTypeText(entry.key)}: ${entry.value} 次');
        }
      });
    } catch (e) {
      setState(() {
        _status = '批量预测失败: ${e.toString()}';
        _logs.add('批量预测失败: ${e.toString()}');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 释放模型资源
  Future<void> _disposeModel() async {
    if (_currentPredictor == null) {
      setState(() {
        _logs.add('没有已初始化的模型');
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _status = '释放模型资源...';
        _logs.add('开始释放模型资源');
      });

      await _currentPredictor!.dispose();
      _currentPredictor = null;

      setState(() {
        _isModelInitialized = false;
        _status = '模型资源已释放';
        _logs.add('模型资源已释放');
      });
    } catch (e) {
      setState(() {
        _status = '释放模型资源失败: ${e.toString()}';
        _logs.add('释放模型资源失败: ${e.toString()}');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 构建图片预览组件
  Widget _buildImagePreview() {
    if (_selectedImagePath == null) {
      return Container(
        color: Colors.grey[200],
        child: const Center(child: Text('无图片')),
      );
    }

    try {
      // 检查是否是文件系统路径
      if (_selectedImagePath!.startsWith('/') ||
          _selectedImagePath!.contains('storage')) {
        final imageFile = File(_selectedImagePath!);
        return Image.file(
          imageFile,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(height: 4),
                    Text('加载失败', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        // 处理assets路径
        return Image.asset(
          _selectedImagePath!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(height: 4),
                    Text('加载失败', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(height: 4),
              Text('预览失败', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
    }
  }

  /// 获取动作类型文本
  String _getActionTypeText(ActionType actionType) {
    switch (actionType) {
      case ActionType.fireBall:
        return '发球';
      case ActionType.playBall:
        return '打球';
      case ActionType.pickBall:
        return '捡球';
      case ActionType.transition:
        return '过渡';
      case ActionType.playback:
        return '回放';
    }
  }

  /// 清理日志
  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 状态显示
              const Text(
                '状态显示',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '状态: $_status',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _isModelInitialized
                                ? Icons.check_circle
                                : Icons.error,
                            color: _isModelInitialized
                                ? Colors.green
                                : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isModelInitialized ? '模型已初始化' : '模型未初始化',
                            style: TextStyle(
                              color: _isModelInitialized
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 模型配置
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '模型配置',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 模型选择
                      Row(
                        children: [
                          const Text('模型名称: '),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedModelName,
                              items: _availableModels.map((model) {
                                return DropdownMenuItem(
                                  value: model,
                                  child: Text(model),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedModelName = value;
                                    _selectedModelPath = AutoclipConstants
                                        .modelNamePathMapping[value]!;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // 类映射显示
                      const Text(
                        '类映射:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      ...(ClassMappings.pingPongClassesMapping.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            '${entry.key} -> ${_getActionTypeText(entry.value)}',
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 已选择的测试图片
              if (_selectedImagePath != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '已选择的测试图片',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 图片预览
                            Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildImagePreview(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 操作按钮
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : _initializeModel,
                      child: const Text('初始化模型'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _selectTestImage,
                      child: const Text('选择测试图片'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed:
                          _isLoading ||
                              _currentPredictor == null ||
                              _selectedImagePath == null
                          ? null
                          : _runPredictionTest,
                      child: const Text('单张预测'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading || _currentPredictor == null
                          ? null
                          : _runBatchPredictionTest,
                      child: const Text('批量预测'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 预测结果
              if (_lastPredictionResult != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '预测结果',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('动作类型: '),
                            Text(
                              _getActionTypeText(_lastPredictionResult!),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('置信度: '),
                            Text(
                              '${(_predictionConfidence * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 资源管理
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '资源管理',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _isLoading || _currentPredictor == null
                                ? null
                                : _disposeModel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('释放模型资源'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _clearLogs,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('清空日志'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 日志显示
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '日志',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: _clearLogs,
                            child: const Text('清空'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200, // 固定高度替代Expanded
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ListView.builder(
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                _logs[index],
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
