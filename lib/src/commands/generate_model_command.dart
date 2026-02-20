import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import '../utils/string_utils.dart';

class GenerateModelCommand extends Command<int> {
  final Logger _logger;

  @override
  String get name => 'model';

  @override
  String get description => 'Generate a new model.';

  GenerateModelCommand({required Logger logger}) : _logger = logger {
    argParser.addOption('feature',
        abbr: 'f', help: 'Target feature for the model');
  }

  @override
  Future<int> run() async {
    final modelName =
        argResults?.rest.isNotEmpty == true ? argResults?.rest.first : null;

    if (modelName == null) {
      _logger.err('Please provide a model name.');
      return ExitCode.usage.code;
    }

    final featureName = argResults?['feature'] as String?;
    final progress = _logger.progress('📦 Generating model: $modelName...');

    try {
      final fileName = StringUtils.toSnakeCase(modelName);
      final className = StringUtils.toPascalCase(modelName);

      final content = '''
import 'package:freezed_annotation/freezed_annotation.dart';

part '$fileName.freezed.dart';
part '$fileName.g.dart';

@freezed
class $className with _\$$className {
  const factory $className({
    required int id,
  }) = _$className;

  factory $className.fromJson(Map<String, dynamic> json) => _\$${className}FromJson(json);
}
''';

      final targetPath = featureName != null
          ? p.join('lib', 'features', StringUtils.toSnakeCase(featureName),
              'data', 'models')
          : p.join('lib', 'core', 'models');

      final file =
          File(p.join(Directory.current.path, targetPath, '$fileName.dart'));
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      file.writeAsStringSync(content);

      progress.complete('Model $className generated in $targetPath! ✅');
      return ExitCode.success.code;
    } catch (e) {
      progress.fail('Failed to generate model: $e');
      return ExitCode.software.code;
    }
  }
}
