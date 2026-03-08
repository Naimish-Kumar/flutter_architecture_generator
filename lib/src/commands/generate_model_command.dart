import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import '../utils/file_helper.dart';
import '../utils/string_utils.dart';
import '../utils/validation_utils.dart';
import '../utils/template_loader.dart';
import '../generators/base_generator.dart';

/// The `model` command — generates a Freezed model file.
class GenerateModelCommand extends Command<int> {
  /// Creates a [GenerateModelCommand].
  GenerateModelCommand({required Logger logger}) : _logger = logger {
    argParser.addOption('feature',
        abbr: 'f', help: 'Target feature for the model');
    argParser.addOption('output', abbr: 'o', help: 'Custom output directory');
    argParser.addOption('config',
        abbr: 'c', help: 'Configuration profile name');
    argParser.addFlag('dry-run',
        abbr: 'n', negatable: false, help: 'Preview changes');
  }

  final Logger _logger;

  @override
  String get name => 'model';

  @override
  String get description => 'Generate a new Freezed model.';

  @override
  Future<int> run() async {
    final modelName =
        argResults?.rest.isNotEmpty == true ? argResults?.rest.first : null;
    if (modelName == null) {
      _logger.err('Please provide a model name.');
      return ExitCode.usage.code;
    }

    final validationError = ValidationUtils.validateName(modelName, 'Model');
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

    final fileName = StringUtils.toSnakeCase(modelName);
    final className = StringUtils.toPascalCase(modelName);

    final content = TemplateLoader.load(
      'model',
      defaultContent: '''
import 'package:freezed_annotation/freezed_annotation.dart';

part '{{fileName}}.freezed.dart';
part '{{fileName}}.g.dart';

@freezed
class {{className}} with _\${{className}} {
  const factory {{className}}({
    required int id,
  }) = _{{className}};

  factory {{className}}.fromJson(Map<String, dynamic> json) => _\${{className}}FromJson(json);
}
''',
      replacements: {
        '{{className}}': className,
        '{{fileName}}': fileName,
      },
      baseDir: baseDir,
    );

    final modelDir = config?.getModelsDirectory() ?? 'data/models';
    final targetPath = featureName != null
        ? p.join(baseDir, 'lib', 'features',
            StringUtils.toSnakeCase(featureName), modelDir)
        : p.join(baseDir, 'lib', 'core', 'models');

    BaseGenerator.writeFile(p.join(targetPath, '$fileName.dart'), content);

    final actions = BaseGenerator.endTracking();
    FileHelper.renderPlan(actions, _logger, baseDir: baseDir);

    if (dryRun) {
      _logger.info('✅ Dry run complete.');
      return ExitCode.success.code;
    }

    if (actions.isNotEmpty) {
      final confirm = _logger.confirm('Generate model?', defaultValue: true);
      if (confirm) {
        FileHelper.applyPlan(actions, command: 'model $modelName');
        _logger.success('Model $className generated successfully! 🎉');
        _logger.info(
            '💡 Run `dart run build_runner build --delete-conflicting-outputs` to generate code.');
      }
    }

    return ExitCode.success.code;
  }
}
