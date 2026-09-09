import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/l10n/huji_localizations_setup.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/pages/desktop/desktop_video_card.dart';
import 'package:huji_app/theme/app_theme.dart';
import 'package:huji_app/theme/app_typography_scale.dart';
import 'package:shared_ui/shared_ui.dart';

/// 视频库（桌面）网格卡片布局回归测试。
///
/// 卡片渲染在 GridView 固定高度（mainAxisExtent: 220）的单元格里。
/// 桌面端自动字号基线 [autoTextScaleForSystem] = OS 缩放 × devicePixelRatio，
/// Retina 屏（dpr 2.0）会到 ×2：文字行高随基线增长，超出单元格剩余高度时
/// RenderFlex 溢出（线上报过 "A RenderFlex overflowed by 4.8 pixels on the
/// bottom"，desktop_home_page 网格卡片）。
void main() {
  // 网格：maxCrossAxisExtent 320，3 列 → 卡片宽 ~293；高固定 220。
  const cardWidth = 293.0;
  const cardHeight = 220.0;

  EdittingVideoRecord record() => EdittingVideoRecord(
        id: 'card-overflow-test',
        processStatus: LocalVideoProcessStatusEnum.completed,
        sportType: SportType.pingpong,
        filePath: '/videos/单打比赛精彩集锦.mp4',
        clipMode: ClipMode.existingVideo,
        allMatchSegments: const [],
        favoritesMatchSegments: const [],
      );

  Future<void> pumpCard(
    WidgetTester tester, {
    required double typographyMultiplier,
  }) async {
    final theme = buildDarkTheme(
      null,
      AppTypographyScale(multiplier: typographyMultiplier),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('zh'),
        localizationsDelegates: HujiLocalizationsSetup.localizationsDelegates,
        supportedLocales: HujiLocalizationsSetup.supportedLocales,
        home: TpTheme(
          data: TpThemeData.fromColorScheme(theme.colorScheme, scale: 1.0),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: DesktopVideoCard(record: record()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('标准字号（×1.0）下不溢出', (tester) async {
    await pumpCard(tester, typographyMultiplier: 1.0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Retina 自动基线（×2.0）下不溢出', (tester) async {
    await pumpCard(tester, typographyMultiplier: 2.0);
    expect(tester.takeException(), isNull);
  });
}
