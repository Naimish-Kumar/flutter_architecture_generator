import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import '../utils/file_helper.dart';
import '../utils/string_utils.dart';
import '../utils/validation_utils.dart';
import '../utils/template_loader.dart';
import '../generators/base_generator.dart';

/// The `service` command — generates a new Service.
class GenerateServiceCommand extends Command<int> {
  /// Creates a [GenerateServiceCommand].
  GenerateServiceCommand({required Logger logger}) : _logger = logger {
    argParser.addOption('feature',
        abbr: 'f', help: 'Target feature for the service');
    argParser.addOption('output', abbr: 'o', help: 'Custom output directory');
    argParser.addOption('config',
        abbr: 'c', help: 'Configuration profile name');
    argParser.addFlag('dry-run',
        abbr: 'n', negatable: false, help: 'Preview changes');
  }

  final Logger _logger;

  @override
  String get name => 'service';

  @override
  String get description => 'Generate a new feature service.';

  @override
  Future<int> run() async {
    final serviceName =
        argResults?.rest.isNotEmpty == true ? argResults?.rest.first : null;
    if (serviceName == null) {
      _logger.err('Please provide a service name.');
      return ExitCode.usage.code;
    }

    final validationError =
        ValidationUtils.validateName(serviceName, 'Service');
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

    final fileName = StringUtils.toSnakeCase(serviceName);
    final className = StringUtils.toPascalCase(serviceName);

    final content = TemplateLoader.load(
      'service',
      defaultContent: '''
class ${className}Service {
  ${className}Service();

  Future<void> performAction() async {
    // TODO: Implement service logic
  }
}
''',
      replacements: {
        '{{className}}': className,
      },
      baseDir: baseDir,
    );

    final serviceDir = config?.getServicesDirectory() ?? 'data/services';
    final targetPath = featureName != null
        ? p.join(baseDir, 'lib', 'features',
            StringUtils.toSnakeCase(featureName), serviceDir)
        : p.join(baseDir, 'lib', 'core', 'services');

    BaseGenerator.writeFile(
        p.join(targetPath, '${fileName}_service.dart'), content);

    final actions = BaseGenerator.endTracking();
    FileHelper.renderPlan(actions, _logger, baseDir: baseDir);

    if (dryRun) {
      _logger.info('✅ Dry run complete.');
      return ExitCode.success.code;
    }

    if (actions.isNotEmpty) {
      final confirm = _logger.confirm('Generate service?', defaultValue: true);
      if (confirm) {
        FileHelper.applyPlan(actions, command: 'service $serviceName');
        _logger.success('Service $className generated successfully! 🎉');
      }
    }

    return ExitCode.success.code;
  }
}
