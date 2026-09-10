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
    Locale locale = const Locale('zh'),
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
          locale: locale,
          localizationsDelegates: HujiLocalizationsSetup.localizationsDelegates,
          supportedLocales: HujiLocalizationsSetup.supportedLocales,
          home: TpTheme(
            // 与 main_desktop.dart 一致：TpTextStyles 经 controlScale 跟随
            // 有效文字倍率（OS 基线 × 用户偏好），只烧 Material 主题不够。
            data: TpThemeData.fromColorScheme(
              theme.colorScheme,
              scale: 1.0,
              controlScale: typographyMultiplier,
            ),
            child: MediaQuery(
              data: MediaQueryData(size: windowSize),
              child: SizedBox(
                width: windowSize.width,
                height: windowSize.height,
                // 页面内部（播放器 Slider）直接查找 Material 祖先，
                // MaterialApp.home 不自带 —— 真实壳层在 DesktopPageShell
                // 之外还有 Material，这里补上。
                child: Material(
                  child: DesktopPreviewExportPage(
                    clipId: 'preview-overflow-test',
                    tabId: 'test-tab',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // 不用 pumpAndSettle：页面存在持续动画/定时器，永远不会稳定。
    await tester.pump(const Duration(milliseconds: 100));
    // _loadRecord 是真实异步 DB IO（fake async zone 不会推进）：runAsync
    // 里等它完成，再 pump 重建出导出配置面板（质量单选 / 摘要行）。
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
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

  // 复现用户上报的 "overflowed by 11 pixels on the right"（Row at
  // desktop_preview_export_page.dart _RadioOption）：导出面板固定 300px，
  // Row 中 label/meta Text 无 flex 约束，长词（如英文 "Original
  // resolution"）最小内在宽度之和超出面板可用宽度即溢出。
  testWidgets('英文 locale 标准字号不溢出', (tester) async {
    await pumpPage(tester, typographyMultiplier: 1.0, locale: const Locale('en'));
    expect(tester.takeException(), isNull);
  });
}
