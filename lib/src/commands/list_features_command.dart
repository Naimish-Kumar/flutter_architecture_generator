/// Command to list generated features.
///
/// Scans the `lib/features/` directory and displays all generated
/// features with their architecture information.
library;

import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import '../utils/file_helper.dart';

/// The `list` command — lists all generated features.
class ListFeaturesCommand extends Command<int> {
  /// Creates a [ListFeaturesCommand].
  ListFeaturesCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  String get name => 'list';

  @override
  String get description => 'List all generated features.';

  @override
  Future<int> run() async {
    final config = FileHelper.loadConfig();
    final featuresDir =
        Directory(p.join(Directory.current.path, 'lib', 'features'));

    if (!featuresDir.existsSync()) {
      _logger.info('📋 No features directory found.');
      _logger.info('Run `flutter_arch_gen init` to set up the project first.');
      return ExitCode.success.code;
    }

    final features = featuresDir
        .listSync()
        .whereType<Directory>()
        .map((d) => p.basename(d.path))
        .toList()
      ..sort();

    if (features.isEmpty) {
      _logger.info('📋 No features generated yet.');
      _logger.info(
          'Run `flutter_arch_gen feature <name>` to create your first feature.');
      return ExitCode.success.code;
    }

    final archDisplay =
        config?.architecture.displayName ?? 'Unknown Architecture';

    _logger.info('');
    _logger.info('📋 Generated Features ($archDisplay):');
    _logger.info('');

    for (final feature in features) {
      final featurePath =
          p.join(Directory.current.path, 'lib', 'features', feature);
      final subDirs = Directory(featurePath)
          .listSync()
          .whereType<Directory>()
          .map((d) => p.basename(d.path))
          .toList()
        ..sort();
      final structure = subDirs.join(', ');
      _logger.info('  • $feature ($structure)');
    }

    _logger.info('');
    _logger.info('Total: ${features.length} feature(s)');

    if (config != null) {
      _logger.info('');
      _logger.info('⚙️  Project Config:');
      _logger.info('  Architecture:      ${config.architecture.displayName}');
      _logger.info('  State Management:  ${config.stateManagement.name}');
      _logger.info('  Routing:           ${config.routing.name}');
      _logger.info('  Localization:      ${config.localization ? "✅" : "❌"}');
      _logger.info('  Firebase:          ${config.firebase ? "✅" : "❌"}');
      _logger.info('  Tests:             ${config.tests ? "✅" : "❌"}');
    }

    return ExitCode.success.code;
  }
}
