/// Provider Architecture feature generator.
///
/// Generates a feature following the Provider / Simple Architecture pattern
/// with Models, Providers, and Pages.
library;

import '../models/generator_config.dart';
import '../utils/template_loader.dart';
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
    final modelContent = TemplateLoader.load(
      'provider_model',
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
  }
}
