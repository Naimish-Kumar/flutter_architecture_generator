import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import '../utils/file_helper.dart';
import '../utils/pubspec_helper.dart';
import '../generators/base_generator.dart';

/// The `update` command — updates dependency versions in pubspec.yaml.
class UpdateDepsCommand extends Command<int> {
  /// Creates an [UpdateDepsCommand].
  UpdateDepsCommand({required Logger logger}) : _logger = logger {
    argParser.addOption('output', abbr: 'o', help: 'Custom output directory');
    argParser.addOption('config',
        abbr: 'c', help: 'Configuration profile name');
    argParser.addFlag('dry-run',
        abbr: 'n', negatable: false, help: 'Preview changes');
  }

  final Logger _logger;

  @override
  String get name => 'update';

  @override
  String get description =>
      'Update generated dependency versions in pubspec.yaml to latest bundled versions.';

  @override
  Future<int> run() async {
    final outputDir = argResults?['output'] as String?;
    final configName = argResults?['config'] as String?;
    final dryRun = argResults?['dry-run'] == true;

    final baseDir = outputDir ?? Directory.current.path;
    final config = FileHelper.loadConfig(baseDir: baseDir, name: configName);

    if (config == null) {
      _logger.err(
          'No .flutter_arch_gen${configName != null ? ".$configName" : ""}.json found.');
      return ExitCode.usage.code;
    }

    BaseGenerator.beginTracking();

    await PubspecHelper.addDependencies(config,
        forceUpdate: true, baseDir: baseDir);

    final actions = BaseGenerator.endTracking();
    FileHelper.renderPlan(actions, _logger, baseDir: baseDir);

    if (dryRun) {
      _logger.info('✅ Dry run complete.');
      return ExitCode.success.code;
    }

    if (actions.isEmpty) {
      _logger.info('Dependencies are already up to date.');
      return ExitCode.success.code;
    }

    final confirm = _logger.confirm('Update dependencies in pubspec.yaml?',
        defaultValue: true);
    if (confirm) {
      FileHelper.applyPlan(actions, command: 'update');
      _logger.success('Dependencies updated successfully! 📦');
      _logger.info('Run `flutter pub get` to apply the changes.');
    }

    return ExitCode.success.code;
  }
}
