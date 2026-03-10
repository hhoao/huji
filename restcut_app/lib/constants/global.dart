import 'dart:io';

import 'package:path/path.dart';
import 'package:restcut/config/environment.dart';
import 'package:restcut/services/storage_service.dart' show storage;

class Global {
  static String get baseUrl => EnvironmentConfig.apiBaseUrl;
  static String get wsUrl => EnvironmentConfig.wsUrl;
  static Future<String> getDatabasePath() async {
    final appDocDir = storage.getApplicationDocumentsDirectory();
    final databasesPath = join(appDocDir.path, 'databases');
    await Directory(databasesPath).create(recursive: true);
    return databasesPath;
  }
}
