import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:flutter_architecture_generator/src/utils/pubspec_helper.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import '../models/generator_config.dart';
import '../utils/file_helper.dart';
import '../utils/string_utils.dart';
import '../utils/template_loader.dart';
import '../generators/base_generator.dart';

/// The `api` command — generates Model, Repository, and Service for an API.
class GenerateApiCommand extends Command<int> {
  /// Creates a [GenerateApiCommand].
  GenerateApiCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'url',
      abbr: 'u',
      help: 'Endpoint URL or path to OpenAPI spec.',
      mandatory: true,
    );
    argParser.addOption(
      'feature',
      abbr: 'f',
      help: 'Target feature for the API files.',
      mandatory: true,
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Custom output directory.',
    );
    argParser.addOption(
      'config',
      abbr: 'c',
      help: 'Configuration profile name.',
    );
    argParser.addFlag(
      'dry-run',
      abbr: 'n',
      negatable: false,
      help: 'Preview changes without applying them.',
    );
  }

  final Logger _logger;

  @override
  String get name => 'api';

  @override
  String get description =>
      'Generate Model + Repository + Service from an API endpoint or spec.';

  @override
  Future<int> run() async {
    final apiName =
        argResults?.rest.isNotEmpty == true ? argResults!.rest.first : null;

    if (apiName == null) {
      _logger.err('Please provide a name for the API entity (e.g. User).');
      return ExitCode.usage.code;
    }

    final url = argResults?['url'] as String;
    final featureName = argResults?['feature'] as String;
    final outputDir = argResults?['output'] as String?;
    final configName = argResults?['config'] as String?;
    final dryRun = argResults?['dry-run'] == true;

    final config = FileHelper.loadConfig(baseDir: outputDir, name: configName);
    if (config == null) {
      _logger.err('No configuration found.');
      return ExitCode.usage.code;
    }

    final progress = _logger.progress('📡 Analyzing API: $url...');

    try {
      final baseDir = outputDir ?? Directory.current.path;
      final pascalName = StringUtils.toPascalCase(apiName);
      final snakeName = StringUtils.toSnakeCase(apiName);
      final snakeFeature = StringUtils.toSnakeCase(featureName);
      final packageName = PubspecHelper.getPackageName(baseDir: baseDir);

      BaseGenerator.beginTracking();

      _generateApiFiles(
        baseDir,
        pascalName,
        snakeName,
        snakeFeature,
        url,
        config,
        packageName,
      );

      final actions = BaseGenerator.endTracking();
      progress.complete('API analysis complete! ✅');

      FileHelper.renderPlan(actions, _logger, baseDir: baseDir);

      if (dryRun) {
        _logger.info('✅ Dry run complete.');
        return ExitCode.success.code;
      }

      final confirm =
          _logger.confirm('Apply these changes?', defaultValue: true);
      if (!confirm) {
        _logger.info('Cancelled.');
        return ExitCode.success.code;
      }

      FileHelper.applyPlan(actions, command: 'api $apiName');
      return ExitCode.success.code;
    } catch (e) {
      progress.fail('Failed to generate API files: $e');
      return ExitCode.software.code;
    }
  }

  void _generateApiFiles(
    String baseDir,
    String pascalName,
    String snakeName,
    String snakeFeature,
    String url,
    GeneratorConfig config,
    String packageName,
  ) {
    final featurePath = p.join(baseDir, 'lib', 'features', snakeFeature);

    // 1. Model
    final modelContent = TemplateLoader.load(
      'api_model',
      defaultContent: '''
import 'package:json_annotation/json_annotation.dart';

part '{{fileName}}_model.g.dart';

@JsonSerializable()
class {{className}}Model {
  final int id;
  final String? name;

  const {{className}}Model({
    required this.id,
    this.name,
  });

  factory {{className}}Model.fromJson(Map<String, dynamic> json) =>
      _\${{className}}ModelFromJson(json);

  Map<String, dynamic> toJson() => _\${{className}}ModelToJson(this);
}
''',
      replacements: {
        '{{className}}': pascalName,
        '{{fileName}}': snakeName,
      },
      baseDir: baseDir,
    );

    // 2. Data Source / Service
    final serviceContent = TemplateLoader.load(
      'api_service',
      defaultContent: '''
import 'package:dio/dio.dart';
import 'package:{{packageName}}/core/network/api_client.dart';
import '../models/{{fileName}}_model.dart';

class {{className}}Service {
  final ApiClient _client;

  {{className}}Service(this._client);

  Future<{{className}}Model> get{{className}}(int id) async {
    try {
      final response = await _client.get('$url/\$id');
      return {{className}}Model.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
''',
      replacements: {
        '{{className}}': pascalName,
        '{{fileName}}': snakeName,
        '{{packageName}}': packageName,
      },
      baseDir: baseDir,
    );

    // 3. Repository
    final repoContent = TemplateLoader.load(
      'api_repository',
      defaultContent: '''
import '../services/{{fileName}}_service.dart';
import '../models/{{fileName}}_model.dart';

class {{className}}Repository {
  final {{className}}Service _service;

  {{className}}Repository(this._service);

  Future<{{className}}Model> get{{className}}(int id) async {
    return _service.get{{className}}(id);
  }
}
''',
      replacements: {
        '{{className}}': pascalName,
        '{{fileName}}': snakeName,
      },
      baseDir: baseDir,
    );

    final modelDir = p.join(featurePath, 'models');
    final serviceDir = p.join(featurePath, 'services');
    final repoDir = p.join(featurePath, 'repositories');

    BaseGenerator.writeFile(
        p.join(modelDir, '${snakeName}_model.dart'), modelContent);
    BaseGenerator.writeFile(
        p.join(serviceDir, '${snakeName}_service.dart'), serviceContent);
    BaseGenerator.writeFile(
        p.join(repoDir, '${snakeName}_repository.dart'), repoContent);
  }
}
