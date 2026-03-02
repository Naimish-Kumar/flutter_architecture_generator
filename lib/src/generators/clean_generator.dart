/// Clean Architecture feature generator.
///
/// Generates the full Clean Architecture feature structure with
/// domain, data, and presentation layers.
library;

import '../models/generator_config.dart';
import '../utils/string_utils.dart';
import '../utils/template_loader.dart';
import 'base_generator.dart';

/// Generates features following Clean Architecture principles.
class CleanGenerator extends BaseGenerator {
  /// Creates a [CleanGenerator].
  const CleanGenerator();

  @override
  List<String> getDirectories(GeneratorConfig config) {
    return [
      'data/models',
      'data/datasources',
      'data/repositories',
      'domain/entities',
      'domain/repositories',
      'domain/usecases',
      'presentation/pages',
      'presentation/widgets',
      'presentation/${config.stateManagement.name}',
    ];
  }

  @override
  Future<void> generateFiles(
    String featureName,
    GeneratorConfig config,
    String packageName,
    String featurePath,
  ) async {
    final pascalName = StringUtils.toPascalCase(featureName);
    final snakeName = StringUtils.toSnakeCase(featureName);

    final replacements = {
      '{{className}}': pascalName,
      '{{fileName}}': snakeName,
      '{{packageName}}': packageName,
    };

    // 1. Entity
    final entityContent = TemplateLoader.load(
      'entity',
      defaultContent: '''
class {{className}}Entity {
  final int id;
  const {{className}}Entity({required this.id});
}
''',
      replacements: replacements,
    );
    BaseGenerator.writeFile(
        '$featurePath/domain/entities/${snakeName}_entity.dart', entityContent);

    // 2. Repository Interface
    final repoInterfaceContent = TemplateLoader.load(
      'repository_interface',
      defaultContent: '''
import 'package:{{packageName}}/features/{{fileName}}/domain/entities/{{fileName}}_entity.dart';

abstract class I{{className}}Repository {
  Future<{{className}}Entity> get{{className}}Data();
}
''',
      replacements: replacements,
    );
    BaseGenerator.writeFile(
        '$featurePath/domain/repositories/${snakeName}_repository.dart',
        repoInterfaceContent);

    // 3. Use Case
    final useCaseContent = TemplateLoader.load(
      'usecase',
      defaultContent: '''
import 'package:{{packageName}}/features/{{fileName}}/domain/repositories/{{fileName}}_repository.dart';
import 'package:{{packageName}}/features/{{fileName}}/domain/entities/{{fileName}}_entity.dart';

class Get{{className}}UseCase {
  final I{{className}}Repository repository;

  Get{{className}}UseCase(this.repository);

  Future<{{className}}Entity> call() async {
    return await repository.get{{className}}Data();
  }
}
''',
      replacements: replacements,
    );
    BaseGenerator.writeFile(
        '$featurePath/domain/usecases/get_${snakeName}_usecase.dart',
        useCaseContent);

    // 4. Model
    final modelContent = TemplateLoader.load(
      'model',
      defaultContent: '''
import 'package:{{packageName}}/features/{{fileName}}/domain/entities/{{fileName}}_entity.dart';

class {{className}}Model extends {{className}}Entity {
  const {{className}}Model({required super.id});

  factory {{className}}Model.fromJson(Map<String, dynamic> json) {
    return {{className}}Model(id: json['id'] as int);
  }

  Map<String, dynamic> toJson() => {'id': id};
}
''',
      replacements: replacements,
    );
    BaseGenerator.writeFile(
        '$featurePath/data/models/${snakeName}_model.dart', modelContent);

    // 5. Repository Implementation
    final repoImplContent = TemplateLoader.load(
      'repository_impl',
      defaultContent: '''
import 'package:{{packageName}}/features/{{fileName}}/domain/repositories/{{fileName}}_repository.dart';
import 'package:{{packageName}}/features/{{fileName}}/domain/entities/{{fileName}}_entity.dart';
import 'package:{{packageName}}/features/{{fileName}}/data/datasources/{{fileName}}_remote_datasource.dart';
import 'package:{{packageName}}/core/errors/failures.dart';

class {{className}}RepositoryImpl implements I{{className}}Repository {
  final I{{className}}RemoteDataSource remoteDataSource;

  {{className}}RepositoryImpl(this.remoteDataSource);

  @override
  Future<{{className}}Entity> get{{className}}Data() async {
    try {
      return await remoteDataSource.get{{className}}FromApi();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
''',
      replacements: replacements,
    );
    BaseGenerator.writeFile(
        '$featurePath/data/repositories/${snakeName}_repository_impl.dart',
        repoImplContent);

    // 6. Data Source
    final dataSourceContent = TemplateLoader.load(
      'remote_datasource',
      defaultContent: '''
import 'package:{{packageName}}/features/{{fileName}}/data/models/{{fileName}}_model.dart';
import 'package:{{packageName}}/core/network/api_client.dart';

abstract class I{{className}}RemoteDataSource {
  Future<{{className}}Model> get{{className}}FromApi();
}

class {{className}}RemoteDataSourceImpl implements I{{className}}RemoteDataSource {
  final ApiClient apiClient;

  {{className}}RemoteDataSourceImpl(this.apiClient);

  @override
  Future<{{className}}Model> get{{className}}FromApi() async {
    final response = await apiClient.dio.get('/{{fileName}}');
    return {{className}}Model.fromJson(response.data);
  }
}
''',
      replacements: replacements,
    );
    BaseGenerator.writeFile(
        '$featurePath/data/datasources/${snakeName}_remote_datasource.dart',
        dataSourceContent);
  }
}
