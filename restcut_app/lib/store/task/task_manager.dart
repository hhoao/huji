import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:restcut/utils/logger_utils.dart';
import 'package:path/path.dart';
import 'package:restcut/constants/global.dart';
import 'package:restcut/services/notification/notification_manager.dart';
import 'package:restcut/store/task/download_task_manager.dart';
import 'package:restcut/store/task/image_compress_task_manager.dart';
import 'package:restcut/store/task/video_clip_task_manager.dart';
import 'package:restcut/store/task/video_segment_detect_task.dart';
import 'package:restcut/store/task/video_compress_task_manager.dart';
import 'package:restcut/store/task/video_upload_task_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:synchronized/synchronized.dart';
import 'package:restcut/services/telemetry_service.dart';

import '../../models/task.dart';

class UpdateTaskOnPauseError extends Error {
  final String message;
  UpdateTaskOnPauseError(TaskStatusEnum status)
    : message = 'Task status is paused, cannot update to $status';
}

abstract class AbstractTaskManager extends ChangeNotifier {
  Future<void> processTask(Task task);
  Future<List<Task>> loadTasks(
    List<Map<String, dynamic>> mainTasks,
    List<Map<String, dynamic>> subTasks,
  );

  String getTableName();

  Future<void> pauseTask(Task task) async => {};
  Future<void> resumeTask(Task task) async => {};
  Future<void> cancelTask(Task task) async => {};
  Future<void> retryTask(Task task) async => {};
  Future<void> deleteTask(Task task) async => {};

  Task copyTask(Task task);

  bool supportsPause(Task task) => false;

  @override
  void dispose();

  String getCreateTableSql();

  Map<String, dynamic> getInsertJson(Task task);

  /// 获取升级表的 SQL 语句
  /// 返回一个 Map，key 为旧版本，value 为 SQL 语句
  Map<int, String> getUpgradeTableSql(int oldVersion) {
    return {};
  }
}

abstract class TaskStore {
  Future<void> resetDatabase();
  Future<void> init();
  Future<void> addTask(Task task);
  Future<void> addAndAsyncProcessTask(Task task);
  Future<void> deleteByTaskId(String taskId);
  // Future<void> updateTask(Task task);
  void addTaskTypeListener(TaskTypeEnum type, VoidCallback listener);
  void removeTaskTypeListener(TaskTypeEnum type, VoidCallback listener);
  Task? getTaskById(String taskId);
  Future<Task?> getTaskByIdSync(String taskId);
  Map<TaskStatusEnum, int> getTaskCounts();
  List<Task> getTasksByStatus(TaskStatusEnum? status);
  List<Task> getTasksByType(TaskTypeEnum type);
  List<Task> getTasksByTypeWithStatus(
    TaskTypeEnum type,
    TaskStatusEnum? status,
  );
  Future<Task> updateTask(String taskId, Task Function(Task) updateFn);
}

class TaskStorage extends ChangeNotifier
    implements AbstractTaskManager, TaskStore {
  static final TaskStorage _instance = TaskStorage._internal();
  factory TaskStorage() => _instance;
  var lock = Lock(reentrant: true);
  int _lastNotifyTime = DateTime.now().millisecondsSinceEpoch;

  TaskStorage._internal() {
    _taskManagers[TaskTypeEnum.videoCompress] = VideoCompressTaskManager(this);
    _taskManagers[TaskTypeEnum.videoClip] = VideoClipTaskManager(this);
    _taskManagers[TaskTypeEnum.imageCompress] = ImageCompressTaskManager(this);
    _taskManagers[TaskTypeEnum.videoUpload] = VideoUploadTaskManager(this);
    _taskManagers[TaskTypeEnum.download] = DownloadManager(this);
    _taskManagers[TaskTypeEnum.videoSegmentDetect] =
        VideoSegmentDetectTaskManager(this);
  }

  static Database? _database;
  static const String mainTable = 'tasks';
  static const _currentDatabaseVersion = 9;

  final List<Task> _tasks = [];

  final NotificationManager _notificationService = NotificationManager.instance;

  List<Task> get tasks => List.unmodifiable(_tasks);

  final Map<TaskTypeEnum, AbstractTaskManager> _taskManagers = {};

  @override
  Map<TaskStatusEnum, int> getTaskCounts() {
    final counts = <TaskStatusEnum, int>{};
    for (final status in TaskStatusEnum.values) {
      counts[status] = _tasks.where((task) => task.status == status).length;
    }
    return counts;
  }

  @override
  List<Task> getTasksByStatus(TaskStatusEnum? status) {
    if (status == null) return _tasks;
    return _tasks
        .where((task) => task.status == status)
        .map((task) => _taskManagers[task.type]!.copyTask(task))
        .toList();
  }

  @override
  List<Task> getTasksByTypeWithStatus(
    TaskTypeEnum type,
    TaskStatusEnum? status,
  ) {
    if (status == null) {
      return _tasks
          .where((task) => task.type == type)
          .map((task) => _taskManagers[task.type]!.copyTask(task))
          .toList();
    }
    return _tasks
        .where((task) => task.type == type && task.status == status)
        .map((task) => _taskManagers[task.type]!.copyTask(task))
        .toList();
  }

  @override
  List<Task> getTasksByType(TaskTypeEnum type) {
    return _tasks
        .where((task) => task.type == type)
        .map((task) => _taskManagers[task.type]!.copyTask(task))
        .toList();
  }

  @override
  Future<void> addTask(Task task) async {
    Task copyTask = _taskManagers[task.type]!.copyTask(task);
    _tasks.add(copyTask);
    await _saveTask(copyTask);
    notifyListeners();

    copyTask = _taskManagers[copyTask.type]!.copyTask(copyTask);

    // 初始化遥测服务（异步，不阻塞）
    TelemetryService.instance.initialize();
  }

  @override
  Future<void> addAndAsyncProcessTask(Task task) async {
    await addTask(task);
    processTask(task);
  }

  @override
  Future<void> deleteByTaskId(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      if (task.status == TaskStatusEnum.processing ||
          task.status == TaskStatusEnum.paused ||
          task.status == TaskStatusEnum.pending) {
        await cancelTask(task);
      }
      await _taskManagers[task.type]?.deleteTask(task);
      _tasks.removeAt(taskIndex);
      await _deleteTaskFromDb(task.id, task.type);

      _notifyListenersInternal(null);
    }
  }

  Future<void> _deleteTaskFromDb(String taskId, TaskTypeEnum type) async {
    final db = await database;
    await db.delete(mainTable, where: 'id = ?', whereArgs: [taskId]);
    await db.delete(
      _taskManagers[type]!.getTableName(),
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
  }

  @override
  Future<List<Task>> loadTasks(
    List<Map<String, dynamic>> mainTasks,
    List<Map<String, dynamic>> subTasks,
  ) async {
    final db = await database;
    final Map<TaskTypeEnum, List<Map<String, dynamic>>> typeMainResults = {};
    final Map<TaskTypeEnum, List<Map<String, dynamic>>> typeSubResults = {};
    for (final taskType in TaskTypeEnum.values) {
      typeMainResults[taskType] = [];
      typeSubResults[taskType] = [];
    }
    final List<Map<String, dynamic>> mainResults = await db.query(mainTable);
    for (final mainRow in mainResults) {
      final taskType = TaskTypeEnum.values[mainRow['type'] as int];

      AbstractTaskManager? taskManager = _taskManagers[taskType];
      if (taskManager == null) {
        continue;
      }
      final tableName = taskManager.getTableName();
      final List<Map<String, dynamic>> rowResult = await db.query(
        tableName,
        where: 'taskId = ?',
        whereArgs: [mainRow['id']],
      );
      if (rowResult.isNotEmpty) {
        typeSubResults[taskType]!.add(rowResult.first);
        typeMainResults[taskType]!.add(mainRow);
      } else {
        AppLogger().w(
          'Task not found for load: ${mainRow['id']}, taskType: $taskType, delete from db',
        );
        await _deleteTaskFromDb(mainRow['id'] as String, taskType);
      }
    }

    final List<Task> tasks = [];
    for (final taskType in TaskTypeEnum.values) {
      if (_taskManagers[taskType] == null) {
        continue;
      }
      final taskManager = _taskManagers[taskType]!;
      tasks.addAll(
        await taskManager.loadTasks(
          typeMainResults[taskType]!,
          typeSubResults[taskType]!,
        ),
      );
    }

    return tasks;
  }

  Future<Database> get database async {
    return await lock.synchronized(() async {
      if (_database != null && _database!.isOpen) {
        final path = await getDatabasePath();
        final dbFile = File(path);
        if (!(await dbFile.exists())) {
          await _database!.close();
          _database = null;
        } else {
          return _database!;
        }
      }
      _database = await _initDatabase();
      return _database!;
    });
  }

  @override
  void addTaskTypeListener(TaskTypeEnum type, VoidCallback listener) {
    lock.synchronized(() {
      _taskManagers[type]?.addListener(listener);
      _taskManagers[type]?.notifyListeners();
    });
  }

  @override
  Future<void> resetDatabase() async {
    return await lock.synchronized(() async {
      if (_database != null && _database!.isOpen) {
        await _database!.close();
      }
      _database = null;

      final path = await getDatabasePath();
      final dbFile = File(path);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      _database = await _initDatabase();
    });
  }

  Future<String> getDatabasePath() async {
    final databasesPath = await Global.getDatabasePath();
    final path = join(databasesPath, 'tasks.db');
    return path;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasePath();
    return await openDatabase(
      path,
      version: _currentDatabaseVersion,
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        await db.execute(getCreateTableSql());
        for (final taskManager in _taskManagers.values) {
          await db.execute(taskManager.getCreateTableSql());
        }
        final upgradeSql = getUpgradeTableSql(oldVersion);
        final sortedUpgradeSql = upgradeSql.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        for (final sql in sortedUpgradeSql) {
          if (oldVersion < sql.key && sql.key <= newVersion) {
            await db.execute(sql.value);
          }
        }
        for (final taskManager in _taskManagers.values) {
          final upgradeSql = taskManager.getUpgradeTableSql(oldVersion);
          final sortedUpgradeSql = upgradeSql.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));
          for (final sql in sortedUpgradeSql) {
            if (oldVersion < sql.key && sql.key <= newVersion) {
              await db.execute(sql.value);
            }
          }
        }
      },
    );
  }

  @override
  String getCreateTableSql() {
    return '''
          CREATE TABLE IF NOT EXISTS $mainTable (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            type INTEGER NOT NULL,
            progress REAL NOT NULL,
            status INTEGER NOT NULL,
            total INTEGER,
            processed INTEGER,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL,
            hide INTEGER NOT NULL,
            image TEXT,
            extraInfo TEXT,
            supportsPause INTEGER NOT NULL
          )
        ''';
  }

  @override
  Map<int, String> getUpgradeTableSql(int oldVersion) {
    final sql = <int, String>{};
    return sql;
  }

  Future<void> _saveTask(Task task) async {
    final db = await database;
    Map<String, dynamic> insertJson = getInsertJson(task);
    await db.insert(
      mainTable,
      getInsertJson(task),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    AbstractTaskManager taskManager = _taskManagers[task.type]!;
    insertJson = taskManager.getInsertJson(task);
    await db.insert(
      taskManager.getTableName(),
      insertJson,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  void _notifyListenersInternal(Task? task) {
    notifyListeners();
    if (task != null) {
      if (task.status == TaskStatusEnum.processing &&
          DateTime.now().millisecondsSinceEpoch - _lastNotifyTime < 1000) {
        return;
      }
      _lastNotifyTime = DateTime.now().millisecondsSinceEpoch;
      _notifyTaskUpdate(task);
      _taskManagers[task.type]?.notifyListeners();
    }
  }

  // 修改 updateTask 的接口
  @override
  Future<Task> updateTask(String taskId, Task Function(Task) updateFn) async {
    return await lock.synchronized(() async {
      final idx = _tasks.indexWhere((t) => t.id == taskId);
      if (idx == -1) {
        AppLogger().w('Task not found for update: $taskId');
      }

      final oldTask = _tasks[idx];
      final oldStatus = oldTask.status;
      final oldCreatedAt = oldTask.createdAt;

      // 在锁内执行更新函数，基于最新数据
      Task updatedTask = updateFn(oldTask);
      updatedTask = _taskManagers[updatedTask.type]!.copyTask(updatedTask);

      // 状态验证
      if (updatedTask.status == TaskStatusEnum.processing &&
          oldTask.status == TaskStatusEnum.paused) {
        throw UpdateTaskOnPauseError(updatedTask.status);
      }

      _tasks[idx] = updatedTask;
      await _saveTask(updatedTask);
      _notifyListenersInternal(updatedTask);

      // 记录遥测数据
      _recordTelemetryIfNeeded(oldTask, updatedTask, oldStatus, oldCreatedAt);

      return updatedTask;
    });
  }

  /// 在任务状态变化时记录遥测数据
  void _recordTelemetryIfNeeded(
    Task oldTask,
    Task newTask,
    TaskStatusEnum oldStatus,
    int oldCreatedAt,
  ) {
    // 只在状态从处理中变为完成或失败时记录
    if (oldStatus == TaskStatusEnum.processing &&
        (newTask.status == TaskStatusEnum.completed ||
            newTask.status == TaskStatusEnum.failed)) {
      final duration = DateTime.now().millisecondsSinceEpoch - oldCreatedAt;
      final success = newTask.status == TaskStatusEnum.completed;

      TelemetryService.instance.recordTaskTelemetry(
        taskType: newTask.type,
        success: success,
        duration: duration,
        extraData: {
          'taskId': newTask.id,
          'taskName': newTask.name,
          'progress': newTask.progress,
        },
      );
    }
  }

  // @override
  // Future<Task> updateTask(Task task) async {
  //   return await lock.synchronized(() async {
  //     Task copyTask = _taskManagers[task.type]!.copyTask(task);
  //     final idx = _tasks.indexWhere((t) => t.id == copyTask.id);
  //     if (idx != -1) {
  //       final oldTask = _tasks[idx];
  //       if (copyTask.status == TaskStatusEnum.processing &&
  //           oldTask.status == TaskStatusEnum.paused) {
  //         throw UpdateTaskOnPauseError(copyTask.status);
  //       }
  //       _tasks[idx] = copyTask;

  //       copyTask.updatedAt = DateTime.now().millisecondsSinceEpoch;
  //       await _saveTask(copyTask);
  //       _notifyListenersInternal(copyTask);
  //     } else {
  //       AppLogger().w('Task not found for update: ${task.id}');
  //     }
  //     return copyTask;
  //   });
  // }

  Future<void> _notifyTaskUpdate(Task newTask) async {
    final hasPermission = await _notificationService
        .checkNotificationPermission();
    if (!hasPermission) {
      AppLogger().w(
        'Notification permission not granted, skipping notification update',
      );
      return;
    }

    await _notificationService.showOrUpdateTaskNotification(newTask);
  }

  @override
  Future<Task?> getTaskByIdSync(String taskId) async {
    return await lock.synchronized(() async {
      return getTaskById(taskId);
    });
  }

  @override
  Task? getTaskById(String taskId) {
    final task = _tasks.firstWhereOrNull((t) => t.id == taskId);
    if (task == null) {
      return null;
    }
    return _taskManagers[task.type]?.copyTask(task);
  }

  @override
  void dispose() {
    super.dispose();
    for (final taskManager in _taskManagers.values) {
      taskManager.dispose();
    }
    _notificationService.cancelAllTaskNotifications();
  }

  @override
  Map<String, dynamic> getInsertJson(Task task) {
    return {
      'id': task.id,
      'name': task.name,
      'type': task.type.index,
      'progress': task.progress,
      'status': task.status.index,
      'total': task.total,
      'processed': task.processed,
      'supportsPause': task.supportsPause ? 1 : 0,
      'createdAt': task.createdAt,
      'updatedAt': task.updatedAt,
      'image': task.image,
      'extraInfo': task.extraInfo,
      'hide': task.hide ? 1 : 0,
    };
  }

  @override
  String getTableName() {
    return mainTable;
  }

  @override
  Future<void> processTask(Task task) async {
    final taskById = getTaskById(task.id)!;
    if (taskById.status == TaskStatusEnum.processing ||
        taskById.status == TaskStatusEnum.completed) {
      AppLogger().w('Task is already processing or completed: ${task.id}');
      return;
    }
    await updateTask(
      task.id,
      (oldTask) => oldTask.copyWith(status: TaskStatusEnum.processing),
    );
    await _taskManagers[taskById.type]?.processTask(taskById);
  }

  @override
  Future<void> cancelTask(Task task) async {
    final taskById = getTaskById(task.id)!;
    if (taskById.status == TaskStatusEnum.cancelled ||
        taskById.status == TaskStatusEnum.completed ||
        taskById.status == TaskStatusEnum.failed) {
      AppLogger().w('Task cannot be cancelled: ${task.status}: ${task.id}');
      return;
    }
    await updateTask(
      taskById.id,
      (oldTask) => oldTask.copyWith(status: TaskStatusEnum.cancelled),
    );
    await _taskManagers[taskById.type]?.cancelTask(taskById);
  }

  @override
  Future<void> pauseTask(Task task) async {
    final taskById = getTaskById(task.id)!;
    if (taskById.status == TaskStatusEnum.paused ||
        taskById.status == TaskStatusEnum.cancelled ||
        taskById.status == TaskStatusEnum.completed ||
        taskById.status == TaskStatusEnum.failed) {
      AppLogger().w('Task is already paused: ${taskById.id}');
      return;
    }
    await updateTask(
      taskById.id,
      (oldTask) => oldTask.copyWith(status: TaskStatusEnum.paused),
    );
    if (supportsPause(taskById)) {
      _taskManagers[taskById.type]?.pauseTask(taskById);
    }
  }

  @override
  Future<void> resumeTask(Task task) async {
    final taskById = getTaskById(task.id)!;
    if (taskById.status != TaskStatusEnum.paused) {
      AppLogger().w('Task is not paused: ${taskById.id}');
      return;
    }
    taskById.status = TaskStatusEnum.processing;
    await updateTask(
      taskById.id,
      (oldTask) => oldTask.copyWith(status: TaskStatusEnum.processing),
    );
    if (supportsPause(taskById)) {
      _taskManagers[taskById.type]?.resumeTask(taskById);
    }
  }

  @override
  Future<void> retryTask(Task task) async {
    final taskById = getTaskById(task.id)!;
    if (taskById.status != TaskStatusEnum.failed) {
      AppLogger().w('Task is not failed: ${taskById.id}');
      return;
    }
    await updateTask(
      taskById.id,
      (oldTask) => oldTask.copyWith(status: TaskStatusEnum.processing),
    );
    _taskManagers[taskById.type]?.retryTask(taskById);
  }

  @override
  bool supportsPause(Task task) {
    final taskById = getTaskById(task.id)!;
    return _taskManagers[taskById.type]?.supportsPause(taskById) ??
        taskById.supportsPause;
  }

  @override
  Task copyTask(Task task) {
    throw UnimplementedError();
  }

  @override
  Future<void> init() async {
    await lock.synchronized(() async {
      await database;
      final tasks = await loadTasks([], []);
      _tasks.addAll(tasks);
      notifyListeners();
    });

    // 初始化遥测服务
    TelemetryService.instance.initialize();
  }

  @override
  void removeTaskTypeListener(TaskTypeEnum type, VoidCallback listener) {
    _taskManagers[type]?.removeListener(listener);
  }

  @override
  Future<void> deleteTask(Task task) async {
    await deleteByTaskId(task.id);
  }
}
