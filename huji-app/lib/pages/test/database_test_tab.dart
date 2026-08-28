import 'package:flutter/material.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/store/video.dart';
import 'package:shared_ui/shared_ui.dart';

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
        TpButton(
          variant: TpButtonVariant.primary,
          onPressed: () async {
            await LocalVideoStorage().resetDatabase();
            if (context.mounted) {
              TpToast.show(
                context,
                message: 'LocalVideoStorage数据库已重置',
                variant: TpToastVariant.info,
              );
            }
          },
          child: const Text('重置LocalVideoStorage数据库'),
        ),
        const SizedBox(height: 16),
        TpButton(
          variant: TpButtonVariant.primary,
          onPressed: () async {
            await TaskStorage().resetDatabase();
            if (context.mounted) {
              TpToast.show(
                context,
                message: 'TaskStorage数据库已重置',
                variant: TpToastVariant.info,
              );
            }
          },
          child: const Text('重置TaskStorage数据库'),
        ),
      ],
    ),
  );
}
