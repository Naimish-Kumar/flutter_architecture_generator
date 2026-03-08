/// BLoC Architecture feature generator.
///
/// Generates a feature following the BLoC Architecture pattern
/// with Models, Repositories, Bloc, and Pages.
library;

import '../models/generator_config.dart';
import '../utils/string_utils.dart';
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
    BaseGenerator.writeFile('$featurePath/models/${snakeName}_model.dart', '''
class ${pascalName}Model {
  final int id;
  const ${pascalName}Model({required this.id});

  factory ${pascalName}Model.fromJson(Map<String, dynamic> json) {
    return ${pascalName}Model(id: json['id'] as int);
  }

  Map<String, dynamic> toJson() => {'id': id};
}
''');

    // 2. Repository
    BaseGenerator.writeFile(
        '$featurePath/repositories/${snakeName}_repository.dart', '''
import 'package:$packageName/core/network/api_client.dart';
import 'package:$packageName/features/$snakeName/models/${snakeName}_model.dart';

class ${pascalName}Repository {
  final ApiClient apiClient;
  ${pascalName}Repository(this.apiClient);

  Future<${pascalName}Model> getData() async {
    final response = await apiClient.dio.get('/$snakeName');
    return ${pascalName}Model.fromJson(response.data);
  }
}
''');
  }
}
