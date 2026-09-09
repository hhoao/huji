import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/l10n/huji_localizations_setup.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/pages/desktop/desktop_preview_export_page.dart';
import 'package:huji_app/services/storage_service.dart';
import 'package:huji_app/shortcuts/command_bus.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/theme/app_theme.dart';
import 'package:huji_app/theme/app_typography_scale.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/fake_path_provider.dart';

/// 预览导出页布局回归测试。
///
/// 桌面端字体倍率烧进主题字号（[autoTextScaleForSystem] = OS 缩放 ×
/// devicePixelRatio，Retina 屏 ×2），本页在 ×2 基线下不应有任何
/// RenderFlex 溢出（用户在预览页看到过 "overflowed by 4.8 pixels" 报错）。
void main() {
  setUpAll(() async {
    PathProviderPlatform.instance = FakePathProvider();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await StorageService.init();
    await LocalVideoStorage().resetDatabase();
    await LocalVideoStorage().init();
    // 真实异步（setUpAll 不在 fake async zone）：seed 记录，播放器因文件
    // 不存在跳过初始化，仅测布局。
    await LocalVideoStorage().add(EdittingVideoRecord(
      id: 'preview-overflow-test',
      processStatus: LocalVideoProcessStatusEnum.completed,
      sportType: SportType.pingpong,
      filePath: '/nonexistent/video.mp4',
      clipMode: ClipMode.existingVideo,
      allMatchSegments: List.generate(
        12,
        (i) => SegmentInfo(
          actionType: ActionType.playBall,
          startSeconds: i * 30.0,
          endSeconds: i * 30.0 + 18.5,
        ),
      ),
      favoritesMatchSegments: const [],
    ));
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    required double typographyMultiplier,
    Size windowSize = const Size(1280, 800),
  }) async {
    final theme = buildDarkTheme(
      null,
      AppTypographyScale(multiplier: typographyMultiplier),
    );
    await tester.pumpWidget(
      RepositoryProvider<CommandBus>.value(
        value: CommandBus(),
        child: MaterialApp(
          theme: theme,
          locale: const Locale('zh'),
          localizationsDelegates: HujiLocalizationsSetup.localizationsDelegates,
          supportedLocales: HujiLocalizationsSetup.supportedLocales,
          home: TpTheme(
            data: TpThemeData.fromColorScheme(theme.colorScheme, scale: 1.0),
            child: MediaQuery(
              data: MediaQueryData(size: windowSize),
              child: SizedBox(
                width: windowSize.width,
                height: windowSize.height,
                child: DesktopPreviewExportPage(
                  clipId: 'preview-overflow-test',
                  tabId: 'test-tab',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // 不用 pumpAndSettle：页面存在持续动画/定时器，永远不会稳定。
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('标准字号 1280x800 不溢出', (tester) async {
    await pumpPage(tester, typographyMultiplier: 1.0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Retina 自动基线（×2.0）不溢出', (tester) async {
    await pumpPage(tester, typographyMultiplier: 2.0);
    expect(tester.takeException(), isNull);
  });
}
