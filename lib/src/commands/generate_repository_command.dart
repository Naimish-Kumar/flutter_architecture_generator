import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import '../utils/file_helper.dart';
import '../utils/pubspec_helper.dart';
import '../utils/string_utils.dart';
import '../utils/validation_utils.dart';
import '../utils/template_loader.dart';
import '../models/generator_config.dart';
import '../generators/base_generator.dart';

/// The `repository` command — generates standalone repository files.
class GenerateRepositoryCommand extends Command<int> {
  /// Creates a [GenerateRepositoryCommand].
  GenerateRepositoryCommand({required Logger logger}) : _logger = logger {
    argParser.addOption('feature',
        abbr: 'f', help: 'Target feature for the repository');
    argParser.addFlag('with-datasource',
        abbr: 'd',
        negatable: false,
        help: 'Also generate a remote data source');
    argParser.addOption('output',
        abbr: 'o', help: 'Custom output directory (monorepo support)');
    argParser.addOption('config',
        abbr: 'c', help: 'Configuration profile name');
    argParser.addFlag('dry-run',
        abbr: 'n', negatable: false, help: 'Preview changes');
  }

  final Logger _logger;

  @override
  String get name => 'repository';

  @override
  String get description =>
      'Generate a standalone repository with interface and implementation.';

  @override
  Future<int> run() async {
    final repoName =
        argResults?.rest.isNotEmpty == true ? argResults!.rest.first : null;

    if (repoName == null) {
      _logger.err('Please provide a repository name.');
      return ExitCode.usage.code;
    }

    final validationError =
        ValidationUtils.validateName(repoName, 'Repository');
    if (validationError != null) {
      _logger.err(validationError);
      return ExitCode.usage.code;
    }

    final featureName = argResults?['feature'] as String?;
    final withDatasource = argResults?['with-datasource'] == true;
    final outputDir = argResults?['output'] as String?;
    final configName = argResults?['config'] as String?;
    final dryRun = argResults?['dry-run'] == true;

    final baseDir = outputDir ?? Directory.current.path;
    final config = FileHelper.loadConfig(baseDir: baseDir, name: configName);
    final packageName = PubspecHelper.getPackageName(baseDir: baseDir);

    BaseGenerator.beginTracking();

    final fileName = StringUtils.toSnakeCase(repoName);
    final className = StringUtils.toPascalCase(repoName);

    String repoDir;
    String? datasourceDir;

    if (featureName != null) {
      final snakeFeature = StringUtils.toSnakeCase(featureName);
      if (config?.architecture == Architecture.clean) {
        repoDir = p.join(
            baseDir, 'lib', 'features', snakeFeature, 'domain', 'repositories');
        datasourceDir = p.join(
            baseDir, 'lib', 'features', snakeFeature, 'data', 'datasources');
      } else {
        repoDir =
            p.join(baseDir, 'lib', 'features', snakeFeature, 'repositories');
        datasourceDir =
            p.join(baseDir, 'lib', 'features', snakeFeature, 'datasources');
      }
    } else {
      repoDir = p.join(baseDir, 'lib', 'core', 'repositories');
      datasourceDir = p.join(baseDir, 'lib', 'core', 'datasources');
    }

    final interfaceContent = TemplateLoader.load(
      'repository_interface',
      defaultContent: '''
abstract class I${className}Repository {
  Future<dynamic> get${className}Data();
  Future<void> save${className}Data(dynamic data);
  Future<void> delete${className}Data(String id);
}
''',
      replacements: {
        '{{className}}': className,
        '{{fileName}}': fileName,
        '{{packageName}}': packageName
      },
    );

    final implContent = TemplateLoader.load(
      'repository_impl',
      defaultContent: '''
import '${fileName}_repository.dart';

class ${className}RepositoryImpl implements I${className}Repository {
  ${className}RepositoryImpl();

  @override
  Future<dynamic> get${className}Data() async {
    throw UnimplementedError();
  }

  @override
  Future<void> save${className}Data(dynamic data) async {
    throw UnimplementedError();
  }

  @override
  Future<void> delete${className}Data(String id) async {
    throw UnimplementedError();
  }
}
''',
      replacements: {
        '{{className}}': className,
        '{{fileName}}': fileName,
        '{{packageName}}': packageName
      },
    );

    BaseGenerator.writeFile(
        p.join(repoDir, '${fileName}_repository.dart'), interfaceContent);
    BaseGenerator.writeFile(
        p.join(repoDir, '${fileName}_repository_impl.dart'), implContent);

    if (withDatasource) {
      final dsContent = TemplateLoader.load(
        'remote_datasource',
        defaultContent: '''
import 'package:$packageName/core/network/api_client.dart';

abstract class I${className}RemoteDataSource {
  Future<dynamic> get${className}FromApi();
}

class ${className}RemoteDataSourceImpl implements I${className}RemoteDataSource {
  final ApiClient apiClient;
  ${className}RemoteDataSourceImpl(this.apiClient);

  @override
  Future<dynamic> get${className}FromApi() async {
    final response = await apiClient.dio.get('/$fileName');
    return response.data;
  }
}
''',
        replacements: {
          '{{className}}': className,
          '{{fileName}}': fileName,
          '{{packageName}}': packageName
        },
      );
      BaseGenerator.writeFile(
          p.join(datasourceDir, '${fileName}_remote_datasource.dart'),
          dsContent);
    }

    final actions = BaseGenerator.endTracking();
    FileHelper.renderPlan(actions, _logger, baseDir: baseDir);

    if (dryRun) {
      _logger.info('✅ Dry run complete.');
      return ExitCode.success.code;
    }

    if (actions.isNotEmpty) {
      final confirm =
          _logger.confirm('Generate repository?', defaultValue: true);
      if (confirm) {
        FileHelper.applyPlan(actions, command: 'repository $repoName');
        _logger.success('Repository $className generated successfully! 🎉');
      }
    }

    return ExitCode.success.code;
  }
}
