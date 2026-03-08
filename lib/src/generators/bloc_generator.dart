/// BLoC Architecture feature generator.
///
/// Generates a feature following the BLoC Architecture pattern
/// with Models, Repositories, Bloc, and Pages.
library;

import '../models/generator_config.dart';
import '../utils/string_utils.dart';
import '../utils/template_loader.dart';
import 'base_generator.dart';

/// Generates features following BLoC Architecture.
class BlocGenerator extends BaseGenerator {
  /// Creates a [BlocGenerator].
  const BlocGenerator();

  @override
  List<String> getDirectories(GeneratorConfig config) {
    return [
      'bloc',
      'models',
      'repositories',
      'pages',
      'widgets',
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

    // 1. Model
    final modelContent = TemplateLoader.load(
      'bloc_model',
      defaultContent: '''
class {{className}}Model {
  final int id;
  const {{className}}Model({required this.id});

  factory {{className}}Model.fromJson(Map<String, dynamic> json) {
    return {{className}}Model(id: json['id'] as int);
  }

  Map<String, dynamic> toJson() => {'id': id};
}
''',
      replacements: {
        '{{className}}': pascalName,
        '{{fileName}}': snakeName,
      },
    );
    BaseGenerator.writeFile(
        '$featurePath/models/${snakeName}_model.dart', modelContent);

    // 2. Repository
    final repoContent = TemplateLoader.load(
      'bloc_repository',
      defaultContent: '''
import 'package:{{packageName}}/core/network/api_client.dart';
import 'package:{{packageName}}/features/{{fileName}}/models/{{fileName}}_model.dart';

class {{className}}Repository {
  final ApiClient apiClient;
  {{className}}Repository(this.apiClient) {}

  Future<{{className}}Model> getData() async {
    final response = await apiClient.dio.get('/{{fileName}}');
    return {{className}}Model.fromJson(response.data);
  }
}
''',
      replacements: {
        '{{className}}': pascalName,
        '{{fileName}}': snakeName,
        '{{packageName}}': packageName,
      },
    );
    BaseGenerator.writeFile(
        '$featurePath/repositories/${snakeName}_repository.dart', repoContent);
  }
}
