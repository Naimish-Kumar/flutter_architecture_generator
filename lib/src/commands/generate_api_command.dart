import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:flutter_architecture_generator/src/utils/pubspec_helper.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import '../models/generator_config.dart';
import '../utils/file_helper.dart';
import '../utils/string_utils.dart';
import '../generators/base_generator.dart';
import '../generators/di_registrar.dart';
import '../templates/api_templates.dart';

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
      'method',
      abbr: 'm',
      help: 'HTTP Method (GET, POST, PUT, DELETE, PATCH).',
      defaultsTo: 'GET',
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
    argParser.addOption(
      'body',
      abbr: 'b',
      help: 'JSON body for POST/PUT requests (as a string).',
    );
  }

  @override
  String get name => 'api';

  @override
  String get description =>
      'Generate Model + Repository + Service from an endpoint URL or spec.';

  final Logger _logger;
  final List<_ApiModelTask> _generationQueue = [];

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
    final method = (argResults?['method'] as String).toUpperCase();
    final bodyString = argResults?['body'] as String?;
    final outputDir = argResults?['output'] as String?;
    final configName = argResults?['config'] as String?;
    final dryRun = argResults?['dry-run'] == true;

    final config = FileHelper.loadConfig(baseDir: outputDir, name: configName);
    if (config == null) {
      _logger.err('No configuration found.');
      return ExitCode.usage.code;
    }

    final progress = _logger.progress('📡 Analyzing API: $url ($method)...');

    try {
      final baseDir = outputDir ?? Directory.current.path;
      final pascalName = StringUtils.toPascalCase(apiName);
      final snakeName = StringUtils.toSnakeCase(apiName);
      final snakeFeature = StringUtils.toSnakeCase(featureName);
      final packageName = PubspecHelper.getPackageName(baseDir: baseDir);

      dynamic apiResponse;
      if (url.startsWith('http')) {
        apiResponse =
            await _fetchApiResponse(url, method: method, body: bodyString);
      } else {
        final filePath =
            url.startsWith('file://') ? url.replaceFirst('file://', '') : url;
        final file = File(filePath);
        if (file.existsSync()) {
          apiResponse = json.decode(file.readAsStringSync());
        } else {
          apiResponse =
              await _fetchApiResponse(url, method: method, body: bodyString);
        }
      }

      BaseGenerator.beginTracking();

      _generationQueue.clear();
      _generationQueue.add(_ApiModelTask(
        pascalName: pascalName,
        snakeName: snakeName,
        data: apiResponse,
        isRoot: true,
      ));

      while (_generationQueue.isNotEmpty) {
        final task = _generationQueue.removeAt(0);
        _generateApiFiles(
          baseDir,
          task.pascalName,
          task.snakeName,
          snakeFeature,
          url,
          config,
          packageName,
          task.data,
          method,
          isRoot: task.isRoot,
        );
      }

      // Register in DI
      DIRegistrar.registerApi(apiName, featureName, config, packageName,
          baseDir: baseDir);

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
    String method, {
    bool isRoot = false,
  }) {
    final featurePath = p.join(baseDir, 'lib', 'features', snakeFeature);
    final isClean = config.architecture == Architecture.clean;

    final fields = _inferFields(apiResponse, pascalName);
    final constructor = _inferConstructor(apiResponse);
    final entityFields = _inferFields(apiResponse, pascalName, isEntity: true);
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
      final entityContent = ApiTemplates.entityContent(
        className: entityName,
        fields: entityFields,
        constructor: entityConstructor,
      );
      BaseGenerator.writeFile(
          p.join(featurePath, 'domain/entities', '${snakeName}_entity.dart'),
          entityContent);
    }

    // 2. Model
    final modelContent = ApiTemplates.modelContent(
      className: pascalName,
      fileName: snakeName,
      packageName: packageName,
      snakeFeature: snakeFeature,
      fields: fields,
      constructor: constructor,
      superName: isClean ? entityName : null,
      superConstructor: isClean ? _inferSuperConstructor(apiResponse) : null,
    );

    final modelDir = p.join(featurePath, config.getModelsDirectory());
    BaseGenerator.writeFile(
        p.join(modelDir, '${snakeName}_model.dart'), modelContent);

    // Only generate Service, Repo, UseCase for the root object
    if (isRoot) {
      // 3. Service
      final serviceContent = ApiTemplates.serviceContent(
        className: pascalName,
        fileName: snakeName,
        packageName: packageName,
        url: url,
        returnType: isList ? 'List<$modelName>' : modelName,
        fromJsonCall: fromJsonCall,
        method: method,
      );
      final serviceDir = p.join(featurePath, config.getServicesDirectory());
      BaseGenerator.writeFile(
          p.join(serviceDir, '${snakeName}_service.dart'), serviceContent);

      // 4. Repository & Interface
      if (isClean) {
        final repoInterface = ApiTemplates.repositoryInterfaceContent(
          className: pascalName,
          fileName: snakeName,
          returnType: returnType,
          method: method,
        );
        BaseGenerator.writeFile(
            p.join(featurePath, 'domain/repositories',
                '${snakeName}_repository.dart'),
            repoInterface);
      }

      final repoContent = ApiTemplates.repositoryImplContent(
        className: pascalName,
        fileName: snakeName,
        returnType: returnType,
        isClean: isClean,
        method: method,
      );
      final repoDir =
          p.join(featurePath, isClean ? 'data/repositories' : 'repositories');
      BaseGenerator.writeFile(
          p.join(
              repoDir, '${snakeName}_repository${isClean ? "_impl" : ""}.dart'),
          repoContent);

      // 5. Use Case (Clean Arch only)
      if (isClean) {
        final useCaseContent = ApiTemplates.useCaseContent(
          className: pascalName,
          fileName: snakeName,
          returnType: returnType,
          packageName: packageName,
          snakeFeature: snakeFeature,
          method: method,
        );
        BaseGenerator.writeFile(
            p.join(featurePath, 'domain/usecases',
                'get_${snakeName}_usecase.dart'),
            useCaseContent);
      }

      // 6. Tests
      final testPath = p.join(baseDir, 'test', 'features', snakeFeature);
      final serviceTest = ApiTemplates.serviceTestContent(
        className: pascalName,
        fileName: snakeName,
        packageName: packageName,
        snakeFeature: snakeFeature,
        isClean: isClean,
      );
      BaseGenerator.writeFile(
          p.join(testPath, isClean ? 'data/services' : 'services',
              '${snakeName}_service_test.dart'),
          serviceTest);

      final repoTest = ApiTemplates.repositoryTestContent(
        className: pascalName,
        fileName: snakeName,
        packageName: packageName,
        snakeFeature: snakeFeature,
        isClean: isClean,
      );
      BaseGenerator.writeFile(
          p.join(testPath, isClean ? 'data/repositories' : 'repositories',
              '${snakeName}_repository_test.dart'),
          repoTest);
    }
  }

  Future<dynamic> _fetchApiResponse(String url,
      {String method = 'GET', String? body}) async {
    final uri = Uri.parse(url);

    if (uri.isScheme('file')) {
      final file = File(uri.toFilePath());
      if (!await file.exists()) {
        throw 'Local file not found: ${uri.toFilePath()}';
      }
      final content = await file.readAsString();
      return json.decode(content);
    }

    final client = HttpClient();
    String? token;

    try {
      while (true) {
        final request = await client.openUrl(method, uri);

        if (token != null) {
          request.headers.set('Authorization', 'Bearer $token');
        }

        if (body != null && body.isNotEmpty) {
          request.headers.contentType = ContentType.json;
          request.write(body);
        }

        final response = await request.close();

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final content = await response.transform(utf8.decoder).join();
          if (content.isEmpty) return {};
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

  String _inferFields(dynamic json, String parentName,
      {bool isEntity = false}) {
    if (json is List) {
      if (json.isEmpty) return '  final List<dynamic>? items;';
      return _inferFields(json.first, parentName, isEntity: isEntity);
    }
    if (json is! Map) return '  final dynamic value;';

    final buffer = StringBuffer();
    json.forEach((key, value) {
      final fieldName = StringUtils.toCamelCase(key.toString());
      final type = _getDartType(value, parentName, fieldName);
      buffer.writeln('  final $type? $fieldName;');
    });
    return buffer.toString();
  }

  String _getDartType(dynamic value, String parentName, String fieldName) {
    if (value == null) return 'dynamic';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    if (value is String) return 'String';
    if (value is List) {
      if (value.isEmpty) return 'List<dynamic>';
      final first = value.first;
      if (first is Map) {
        final subClassName = StringUtils.toPascalCase(fieldName);
        _addToQueue(subClassName, first);
        return 'List<${subClassName}Model>';
      }
      return 'List<${_getDartType(first, parentName, fieldName)}>';
    }
    if (value is Map) {
      final subClassName = StringUtils.toPascalCase(fieldName);
      _addToQueue(subClassName, value);
      return '${subClassName}Model';
    }
    return 'dynamic';
  }

  void _addToQueue(String pascalName, dynamic data) {
    if (_generationQueue.any((t) => t.pascalName == pascalName)) return;
    _generationQueue.add(_ApiModelTask(
      pascalName: pascalName,
      snakeName: StringUtils.toSnakeCase(pascalName),
      data: data,
    ));
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

class _ApiModelTask {

  _ApiModelTask({
    required this.pascalName,
    required this.snakeName,
    required this.data,
    this.isRoot = false,
  });
  final String pascalName;
  final String snakeName;
  final dynamic data;
  final bool isRoot;
}
