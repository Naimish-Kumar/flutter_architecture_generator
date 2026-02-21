// ignore_for_file: public_member_api_docs
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import '../models/generator_config.dart';
import '../templates/base_templates.dart';
import 'pubspec_helper.dart';

class FileHelper {
  static Future<void> generateBaseStructure(GeneratorConfig config) async {
    final currentDir = Directory.current.path;
    final packageName = PubspecHelper.getPackageName();

    // 1. Create Directories
    final directories = [
      'lib/core/constants',
      'lib/core/errors',
      'lib/core/network',
      'lib/core/theme',
      'lib/core/utils',
      'lib/core/services',
      'lib/features',
      'lib/routes',
      'lib/di',
      'assets/images',
      'assets/fonts',
      'assets/translations',
    ];

    if (config.localization) {
      directories.add('lib/l10n');
    }

    if (config.tests) {
      directories.addAll(['test/unit', 'test/widget', 'test/integration']);
    }

    for (var dir in directories) {
      await Directory(p.join(currentDir, dir)).create(recursive: true);
    }

    // 2. Create Base Files
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
    };

    if (config.localization) {
      files['l10n.yaml'] = BaseTemplates.l10nYamlContent();
      files['lib/l10n/app_en.arb'] = BaseTemplates.arbContent(config);
    }

    if (config.tests) {
      files['test/unit/sample_test.dart'] = BaseTemplates.testContent();
    }

    files.forEach((path, content) {
      File(p.join(currentDir, path)).writeAsStringSync(content);
    });

    // 3. Update pubspec.yaml
    await PubspecHelper.addDependencies(config);

    // 4. Save config
    _saveConfig(config);
  }

  static void _saveConfig(GeneratorConfig config) {
    File('.flutter_arch_gen.json')
        .writeAsStringSync(jsonEncode(config.toJson()));
  }

  static GeneratorConfig? loadConfig() {
    final file = File('.flutter_arch_gen.json');
    if (!file.existsSync()) return null;
    try {
      final json = jsonDecode(file.readAsStringSync());
      return GeneratorConfig.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static String _gitignoreContent() {
    return '''
# Environment files
.env*
!.env.example

# Generator config
.flutter_arch_gen.json

# Dart/Flutter
.dart_tool/
.packages
build/
.flutter-plugins
.flutter-plugins-dependencies

# IDE
.idea/
.vscode/
*.iml

# Generated files
*.g.dart
*.freezed.dart
*.gr.dart
*.config.dart
''';
  }
}
