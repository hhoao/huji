// test/tools/generate_app_icon_test.dart
//
// Renders the vector logo into the committed mobile/web master icon. Run from
// `huji-app/`:
//
//   flutter test test/tools/generate_app_icon_test.dart
//
// Output (committed):
//   - assets/icons/logo_bg_1024.png  mobile / web launcher master
//
// Desktop launcher icons use the black-plate assets
// (`assets/icons/icon_bg.png` / `icon_bg_1024.png`) and are synced by
// `dart run tool/sync_app_icons.dart`.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

const _sourceSvg = 'assets/svg/logo_no_font.svg';
const _masterIcon = 'assets/icons/logo_bg_1024.png';

/// Logo width as a fraction of the icon canvas. 0.94 calibrated against the
/// previous 418px logo_bg.png composition (its artwork — main mark plus side
/// accents — spans 93.8% of the canvas width; the shipped iOS icon generated
/// from it measures 94.2%). adjust if the master looks off next to
/// assets/icons/logo_bg.png.
const _logoScale = 0.94;

Future<ui.Image> _renderIcon(
  WidgetTester tester, {
  required double logicalSize,
  required double pixelRatio,
}) async {
  // Preload the SVG string so no async asset loading races the pump. Real
  // async (asset IO, engine image ops, file writes) must run inside
  // `tester.runAsync` — inside the test's fake-async zone those futures
  // never complete and the test hangs at teardown.
  final svg = await tester.runAsync(() => rootBundle.loadString(_sourceSvg));
  expect(
    svg,
    isNotNull,
    reason: '$_sourceSvg missing from the asset bundle',
  );

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Center(
        child: RepaintBoundary(
          key: key,
          child: _iconBody(logicalSize, svg!),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() => boundary.toImage(pixelRatio: pixelRatio)))!;
}

Widget _iconBody(double size, String svg) {
  return Container(
    width: size,
    height: size,
    color: Colors.black,
    alignment: Alignment.center,
    child: SvgPicture.string(
      svg,
      width: size * _logoScale,
      fit: BoxFit.contain,
    ),
  );
}

Future<void> _writePng(WidgetTester tester, ui.Image image, String path) async {
  final data = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  expect(
    data,
    isNotNull,
    reason: 'PNG encode of the rendered icon failed',
  );
  await tester.runAsync(() async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('generate 1024px mobile/web master icon', (tester) async {
    final image = await _renderIcon(
      tester,
      logicalSize: 256,
      pixelRatio: 4,
    );
    expect(image.width, 1024);
    expect(image.height, 1024);
    await _writePng(tester, image, _masterIcon);
  });
}
