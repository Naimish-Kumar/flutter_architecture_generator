/// GetX Architecture feature generator.
///
/// Generates a feature following the GetX Architecture pattern
/// with Models, Controllers, Bindings, and Views.
library;

import '../models/generator_config.dart';
import '../utils/string_utils.dart';
import '../utils/template_loader.dart';
import 'base_generator.dart';

/// Generates features following GetX Architecture.
class GetxGenerator extends BaseGenerator {
  /// Creates a [GetxGenerator].
  const GetxGenerator();

  @override
  List<String> getDirectories(GeneratorConfig config) {
    return [
      'controllers',
      'models',
      'views/pages',
      'views/widgets',
      'bindings',
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
      'getx_model',
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

    // 2. Binding
    final bindingContent = TemplateLoader.load(
      'getx_binding',
      defaultContent: '''
import 'package:get/get.dart';
import 'package:{{packageName}}/features/{{fileName}}/controllers/{{fileName}}_controller.dart';

class {{className}}Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => {{className}}Controller());
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
        '$featurePath/bindings/${snakeName}_binding.dart', bindingContent);
  }
}
