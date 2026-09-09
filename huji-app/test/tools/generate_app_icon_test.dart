// test/tools/generate_app_icon_test.dart
//
// Renders the vector logo into the committed app-icon PNGs. Run from
// `huji-app/`:
//
//   flutter test test/tools/generate_app_icon_test.dart
//
// Outputs (both committed):
//   - assets/icons/logo_bg_1024.png  master launcher icon (full-bleed square)
//   - scripts/appimage/huji.png     256px AppImage icon (rounded corners)
//
// Re-run via `dart run tool/sync_app_icons.dart` which also regenerates the
// platform icons.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

const _sourceSvg = 'assets/svg/logo_no_font.svg';
const _masterIcon = 'assets/icons/logo_bg_1024.png';
const _appimageIcon = 'scripts/appimage/huji.png';

/// Logo width as a fraction of the icon canvas. 0.94 calibrated against the
/// previous 418px logo_bg.png composition (its artwork — main mark plus side
/// accents — spans 93.8% of the canvas width; the shipped iOS icon generated
/// from it measures 94.2%). adjust if the master looks off next to
/// assets/icons/logo_bg.png.
const _logoScale = 0.94;

/// Corner radius fraction for the rounded variant — same as the old
/// scripts/appimage/huji.svg placeholder (rx=48 of 256).
const _cornerRadiusFraction = 48 / 256;

Future<ui.Image> _renderIcon(
  WidgetTester tester, {
  required double logicalSize,
  required double pixelRatio,
  required bool rounded,
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
          child: rounded
              ? ClipRRect(
                  borderRadius:
                      BorderRadius.circular(logicalSize * _cornerRadiusFraction),
                  child: _iconBody(logicalSize, svg!),
                )
              : _iconBody(logicalSize, svg!),
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

/// Alpha channel of the (x, y) pixel of a rawRgba byte buffer.
int _alphaAt(Uint8List rgba, int width, int x, int y) =>
    rgba[(y * width + x) * 4 + 3];

void main() {
  testWidgets('generate 1024px master icon', (tester) async {
    final image = await _renderIcon(
      tester,
      logicalSize: 256,
      pixelRatio: 4,
      rounded: false,
    );
    expect(image.width, 1024);
    expect(image.height, 1024);
    await _writePng(tester, image, _masterIcon);
  });

  testWidgets('generate 256px rounded AppImage icon', (tester) async {
    final image = await _renderIcon(
      tester,
      logicalSize: 256,
      pixelRatio: 1,
      rounded: true,
    );
    expect(image.width, 256);
    expect(image.height, 256);

    // Self-guard the rounded-corner geometry: corners transparent, center
    // and edge midpoints opaque (guards against ClipRRect regressions).
    // (2, 2) is outside the 48px corner arc; (128, 2) / (128, 128) sit in
    // the opaque body.
    final rgba = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    expect(rgba, isNotNull, reason: 'rawRgba decode of the icon failed');
    final pixels = rgba!.buffer.asUint8List();
    expect(_alphaAt(pixels, image.width, 2, 2), 0,
        reason: 'corner pixel must be transparent (ClipRRect)');
    expect(_alphaAt(pixels, image.width, 128, 2), 255,
        reason: 'top edge midpoint must be opaque');
    expect(_alphaAt(pixels, image.width, 128, 128), 255,
        reason: 'center pixel must be opaque');

    await _writePng(tester, image, _appimageIcon);
  });
}
