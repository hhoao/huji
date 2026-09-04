import 'dart:io';

import 'package:yaml/yaml.dart';

import '../models/desktop.dart';
import '../models/platforms.dart';
import '../models/config.dart';

import '../common/utils.dart';
import '../common/const.dart';

import '../templates/macos.dart';
import '../templates/macos_build.dart';

import '../src/logger.dart';

/// Parse Macos platform specific configuration with input validation
/// Returns null if Macos configuration does not exist
DesktopSplashConfig? parseMacosConfig(YamlMap yaml) {
  // Check if macos config exists
  if (!yaml.containsKey('macos') || yaml['macos'] is! YamlMap) {
    logger.e("Macos is enabled, while it's config is not completed.");
    return null;
    // throw Exception('There is no macos configuration yaml block');
  }

  final macosYaml = yaml['macos'] as YamlMap;

  // Default window dimensions
  final windowWidth = macosYaml['window_width'] as int? ?? 500;
  final windowHeight = macosYaml['window_height'] as int? ?? 250;

  // Background dimensions with logical constraints
  final backgroundWidth = macosYaml['background_width'] as int? ?? 0;
  final backgroundHeight = macosYaml['background_height'] as int? ?? 0;

  // Ensure background isn't larger than window
  if (backgroundWidth > windowWidth) {
    throw Exception(
      'Macos configuration error: '
      'background_width should be "<=" window_width',
    );
  }
  if (backgroundHeight > windowHeight) {
    throw Exception(
      'Macos configuration error: '
      'background_height should be "<=" window_height',
    );
  }

  final validWidth = backgroundWidth != 0 ? backgroundWidth : windowWidth;
  final validHeight = backgroundHeight != 0 ? backgroundHeight : windowHeight;

  // Image dimensions with logical constraints
  final imageWidth = macosYaml['image_width'] as int? ?? 0;
  final imageHeight = macosYaml['image_height'] as int? ?? 0;

  // Ensure image isn't larger than background or window
  if (imageWidth > validWidth) {
    throw Exception(
      'Macos configuration error: '
      'image_width should be "<=" background_width and window_width',
    );
  }
  if (imageHeight > validHeight) {
    throw Exception(
      'Macos configuration error: '
      'background_height should be "<=" background_height and window_height',
    );
  }

  // Parse color values
  final windowColor = parseColor('#00000000');
  final backgroundColor = parseColor(
    macosYaml['background_color'] as String? ?? '#00000000',
  );

  // Get image path and validate existence
  final String imagePath = macosYaml['image_path'] as String? ?? "";
  final imageFile = File(imagePath);
  if (!imageFile.existsSync()) {
    throw Exception(
      'Macos configuration error: '
      'image not found at: $imagePath',
    );
  }

  return DesktopSplashConfig(
    windowWidth: windowWidth,
    windowHeight: windowHeight,
    windowTitle: macosYaml['window_title'] as String? ?? 'Splash Screen',
    windowClass: macosYaml['window_class'] as String? ?? 'splash_window',
    windowColor: windowColor,
    imagePath: imageFile.path,
    imageWidth: imageWidth,
    imageHeight: imageHeight,
    imageBorderRadius: macosYaml['image_border_radius'] as double? ?? 0.0,
    imageBlurRadius: macosYaml['blur_radius'] as double? ?? 0.0,
    imageScaling: macosYaml['image_scaling'] as bool? ?? false,
    backgroundColor: backgroundColor,
    backgroundWidth: validWidth,
    backgroundHeight: validHeight,
    backgroundBorderRadius:
        macosYaml['background_border_radius'] as double? ?? 0.0,
    withAnimation: macosYaml['with_animation'] as bool? ?? true,
  );
}

DesktopSplashConfig? checkMacos(
  Platform platform,
  DesktopSplashConfig? original,
  DesktopSplashConfig? fallback,
  bool verbose,
  String flavor,
) {
  final missing = original == null;
  if (missing) {
    if (verbose) {
      logger.w("Macos platform is missing the flavor config !!");
    }
  }

  DesktopSplashConfig? result;
  final chance = fallback == null;
  if (chance) {
    bool required = false;
    if (missing) required = true;
    if (platform.canFall && required) {
      logger.f("Macos platform is missing the fallback config !!");
      exit(1);
    } else if (platform.canFall && !required) {
      if (verbose) {
        logger.w("Macos platform is missing the fallback config !!");
      }
    }
  } else {
    result = fallback;
  }
  if (!missing) {
    result = original;
  }
  if (result == null) {
    logger.f("Macos check failed due to missing config.");
    exit(2);
  }

  return result;
}

Future<void> handleMacos(SplashScreenConfig config, bool verbose) async {
  if (!config.platforms.hasMacos) {
    if (verbose) {
      logger.w("Macos platform is not enabled.");
    }
    return;
  }

  final dirPath = config.platforms.macos!.path;
  final Directory distDir;

  try {
    distDir = requireBuildFile(dirPath, "NativeSplashScreen.swift");
  } catch (_) {
    logger.f(
      '[native_splash_screen_cli] Error: Missing NativeSplashScreen.swift\n'
      'In: $dirPath\n'
      'Please run: dart run native_splash_screen_cli to generate it.',
    );
    exit(1);
  }

  final r1 = checkMacos(
    config.platforms.macos!,
    config.release.macos,
    config.fallback.macos,
    verbose,
    RELEASE,
  );
  final r2 = await generateMacosCode(
    config: r1!,
    flavor: RELEASE,
    outputDir: distDir,
  );
  if (r2 && verbose) {
    logger.success("Generated Macos $RELEASE configuration.");
  }

  final p1 = checkMacos(
    config.platforms.macos!,
    config.profile.macos,
    config.fallback.macos,
    verbose,
    PROFILE,
  );
  final p2 = await generateMacosCode(
    config: p1!,
    flavor: PROFILE,
    outputDir: distDir,
  );
  if (p2 && verbose) {
    logger.success("Generated Macos $PROFILE configuration.");
  }

  final d1 = checkMacos(
    config.platforms.macos!,
    config.debug.macos,
    config.fallback.macos,
    verbose,
    DEBUG,
  );
  final d2 = await generateMacosCode(
    config: d1!,
    flavor: DEBUG,
    outputDir: distDir,
  );
  if (d2 && verbose) {
    logger.success("Generated Macos $DEBUG configuration.");
  }
  if (r2 && p2 && d2) {
    logger.success("Generated Macos configuration successfully.");
  }

  return;
}

Future<void> setupMacos(
  Platform? platform,
  bool? force,
  bool? noRunner,
  bool verbose,
) async {
  if (platform == null || !platform.enabled!) {
    if (verbose) {
      logger.w("Macos platform is not enabled.");
    }
    return;
  }

  // If outputPath is provided, use it; otherwise default to 'macos'.
  final Directory distDir;
  if (noRunner != true) {
    distDir = Directory(platform.path);
  } else {
    distDir = locateOrCreateRunnerDir("macos", platform.path);
  }

  // Ensure output directory exists
  if (!distDir.existsSync()) {
    try {
      distDir.createSync(recursive: true);
      logger.i('Created Runner directory at: ${distDir.path}');
    } catch (e) {
      throw Exception(
        'Failed to create Runner directory at ${distDir.path}: $e',
      );
    }
  }

  createMacosBuildFile(distDir.path, force);
}
