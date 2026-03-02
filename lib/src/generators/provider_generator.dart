/// Provider Architecture feature generator.
///
/// Generates a feature following the Provider / Simple Architecture pattern
/// with Models, Providers, and Pages.
library;
import '../models/generator_config.dart';
import 'base_generator.dart';
import '../utils/string_utils.dart';

/// Generates features following Provider Architecture.
class ProviderGenerator extends BaseGenerator {
  /// Creates a [ProviderGenerator].
  const ProviderGenerator();

  @override
  List<String> getDirectories(GeneratorConfig config) {
    return [
      'providers',
      'models',
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
  }
}
