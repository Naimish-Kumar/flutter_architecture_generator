import 'dart:convert';
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
      help: 'Output directory for the feature.',
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
    argParser.addFlag(
      'force',
      abbr: 'r',
      negatable: false,
      help: 'Apply changes without confirmation.',
    );
  }

  @override
  String get name => 'api';

  @override
  String get description =>
      'Generate Model + Repository + Service from an endpoint URL or spec.';

  final Logger _logger;

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

      dynamic apiResponse;
      if (url.startsWith('http')) {
        apiResponse = await _fetchApiResponse(url);
      } else if (url.startsWith('file://')) {
        final filePath = url.replaceFirst('file://', '');
        final file = File(filePath);
        if (file.existsSync()) {
          apiResponse = json.decode(file.readAsStringSync());
        } else {
          _logger.err('Local file not found: $filePath');
          return ExitCode.ioError.code;
        }
      }

      BaseGenerator.beginTracking();

      _generateApiFiles(
        baseDir,
        pascalName,
        snakeName,
        snakeFeature,
        url,
        config,
        packageName,
        apiResponse,
      );

      final actions = BaseGenerator.endTracking();
      progress.complete('API analysis complete! ✅');

      FileHelper.renderPlan(actions, _logger, baseDir: baseDir);

      if (dryRun) {
        _logger.info('✅ Dry run complete.');
        return ExitCode.success.code;
      }

      final force = argResults?['force'] == true;
      if (!force) {
        final confirm =
            _logger.confirm('Apply these changes?', defaultValue: true);
        if (!confirm) {
          _logger.info('Cancelled.');
          return ExitCode.success.code;
        }
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
    dynamic apiResponse,
  ) {
    final featurePath = p.join(baseDir, 'lib', 'features', snakeFeature);
    final isClean = config.architecture == Architecture.clean;

    final fields = _inferFields(apiResponse);
    final constructor = _inferConstructor(apiResponse);
    final entityFields = _inferFields(apiResponse, isEntity: true);
    final entityConstructor = _inferConstructor(apiResponse, isEntity: true);

    final isList = apiResponse is List;
    final modelName = '${pascalName}Model';
    final entityName = '${pascalName}Entity';
    final baseReturnName = isClean ? entityName : modelName;

    final returnType = isList ? 'List<$baseReturnName>' : baseReturnName;
    final fromJsonCall = isList
        ? '(response.data as List).map((e) => $modelName.fromJson(e as Map<String, dynamic>)).toList()'
        : '$modelName.fromJson(response.data as Map<String, dynamic>)';

    // 1. Entity (Clean Arch only)
    if (isClean) {
      final entityContent = TemplateLoader.load(
        'api_entity',
        defaultContent: '''
class $entityName {
$entityFields

  const $entityName({
$entityConstructor
  });
}
''',
        baseDir: baseDir,
      );
      BaseGenerator.writeFile(
          p.join(featurePath, 'domain/entities', '${snakeName}_entity.dart'),
          entityContent);
    }

    // 2. Model
    final modelContent = TemplateLoader.load(
      'api_model',
      defaultContent: isClean
          ? '''
import 'package:json_annotation/json_annotation.dart';
import 'package:{{packageName}}/features/{{snakeFeature}}/domain/entities/{{fileName}}_entity.dart';

part '{{fileName}}_model.g.dart';

@JsonSerializable()
class {{className}}Model extends {{className}}Entity {
{{fields}}

  const {{className}}Model({
{{constructor}}
  }) : super(
{{superConstructor}}
  );

  factory {{className}}Model.fromJson(Map<String, dynamic> json) =>
      _\${{className}}ModelFromJson(json);

  Map<String, dynamic> toJson() => _\${{className}}ModelToJson(this);
}
'''
          : '''
import 'package:json_annotation/json_annotation.dart';

part '{{fileName}}_model.g.dart';

@JsonSerializable()
class {{className}}Model {
{{fields}}

  const {{className}}Model({
{{constructor}}
  });

  factory {{className}}Model.fromJson(Map<String, dynamic> json) =>
      _\${{className}}ModelFromJson(json);

  Map<String, dynamic> toJson() => _\${{className}}ModelToJson(this);
}
''',
      replacements: {
        '{{className}}': pascalName,
        '{{fileName}}': snakeName,
        '{{fields}}': fields,
        '{{constructor}}': constructor,
        '{{superConstructor}}': _inferSuperConstructor(apiResponse),
        '{{packageName}}': packageName,
        '{{snakeFeature}}': snakeFeature,
      },
      baseDir: baseDir,
    );

    // 3. Data Source / Service
    final serviceContent = TemplateLoader.load(
      'api_service',
      defaultContent: '''
import 'package:dio/dio.dart';
import 'package:{{packageName}}/core/network/api_client.dart';
import '../models/{{fileName}}_model.dart';

class {{className}}Service {
  final ApiClient _client;

  {{className}}Service(this._client);

  Future<{{returnType}}> get{{className}}Data() async {
    try {
      final response = await _client.dio.get('{{url}}');
      return {{fromJsonCall}};
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
        '{{url}}': url,
        '{{returnType}}': isList ? 'List<$modelName>' : modelName,
        '{{fromJsonCall}}': fromJsonCall,
      },
      baseDir: baseDir,
    );

    // 4. Repository
    final repoContent = TemplateLoader.load(
      'api_repository',
      defaultContent: isClean
          ? '''
import '../../domain/repositories/{{fileName}}_repository.dart';
import '../../domain/entities/{{fileName}}_entity.dart';
import '../datasources/{{fileName}}_remote_datasource.dart'; // Fallback to service if needed

class {{className}}RepositoryImpl implements I{{className}}Repository {
  final {{className}}Service _service;

  {{className}}RepositoryImpl(this._service);

  @override
  Future<{{returnType}}> get{{className}}Data() async {
    return await _service.get{{className}}Data();
  }
}
'''
          : '''
import '../services/{{fileName}}_service.dart';
import '../models/{{fileName}}_model.dart';

class {{className}}Repository {
  final {{className}}Service _service;

  {{className}}Repository(this._service);

  Future<{{returnType}}> get{{className}}Data() async {
    return await _service.get{{className}}Data();
  }
}
''',
      replacements: {
        '{{className}}': pascalName,
        '{{fileName}}': snakeName,
        '{{returnType}}': returnType,
      },
      baseDir: baseDir,
    );

    // 5. Repository Interface (Clean Arch only)
    if (isClean) {
      final repoInterfaceContent = TemplateLoader.load(
        'api_repository_interface',
        defaultContent: '''
import '../entities/{{fileName}}_entity.dart';

abstract class I{{className}}Repository {
  Future<{{returnType}}> get{{className}}Data();
}
''',
        replacements: {
          '{{className}}': pascalName,
          '{{fileName}}': snakeName,
          '{{returnType}}': returnType,
        },
        baseDir: baseDir,
      );
      BaseGenerator.writeFile(
          p.join(featurePath, 'domain/repositories',
              '${snakeName}_repository.dart'),
          repoInterfaceContent);
    }

    final modelDir = p.join(featurePath, config.getModelsDirectory());
    final serviceDir = p.join(featurePath, config.getServicesDirectory());
    final repoDir =
        p.join(featurePath, isClean ? 'data/repositories' : 'repositories');

    BaseGenerator.writeFile(
        p.join(modelDir, '${snakeName}_model.dart'), modelContent);
    BaseGenerator.writeFile(
        p.join(serviceDir, '${snakeName}_service.dart'), serviceContent);
    BaseGenerator.writeFile(
        p.join(
            repoDir, '${snakeName}_repository${isClean ? "_impl" : ""}.dart'),
        repoContent);
  }

  Future<dynamic> _fetchApiResponse(String url) async {
    final client = HttpClient();
    String? token;

    try {
      while (true) {
        final uri = Uri.parse(url);
        final request = await client.getUrl(uri);

        if (token != null) {
          request.headers.set('Authorization', 'Bearer $token');
        }

        final response = await request.close();

        if (response.statusCode == 200) {
          final content = await response.transform(utf8.decoder).join();
          return json.decode(content);
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          _logger.info('🔒 API requires authorization.');
          token = _logger.prompt('Enter Authorization Token:');
          if (token.isEmpty) {
            throw 'Authorization required but no token provided.';
          }
          continue; // Retry with token
        } else {
          throw 'API returned status code ${response.statusCode}: ${response.reasonPhrase}';
        }
      }
    } finally {
      client.close();
    }
  }

  String _inferFields(dynamic json, {bool isEntity = false}) {
    if (json is List) {
      if (json.isEmpty) return '  final List<dynamic>? items;';
      return _inferFields(json.first, isEntity: isEntity);
    }
    if (json is! Map) return '  final dynamic value;';

    final buffer = StringBuffer();
    json.forEach((key, value) {
      final type = _getDartType(value);
      final fieldName = StringUtils.toCamelCase(key.toString());
      if (isEntity) {
        buffer.writeln('  final $type? $fieldName;');
      } else {
        // Model fields are inherited from Entity in Clean Arch
        // unless we want to redeclare them?
        // Actually, if it extends Entity, we don't need to redeclare them
        // BUT if it's not Clean Arch, we DO need them.
        // My template logic handles this by using 'fields' placeholder.
        buffer.writeln('  final $type? $fieldName;');
      }
    });
    return buffer.toString();
  }

  String _getDartType(dynamic value) {
    if (value == null) return 'dynamic';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    if (value is String) return 'String';
    if (value is List) {
      if (value.isEmpty) return 'List<dynamic>';
      final firstType = _getDartType(value.first);
      return 'List<$firstType>';
    }
    if (value is Map) return 'Map<String, dynamic>';
    return 'dynamic';
  }

  String _inferConstructor(dynamic json, {bool isEntity = false}) {
    if (json is List) {
      if (json.isEmpty) return '    this.items,';
      return _inferConstructor(json.first, isEntity: isEntity);
    }
    if (json is! Map) return '    this.value,';

    final buffer = StringBuffer();
    for (final key in json.keys) {
      final fieldName = StringUtils.toCamelCase(key.toString());
      if (isEntity) {
        buffer.writeln('    required this.$fieldName,');
      } else {
        buffer.writeln('    this.$fieldName,');
      }
    }
    return buffer.toString();
  }

  String _inferSuperConstructor(dynamic json) {
    if (json is List) {
      if (json.isEmpty) return '    items: items,';
      return _inferSuperConstructor(json.first);
    }
    if (json is! Map) return '    value: value,';

    final buffer = StringBuffer();
    for (final key in json.keys) {
      final fieldName = StringUtils.toCamelCase(key.toString());
      buffer.writeln('    $fieldName: $fieldName,');
    }
    return buffer.toString();
  }
}
