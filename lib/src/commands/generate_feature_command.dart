/// Command to generate a new feature.
///
/// Orchestrates the generation of a feature following the project's
/// selected architecture and state management patterns.
library;

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import '../utils/file_helper.dart';
import '../utils/feature_helper.dart';
import '../utils/pubspec_helper.dart';
import '../utils/validation_utils.dart';
import '../generators/base_generator.dart';

/// The `generate feature` command.
class GenerateFeatureCommand extends Command<int> {
  /// Creates a [GenerateFeatureCommand].
  GenerateFeatureCommand({required Logger logger}) : _logger = logger {
    argParser.addFlag(
      'force',
      abbr: 'f',
      negatable: false,
      help: 'Overwrite existing feature files.',
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
  String get name => 'feature';

  @override
  String get description => 'Generate a new feature scaffold.';

  @override
  String get invocation => 'flutter_arch_gen generate feature <name> [flags]';

  @override
  Future<int> run() async {
    final featureName =
        argResults?.rest.isNotEmpty == true ? argResults!.rest.first : null;

    if (featureName == null) {
      _logger.err('Please provide a feature name.');
      _logger.info(usage);
      return ExitCode.usage.code;
    }

    // Validate name
    final validationError =
        ValidationUtils.validateName(featureName, 'feature');
    if (validationError != null) {
      _logger.err(validationError);
      return ExitCode.usage.code;
    }

    final force = argResults?['force'] == true;
    final outputDir = argResults?['output'] as String?;
    final configName = argResults?['config'] as String?;
    final dryRun = argResults?['dry-run'] == true;

    final config = FileHelper.loadConfig(baseDir: outputDir, name: configName);
    if (config == null) {
      _logger.err(
          'No .flutter_arch_gen${configName != null ? ".$configName" : ""}.json found. Run `flutter_arch_gen init` first.');
      return ExitCode.usage.code;
    }

    try {
      final actions = await FeatureHelper.generateFeature(
        featureName,
        config: config,
        logger: _logger,
        force: force,
        outputDir: outputDir,
      );

      // Ensure dependencies are present
      BaseGenerator.beginTracking();
      await PubspecHelper.addDependencies(config, baseDir: outputDir);
      final pubspecActions = BaseGenerator.endTracking();

      final allActions = [...actions, ...pubspecActions];

      if (allActions.isEmpty) {
        _logger.info('No changes needed.');
        return ExitCode.success.code;
      }

      FileHelper.renderPlan(allActions, _logger, baseDir: outputDir);

      if (dryRun) {
        _logger.info('✅ Dry run complete. No files were modified.');
        return ExitCode.success.code;
      }

      final confirm = _logger.confirm(
        'Proceed with these changes?',
        defaultValue: true,
      );

      if (!confirm) {
        _logger.info('Cancelled.');
        return ExitCode.success.code;
      }

      final progress = _logger.progress('🚀 Applying changes...');
      FileHelper.applyPlan(actions, command: 'generate feature $featureName');
      progress.complete('Feature "$featureName" generated successfully! 🎉');

      return ExitCode.success.code;
    } catch (e) {
      _logger.err('Failed to generate feature: $e');
      return ExitCode.software.code;
    }
  }
}
