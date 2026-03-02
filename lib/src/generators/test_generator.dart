/// Test file generation logic.
///
/// Generates architecture-appropriate test files for each feature.
library;
import '../models/generator_config.dart';
import '../utils/string_utils.dart';
import 'base_generator.dart';

/// Generates test files for features based on the architecture.
class TestGenerator {
  /// Generates test files for the given feature.
  static void generate(
      String name, GeneratorConfig config, String packageName) {
    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);
    final testPath = 'test/features/$snakeName';

    switch (config.architecture) {
      case Architecture.clean:
        _generateCleanTest(testPath, snakeName, pascalName, packageName);
        break;
      case Architecture.mvvm:
        _generateMvvmTest(testPath, snakeName, pascalName, packageName);
        break;
      case Architecture.bloc:
        _generateBlocTest(testPath, snakeName, pascalName, packageName);
        break;
      case Architecture.getx:
        _generateGetxTest(testPath, snakeName, pascalName, packageName);
        break;
      case Architecture.provider:
        _generateProviderTest(testPath, snakeName, pascalName, packageName);
        break;
    }
  }

  static void _generateCleanTest(String testPath, String snakeName,
      String pascalName, String packageName) {
    BaseGenerator.writeFile('$testPath/${snakeName}_repository_test.dart', '''
import 'package:flutter_test/flutter_test.dart';
import 'package:$packageName/features/$snakeName/data/repositories/${snakeName}_repository_impl.dart';
import 'package:$packageName/features/$snakeName/data/datasources/${snakeName}_remote_datasource.dart';
import 'package:$packageName/features/$snakeName/data/models/${snakeName}_model.dart';

// Note: In a real project, use mocktail or mockito for mocking
class Mock${pascalName}RemoteDataSource implements I${pascalName}RemoteDataSource {
  @override
  Future<${pascalName}Model> get${pascalName}FromApi() async {
    return const ${pascalName}Model(id: 1);
  }
}

void main() {
  late ${pascalName}RepositoryImpl repository;
  late Mock${pascalName}RemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = Mock${pascalName}RemoteDataSource();
    repository = ${pascalName}RepositoryImpl(mockRemoteDataSource);
  });

  test('should return data from remote data source', () async {
    final result = await repository.get${pascalName}Data();
    expect(result.id, 1);
  });
}
''');
  }

  static void _generateMvvmTest(String testPath, String snakeName,
      String pascalName, String packageName) {
    BaseGenerator.writeFile('$testPath/${snakeName}_view_model_test.dart', '''
import 'package:flutter_test/flutter_test.dart';
import 'package:$packageName/features/$snakeName/view_models/${snakeName}_view_model.dart';
import 'package:$packageName/features/$snakeName/services/${snakeName}_service.dart';
import 'package:$packageName/features/$snakeName/models/${snakeName}_model.dart';

class Mock${pascalName}Service implements ${pascalName}Service {
  @override
  late final dynamic apiClient;
  @override
  Future<${pascalName}Model> fetch$pascalName() async {
    return const ${pascalName}Model(id: 1);
  }
}

void main() {
  late ${pascalName}ViewModel viewModel;
  late Mock${pascalName}Service mockService;

  setUp(() {
    mockService = Mock${pascalName}Service();
    viewModel = ${pascalName}ViewModel(mockService);
  });

  test('initial values are correct', () {
    expect(viewModel.isLoading, false);
    expect(viewModel.data, null);
  });
}
''');
  }

  static void _generateBlocTest(String testPath, String snakeName,
      String pascalName, String packageName) {
    BaseGenerator.writeFile('$testPath/${snakeName}_bloc_test.dart', '''
import 'package:flutter_test/flutter_test.dart';
import 'package:$packageName/features/$snakeName/bloc/${snakeName}_bloc.dart';
import 'package:$packageName/features/$snakeName/repositories/${snakeName}_repository.dart';

class Mock${pascalName}Repository implements ${pascalName}Repository {
  @override
  late final dynamic apiClient;
  @override
  Future<dynamic> getData() async {
    return null;
  }
}

void main() {
  test('Initial state should be ${pascalName}Initial', () {
    final mockRepo = Mock${pascalName}Repository();
    expect(${pascalName}Bloc(mockRepo).state, ${pascalName}Initial());
  });
}
''');
  }

  static void _generateGetxTest(String testPath, String snakeName,
      String pascalName, String packageName) {
    BaseGenerator.writeFile('$testPath/${snakeName}_controller_test.dart', '''
import 'package:flutter_test/flutter_test.dart';
import 'package:$packageName/features/$snakeName/controllers/${snakeName}_controller.dart';

void main() {
  late ${pascalName}Controller controller;

  setUp(() {
    controller = ${pascalName}Controller();
  });

  test('initial loading state should be false', () {
    expect(controller.isLoading.value, false);
  });

  test('data should be initially null', () {
    expect(controller.data.value, null);
  });
}
''');
  }

  static void _generateProviderTest(String testPath, String snakeName,
      String pascalName, String packageName) {
    BaseGenerator.writeFile('$testPath/${snakeName}_provider_test.dart', '''
import 'package:flutter_test/flutter_test.dart';
import 'package:$packageName/features/$snakeName/providers/${snakeName}_provider.dart';

void main() {
  late ${pascalName}Provider provider;

  setUp(() {
    provider = ${pascalName}Provider();
  });

  test('initial loading state should be false', () {
    expect(provider.isLoading, false);
  });
}
''');
  }
}
