import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import '../utils/file_helper.dart';
import '../utils/string_utils.dart';
import '../utils/validation_utils.dart';
import '../generators/base_generator.dart';

/// The `rename` command — renames a feature and updates all references.
class RenameFeatureCommand extends Command<int> {
  /// Creates a [RenameFeatureCommand].
  RenameFeatureCommand({required Logger logger}) : _logger = logger {
    argParser.addOption('output', abbr: 'o', help: 'Custom output directory');
    argParser.addOption('config',
        abbr: 'c', help: 'Configuration profile name');
    argParser.addFlag('dry-run',
        abbr: 'n', negatable: false, help: 'Preview changes');
  }

  final Logger _logger;

  @override
  String get name => 'rename';

  @override
  String get description =>
      'Rename a feature and update its DI and router registrations.';

  @override
  Future<int> run() async {
    final args = argResults?.rest ?? [];
    if (args.length < 2) {
      _logger.err('Please provide the old and new feature names.');
      _logger.info('Usage: flutter_arch_gen rename <old_name> <new_name>');
      return ExitCode.usage.code;
    }

    final oldName = args[0];
    final newName = args[1];
    final outputDir = argResults?['output'] as String?;
    final configName = argResults?['config'] as String?;
    final dryRun = argResults?['dry-run'] == true;

    final baseDir = outputDir ?? Directory.current.path;
    FileHelper.loadConfig(baseDir: baseDir, name: configName);

    // Validate new name
    final validationError = ValidationUtils.validateName(newName, 'Feature');
    if (validationError != null) {
      _logger.err(validationError);
      return ExitCode.usage.code;
    }

    final oldSnake = StringUtils.toSnakeCase(oldName);
    final newSnake = StringUtils.toSnakeCase(newName);
    final oldPascal = StringUtils.toPascalCase(oldName);
    final newPascal = StringUtils.toPascalCase(newName);
    final oldCamel = StringUtils.toCamelCase(oldName);
    final newCamel = StringUtils.toCamelCase(newName);

    if (oldSnake == newSnake) {
      _logger.info('Old and new names are the same. Nothing to do.');
      return ExitCode.success.code;
    }

    final oldDir = Directory(p.join(baseDir, 'lib', 'features', oldSnake));
    if (!oldDir.existsSync()) {
      _logger.err('Feature "$oldSnake" not found at ${oldDir.path}');
      return ExitCode.usage.code;
    }

    BaseGenerator.beginTracking();

    // 1. Record renaming of files within the directory (DELETE + CREATE)
    _recordRenamesRecursive(oldDir, baseDir, oldSnake, newSnake, oldPascal,
        newPascal, oldCamel, newCamel);

    // 2. Update DI registrations
    _recordFileUpdate(p.join(baseDir, 'lib', 'di', 'injection_container.dart'),
        oldSnake, newSnake, oldPascal, newPascal, oldCamel, newCamel);

    // 3. Update router registrations
    _recordFileUpdate(p.join(baseDir, 'lib', 'routes', 'app_router.dart'),
        oldSnake, newSnake, oldPascal, newPascal, oldCamel, newCamel);

    // 4. Rename test directory
    final oldTestDir = Directory(p.join(baseDir, 'test', 'features', oldSnake));
    if (oldTestDir.existsSync()) {
      _recordRenamesRecursive(oldTestDir, baseDir, oldSnake, newSnake,
          oldPascal, newPascal, oldCamel, newCamel);
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

    final confirm =
        _logger.confirm('🔄 Rename $oldSnake → $newSnake?', defaultValue: true);
    if (confirm) {
      FileHelper.applyPlan(actions, command: 'rename $oldName $newName');
      _logger
          .success('Feature $oldPascal renamed to $newPascal successfully! 🔄');
    }

    return ExitCode.success.code;
  }

  void _recordRenamesRecursive(
      Directory oldDir,
      String baseDir,
      String oldSnake,
      String newSnake,
      String oldPascal,
      String newPascal,
      String oldCamel,
      String newCamel) {
    for (final entity in oldDir.listSync(recursive: true)) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: baseDir);
        final newRelativePath = relativePath
            .replaceAll(oldSnake, newSnake)
            .replaceAll('lib/features/$oldSnake', 'lib/features/$newSnake')
            .replaceAll('test/features/$oldSnake', 'test/features/$newSnake');

        var contents = entity.readAsStringSync();
        contents = contents
            .replaceAll(oldSnake, newSnake)
            .replaceAll(oldPascal, newPascal)
            .replaceAll(oldCamel, newCamel);

        // Record deletion of old file
        BaseGenerator.deleteFile(entity.path);
        // Record creation of new file
        BaseGenerator.writeFile(p.join(baseDir, newRelativePath), contents);
      }
    }
  }

  void _recordFileUpdate(String path, String oldSnake, String newSnake,
      String oldPascal, String newPascal, String oldCamel, String newCamel) {
    final file = File(path);
    if (!file.existsSync()) return;
    var contents = file.readAsStringSync();
    contents = contents
        .replaceAll(oldSnake, newSnake)
        .replaceAll(oldPascal, newPascal)
        .replaceAll(oldCamel, newCamel);
    BaseGenerator.writeFile(path, contents);
  }
}
