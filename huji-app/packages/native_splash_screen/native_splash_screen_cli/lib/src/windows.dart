import 'dart:io';

import 'package:yaml/yaml.dart';

import '../models/desktop.dart';
import '../models/platforms.dart';
import '../models/config.dart';

import '../common/utils.dart';
import '../common/const.dart';

import '../templates/windows.dart';
import '../templates/windows_build.dart';

import '../src/logger.dart';

/// Parse Windows platform specific configuration with input validation
/// Returns null if Windows configuration does not exist
DesktopSplashConfig? parseWindowsConfig(YamlMap yaml) {
  // Check if windows config exists
  if (!yaml.containsKey('windows') || yaml['windows'] is! YamlMap) {
    logger.e("Windows is enabled, while it's config is not completed.");
    return null;
    // throw Exception('There is no windows configuration yaml block');
  }

  final windowsYaml = yaml['windows'] as YamlMap;

  // Default window dimensions
  final windowWidth = windowsYaml['window_width'] as int? ?? 500;
  final windowHeight = windowsYaml['window_height'] as int? ?? 250;

  // Background dimensions with logical constraints
  final backgroundWidth = windowsYaml['background_width'] as int? ?? 0;
  final backgroundHeight = windowsYaml['background_height'] as int? ?? 0;

  // Ensure background isn't larger than window
  if (backgroundWidth > windowWidth) {
    throw Exception(
      'Windows configuration error: '
      'background_width should be "<=" window_width',
    );
  }
  if (backgroundHeight > windowHeight) {
    throw Exception(
      'Windows configuration error: '
      'background_height should be "<=" window_height',
    );
  }

  final validWidth = backgroundWidth != 0 ? backgroundWidth : windowWidth;
  final validHeight = backgroundHeight != 0 ? backgroundHeight : windowHeight;

  // Image dimensions with logical constraints
  final imageWidth = windowsYaml['image_width'] as int? ?? 0;
  final imageHeight = windowsYaml['image_height'] as int? ?? 0;

  // Ensure image isn't larger than background or window
  if (imageWidth > validWidth) {
    throw Exception(
      'Windows configuration error: '
      'image_width should be "<=" background_width and window_width',
    );
  }
  if (imageHeight > validHeight) {
    throw Exception(
      'Windows configuration error: '
      'background_height should be "<=" background_height and window_height',
    );
  }

  // Parse color values
  final windowColor = parseColor('#00000000');
  final backgroundColor = parseColor(
    windowsYaml['background_color'] as String? ?? '#00000000',
  );

  // Get image path and validate existence
  final String imagePath = windowsYaml['image_path'] as String? ?? "";
  final imageFile = File(imagePath);
  if (!imageFile.existsSync()) {
    throw Exception(
      'Windows configuration error: '
      'image not found at: $imagePath',
    );
  }

  return DesktopSplashConfig(
    windowWidth: windowWidth,
    windowHeight: windowHeight,
    windowTitle: windowsYaml['window_title'] as String? ?? 'Splash Screen',
    windowClass: windowsYaml['window_class'] as String? ?? 'splash_window',
    windowColor: windowColor,
    imagePath: imageFile.path,
    imageWidth: imageWidth,
    imageHeight: imageHeight,
    imageBorderRadius: windowsYaml['image_border_radius'] as double? ?? 0.0,
    imageBlurRadius: windowsYaml['blur_radius'] as double? ?? 0.0,
    imageScaling: windowsYaml['image_scaling'] as bool? ?? true,
    backgroundColor: backgroundColor,
    backgroundWidth: validWidth,
    backgroundHeight: validHeight,
    backgroundBorderRadius:
        windowsYaml['background_border_radius'] as double? ?? 0.0,
    withAnimation: windowsYaml['with_animation'] as bool? ?? true,
  );
}

DesktopSplashConfig? checkWindows(
  Platform platform,
  DesktopSplashConfig? original,
  DesktopSplashConfig? fallback,
  bool verbose,
  String flavor,
) {
  final missing = original == null;
  if (missing) {
    if (verbose) {
      logger.w("Windows platform is missing the flavor config !!");
    }
  }

  DesktopSplashConfig? result;
  final chance = fallback == null;
  if (chance) {
    bool required = false;
    if (missing) required = true;
    if (platform.canFall && required) {
      logger.f("Windows platform is missing the fallback config !!");
      exit(1);
    } else if (platform.canFall && !required) {
      if (verbose) {
        logger.w("Windows platform is missing the fallback config !!");
      }
    }
  } else {
    result = fallback;
  }
  if (!missing) {
    result = original;
  }
  if (result == null) {
    logger.f("Windows check failed due to missing config.");
    exit(2);
  }

  return result;
}

Future<void> handleWindows(SplashScreenConfig config, bool verbose) async {
  if (!config.platforms.hasWindows) {
    if (verbose) {
      logger.w("Windows platform is not enabled.");
    }
    return;
  }

  final dirPath = config.platforms.windows!.path;
  final Directory distDir;
  try {
    distDir = requireBuildFile(dirPath, "native_splash_screen.cmake");
  } catch (_) {
    logger.f(
      '[native_splash_screen_cli] Error: Missing native_splash_screen.cmake\n'
      'In: $dirPath\n'
      'Please run: dart run native_splash_screen_cli to generate it.',
    );
    exit(1);
  }

  final r1 = checkWindows(
    config.platforms.windows!,
    config.release.windows,
    config.fallback.windows,
    verbose,
    RELEASE,
  );
  final r2 = await generateWindowsCode(
    config: r1!,
    flavor: RELEASE,
    outputDir: distDir,
  );
  if (r2 && verbose) {
    logger.success("Generated Windows $RELEASE configuration.");
  }

  final p1 = checkWindows(
    config.platforms.windows!,
    config.profile.windows,
    config.fallback.windows,
    verbose,
    PROFILE,
  );
  final p2 = await generateWindowsCode(
    config: p1!,
    flavor: PROFILE,
    outputDir: distDir,
  );
  if (p2 && verbose) {
    logger.success("Generated Windows $PROFILE configuration.");
  }

  final d1 = checkWindows(
    config.platforms.windows!,
    config.debug.windows,
    config.fallback.windows,
    verbose,
    DEBUG,
  );
  final d2 = await generateWindowsCode(
    config: d1!,
    flavor: DEBUG,
    outputDir: distDir,
  );
  if (d2 && verbose) {
    logger.success("Generated Windows $DEBUG configuration.");
  }
  if (r2 && p2 && d2) {
    logger.success("Generated Windows configuration successfully.");
  }

  return;
}

Future<void> setupWindows(
  Platform? platform,
  bool? force,
  bool? noRunner,
  bool verbose,
) async {
  if (platform == null || !platform.enabled!) {
    if (verbose) {
      logger.w("Windows platform is not enabled.");
    }
    return;
  }

  // If outputPath is provided, use it; otherwise default to 'windows'.
  final Directory distDir;
  if (noRunner != true) {
    distDir = Directory(platform.path);
  } else {
    distDir = locateOrCreateRunnerDir("windows", platform.path);
  }

  // Ensure output directory exists
  if (!distDir.existsSync()) {
    try {
      distDir.createSync(recursive: true);
      logger.i('Created runner directory at: ${distDir.path}');
    } catch (e) {
      throw Exception(
        'Failed to create runner directory at ${distDir.path}: $e',
      );
    }
  }

  createWindowsBuildFile(distDir.path, force);
}
