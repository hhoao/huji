import 'dart:convert';
import 'dart:io';

import 'package:android_package_installer/android_package_installer.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:isolate_manager/isolate_manager.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:restcut/models/task.dart';
import 'package:restcut/store/task/task_manager.dart';

part 'download_task_manager.g.dart';

RootIsolateToken rootTokenFromJson(RootIsolateToken value) {
  return value;
}

RootIsolateToken rootTokenToJson(RootIsolateToken value) {
  return value;
}

@JsonSerializable(explicitToJson: true)
class IsolateDownloadParams {
  @JsonKey(fromJson: rootTokenFromJson, toJson: rootTokenToJson)
  final RootIsolateToken rootToken;
  final DownloadTask downloadTask;

  IsolateDownloadParams({required this.rootToken, required this.downloadTask});

  factory IsolateDownloadParams.fromJson(Map<String, dynamic> json) =>
      _$IsolateDownloadParamsFromJson(json);

  Map<String, dynamic> toJson() => _$IsolateDownloadParamsToJson(this);
}

@pragma('vm:entry-point')
@isolateManagerCustomWorker
void downloadIsolate(dynamic params) async {
  IsolateManagerFunction.customFunction<String, Map<String, dynamic>>(
    params,
    onEvent: (controller, params) async {
      final downLoadParams = IsolateDownloadParams.fromJson(params);
      BackgroundIsolateBinaryMessenger.ensureInitialized(
        downLoadParams.rootToken,
      );

      if (downLoadParams.downloadTask.cache) {
        final file = await DefaultCacheManager().getFileFromCache(
          downLoadParams.downloadTask.cacheKey,
        );
        if (file != null) {
          downLoadParams.downloadTask.progress = 1;
          downLoadParams.downloadTask.status = TaskStatusEnum.completed;
          downLoadParams.downloadTask.extraInfo = '文件已缓存';
          if (file.file.existsSync() &&
              !File(downLoadParams.downloadTask.savePath).existsSync()) {
            File(
              downLoadParams.downloadTask.savePath,
            ).writeAsBytesSync(file.file.readAsBytesSync());
          }

          return jsonEncode(downLoadParams.downloadTask.toJson());
        }
      }

      final dio = Dio();

      final savePath = downLoadParams.downloadTask.savePath;
      int latestUpdatedAt = 0;

      final task = downLoadParams.downloadTask;
      try {
        await dio.download(
          downLoadParams.downloadTask.url,
          savePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              if (DateTime.now().millisecondsSinceEpoch - latestUpdatedAt >=
                  1000) {
                task.processed = received;
                task.total = total;
                task.progress = received / total;
                task.status = TaskStatusEnum.processing;
                latestUpdatedAt = DateTime.now().millisecondsSinceEpoch;

                controller.sendResult(jsonEncode(task.toJson()));
              }
            }
          },
        );

        if (task.isInstall) {
          await AndroidPackageInstaller.installApk(apkFilePath: savePath);
        }

        task.progress = 1;
        task.status = TaskStatusEnum.completed;

        if (task.cache) {
          final file = File(savePath);
          DefaultCacheManager().putFile(
            task.cacheKey,
            file.readAsBytesSync(),
            fileExtension: file.path.split('.').last,
          );
        }

        return jsonEncode(task.toJson());
      } catch (e) {
        task.progress = 1;
        task.status = TaskStatusEnum.failed;
        task.extraInfo = e.toString();
        return jsonEncode(task.toJson());
      }
    },
  );
}

class DownloadManager extends AbstractTaskManager {
  static const String downloadTable = 'download_tasks';
  final Map<String, IsolateManager<dynamic, dynamic>> taskIsolatesMap = {};

  final TaskStorage _taskRunner;

  DownloadManager(this._taskRunner);

  @override
  Future<List<Task>> loadTasks(
    List<Map<String, dynamic>> mainTasks,
    List<Map<String, dynamic>> subTasks,
  ) async {
    final tasks = <Task>[];
    for (int i = 0; i < mainTasks.length; i++) {
      final mainTask = mainTasks[i];
      final subTask = subTasks[i];
      tasks.add(DownloadTask.fromJson({...mainTask, ...subTask}));
    }
    return tasks;
  }

  @override
  Future<void> processTask(Task task) async {
    DownloadTask currentTask = task as DownloadTask;
    final token = RootIsolateToken.instance;
    if (token != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    }

    final isolate = IsolateManager.createCustom(
      downloadIsolate,
      workerName: 'downloadUpdate',
      isDebug: true,
    );
    taskIsolatesMap[currentTask.id] = isolate;
    final params = IsolateDownloadParams(
      rootToken: RootIsolateToken.instance!,
      downloadTask: currentTask,
    );
    isolate.compute(
      params.toJson(),
      callback: (dynamic value) {
        try {
          final task = DownloadTask.fromJson(jsonDecode(value as String));
          _taskRunner.updateTask(task.id, (oldTask) => task);
          if (task.status == TaskStatusEnum.processing) {
            return false;
          } else if (task.status == TaskStatusEnum.completed ||
              task.status == TaskStatusEnum.failed) {
            return true;
          }
        } catch (e) {
          return true;
        }
        return true;
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    for (var isolate in taskIsolatesMap.values) {
      isolate.stop();
    }
    taskIsolatesMap.clear();
  }

  @override
  Future<void> pauseTask(Task task) async {
    throw UnimplementedError();
  }

  @override
  Future<void> resumeTask(Task task) async {
    throw UnimplementedError();
  }

  @override
  String getTableName() {
    return downloadTable;
  }

  @override
  String getCreateTableSql() {
    return '''
          CREATE TABLE IF NOT EXISTS $downloadTable (
            taskId TEXT PRIMARY KEY,
            url TEXT NOT NULL,
            savePath TEXT NOT NULL,
            isInstall INTEGER NOT NULL,
            cache INTEGER NOT NULL,
            cacheKey TEXT
          )
        ''';
  }

  @override
  Map<String, dynamic> getInsertJson(Task task) {
    DownloadTask downloadTask = task as DownloadTask;
    return {
      'taskId': task.id,
      'url': downloadTask.url,
      'savePath': downloadTask.savePath,
      'isInstall': downloadTask.isInstall ? 1 : 0,
      'cache': downloadTask.cache ? 1 : 0,
      'cacheKey': downloadTask.cacheKey,
    };
  }

  @override
  Future<void> cancelTask(Task task) {
    final isolate = taskIsolatesMap[task.id];
    if (isolate != null) {
      isolate.stop();
      taskIsolatesMap.remove(task.id);
    }
    return Future.value();
  }

  @override
  bool supportsPause(Task task) => false;

  @override
  Task copyTask(Task task) {
    final downloadTask = task as DownloadTask;
    return downloadTask.copyWith();
  }
}
