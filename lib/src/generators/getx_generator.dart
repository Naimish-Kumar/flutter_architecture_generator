/// GetX Architecture feature generator.
///
/// Generates a feature following the GetX Architecture pattern
/// with Models, Controllers, Bindings, and Views.
library;
import '../models/generator_config.dart';
import '../utils/string_utils.dart';
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

    // 2. Binding
    BaseGenerator.writeFile(
        '$featurePath/bindings/${snakeName}_binding.dart', '''
import 'package:get/get.dart';
import 'package:$packageName/features/$snakeName/controllers/${snakeName}_controller.dart';

class ${pascalName}Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ${pascalName}Controller());
  }
}
''');
  }
}
