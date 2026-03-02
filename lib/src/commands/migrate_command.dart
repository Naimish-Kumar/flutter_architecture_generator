import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import '../models/generator_config.dart';
import '../utils/file_helper.dart';
import '../utils/pubspec_helper.dart';
import '../generators/state_management_generator.dart';
import '../generators/base_generator.dart';

/// The `migrate` command — migrates between state management patterns.
class MigrateCommand extends Command<int> {
  /// Creates a [MigrateCommand].
  MigrateCommand({required Logger logger}) : _logger = logger {
    argParser.addOption('to',
        help: 'Target state management.',
        allowed: ['bloc', 'cubit', 'riverpod', 'provider', 'getx'],
        mandatory: true);
    argParser.addFlag('dry-run',
        negatable: false,
        help: 'Preview what would change without modifying files.');
    argParser.addOption('output',
        abbr: 'o', help: 'Custom output directory (monorepo support).');
    argParser.addOption('config',
        abbr: 'c', help: 'Configuration profile name');
  }

  final Logger _logger;

  @override
  String get name => 'migrate';

  @override
  String get description =>
      'Migrate state management (e.g., Provider → BLoC) across all features.';

  @override
  Future<int> run() async {
    final targetSM = argResults?['to'] as String;
    final dryRun = argResults?['dry-run'] == true;
    final outputDir = argResults?['output'] as String?;
    final configName = argResults?['config'] as String?;

    final baseDir = outputDir ?? Directory.current.path;
    final config = FileHelper.loadConfig(baseDir: baseDir, name: configName);

    if (config == null) {
      _logger.err(
          'No .flutter_arch_gen${configName != null ? ".$configName" : ""}.json found.');
      return ExitCode.usage.code;
    }

    final targetManagement = StateManagement.values.firstWhere(
      (e) => e.name == targetSM,
      orElse: () => StateManagement.bloc,
    );

    if (config.stateManagement == targetManagement) {
      _logger
          .info('Already using ${targetManagement.name}. Nothing to migrate.');
      return ExitCode.success.code;
    }

    final fromName = config.stateManagement.name;
    final toName = targetManagement.name;

    final featuresDir = Directory(p.join(baseDir, 'lib', 'features'));
    if (!featuresDir.existsSync()) {
      _logger.err('No features directory found.');
      return ExitCode.usage.code;
    }

    final features = featuresDir
        .listSync()
        .whereType<Directory>()
        .map((d) => p.basename(d.path))
        .toList()
      ..sort();

    BaseGenerator.beginTracking();

    final packageName = PubspecHelper.getPackageName(baseDir: baseDir);
    final newConfig = GeneratorConfig(
      architecture: config.architecture,
      stateManagement: targetManagement,
      routing: config.routing,
      localization: config.localization,
      firebase: config.firebase,
      tests: config.tests,
      version: config.version,
    );

    for (final feature in features) {
      final featurePath = p.join(baseDir, 'lib', 'features', feature);
      // 1. Record deletion of old SM files
      _recordOldSmDeletion(featurePath, config);
      // 2. Record generation of new SM files
      StateManagementGenerator.generate(
          featurePath, feature, newConfig, packageName);
    }

    final actions = BaseGenerator.endTracking();
    FileHelper.renderPlan(actions, _logger, baseDir: baseDir);

    if (dryRun) {
      _logger.info('✅ Dry run complete.');
      return ExitCode.success.code;
    }

    if (actions.isEmpty) {
      _logger.info('No changes needed.');
      return ExitCode.success.code;
    }

    final confirm = _logger.confirm(
      '⚠️  Migrate $fromName → $toName for ${features.length} features?',
      defaultValue: false,
    );

    if (!confirm) {
      _logger.info('Cancelled.');
      return ExitCode.success.code;
    }

    final progress = _logger.progress('🔄 Migrating $fromName → $toName...');
    try {
      FileHelper.applyPlan(actions, command: 'migrate $toName');
      FileHelper.saveConfig(newConfig, baseDir: baseDir, name: configName);

      // Update dependencies as well
      await PubspecHelper.addDependencies(newConfig,
          forceUpdate: true, baseDir: baseDir);

      progress.complete('Migration complete! ✅');
      _logger.info('');
      _logger.info('Next steps:');
      _logger.info('  1. Run `flutter pub get`');
      _logger.info('  2. Update DI registrations if needed');
      return ExitCode.success.code;
    } catch (e) {
      progress.fail('Migration failed: $e');
      return ExitCode.software.code;
    }
  }

  void _recordOldSmDeletion(String featurePath, GeneratorConfig config) {
    final smDir = config.getStateManagementDirectory();
    final oldSmDir = Directory(p.join(featurePath, smDir));

    if (oldSmDir.existsSync()) {
      for (final entity in oldSmDir.listSync()) {
        if (entity is File && entity.path.endsWith('.dart')) {
          BaseGenerator.deleteFile(entity.path);
        }
      }
    }
  }
}
