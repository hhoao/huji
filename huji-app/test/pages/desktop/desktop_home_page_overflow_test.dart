@Tags(['integration'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/constants/theme.dart';
import 'package:huji_app/l10n/huji_localizations_setup.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/pages/desktop/desktop_home_page.dart';
import 'package:huji_app/services/storage_service.dart';
import 'package:huji_app/store/video.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/fake_path_provider.dart';

/// 桌面视频库布局回归测试。
///
/// 复现线上报错 "A RenderFlex overflowed by 4.8 pixels on the bottom"：
/// 网格卡片 [mainAxisExtent] 固定 220、底部文字区固定拿 2/5（88px 减
/// padding 后 68px），而桌面端字体倍率烧进主题字号（Retina 基线 =
/// os × dpr，最高 2.0），大倍率下两行文字超过 68px，卡片底部溢出。
void main() {
  // Live binding（真实异步时钟）：LocalVideoStorage 走 sqflite_ffi 真实
  // I/O，fake async 的假时钟会让查询 Future 永远不完成，测试卡到超时。
  LiveTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    PathProviderPlatform.instance = FakePathProvider();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await StorageService.init();
    await LocalVideoStorage().resetDatabase();
    await LocalVideoStorage().init();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    required double textScale,
    Size windowSize = const Size(1280, 800),
  }) async {
    await LocalVideoStorage().resetDatabase();
    await LocalVideoStorage().add(SavedVideoRecord(
      id: 'library-overflow-test',
      sportType: SportType.pingpong,
      filePath: '/nonexistent/video.mp4',
      duration: 95,
      fileSize: 1024 * 1024,
    ));

    final theme = AppTheme.darkTheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('zh'),
        localizationsDelegates: HujiLocalizationsSetup.localizationsDelegates,
        supportedLocales: HujiLocalizationsSetup.supportedLocales,
        home: TpTheme(
          data: TpThemeData.fromColorScheme(theme.colorScheme, scale: 1.0),
          child: MediaQuery(
            data: MediaQueryData(
              size: windowSize,
              textScaler: TextScaler.linear(textScale),
            ),
            child: SizedBox(
              width: windowSize.width,
              height: windowSize.height,
              child: const DesktopHomePage(),
            ),
          ),
        ),
      ),
    );

    // Live binding 下 pumpAndSettle 会在 sqflite I/O 空档提前 settle，
    // 轮询等待记录加载、网格卡片真正渲染出来（否则是假绿）。
    var rendered = false;
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('video.mp4').evaluate().isNotEmpty) {
        rendered = true;
        break;
      }
    }
    expect(rendered, isTrue, reason: '视频卡片未渲染（记录未加载）');
    await tester.pumpAndSettle();
  }

  testWidgets('默认字号 1280x800 网格卡片不溢出', (tester) async {
    await pumpPage(tester, textScale: 1.0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('大字号（textScale 2.0，Retina 桌面基线）网格卡片不溢出', (tester) async {
    await pumpPage(tester, textScale: 2.0);
    expect(tester.takeException(), isNull);
  });
}
