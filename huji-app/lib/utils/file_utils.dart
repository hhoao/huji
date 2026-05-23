import 'dart:io';

import 'package:restcut/services/storage_service.dart' show storage;

bool isExternalStorage(String path) {
  if (Platform.isAndroid) {
    return path.startsWith('/storage/emulated/0/');
  } else if (Platform.isIOS) {
    return path.startsWith('/var/mobile/Containers/Data/Application/');
  } else {
    return false;
  }
}

String formatBytesSize(double bytes) {
  if (bytes < 1024) {
    return '${bytes.toStringAsFixed(1)}B';
  } else if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)}KB';
  } else if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  } else {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

Future<Directory> getDownloadsDirectory() async {
  return await storage.getDownloadsDirectory();
}
