import 'dart:io';

import 'package:args/args.dart';
import 'package:logger/logger.dart';

import 'package:native_splash_screen_cli/src/generator.dart';
import 'package:native_splash_screen_cli/src/logger.dart';
import 'package:native_splash_screen_cli/templates/_config.dart';

void main(List<String> arguments) async {
  final parser = ArgParser();

  // Global flags
  parser
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Logs all the generation steps.',
    )
    ..addOption(
      'config',
      abbr: 'c',
      help: 'Path to the config file',
      defaultsTo: 'native_splash_screen.yaml',
    )
    ..addFlag(
      'color',
      defaultsTo: true,
      help: 'Enable or disable colored output',
    );

  // Subcommand: init
  parser.addCommand('init')
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag(
      'force',
      abbr: 'f',
      negatable: false,
      help: 'Force overwrite the current config file if its already exists.',
    );

  // Subcommand: setup
  parser.addCommand('setup')
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag(
      'no-runner',
      abbr: 'n',
      negatable: false,
      help: 'Do not check for the runner directory.',
    )
    ..addFlag(
      'force',
      abbr: 'f',
      negatable: false,
      help: 'Force overwrite if the CMake files already exist.',
    );

  // Subcommand: gen
  parser.addCommand('gen')
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addOption(
      'flavor',
      abbr: 'f',
      help: 'Build flavor to use (replaces release flavor)',
      defaultsTo: 'release',
    );

  // Logger setup
  final useColor = !arguments.contains('--no-color');
  final log = Logger(
    filter: ProductionFilter(),
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 0,
      lineLength: 95,
      colors: useColor,
      printEmojis: false,
      dateTimeFormat: DateTimeFormat.none,
    ),
  );

  ArgResults argResults;
  try {
    setLogger(logger: log);
    argResults = parser.parse(arguments);
  } catch (e) {
    logger.e('Error parsing arguments: $e');
    _printUsage(logger, parser);
    exit(1);
  }

  final configPath = argResults['config'] as String;
  final verbose = argResults['verbose'] as bool? ?? false;

  try {
    if (argResults.command == null) {
      _printUsage(logger, parser);
      return;
    }

    logger.i('🌟 Native Splash Screen CLI');
    final generator = SplashScreenGenerator(verbose);
    if (argResults.command!.name == "init") {
      final initCommand = parser.commands['init']!;
      if (argResults.command!['help'] == true) {
        logger.i('Usage: native_splash_screen_cli init [SUBCOMMAND FLAGS]');
        logger.i(
          'Available [SUBCOMMAND FLAGS]:\n\n'
          '${initCommand.usage}',
        );
        return;
      }
      final force = argResults.command!['force'] as bool? ?? false;
      createConfigFile(force);
      return;
    }
    if (argResults.command!.name == "setup") {
      final setupCommand = parser.commands['setup']!;
      if (argResults.command!['help'] == true) {
        logger.i('Usage: native_splash_screen_cli setup [SUBCOMMAND FLAGS]');
        logger.i(
          'Available [SUBCOMMAND FLAGS]:\n\n'
          '${setupCommand.usage}',
        );
        return;
      }
      logger.i('Parsing platforms from $configPath ...');

      final force = argResults.command!['force'] as bool? ?? false;
      final noRunner = argResults.command!['no-runner'] as bool? ?? false;
      final platforms = generator.check(configPath);
      final _ = await generator.setup(platforms, force, noRunner);
      return;
    }
    if (argResults.command!.name == "gen") {
      final genCommand = parser.commands['gen']!;
      if (argResults.command!['help'] == true) {
        logger.i('Usage: native_splash_screen_cli gen [SUBCOMMAND FLAGS]');
        logger.i(
          'Available [SUBCOMMAND FLAGS]:\n\n'
          '${genCommand.usage}',
        );
        return;
      }

      logger.i('Parsing configuration from $configPath ...');

      final flavorName = argResults.command!['flavor'] as String?;
      String? customFlavor;
      if (flavorName != 'release' &&
          flavorName != 'debug' &&
          flavorName != 'profile') {
        customFlavor = flavorName;
      }

      final config = generator.parse(configPath, customFlavor);
      final _ = await generator.generate(config: config);
      return;
    }
    throw Exception('Unknown subcommand: ${argResults.command!.name}');
  } catch (e) {
    logger.e('Failed to run.', error: e.toString(), stackTrace: null);
    exit(1);
  }
}

void _printUsage(Logger logger, ArgParser parser) {
  logger.i('Native Splash Screen CLI 🎨');
  logger.i(
    'Usage : dart run native_splash_screen_cli [GLOBAL FLAGS] <subcommand> [SUBCOMMAND FLAGS]',
  );
  logger.i(
    'Available [GLOBAL FLAGS]:\n\n'
    '${parser.usage}',
  );
  logger.i(
    'Available <subcommand>:\n\n'
    '    init:        create the configuration yaml file.\n'
    '    setup:       add the necessary build files.\n'
    '    gen:         generate the splash screen based on the config option.\n',
  );
  logger.i(
    'Example: dart run native_splash_screen_cli --config=my_config.yaml',
  );
}
