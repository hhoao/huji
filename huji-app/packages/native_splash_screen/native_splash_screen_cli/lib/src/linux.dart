import 'dart:io';

import 'package:yaml/yaml.dart';

import '../models/desktop.dart';
import '../models/platforms.dart';
import '../models/config.dart';

import '../common/utils.dart';
import '../common/const.dart';

import '../templates/linux.dart';
import '../templates/linux_build.dart';

import '../src/logger.dart';

/// Parse Linux platform specific configuration with input validation
/// Returns null if Linux configuration does not exist
DesktopSplashConfig? parseLinuxConfig(YamlMap yaml) {
  // Check if linux config exists
  if (!yaml.containsKey('linux') || yaml['linux'] is! YamlMap) {
    logger.e("Linux is enabled, while it's config is not completed.");
    return null;
    // throw Exception('There is no linux configuration yaml block');
  }

  final linuxYaml = yaml['linux'] as YamlMap;

  // Default window dimensions
  final windowWidth = linuxYaml['window_width'] as int? ?? 500;
  final windowHeight = linuxYaml['window_height'] as int? ?? 250;

  // Background dimensions with logical constraints
  final backgroundWidth = linuxYaml['background_width'] as int? ?? 0;
  final backgroundHeight = linuxYaml['background_height'] as int? ?? 0;

  // Ensure background isn't larger than window
  if (backgroundWidth > windowWidth) {
    throw Exception(
      'Linux configuration error: '
      'background_width should be "<=" window_width',
    );
  }
  if (backgroundHeight > windowHeight) {
    throw Exception(
      'Linux configuration error: '
      'background_height should be "<=" window_height',
    );
  }

  final validWidth = backgroundWidth != 0 ? backgroundWidth : windowWidth;
  final validHeight = backgroundHeight != 0 ? backgroundHeight : windowHeight;

  // Image dimensions with logical constraints
  final imageWidth = linuxYaml['image_width'] as int? ?? 0;
  final imageHeight = linuxYaml['image_height'] as int? ?? 0;

  // Ensure image isn't larger than background or window
  if (imageWidth > validWidth) {
    throw Exception(
      'Linux configuration error: '
      'image_width should be "<=" background_width and window_width',
    );
  }
  if (imageHeight > validHeight) {
    throw Exception(
      'Linux configuration error: '
      'background_height should be "<=" background_height and window_height',
    );
  }

  // Parse color values
  final windowColor = parseColor(
    linuxYaml['window_color'] as String? ?? '#00000000',
  );
  final backgroundColor = parseColor(
    linuxYaml['background_color'] as String? ?? '#00000000',
  );

  // Get image path and validate existence
  final String imagePath = linuxYaml['image_path'] as String? ?? "";
  final imageFile = File(imagePath);
  if (!imageFile.existsSync()) {
    throw Exception(
      'Linux configuration error: '
      'image not found at: $imagePath',
    );
  }

  return DesktopSplashConfig(
    windowWidth: windowWidth,
    windowHeight: windowHeight,
    windowTitle: linuxYaml['window_title'] as String? ?? 'Splash Screen',
    windowClass: linuxYaml['window_class'] as String? ?? 'splash_window',
    windowColor: windowColor,
    imagePath: imageFile.path,
    imageWidth: imageWidth,
    imageHeight: imageHeight,
    imageBorderRadius: linuxYaml['image_border_radius'] as double? ?? 0.0,
    imageBlurRadius: linuxYaml['blur_radius'] as double? ?? 0.0,
    imageScaling: linuxYaml['image_scaling'] as bool? ?? false,
    backgroundColor: backgroundColor,
    backgroundWidth: validWidth,
    backgroundHeight: validHeight,
    backgroundBorderRadius:
        linuxYaml['background_border_radius'] as double? ?? 0.0,
    withAnimation: linuxYaml['with_animation'] as bool? ?? true,
  );
}

DesktopSplashConfig? checkLinux(
  Platform platform,
  DesktopSplashConfig? original,
  DesktopSplashConfig? fallback,
  bool verbose,
  String flavor,
) {
  final missing = original == null;
  if (missing) {
    if (verbose) {
      logger.w("Linux platform is missing the flavor config !!");
    }
  }

  DesktopSplashConfig? result;
  final chance = fallback == null;
  if (chance) {
    bool required = false;
    if (missing) required = true;
    if (platform.canFall && required) {
      logger.f("Linux platform is missing the fallback config !!");
      exit(1);
    } else if (platform.canFall && !required) {
      if (verbose) {
        logger.w("Linux platform is missing the fallback config !!");
      }
    }
  } else {
    result = fallback;
  }
  if (!missing) {
    result = original;
  }
  if (result == null) {
    logger.f("Linux check failed due to missing config.");
    exit(2);
  }

  return result;
}

Future<void> handleLinux(SplashScreenConfig config, bool verbose) async {
  if (!config.platforms.hasLinux) {
    if (verbose) {
      logger.w("Linux platform is not enabled.");
    }
    return;
  }

  final dirPath = config.platforms.linux!.path;
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

  final r1 = checkLinux(
    config.platforms.linux!,
    config.release.linux,
    config.fallback.linux,
    verbose,
    RELEASE,
  );
  final r2 = await generateLinuxCode(
    config: r1!,
    flavor: RELEASE,
    outputDir: distDir,
  );
  if (r2 && verbose) {
    logger.success("Generated Linux $RELEASE configuration.");
  }

  final p1 = checkLinux(
    config.platforms.linux!,
    config.profile.linux,
    config.fallback.linux,
    verbose,
    PROFILE,
  );
  final p2 = await generateLinuxCode(
    config: p1!,
    flavor: PROFILE,
    outputDir: distDir,
  );
  if (p2 && verbose) {
    logger.success("Generated Linux $PROFILE configuration.");
  }

  final d1 = checkLinux(
    config.platforms.linux!,
    config.debug.linux,
    config.fallback.linux,
    verbose,
    DEBUG,
  );
  final d2 = await generateLinuxCode(
    config: d1!,
    flavor: DEBUG,
    outputDir: distDir,
  );
  if (d2 && verbose) {
    logger.success("Generated Linux $DEBUG configuration.");
  }
  if (r2 && p2 && d2) {
    logger.success("Generated Linux configuration successfully.");
  }

  return;
}

Future<void> setupLinux(
  Platform? platform,
  bool? force,
  bool? noRunner,
  bool verbose,
) async {
  if (platform == null || !platform.enabled!) {
    if (verbose) {
      logger.w("Linux platform is not enabled.");
    }
    return;
  }

  // If outputPath is provided, use it; otherwise default to 'linux'.
  final Directory distDir;
  if (noRunner != true) {
    distDir = Directory(platform.path);
  } else {
    distDir = locateOrCreateRunnerDir("linux", platform.path);
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

  createLinuxBuildFile(distDir.path, force);
}
