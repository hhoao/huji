import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Minimal path_provider fake for integration tests on VM (no platform channels).
class FakePathProvider extends PathProviderPlatform {
  FakePathProvider({this.root = '/tmp/huji_test'});

  final String root;

  @override
  Future<String?> getTemporaryPath() async => '$root/tmp';

  @override
  Future<String?> getApplicationSupportPath() async => '$root/support';

  @override
  Future<String?> getLibraryPath() async => '$root/lib';

  @override
  Future<String?> getApplicationDocumentsPath() async => '$root/docs';

  @override
  Future<String?> getApplicationCachePath() async => '$root/cache';

  @override
  Future<String?> getExternalStoragePath() async => null;

  @override
  Future<List<String>?> getExternalCachePaths() async => null;

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async =>
      null;

  @override
  Future<String?> getDownloadsPath() async => '$root/downloads';
}
