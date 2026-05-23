import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:restcut/api/models/autoclip/clip_models.dart';
import 'package:restcut/services/storage_service.dart' show storage;
import 'package:restcut/api/models/autoclip/video_models.dart';
import 'package:restcut/models/autoclip_models.dart';
import 'package:restcut/models/task.dart';
import 'package:restcut/models/video.dart';
import 'package:restcut/pages/clip/round_clip_page.dart';
import 'package:restcut/services/memory_stream_service.dart';
import 'package:restcut/store/task/task_manager.dart';
import 'package:restcut/store/video.dart';
import 'package:restcut/utils/logger_utils.dart';
import 'package:restcut/utils/video_utils.dart';
import 'package:restcut/widgets/file_picker/file_selection_page.dart';
import 'package:uuid/uuid.dart';

/// 视频片段检测任务测试页面
class AutoClipperTestTab extends StatefulWidget {
  const AutoClipperTestTab({super.key});

  @override
  State<AutoClipperTestTab> createState() => _AutoClipperTestTabState();
}

class _AutoClipperTestTabState extends State<AutoClipperTestTab> {
  bool _isLoading = false;
  String _status = '准备就绪';
  final List<String> _logs = [];
  String? _selectedVideoPath;
  double _progress = 0.0;
  bool _showProgress = false;

  // 配置相关
  SportType _selectedSportType = SportType.pingpong;
  ModeEnum _mode = ModeEnum.backendClip;
  MatchType _matchType = MatchType.singlesMatch;
  bool _greatBallEditing = true;
  bool _removeReplay = true;
  double _reserveTimeBeforeSingleRound = 1.0;
  double _reserveTimeAfterSingleRound = 1.0;
  double _minimumDurationSingleRound = 2.0;
  double _minimumDurationGreatBall = 10.0;
  double _fireballMaxSeconds = 2.0;
  bool _mergeFireBallAndPlayBall = true;

  VideoSegmentDetectTask? _currentTask;
  EdittingVideoRecord? _lastEdittingRecord;
  String? _frameStreamId;

  final List<SegmentInfo> _realtimeSegments = [];
  double _frameInterval = 5.0; // 帧提取间隔
  double _simulationSpeed = 1.0; // 模拟速度倍数

  // 实时测试相关变量
  bool _isRealtimeRunning = false;
  double _realtimeCurrentTime = 0.0;

  // 测试模式
  bool _isRealtimeMode = false;

  StreamController<Tuple<double, Uint8List>?>? _controller;

  @override
  void dispose() {
    log("auto_clipper_test_tab.dart onDispose");
    super.dispose();
  }

  /// 选择视频文件
  Future<void> _selectVideoFile() async {
    final result = await FileSelection.selectVideos(
      context: context,
      allowMultiple: false,
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _selectedVideoPath = result.first.path;
      });
    }
  }

  /// 执行视频片段检测任务测试
  Future<void> _runVideoSegmentDetectTest() async {
    try {
      setState(() {
        _isLoading = true;
        _showProgress = true;
        _progress = 0.0;
        _status = '开始视频片段检测...';
        _logs.add('开始视频片段检测任务测试');
      });

      if (_isRealtimeMode) {
        _currentTask = await _startRealtimeTest();
      } else {
        _currentTask = await _startBatchTest();
      }

      TaskStorage().removeTaskTypeListener(
        TaskTypeEnum.videoSegmentDetect,
        _onTaskProgress,
      );
      TaskStorage().addTaskTypeListener(
        TaskTypeEnum.videoSegmentDetect,
        _onTaskProgress,
      );
    } catch (e, stackTrace) {
      setState(() {
        _status = '视频片段检测失败: ${e.toString()}';
        _logs.add('视频片段检测失败: ${e.toString()}, stack trace: $stackTrace');
        _isLoading = false;
        _showProgress = false;
      });
    }
  }

  Future<VideoSegmentDetectTask> _startBatchTest() async {
    final taskId = Uuid().v4();
    EdittingVideoRecord edittingRecord = EdittingVideoRecord(
      id: Uuid().v4(),
      processStatus: LocalVideoProcessStatusEnum.processing,
      sportType: _selectedSportType,
      filePath: _selectedVideoPath!,
      thumbnailPath: _selectedVideoPath!,
      allMatchSegments: [],
      favoritesMatchSegments: [],
    );

    await LocalVideoStorage().add(edittingRecord);
    final task = VideoSegmentDetectTask(
      id: taskId,
      edittingRecordId: edittingRecord.id,
      name: '视频片段检测测试',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      videoPath: _selectedVideoPath!,
      sportType: _selectedSportType,
      clipConfig: _createClipConfig(),
      frameStreamId: null,
      detectedTime: _currentTask?.detectedTime ?? 0.0,
    );

    await TaskStorage().addAndAsyncProcessTask(task);
    return task;
  }

  /// 停止实时测试
  Future<void> _stopRealtimeTest() async {
    _controller?.close();
    MemoryStreamService().removeStream(_frameStreamId!);
    TaskStorage().removeTaskTypeListener(
      TaskTypeEnum.videoSegmentDetect,
      _onTaskProgress,
    );
    _controller = null;
    _frameStreamId = null;
    setState(() {
      _isRealtimeRunning = false;
      _realtimeCurrentTime = 0.0;
    });
  }

  /// 创建剪辑配置
  VideoClipConfigReqVo _createClipConfig() {
    if (_selectedSportType == SportType.pingpong) {
      return PingPongVideoClipConfigReqVo(
        mode: _mode,
        matchType: _matchType,
        greatBallEditing: _greatBallEditing,
        removeReplay: _removeReplay,
        reserveTimeBeforeSingleRound: _reserveTimeBeforeSingleRound,
        reserveTimeAfterSingleRound: _reserveTimeAfterSingleRound,
        minimumDurationSingleRound: _minimumDurationSingleRound,
        minimumDurationGreatBall: _minimumDurationGreatBall,
        maxFireBallTime: _fireballMaxSeconds,
        mergeFireBallAndPlayBall: _mergeFireBallAndPlayBall,
      );
    } else {
      return BadmintonVideoClipConfigReqVo(
        mode: _mode,
        matchType: _matchType,
        greatBallEditing: _greatBallEditing,
        removeReplay: _removeReplay,
        reserveTimeBeforeSingleRound: _reserveTimeBeforeSingleRound,
        reserveTimeAfterSingleRound: _reserveTimeAfterSingleRound,
        minimumDurationSingleRound: _minimumDurationSingleRound,
        minimumDurationGreatBall: _minimumDurationGreatBall,
      );
    }
  }

  Future<void> _onTaskProgress() async {
    if (mounted) {
      final taskById =
          TaskStorage().getTaskById(_currentTask!.id)
              as VideoSegmentDetectTask?;
      final record =
          await LocalVideoStorage().findById(taskById!.edittingRecordId!)
              as EdittingVideoRecord?;
      setState(() {
        if (record != null) {
          _progress = taskById.progress;
          if (taskById.status == TaskStatusEnum.completed) {
            _isLoading = false;
            _showProgress = false;
            if (_frameStreamId != null) {
              _stopRealtimeTest();
            }
            _status = '视频片段检测完成';
            _logs.add('视频片段检测完成');
            _loadEdittingRecord(taskById.edittingRecordId);
          } else if (taskById.status == TaskStatusEnum.failed) {
            _isLoading = false;
            _showProgress = false;
            if (_frameStreamId != null) {
              _stopRealtimeTest();
            }
            _status = '视频片段检测失败';
            _logs.add(
              '视频片段检测失败: ${taskById.extraInfo}, stack trace: ${StackTrace.current}',
            );
          } else {
            _status = '处理中: ${(taskById.progress * 100).toStringAsFixed(1)}%';
            _logs.add("currentRecords: ${record.allMatchSegments}");
            _logs.add('处理中: ${(taskById.progress * 100).toStringAsFixed(1)}%');
          }
        }
      });
    }
  }

  /// 加载编辑记录
  Future<void> _loadEdittingRecord(String? recordId) async {
    if (recordId == null) return;

    try {
      final record = await LocalVideoStorage().findById(recordId);
      if (record is EdittingVideoRecord) {
        setState(() {
          _lastEdittingRecord = record;
          _logs.add('加载编辑记录成功');
          _logs.add('所有片段数量: ${record.allMatchSegments.length}');
          _logs.add('收藏片段数量: ${record.favoritesMatchSegments.length}');
        });
      }
    } catch (e, stackTrace) {
      AppLogger().e('Error loading editting record: $e', stackTrace);
    }
  }

  /// 创建帧流用于测试
  Future<VideoSegmentDetectTask> _startRealtimeTest() async {
    setState(() {
      _isRealtimeRunning = true;
      _realtimeCurrentTime = 0.0;
      _realtimeSegments.clear();
    });

    final tempDir = await Directory.systemTemp.createTemp('frame_stream_');

    Stream<String> thumbnailsStream = await VideoUtils.generateThumbnails(
      _selectedVideoPath!,
      _frameInterval,
      dirPath: tempDir.path,
    );

    // _controller = createStreamController(thumbnailsStream);
    var timestampFrameStream = createTimestampFrameStream(thumbnailsStream);

    // _frameStreamId = MemoryStreamService().addStream(_controller!.stream);
    _frameStreamId = MemoryStreamService().addStream(timestampFrameStream);
    final appDocDir = storage.getApplicationDocumentsDirectory();

    EdittingVideoRecord edittingRecord = EdittingVideoRecord(
      id: Uuid().v4(),
      processStatus: LocalVideoProcessStatusEnum.processing,
      sportType: _selectedSportType,
      filePath: _selectedVideoPath!,
      thumbnailPath: _selectedVideoPath!,
      allMatchSegments: [],
      favoritesMatchSegments: [],
    );

    await LocalVideoStorage().add(edittingRecord);

    final taskId = Uuid().v4();
    final task = VideoSegmentDetectTask(
      id: taskId,
      edittingRecordId: edittingRecord.id,
      name: '视频片段检测测试',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      videoPath: _selectedVideoPath!,
      image: await VideoUtils.generateVideoThumbnail(
        _selectedVideoPath!,
        dirPath: appDocDir.path,
      ),
      sportType: _selectedSportType,
      clipConfig: _createClipConfig(),
      frameStreamId: _frameStreamId,
      detectedTime: _currentTask?.detectedTime ?? 0.0,
    );
    await TaskStorage().addAndAsyncProcessTask(task);
    return task;
  }

  Stream<Tuple<double, Uint8List>> createTimestampFrameStream(
    Stream<String> frameFilesStream,
  ) {
    int computationCount = 0;
    return frameFilesStream.map((data) {
      _realtimeCurrentTime = computationCount / _frameInterval;
      computationCount++;
      return Tuple<double, Uint8List>(
        item1: _realtimeCurrentTime,
        item2: File(data).readAsBytesSync(),
      );
    });
  }

  /// 清理日志
  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  /// 切换测试模式
  void _toggleTestMode() {
    setState(() {
      _isRealtimeMode = !_isRealtimeMode;
      _logs.add('切换到${_isRealtimeMode ? '实时' : '离线'}测试模式');
    });
  }

  /// 导航到回合剪辑页面
  void _navigateToRoundClip() {
    if (_lastEdittingRecord == null) {
      setState(() {
        _logs.add('没有可用的编辑记录，无法进入回合剪辑页面');
      });
      return;
    }

    setState(() {
      _logs.add('跳转到回合剪辑页面');
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RoundClipPage(videoRecord: _lastEdittingRecord),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 状态显示
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
                        if (_showProgress) ...[
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: _progress),
                        ],
                        if (_isRealtimeRunning) ...[
                          const SizedBox(height: 8),
                          Text(
                            '实时检测时间: ${_realtimeCurrentTime.toStringAsFixed(2)}s',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.blue,
                            ),
                          ),
                          Text(
                            '已检测片段: ${_realtimeSegments.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 测试模式选择
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '测试模式',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _toggleTestMode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isRealtimeMode
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                                child: Text(
                                  _isRealtimeMode ? '实时测试' : '离线测试',
                                  style: TextStyle(
                                    color: _isRealtimeMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRealtimeMode
                              ? '实时测试模式：模拟实时视频流，逐帧检测动作片段'
                              : '离线测试模式：处理完整视频文件，批量检测所有片段',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 帧流配置（仅实时模式显示）
                if (_isRealtimeMode) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '帧流配置',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildSliderRow('帧提取间隔', _frameInterval, 0.5, 5.0, (
                            value,
                          ) {
                            setState(() {
                              _frameInterval = value;
                            });
                          }),

                          _buildSliderRow('模拟速度', _simulationSpeed, 0.1, 5.0, (
                            value,
                          ) {
                            setState(() {
                              _simulationSpeed = value;
                            });
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 配置设置
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '配置设置',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 运动类型选择
                        Row(
                          children: [
                            const Text('运动类型: '),
                            DropdownButton<SportType>(
                              value: _selectedSportType,
                              items: SportType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    type == SportType.pingpong ? '乒乓球' : '羽毛球',
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedSportType = value;
                                  });
                                }
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // 模式选择
                        Row(
                          children: [
                            const Text('模式: '),
                            DropdownButton<ModeEnum>(
                              value: _mode,
                              items: ModeEnum.values.map((mode) {
                                return DropdownMenuItem(
                                  value: mode,
                                  child: Text(
                                    mode == ModeEnum.backendClip
                                        ? '后端剪辑'
                                        : '自定义剪辑',
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _mode = value;
                                  });
                                }
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // 比赛类型
                        Row(
                          children: [
                            const Text('比赛类型: '),
                            DropdownButton<MatchType>(
                              value: _matchType,
                              items: MatchType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    type == MatchType.singlesMatch
                                        ? '单打'
                                        : '双打',
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _matchType = value;
                                  });
                                }
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // 布尔选项
                        Row(
                          children: [
                            Checkbox(
                              value: _greatBallEditing,
                              onChanged: (value) {
                                setState(() {
                                  _greatBallEditing = value ?? true;
                                });
                              },
                            ),
                            const Text('精彩球编辑'),
                            const SizedBox(width: 16),
                            Checkbox(
                              value: _removeReplay,
                              onChanged: (value) {
                                setState(() {
                                  _removeReplay = value ?? true;
                                });
                              },
                            ),
                            const Text('移除回放'),
                          ],
                        ),

                        if (_selectedSportType == SportType.pingpong) ...[
                          Row(
                            children: [
                              Checkbox(
                                value: _mergeFireBallAndPlayBall,
                                onChanged: (value) {
                                  setState(() {
                                    _mergeFireBallAndPlayBall = value ?? true;
                                  });
                                },
                              ),
                              const Text('合并发球和打球'),
                            ],
                          ),
                        ],

                        const SizedBox(height: 8),

                        // 数值配置
                        _buildSliderRow(
                          '预留时间(前)',
                          _reserveTimeBeforeSingleRound,
                          0.0,
                          5.0,
                          (value) {
                            setState(() {
                              _reserveTimeBeforeSingleRound = value;
                            });
                          },
                        ),

                        _buildSliderRow(
                          '预留时间(后)',
                          _reserveTimeAfterSingleRound,
                          0.0,
                          5.0,
                          (value) {
                            setState(() {
                              _reserveTimeAfterSingleRound = value;
                            });
                          },
                        ),

                        _buildSliderRow(
                          '最小时长(单轮)',
                          _minimumDurationSingleRound,
                          1.0,
                          10.0,
                          (value) {
                            setState(() {
                              _minimumDurationSingleRound = value;
                            });
                          },
                        ),

                        _buildSliderRow(
                          '最小时长(精彩球)',
                          _minimumDurationGreatBall,
                          5.0,
                          30.0,
                          (value) {
                            setState(() {
                              _minimumDurationGreatBall = value;
                            });
                          },
                        ),

                        if (_selectedSportType == SportType.pingpong) ...[
                          _buildSliderRow(
                            '发球最大时长',
                            _fireballMaxSeconds,
                            0.5,
                            5.0,
                            (value) {
                              setState(() {
                                _fireballMaxSeconds = value;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 操作按钮
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: _isLoading ? null : _selectVideoFile,
                        child: const Text('选择视频'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isLoading || _selectedVideoPath == null
                            ? null
                            : _runVideoSegmentDetectTest,
                        child: Text(_isRealtimeMode ? '开始实时检测' : '执行检测'),
                      ),
                      if (_isRealtimeRunning) ...[
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _stopRealtimeTest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text(
                            '停止实时检测',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 结果查看按钮
                if (_lastEdittingRecord != null) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: _navigateToRoundClip,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('处理回合'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
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
      ),
    );
  }

  /// 构建滑块行
  Widget _buildSliderRow(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text('$label: ${value.toStringAsFixed(1)}'),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: ((max - min) * 10).round(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
