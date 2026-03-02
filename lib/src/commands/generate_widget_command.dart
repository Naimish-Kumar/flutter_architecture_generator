import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import '../utils/file_helper.dart';
import '../utils/string_utils.dart';
import '../utils/validation_utils.dart';
import '../utils/template_loader.dart';
import '../generators/base_generator.dart';

/// The `widget` command — generates a new Widget.
class GenerateWidgetCommand extends Command<int> {
  /// Creates a [GenerateWidgetCommand].
  GenerateWidgetCommand({required Logger logger}) : _logger = logger {
    argParser.addOption('feature',
        abbr: 'f', help: 'Target feature for the widget');
    argParser.addOption('output', abbr: 'o', help: 'Custom output directory');
    argParser.addOption('config',
        abbr: 'c', help: 'Configuration profile name');
    argParser.addFlag('dry-run',
        abbr: 'n', negatable: false, help: 'Preview changes');
  }

  final Logger _logger;

  @override
  String get name => 'widget';

  @override
  String get description => 'Generate a new feature widget.';

  @override
  Future<int> run() async {
    final widgetName =
        argResults?.rest.isNotEmpty == true ? argResults?.rest.first : null;
    if (widgetName == null) {
      _logger.err('Please provide a widget name.');
      return ExitCode.usage.code;
    }

    final validationError = ValidationUtils.validateName(widgetName, 'Widget');
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

    final fileName = StringUtils.toSnakeCase(widgetName);
    final className = StringUtils.toPascalCase(widgetName);

    final content = TemplateLoader.load(
      'widget',
      defaultContent: '''
import 'package:flutter/material.dart';

class $className extends StatelessWidget {
  const $className({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      child: Text('$className'),
    );
  }
}
''',
      replacements: {
        '{{className}}': className,
      },
      baseDir: baseDir,
    );

    final widgetDir = config?.getWidgetsDirectory() ?? 'presentation/widgets';
    final targetPath = featureName != null
        ? p.join(baseDir, 'lib', 'features',
            StringUtils.toSnakeCase(featureName), widgetDir)
        : p.join(baseDir, 'lib', 'core', 'widgets');

    BaseGenerator.writeFile(
        p.join(targetPath, '${fileName}_widget.dart'), content);

    final actions = BaseGenerator.endTracking();
    FileHelper.renderPlan(actions, _logger, baseDir: baseDir);

    if (dryRun) {
      _logger.info('✅ Dry run complete.');
      return ExitCode.success.code;
    }

    if (actions.isNotEmpty) {
      final confirm = _logger.confirm('Generate widget?', defaultValue: true);
      if (confirm) {
        FileHelper.applyPlan(actions, command: 'widget $widgetName');
        _logger.success('Widget $className generated successfully! 🎉');
      }
    }

    return ExitCode.success.code;
  }
}
