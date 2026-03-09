/// Base interface for architecture-specific feature generators.
library;

import 'dart:io';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import '../models/generator_config.dart';
import '../utils/string_utils.dart';
import '../utils/pubspec_helper.dart';
import '../utils/history_helper.dart';
import 'di_registrar.dart';
import 'router_registrar.dart';
import 'test_generator.dart';
import 'state_management_generator.dart';
import 'page_generator.dart';

/// Base class for all architecture generators.
abstract class BaseGenerator {
  /// Creates a [BaseGenerator].
  const BaseGenerator();

  /// Returns the list of directories to create for this architecture.
  List<String> getDirectories(GeneratorConfig config);

  /// Generates the architecture-specific files (models, repos, etc.).
  Future<void> generateFiles(
    String featureName,
    GeneratorConfig config,
    String packageName,
    String featurePath,
  );

  /// Internal action tracker.
  static final List<FileAction> _actions = [];

  /// Start collecting file actions.
  static void beginTracking() => _actions.clear();

  /// Stop tracking and return actions.
  static List<FileAction> endTracking() => List.from(_actions);

  /// Full feature generation pipeline.
  Future<List<FileAction>> generateFeature(
    String featureName, {
    required GeneratorConfig config,
    Logger? logger,
    bool force = false,
    String? outputDir,
  }) async {
    final baseDir = outputDir ?? Directory.current.path;
    final snakeFeatureName = StringUtils.toSnakeCase(featureName);
    final featurePath = p.join(baseDir, 'lib', 'features', snakeFeatureName);
    final packageName = PubspecHelper.getPackageName(baseDir: baseDir);

    beginTracking();

    await generateFiles(featureName, config, packageName, featurePath);
    StateManagementGenerator.generate(
        featurePath, featureName, config, packageName);
    PageGenerator.generatePages(featurePath, featureName, config, packageName);
    DIRegistrar.register(featureName, config, packageName, baseDir: baseDir);
    RouterRegistrar.register(featureName, config, packageName,
        baseDir: baseDir);

    if (config.tests) {
      TestGenerator.generate(featureName, config, packageName,
          baseDir: baseDir);
    }

    return endTracking();
  }

  /// Helper to record a file write action.
  static void writeFile(String path, String content) {
    final file = File(path);
    if (file.existsSync()) {
      _actions.add(FileAction(
        path: path,
        action: 'MODIFY',
        oldContent: file.readAsStringSync(),
        newContent: content,
      ));
    } else {
      _actions.add(FileAction(
        path: path,
        action: 'CREATE',
        newContent: content,
      ));
    }
  }

  /// Helper to record a file deletion action.
  static void deleteFile(String path) {
    final file = File(path);
    if (file.existsSync()) {
      _actions.add(FileAction(
        path: path,
        action: 'DELETE',
        oldContent: file.readAsStringSync(),
      ));
    }
  }
}
