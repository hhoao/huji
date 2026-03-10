import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:restcut/models/task.dart';
import 'package:restcut/models/video.dart';
import 'package:restcut/services/storage_service.dart' show storage;
import 'package:restcut/store/task/task_manager.dart';
import 'package:restcut/utils/json_utils.dart';
import 'package:restcut/utils/logger_utils.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:synchronized/synchronized.dart';

class LocalVideoStorage extends ChangeNotifier {
  final Lock lock = Lock();
  static Database? _database;
  static const String _tableName = 'video_records';

  // 单例模式
  static final LocalVideoStorage _instance = LocalVideoStorage._internal();
  factory LocalVideoStorage() => _instance;
  LocalVideoStorage._internal();

  Future<void> init() async {
    await lock.synchronized(() async {
      await database;
    });
  }

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // 初始化数据库
  static Future<Database> _initDatabase() async {
    // 获取数据库路径
    final appDocDir = storage.getApplicationDocumentsDirectory();
    final databasesPath = join(appDocDir.path, 'databases');
    await Directory(databasesPath).create(recursive: true);
    final path = join(databasesPath, 'video_records.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            taskId TEXT,
            type TEXT NOT NULL,
            processStatus INTEGER NOT NULL,
            sportType INTEGER NOT NULL,
            filePath TEXT ,
            thumbnailPath TEXT,
            clipMode TEXT,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL,
            videoClipConfigReqVo TEXT,
            processRecordId INTEGER,
            videoProcessProgressVO TEXT,
            editVideoInfoVO TEXT,
            favoritesMatchSegments TEXT,
            allMatchSegments TEXT
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        final upgradeSql = getUpgradeTableSql(oldVersion);
        final sortedUpgradeSql = upgradeSql.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        for (final sql in sortedUpgradeSql) {
          if (oldVersion < sql.key && sql.key <= newVersion) {
            await db.execute(sql.value);
          }
        }
      },
    );
  }

  static Map<int, String> getUpgradeTableSql(int oldVersion) {
    return {};
  }

  // 加载所有视频记录
  Future<List<LocalVideoRecord>> load() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'createdAt DESC',
    );

    final records = maps
        .map((map) => dbDataToObj(map, (map) => LocalVideoRecord.fromJson(map)))
        .toList();
    return records.where((record) {
      if (record is ProcessVideoRecord) {
        final task = TaskStorage().getTaskById(record.taskId);
        if (task != null &&
            (task.status == TaskStatusEnum.completed ||
                task.status == TaskStatusEnum.failed)) {
          removeById(record.id);
          return false;
        }
        return true;
      }
      return true;
    }).toList();
  }

  // 根据状态加载视频记录
  Future<List<LocalVideoRecord>> loadByStatus(
    LocalVideoProcessStatusEnum status,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'processStatus = ?',
      whereArgs: [status.value],
      orderBy: 'createdAt DESC',
    );

    return maps
        .map((map) => dbDataToObj(map, (map) => LocalVideoRecord.fromJson(map)))
        .toList();
  }

  // 添加单个视频记录
  Future<int> add(LocalVideoRecord record) async {
    final db = await database;
    record.updatedAt = DateTime.now().millisecondsSinceEpoch;

    final result = await db.insert(
      _tableName,
      objectToDbData(record, (record) => record.toJson()),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners(); // 通知监听器数据已变化
    return result;
  }

  // 更新视频记录
  Future<LocalVideoRecord> update(
    String videoId,
    LocalVideoRecord Function(LocalVideoRecord) updateFn, {
    bool notifyChange = true, // 是否通知监听器，默认为 true
  }) async {
    return await lock.synchronized(() async {
      var record = await findById(videoId);
      if (record == null) {
        throw Exception('Video record not found: $videoId');
      }

      // 在锁内执行更新函数，基于最新数据
      LocalVideoRecord updatedRecord = updateFn(record);

      final db = await database;
      updatedRecord.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await db.update(
        _tableName,
        objectToDbData(updatedRecord, (record) => record.toJson()),
        where: 'id = ?',
        whereArgs: [updatedRecord.id],
      );
      if (notifyChange) {
        notifyListeners(); // 通知监听器数据已变化
      }
      return updatedRecord;
    });
  }

  // 根据ID删除视频记录
  Future<void> removeById(String id) async {
    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
    notifyListeners(); // 通知监听器数据已变化
  }

  // 根据处理记录ID删除处理记录
  Future<void> removeProcessRecordByProcessRecordId(int processRecordId) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'type = ? AND processRecordId = ?',
      whereArgs: ['process', processRecordId],
    );
    notifyListeners(); // 通知监听器数据已变化
  }

  // 根据文件路径查找记录
  Future<LocalVideoRecord?> findById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return dbDataToObj(maps.first, (map) => LocalVideoRecord.fromJson(map));
  }

  // 根据处理记录ID查找处理记录
  Future<ProcessVideoRecord?> findProcessRecordByProcessRecordId(
    int processRecordId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'type = ? AND processRecordId = ?',
      whereArgs: ['process', processRecordId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    final record = dbDataToObj(
      maps.first,
      (map) => LocalVideoRecord.fromJson(map),
    );
    return record is ProcessVideoRecord ? record : null;
  }

  // 根据任务ID查找处理记录
  Future<ProcessVideoRecord?> findProcessRecordByTaskId(String taskId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'type = ? AND processRecordId = ?',
      whereArgs: ['process', taskId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    final record = dbDataToObj(
      maps.first,
      (map) => LocalVideoRecord.fromJson(map),
    );
    return record is ProcessVideoRecord ? record : null;
  }

  // 清理不存在的文件记录
  static Future<void> cleanupOrphanedRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);

    for (final map in maps) {
      final filePath = map['filePath'] as String?;

      // 如果filePath为空，跳过检查（边拍边剪辑模式）
      if (filePath == null) {
        continue;
      }

      final file = File(filePath);
      if (!await file.exists()) {
        await db.delete(_tableName, where: 'id = ?', whereArgs: [map['id']]);
      }
    }
  }

  // 获取数据库统计信息
  static Future<Map<String, int>> getStats() async {
    final db = await database;
    final List<Map<String, dynamic>> rawCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE type = ?',
      ['raw'],
    );
    final List<Map<String, dynamic>> processCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE type = ?',
      ['process'],
    );
    final List<Map<String, dynamic>> edittingCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE type = ?',
      ['editting'],
    );

    return {
      'raw': rawCount.first['count'] as int,
      'process': processCount.first['count'] as int,
      'editting': edittingCount.first['count'] as int,
    };
  }

  // 关闭数据库
  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // 测试数据库连接
  static Future<bool> testConnection() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT 1 as test');
      return result.isNotEmpty && result.first['test'] == 1;
    } catch (e, stackTrace) {
      AppLogger().e('数据库连接测试失败: $e', stackTrace, e);
      return false;
    }
  }

  // 重置数据库（开发阶段使用）
  Future<void> resetDatabase() async {
    final db = await database;
    await db.close();
    _database = null;

    final appDocDir = storage.getApplicationDocumentsDirectory();
    final databasesPath = join(appDocDir.path, 'databases');
    final path = join(databasesPath, 'video_records.db');

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      AppLogger().i('Deleted video database file: $path');
    }

    // 重新初始化数据库
    await database;
    AppLogger().i('Video database reset completed');
  }
}
