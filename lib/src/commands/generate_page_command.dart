import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import '../utils/file_helper.dart';
import '../utils/string_utils.dart';
import '../utils/validation_utils.dart';
import '../utils/template_loader.dart';
import '../generators/base_generator.dart';

/// The `page` command — generates a new Page.
class GeneratePageCommand extends Command<int> {
  /// Creates a [GeneratePageCommand].
  GeneratePageCommand({required Logger logger}) : _logger = logger {
    argParser.addOption('feature',
        abbr: 'f', help: 'Target feature for the page');
    argParser.addOption('output', abbr: 'o', help: 'Custom output directory');
    argParser.addOption('config',
        abbr: 'c', help: 'Configuration profile name');
    argParser.addFlag('dry-run',
        abbr: 'n', negatable: false, help: 'Preview changes');
  }

  final Logger _logger;

  @override
  String get name => 'page';

  @override
  String get description => 'Generate a new feature page.';

  @override
  Future<int> run() async {
    final pageName =
        argResults?.rest.isNotEmpty == true ? argResults?.rest.first : null;
    if (pageName == null) {
      _logger.err('Please provide a page name.');
      return ExitCode.usage.code;
    }

    final validationError = ValidationUtils.validateName(pageName, 'Page');
    if (validationError != null) {
      _logger.err(validationError);
      return ExitCode.usage.code;
    }

    final featureName = argResults?['feature'] as String?;
    final outputDir = argResults?['output'] as String?;
    final configName = argResults?['config'] as String?;
    final dryRun = argResults?['dry-run'] == true;

    final baseDir = outputDir ?? Directory.current.path;
    final config = FileHelper.loadConfig(baseDir: baseDir, name: configName);

    BaseGenerator.beginTracking();

    final fileName = StringUtils.toSnakeCase(pageName);
    final className = StringUtils.toPascalCase(pageName);

    final content = TemplateLoader.load(
      'page',
      defaultContent: '''
import 'package:flutter/material.dart';

class ${className}Page extends StatelessWidget {
  const ${className}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$className')),
      body: const Center(child: Text('$className Page')),
    );
  }
}
''',
      replacements: {
        '{{className}}': className,
      },
      baseDir: baseDir,
    );

    final pageDir = config?.getPagesDirectory() ?? 'presentation/pages';
    final targetPath = featureName != null
        ? p.join(baseDir, 'lib', 'features',
            StringUtils.toSnakeCase(featureName), pageDir)
        : p.join(baseDir, 'lib', 'core', 'pages');

    BaseGenerator.writeFile(
        p.join(targetPath, '${fileName}_page.dart'), content);

    final actions = BaseGenerator.endTracking();
    FileHelper.renderPlan(actions, _logger, baseDir: baseDir);

    if (dryRun) {
      _logger.info('✅ Dry run complete.');
      return ExitCode.success.code;
    }

    if (actions.isNotEmpty) {
      final confirm = _logger.confirm('Generate page?', defaultValue: true);
      if (confirm) {
        FileHelper.applyPlan(actions, command: 'page $pageName');
        _logger.success('Page $className generated successfully! 🎉');
      }
    }

    return ExitCode.success.code;
  }
}
