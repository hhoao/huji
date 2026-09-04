import 'dart:io';

import 'package:yaml/yaml.dart';

import '../models/config.dart';
import '../models/flavor.dart';
import '../models/platforms.dart';

import '../src/logger.dart';
import '../src/linux.dart';
import '../src/windows.dart';
import '../src/macos.dart';

import '../common/const.dart';

class SplashScreenGenerator {
  bool verbose;
  SplashScreenGenerator(this.verbose);

  /// Check the platforms from the YAML configuration file
  Platforms check(String configPath) {
    final configFile = File(configPath);
    if (!configFile.existsSync()) {
      throw FileSystemException('Config file not found', configPath);
    }
    final configContent = configFile.readAsStringSync();
    final yaml = loadYaml(configContent) as YamlMap;

    // Parse platforms configuration
    final platforms = _parsePlatforms(yaml);
    if (!platforms.hasAnyPlatform) {
      throw Exception("Configuration must enable at least one platform");
    }

    logger.i('Detected platforms: ${platforms.all()}');
    return platforms;
  }

  /// Parse the YAML configuration file into our model
  SplashScreenConfig parse(String configPath, String? custom) {
    final configFile = File(configPath);
    if (!configFile.existsSync()) {
      throw FileSystemException('Config file not found', configPath);
    }
    final configContent = configFile.readAsStringSync();
    final yaml = loadYaml(configContent) as YamlMap;

    // Parse platforms configuration
    final platforms = _parsePlatforms(yaml);
    if (!platforms.hasAnyPlatform) {
      throw Exception("Configuration must enable at least one platform");
    }
    logger.i('Detected platforms: ${platforms.all()}');

    Flavor fallback;
    Flavor release;
    if (platforms.canFallback()) {
      // Parse release flavor (required)
      if (!yaml.containsKey(RELEASE)) {
        throw Exception(
          'Required "$RELEASE" configuration is missing from the config file.\n'
          'Please add a "$RELEASE" section to your configuration.\n'
          'Also configure the platforms that has fallback enabled.',
        );
      } else {
        release = _parseFlavor(yaml, RELEASE, platforms);
        if (release.empty) {
          throw Exception(
            'Release configuration is empty.\n'
            'Configure at least the platforms that has fallback enabled.\n'
            'Or disable them, and create there flavors config.',
          );
        }
        fallback = release;

        if (verbose) {
          logger.i('Parsed $RELEASE configuration successfully');
        }
      }
    } else {
      release = _parseFlavor(yaml, RELEASE, platforms);
      if (release.empty) {
        if (verbose) {
          logger.w('Release configuration is incomplete.');
        }
      } else {
        if (verbose) {
          logger.i('Parsed $RELEASE configuration successfully');
        }
      }
      fallback = release;
    }

    // Parse custom flavors if they exist
    List<Flavor> customFlavors = [];
    if (custom != null &&
        yaml.containsKey('flavors') &&
        yaml['flavors'] is YamlMap) {
      // if (custom != null && yaml.containsKey('flavors')) {
      final flavorsMap = yaml['flavors'] as YamlMap;

      for (final key in flavorsMap.keys) {
        final flavorName = key.toString();
        final name = flavorName.toLowerCase();
        if (name.contains(RELEASE) ||
            name.contains(PROFILE) ||
            name.contains(DEBUG)) {
          throw Exception(
            'The keyword [$flavorName] is not allowed as a valid flavor name.',
          );
        }

        final flavorConfig = flavorsMap[key] as YamlMap?;
        if (flavorConfig != null) {
          customFlavors.add(
            _parseCustomFlavor(flavorConfig, flavorName, platforms),
          );
          if (verbose) {
            logger.i('Parsed custom flavor: $flavorName');
          }
        }
      }
    }
    if (customFlavors.isNotEmpty) {
      List<String> flavors = [];
      action(Flavor f) {
        flavors.add(f.name);
      }

      customFlavors.forEach(action);
      logger.i("Parsed custom flavors: ${flavors.join(", ")}");
    }

    if (custom != null) {
      if (customFlavors.isEmpty) {
        throw Exception(
          'There is no flavors. Consider to create one in the config file.',
        );
      }
      Flavor? flavor;
      for (final f in customFlavors) {
        if (f.name == custom) {
          flavor = f;
          break;
        }
      }
      if (flavor == null) {
        throw Exception('There is no [$custom] flavor in the flavors list !?');
      }
      release = flavor;
    }

    // Parse debug flavor (or default to release)
    Flavor debug;
    if (yaml.containsKey(DEBUG)) {
      debug = _parseFlavor(yaml, DEBUG, platforms);
      logger.i('Parsed $DEBUG configuration successfully');
    } else {
      logger.w(
        'No $DEBUG configuration found. fallback to release values instead',
      );
      debug = release;
    }

    // Parse profile flavor (or default to release)
    Flavor profile;
    if (yaml.containsKey(PROFILE)) {
      profile = _parseFlavor(yaml, PROFILE, platforms);
      logger.i('Parsed $PROFILE configuration successfully');
    } else {
      logger.w(
        'No $PROFILE configuration found. fallback to release values instead',
      );
      profile = release;
    }

    return SplashScreenConfig(
      platforms: platforms,
      release: release,
      debug: debug,
      profile: profile,
      fallback: fallback,
    );
  }

  /// Parse platforms configuration from YAML
  Platforms _parsePlatforms(YamlMap yaml) {
    // Check if platforms section exists
    if (!yaml.containsKey('platforms') || yaml['platforms'] is! YamlMap) {
      // Default: no platforms enabled
      return Platforms();
    }

    final platformsYaml = yaml['platforms'] as YamlMap;

    Platform? parsePlatform(YamlMap? map, String path) {
      if (map == null) return null;

      return Platform(
        enabled: map['enabled'] as bool? ?? false,
        fallback: map['fallback'] as bool? ?? false,
        path: map['path'] as String? ?? path,
      );
    }

    return Platforms(
      linux: platformsYaml['linux'] is YamlMap
          ? parsePlatform(platformsYaml['linux'] as YamlMap, "linux/runner")
          : null,
      windows: platformsYaml['windows'] is YamlMap
          ? parsePlatform(
              platformsYaml['windows'] as YamlMap,
              "windows/runner",
            )
          : null,
      macos: platformsYaml['macos'] is YamlMap
          ? parsePlatform(platformsYaml['macos'] as YamlMap, "macos/Runner")
          : null,
    );
    // TODO: Additional platforms can be added here in the future
  }

  /// Parse a standard flavor from the root config
  Flavor _parseFlavor(YamlMap yaml, String flavorName, Platforms platforms) {
    // Check if the flavor section exists in the YAML
    if (!yaml.containsKey(flavorName)) {
      return Flavor(name: flavorName);
    }

    // Get the flavor-specific configuration
    final flavorConfig = yaml[flavorName] as YamlMap?;
    if (flavorConfig == null) {
      return Flavor(name: flavorName);
      // throw Exception(
      //   'Configuration for flavor "$flavorName" is not a valid YAML map',
      // );
    }

    // Only parse platforms that are enabled and exist in the flavor config
    final linuxConfig =
        platforms.hasLinux ? parseLinuxConfig(flavorConfig) : null;

    final windowsConfig =
        platforms.hasWindows ? parseWindowsConfig(flavorConfig) : null;

    final macosConfig =
        platforms.hasMacos ? parseMacosConfig(flavorConfig) : null;

    return Flavor(
      name: flavorName,
      linux: linuxConfig,
      windows: windowsConfig,
      macos: macosConfig,
    );
    // TODO: Additional platforms can be added here in the future
  }

  /// Parse a custom flavor from the flavors section
  Flavor _parseCustomFlavor(
    YamlMap flavorYaml,
    String flavorName,
    Platforms platforms,
  ) {
    // Only parse platforms that are enabled and exist in the flavor config
    final linuxConfig =
        platforms.hasLinux ? parseLinuxConfig(flavorYaml) : null;

    final windowsConfig =
        platforms.hasWindows ? parseWindowsConfig(flavorYaml) : null;

    final macosConfig =
        platforms.hasMacos ? parseMacosConfig(flavorYaml) : null;

    return Flavor(
      name: flavorName,
      linux: linuxConfig,
      windows: windowsConfig,
      macos: macosConfig,
    );
    // TODO: Additional platforms can be added here in the future
  }

  /// Generate code for all build modes (release, debug, profile)
  Future<void> generate({required SplashScreenConfig config}) async {
    await handleLinux(config, verbose);
    await handleWindows(config, verbose);
    await handleMacos(config, verbose);
    return;
    // TODO: Additional platforms can be added here in the future
  }

  /// Setup the build configuration for the supported platforms
  Future<void> setup(Platforms platforms, [bool? force, bool? noRunner]) async {
    await setupLinux(platforms.linux, force, noRunner, verbose);
    await setupWindows(platforms.windows, force, noRunner, verbose);
    await setupMacos(platforms.macos, force, noRunner, verbose);
    return;
    // TODO: Additional platforms can be added here in the future
  }
}
