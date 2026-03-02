import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import '../utils/string_utils.dart';
import '../utils/file_helper.dart';
import '../generators/base_generator.dart';

/// The `delete` command — removes a feature and its registrations.
class DeleteFeatureCommand extends Command<int> {
  /// Creates a [DeleteFeatureCommand].
  DeleteFeatureCommand({required Logger logger}) : _logger = logger {
    argParser.addOption('output', abbr: 'o', help: 'Custom output directory');
    argParser.addOption('config',
        abbr: 'c', help: 'Configuration profile name');
    argParser.addFlag('dry-run',
        abbr: 'n', negatable: false, help: 'Preview changes');
  }

  final Logger _logger;

  @override
  String get name => 'delete';

  @override
  String get description =>
      'Delete a feature and clean up its DI and router registrations.';

  @override
  Future<int> run() async {
    final featureName =
        argResults?.rest.isNotEmpty == true ? argResults?.rest.first : null;
    if (featureName == null) {
      _logger.err('Please provide a feature name to delete.');
      return ExitCode.usage.code;
    }

    final outputDir = argResults?['output'] as String?;
    final configName = argResults?['config'] as String?;
    final dryRun = argResults?['dry-run'] == true;

    final baseDir = outputDir ?? Directory.current.path;
    final config = FileHelper.loadConfig(baseDir: baseDir, name: configName);
    final snakeName = StringUtils.toSnakeCase(featureName);
    final pascalName = StringUtils.toPascalCase(featureName);

    final featureDir = Directory(p.join(baseDir, 'lib', 'features', snakeName));
    if (!featureDir.existsSync()) {
      _logger.err('Feature "$snakeName" not found.');
      return ExitCode.usage.code;
    }

    BaseGenerator.beginTracking();

    // 1. Record feature directory deletion
    _recordDirectoryDeletion(featureDir.path);

    // 2. Record test directory deletion
    final testDir = Directory(p.join(baseDir, 'test', 'features', snakeName));
    if (testDir.existsSync()) {
      _recordDirectoryDeletion(testDir.path);
    }

    // 3. Clean up registrations
    _cleanUpDI(baseDir, snakeName, pascalName);
    _cleanUpRouter(baseDir, snakeName, pascalName, config);

    final actions = BaseGenerator.endTracking();
    FileHelper.renderPlan(actions, _logger, baseDir: baseDir);

    if (dryRun) {
      _logger.info('✅ Dry run complete.');
      return ExitCode.success.code;
    }

    if (actions.isNotEmpty) {
      final confirm = _logger.confirm(
          '⚠️  Permanently delete "$snakeName" and all its files?',
          defaultValue: false);
      if (confirm) {
        FileHelper.applyPlan(actions, command: 'delete $featureName');
        _logger.success('Feature "$snakeName" deleted successfully! 🗑️');
      }
    }

    return ExitCode.success.code;
  }

  void _recordDirectoryDeletion(String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return;
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File) {
        BaseGenerator.deleteFile(entity.path);
      }
    }
  }

  void _cleanUpDI(String baseDir, String snakeName, String pascalName) {
    final diPath = p.join(baseDir, 'lib', 'di', 'injection_container.dart');
    final file = File(diPath);
    if (!file.existsSync()) return;
    final lines = file.readAsLinesSync();
    final filteredLines = <String>[];
    var skipping = false;
    for (final line in lines) {
      if (line.contains('features/$snakeName/')) continue;
      if (line.trim().startsWith('// $pascalName Feature')) {
        skipping = true;
        continue;
      }
      if (skipping) {
        if (line.trim().startsWith('// ') &&
            !line.trim().startsWith('// $pascalName')) {
          skipping = false;
          filteredLines.add(line);
        } else if (line.trim().isEmpty) {
          skipping = false;
        }
        continue;
      }
      filteredLines.add(line);
    }
    BaseGenerator.writeFile(diPath, filteredLines.join('\n'));
  }

  void _cleanUpRouter(
      String baseDir, String snakeName, String pascalName, dynamic config) {
    final routerPath = p.join(baseDir, 'lib', 'routes', 'app_router.dart');
    final file = File(routerPath);
    if (!file.existsSync()) return;
    final lines = file.readAsLinesSync();
    final filteredLines = <String>[];
    var skipGoRoute = false;
    var braceCount = 0;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('features/$snakeName/')) continue;
      if (skipGoRoute) {
        if (line.contains('(')) braceCount++;
        if (line.contains(')')) braceCount--;
        if (braceCount <= 0) skipGoRoute = false;
        continue;
      }
      if (line.contains("path: '/$snakeName'") ||
          (line.contains('GoRoute') &&
              i + 1 < lines.length &&
              lines[i + 1].contains("path: '/$snakeName'"))) {
        skipGoRoute = true;
        braceCount = 0;
        if (line.contains('(')) braceCount++;
        if (line.contains(')')) braceCount--;
        if (braceCount <= 0) skipGoRoute = false;
        continue;
      }
      if (line.contains('${pascalName}Route.page')) continue;
      if (line.contains('static const String $snakeName')) continue;
      if (line.contains('${pascalName}Page()')) continue;
      filteredLines.add(line);
    }
    BaseGenerator.writeFile(routerPath, filteredLines.join('\n'));
  }
}
