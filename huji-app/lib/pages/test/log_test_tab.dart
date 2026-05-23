import 'package:flutter/material.dart';
import 'package:restcut/utils/logger_utils.dart';

class LogTestTab extends StatefulWidget {
  const LogTestTab({super.key});

  @override
  State<LogTestTab> createState() => _LogTestTabState();
}

class _LogTestTabState extends State<LogTestTab> {
  final List<String> _testResults = [];

  void _addResult(String result) {
    setState(() {
      _testResults.add(
        '${DateTime.now().toString().substring(11, 19)}: $result',
      );
    });
  }

  void _testInfoLog() {
    AppLogger.instance.i('这是一条信息日志测试');
    _addResult('发送信息日志');
  }

  void _testDebugLog() {
    AppLogger.instance.d('这是一条调试日志测试');
    _addResult('发送调试日志');
  }

  void _testWarningLog() {
    AppLogger.instance.w('这是一条警告日志测试');
    _addResult('发送警告日志');
  }

  void _testErrorLog() {
    try {
      throw Exception('这是一个测试异常');
    } catch (e, stackTrace) {
      AppLogger.instance.e('这是一条错误日志测试', stackTrace, e);
      _addResult('发送错误日志');
    }
  }

  void _testMultipleLogs() {
    for (int i = 1; i <= 5; i++) {
      AppLogger.instance.i('批量日志测试 $i');
    }
    _addResult('发送5条批量日志');
  }

  void _clearResults() {
    setState(() {
      _testResults.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '日志测试',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            '点击下面的按钮测试不同类型的日志输出到adb logcat。\n'
            '使用以下命令查看日志：\n'
            'adb logcat | grep "flutter"',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: _testInfoLog,
                child: const Text('信息日志'),
              ),
              ElevatedButton(
                onPressed: _testDebugLog,
                child: const Text('调试日志'),
              ),
              ElevatedButton(
                onPressed: _testWarningLog,
                child: const Text('警告日志'),
              ),
              ElevatedButton(
                onPressed: _testErrorLog,
                child: const Text('错误日志'),
              ),
              ElevatedButton(
                onPressed: _testMultipleLogs,
                child: const Text('批量日志'),
              ),
              ElevatedButton(
                onPressed: _clearResults,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('清空结果'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '测试结果:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: _testResults.isEmpty
                  ? const Center(
                      child: Text(
                        '暂无测试结果',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _testResults.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            _testResults[index],
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
