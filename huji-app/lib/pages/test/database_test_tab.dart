import 'package:flutter/material.dart';
import 'package:restcut/store/task/task_manager.dart';
import 'package:restcut/store/video.dart';

class DatabaseTestTab extends StatefulWidget {
  const DatabaseTestTab({super.key});

  @override
  State<DatabaseTestTab> createState() => _DatabaseTestTabState();
}

class _DatabaseTestTabState extends State<DatabaseTestTab> {
  @override
  Widget build(BuildContext context) {
    return _buildDatabaseTestTab(context);
  }
}

Widget _buildDatabaseTestTab(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '数据库测试',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () async {
            await LocalVideoStorage().resetDatabase();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('LocalVideoStorage数据库已重置'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: const Text('重置LocalVideoStorage数据库'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () async {
            await TaskStorage().resetDatabase();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('TaskStorage数据库已重置'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: const Text('重置TaskStorage数据库'),
        ),
      ],
    ),
  );
}
