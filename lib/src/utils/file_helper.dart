/// File system helper utilities.
///
/// Manages directory creation, base file generation, configuration
/// persistence, and overwrite protection for the generator.
library;

import 'dart:io';
import 'dart:convert';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import '../models/generator_config.dart';
import '../templates/base_templates.dart';
import 'pubspec_helper.dart';
import 'template_loader.dart';
import 'history_helper.dart';

/// Provides file system operations for the generator.
class FileHelper {
  /// Default configuration filename.
  static const String defaultConfig = '.flutter_arch_gen';

  /// Generates the base project structure for the given [config].
  static Future<List<FileAction>> generateBaseStructure(
    GeneratorConfig config, {
    bool force = false,
    String? outputDir,
    String? configName,
  }) async {
    final baseDir = outputDir ?? Directory.current.path;
    final packageName = PubspecHelper.getPackageName(baseDir: baseDir);

    TemplateLoader.initTemplateDir();

    final files = <String, String>{
      'lib/main.dart': BaseTemplates.mainContent(config, packageName),
      'lib/app.dart': BaseTemplates.appContent(config, packageName),
      'lib/di/injection_container.dart':
          BaseTemplates.diContent(config, packageName),
      'lib/core/network/api_client.dart': BaseTemplates.apiClientContent(),
      'lib/core/errors/failures.dart': BaseTemplates.errorContent(),
      'lib/core/theme/app_theme.dart': BaseTemplates.themeContent(),
      'lib/core/constants/app_constants.dart':
          BaseTemplates.constantsContent(config),
      'lib/routes/app_router.dart': BaseTemplates.routerContent(config),
      '.env.dev': 'API_BASE_URL=https://dev.api.example.com',
      '.env.prod': 'API_BASE_URL=https://api.example.com',
      '.gitignore': _gitignoreContent(),
      '.github/workflows/ci.yml': BaseTemplates.githubActionsContent(),
    };

    if (config.localization) {
      files['l10n.yaml'] = BaseTemplates.l10nYamlContent();
      files['lib/l10n/app_en.arb'] = BaseTemplates.arbContent(config);
    }

    if (config.tests) {
      files['test/unit/sample_test.dart'] = BaseTemplates.testContent();
    }

    final actions = <FileAction>[];
    files.forEach((path, content) {
      final absolutePath = p.join(baseDir, path);
      final file = File(absolutePath);
      if (file.existsSync()) {
        actions.add(FileAction(
          path: absolutePath,
          action: 'MODIFY',
          oldContent: file.readAsStringSync(),
          newContent: content,
        ));
      } else {
        actions.add(FileAction(
          path: absolutePath,
          action: 'CREATE',
          newContent: content,
        ));
      }
    });

    return actions;
  }

  /// Renders a list of actions to the console as a plan.
  static void renderPlan(List<FileAction> actions, Logger logger,
      {String? baseDir}) {
    final root = baseDir ?? Directory.current.path;
    logger.info('');
    logger.info(lightCyan.wrap('📋 Execution Plan:'));
    logger.info('');

    for (final action in actions) {
      final relativePath = p.relative(action.path, from: root);
      String prefix;
      switch (action.action) {
        case 'CREATE':
          prefix = green.wrap('[+] CREATE')!;
          break;
        case 'MODIFY':
          prefix = yellow.wrap('[M] MODIFY')!;
          break;
        case 'DELETE':
          prefix = red.wrap('[-] DELETE')!;
          break;
        default:
          prefix = action.action;
      }
      logger.info('  $prefix $relativePath');
    }
    logger.info('');
    logger.info('Total: ${actions.length} changes.');
    logger.info('');
  }

  /// Applies a list of actions to the file system.
  static void applyPlan(List<FileAction> actions, {String? command}) {
    for (final action in actions) {
      final file = File(action.path);
      if (action.action == 'DELETE') {
        if (file.existsSync()) file.deleteSync();
      } else {
        if (!file.parent.existsSync()) {
          file.parent.createSync(recursive: true);
        }
        file.writeAsStringSync(action.newContent ?? '');
      }
    }

    if (command != null && actions.isNotEmpty) {
      HistoryHelper.saveEntry(HistoryEntry(
        timestamp: DateTime.now(),
        command: command,
        actions: actions,
      ));
    }
  }

  /// Saves the generator configuration.
  static void saveConfig(GeneratorConfig config,
      {String? baseDir, String? name}) {
    final configBase = baseDir ?? Directory.current.path;
    final filename =
        name == null ? '$defaultConfig.json' : '$defaultConfig.$name.json';
    final configPath = p.join(configBase, filename);
    File(configPath).writeAsStringSync(jsonEncode(config.toJson()));
  }

  /// Loads the generator configuration.
  static GeneratorConfig? loadConfig({String? baseDir, String? name}) {
    final configBase = baseDir ?? Directory.current.path;
    final filename =
        name == null ? '$defaultConfig.json' : '$defaultConfig.$name.json';
    final configPath = p.join(configBase, filename);
    final file = File(configPath);
    if (!file.existsSync()) return null;
    try {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return GeneratorConfig.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static String _gitignoreContent() {
    return '''
# Flutter/Dart
.dart_tool/
.packages
.pub-cache/
.pub/
build/
ios/.generated/
*.env*
!.env.example

# Config
.flutter_arch_gen*.json
''';
  }
}
