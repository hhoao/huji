import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/constants/demo_videos.dart';
import 'package:huji_app/services/demo_video_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../helpers/fake_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    PathProviderPlatform.instance = FakePathProvider();
  });

  group('DemoVideoService', () {
    test('materializes ping pong demo asset to disk', () async {
      final file = await DemoVideoService.materialize(demoVideos.first);
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(1000000));

      // Cached on second call
      final cached = await DemoVideoService.materialize(demoVideos.first);
      expect(cached.path, file.path);
    });
  });
}
