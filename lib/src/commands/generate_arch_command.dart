/// Command to initialize a new Flutter project architecture.
///
/// Sets up the base directory structure, core files, and a sample feature.
library;

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import '../models/generator_config.dart';
import '../utils/file_helper.dart';
import '../utils/template_loader.dart';
import '../utils/feature_helper.dart';

/// The `init` command.
class GenerateArchCommand extends Command<int> {
  /// Creates a [GenerateArchCommand].
  GenerateArchCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'arch',
      abbr: 'a',
      help: 'Architecture pattern.',
      allowed: ['clean', 'mvvm'],
      defaultsTo: 'clean',
    );
    argParser.addOption(
      'state',
      abbr: 's',
      help: 'State management pattern.',
      allowed: ['bloc', 'cubit', 'riverpod', 'provider', 'getx'],
      defaultsTo: 'bloc',
    );
    argParser.addOption(
      'routing',
      abbr: 'r',
      help: 'Routing strategy.',
      allowed: ['navigator', 'goRouter', 'autoRoute'],
      defaultsTo: 'goRouter',
    );
    argParser.addFlag(
      'localization',
      abbr: 'l',
      help: 'Enable localization support.',
      defaultsTo: true,
    );
    argParser.addFlag(
      'firebase',
      abbr: 'f',
      help: 'Enable sample Firebase setup.',
      defaultsTo: false,
    );
    argParser.addFlag(
      'tests',
      abbr: 't',
      help: 'Generate sample tests.',
      defaultsTo: true,
    );
    argParser.addFlag(
      'force',
      negatable: false,
      help: 'Overwrite existing files.',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Custom output directory (monorepo support).',
    );
    argParser.addOption(
      'config',
      abbr: 'c',
      help:
          'Configuration profile name (e.g. "dev" for .flutter_arch_gen.dev.json).',
    );
    argParser.addFlag(
      'dry-run',
      abbr: 'n',
      negatable: false,
      help: 'Preview changes without applying them.',
    );
  }

  final Logger _logger;

  @override
  String get name => 'init';

  @override
  String get description => 'Initialize project with selected architecture.';

  @override
  Future<int> run() async {
    final outputDir = argResults?['output'] as String?;
    final configName = argResults?['config'] as String?;
    final dryRun = argResults?['dry-run'] == true;
    final force = argResults?['force'] == true;

    final config = GeneratorConfig(
      architecture: Architecture.values.firstWhere(
          (e) => e.name == argResults?['arch'],
          orElse: () => Architecture.clean),
      stateManagement: StateManagement.values.firstWhere(
          (e) => e.name == argResults?['state'],
          orElse: () => StateManagement.bloc),
      routing: Routing.values.firstWhere(
          (e) => e.name == argResults?['routing'],
          orElse: () => Routing.goRouter),
      localization: argResults?['localization'] == true,
      firebase: argResults?['firebase'] == true,
      tests: argResults?['tests'] == true,
      version: configVersion,
    );

    try {
      final baseActions = await FileHelper.generateBaseStructure(
        config,
        force: force,
        outputDir: outputDir,
        configName: configName,
      );

      final featureActions = await FeatureHelper.generateFeature(
        'example',
        config: config,
        logger: _logger,
        force: force,
        outputDir: outputDir,
      );

      final allActions = [...baseActions, ...featureActions];

      FileHelper.renderPlan(allActions, _logger, baseDir: outputDir);

      if (dryRun) {
        _logger.info('✅ Dry run complete. No files were modified.');
        return ExitCode.success.code;
      }

      final confirm = _logger.confirm(
        'Initialize project with these changes?',
        defaultValue: true,
      );

      if (!confirm) {
        _logger.info('Cancelled.');
        return ExitCode.success.code;
      }

      final progress = _logger.progress('🚀 Initializing project...');
      FileHelper.applyPlan(allActions,
          command: 'init ${config.architecture.name}');
      FileHelper.saveConfig(config, baseDir: outputDir, name: configName);
      TemplateLoader.initTemplateDir(baseDir: outputDir);
      progress.complete('Project initialized successfully! 🎉');

      return ExitCode.success.code;
    } catch (e) {
      _logger.err('Failed to initialize: $e');
      return ExitCode.software.code;
    }
  }
}
