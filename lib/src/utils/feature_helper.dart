// ignore_for_file: public_member_api_docs
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:mason_logger/mason_logger.dart';
import '../models/generator_config.dart';
import 'pubspec_helper.dart';
import 'string_utils.dart';

class FeatureHelper {
  static Future<void> generateFeature(
    String featureName, {
    required GeneratorConfig config,
    Logger? logger,
  }) async {
    final currentDir = Directory.current.path;
    final snakeFeatureName = StringUtils.toSnakeCase(featureName);
    final featurePath = p.join(currentDir, 'lib', 'features', snakeFeatureName);
    final packageName = PubspecHelper.getPackageName();

    final directories = _getDirectoriesForArchitecture(config);

    for (var dir in directories) {
      await Directory(p.join(featurePath, dir)).create(recursive: true);
    }

    switch (config.architecture) {
      case Architecture.clean:
        await _generateCleanFeature(
            featureName, config, packageName, featurePath);
        break;
      case Architecture.mvvm:
        await _generateMVVMFeature(
            featureName, config, packageName, featurePath);
        break;
      case Architecture.bloc:
        await _generateBlocFeature(
            featureName, config, packageName, featurePath);
        break;
      case Architecture.getx:
        await _generateGetXFeature(
            featureName, config, packageName, featurePath);
        break;
      case Architecture.provider:
        await _generateProviderFeature(
            featureName, config, packageName, featurePath);
        break;
    }
  }

  static List<String> _getDirectoriesForArchitecture(GeneratorConfig config) {
    switch (config.architecture) {
      case Architecture.clean:
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
      case Architecture.mvvm:
        return [
          'models',
          'views/pages',
          'views/widgets',
          'view_models',
          'services',
        ];
      case Architecture.bloc:
        return [
          'bloc',
          'models',
          'repositories',
          'pages',
          'widgets',
        ];
      case Architecture.getx:
        return [
          'controllers',
          'models',
          'views/pages',
          'views/widgets',
          'bindings',
        ];
      case Architecture.provider:
        return [
          'providers',
          'models',
          'pages',
          'widgets',
        ];
    }
  }

  static Future<void> _generateCleanFeature(String featureName,
      GeneratorConfig config, String packageName, String featurePath) async {
    final pascalName = StringUtils.toPascalCase(featureName);
    final snakeName = StringUtils.toSnakeCase(featureName);

    // 1. Entity
    _writeFile(
        p.join(featurePath, 'domain', 'entities', '${snakeName}_entity.dart'),
        '''
class ${pascalName}Entity {
  final int id;
  const ${pascalName}Entity({required this.id});
}
''');

    // 2. Repository Interface
    _writeFile(
        p.join(featurePath, 'domain', 'repositories',
            '${snakeName}_repository.dart'),
        '''
import 'package:$packageName/features/$snakeName/domain/entities/${snakeName}_entity.dart';

abstract class I${pascalName}Repository {
  Future<${pascalName}Entity> get${pascalName}Data();
}
''');

    // 3. Use Case
    _writeFile(
        p.join(
            featurePath, 'domain', 'usecases', 'get_${snakeName}_usecase.dart'),
        '''
import 'package:$packageName/features/$snakeName/domain/repositories/${snakeName}_repository.dart';
import 'package:$packageName/features/$snakeName/domain/entities/${snakeName}_entity.dart';

class Get${pascalName}UseCase {
  final I${pascalName}Repository repository;

  Get${pascalName}UseCase(this.repository);

  Future<${pascalName}Entity> call() async {
    return await repository.get${pascalName}Data();
  }
}
''');

    // 4. Model
    _writeFile(
        p.join(featurePath, 'data', 'models', '${snakeName}_model.dart'), '''
import 'package:$packageName/features/$snakeName/domain/entities/${snakeName}_entity.dart';

class ${pascalName}Model extends ${pascalName}Entity {
  const ${pascalName}Model({required super.id});

  factory ${pascalName}Model.fromJson(Map<String, dynamic> json) {
    return ${pascalName}Model(id: json['id'] as int);
  }

  Map<String, dynamic> toJson() => {'id': id};
}
''');

    // 5. Repository Implementation
    _writeFile(
        p.join(featurePath, 'data', 'repositories',
            '${snakeName}_repository_impl.dart'),
        '''
import 'package:$packageName/features/$snakeName/domain/repositories/${snakeName}_repository.dart';
import 'package:$packageName/features/$snakeName/domain/entities/${snakeName}_entity.dart';
import 'package:$packageName/features/$snakeName/data/datasources/${snakeName}_remote_datasource.dart';
import 'package:$packageName/core/errors/failures.dart';

class ${pascalName}RepositoryImpl implements I${pascalName}Repository {
  final I${pascalName}RemoteDataSource remoteDataSource;

  ${pascalName}RepositoryImpl(this.remoteDataSource);

  @override
  Future<${pascalName}Entity> get${pascalName}Data() async {
    try {
      return await remoteDataSource.get${pascalName}FromApi();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
''');

    // 6. Data Source
    _writeFile(
        p.join(featurePath, 'data', 'datasources',
            '${snakeName}_remote_datasource.dart'),
        '''
import 'package:$packageName/features/$snakeName/data/models/${snakeName}_model.dart';
import 'package:$packageName/core/network/api_client.dart';

abstract class I${pascalName}RemoteDataSource {
  Future<${pascalName}Model> get${pascalName}FromApi();
}

class ${pascalName}RemoteDataSourceImpl implements I${pascalName}RemoteDataSource {
  final ApiClient apiClient;

  ${pascalName}RemoteDataSourceImpl(this.apiClient);

  @override
  Future<${pascalName}Model> get${pascalName}FromApi() async {
    final response = await apiClient.dio.get('/$snakeName');
    return ${pascalName}Model.fromJson(response.data);
  }
}
''');

    // 7. State Management
    _generateStateManagementContent(
        featurePath, featureName, config, packageName);

    // 8. Pages
    _generatePages(featurePath, featureName, config, packageName);

    // 9. DI Registration
    _registerInDI(featureName, config, packageName);

    // 10. Router Registration
    _registerInRouter(featureName, config, packageName);

    // 11. Feature Tests
    if (config.tests) {
      _generateFeatureTest(featureName, config, packageName);
    }
  }

  static Future<void> _generateMVVMFeature(String featureName,
      GeneratorConfig config, String packageName, String featurePath) async {
    final pascalName = StringUtils.toPascalCase(featureName);
    final snakeName = StringUtils.toSnakeCase(featureName);

    // 1. Model
    _writeFile(p.join(featurePath, 'models', '${snakeName}_model.dart'), '''
class ${pascalName}Model {
  final int id;
  const ${pascalName}Model({required this.id});

  factory ${pascalName}Model.fromJson(Map<String, dynamic> json) {
    return ${pascalName}Model(id: json['id'] as int);
  }

  Map<String, dynamic> toJson() => {'id': id};
}
''');

    // 2. Service
    _writeFile(p.join(featurePath, 'services', '${snakeName}_service.dart'), '''
import 'package:$packageName/core/network/api_client.dart';
import 'package:$packageName/features/$snakeName/models/${snakeName}_model.dart';

class ${pascalName}Service {
  final ApiClient apiClient;
  ${pascalName}Service(this.apiClient);

  Future<${pascalName}Model> fetch$pascalName() async {
    final response = await apiClient.dio.get('/$snakeName');
    return ${pascalName}Model.fromJson(response.data);
  }
}
''');

    // 3. ViewModel
    _writeFile(
        p.join(featurePath, 'view_models', '${snakeName}_view_model.dart'), '''
import 'package:flutter/material.dart';
import 'package:$packageName/features/$snakeName/services/${snakeName}_service.dart';
import 'package:$packageName/features/$snakeName/models/${snakeName}_model.dart';

class ${pascalName}ViewModel extends ChangeNotifier {
  final ${pascalName}Service service;
  ${pascalName}ViewModel(this.service);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ${pascalName}Model? _data;
  ${pascalName}Model? get data => _data;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _data = await service.fetch$pascalName();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
''');

    // 4. Pages
    _generatePages(featurePath, featureName, config, packageName);

    // 5. DI
    _registerInDI(featureName, config, packageName);

    // 6. Router
    _registerInRouter(featureName, config, packageName);

    // 7. Tests
    if (config.tests) {
      _generateFeatureTest(featureName, config, packageName);
    }
  }

  static Future<void> _generateBlocFeature(String featureName,
      GeneratorConfig config, String packageName, String featurePath) async {
    final pascalName = StringUtils.toPascalCase(featureName);
    final snakeName = StringUtils.toSnakeCase(featureName);

    // 1. Model
    _writeFile(p.join(featurePath, 'models', '${snakeName}_model.dart'), '''
class ${pascalName}Model {
  final int id;
  const ${pascalName}Model({required this.id});

  factory ${pascalName}Model.fromJson(Map<String, dynamic> json) {
    return ${pascalName}Model(id: json['id'] as int);
  }
}
''');

    // 2. Repository
    _writeFile(
        p.join(featurePath, 'repositories', '${snakeName}_repository.dart'), '''
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

    // 3. Bloc
    _generateStateManagementContent(
        featurePath, featureName, config, packageName);

    // 4. Pages
    _generatePages(featurePath, featureName, config, packageName);

    // 5. DI
    _registerInDI(featureName, config, packageName);

    // 6. Router
    _registerInRouter(featureName, config, packageName);

    // 7. Tests
    if (config.tests) {
      _generateFeatureTest(featureName, config, packageName);
    }
  }

  static Future<void> _generateGetXFeature(String featureName,
      GeneratorConfig config, String packageName, String featurePath) async {
    final pascalName = StringUtils.toPascalCase(featureName);
    final snakeName = StringUtils.toSnakeCase(featureName);

    // 1. Model
    _writeFile(p.join(featurePath, 'models', '${snakeName}_model.dart'), '''
class ${pascalName}Model {
  final int id;
  const ${pascalName}Model({required this.id});

  factory ${pascalName}Model.fromJson(Map<String, dynamic> json) {
    return ${pascalName}Model(id: json['id'] as int);
  }

  Map<String, dynamic> toJson() => {'id': id};
}
''');

    // 2. Controller
    _generateStateManagementContent(
        featurePath, featureName, config, packageName);

    // 3. Binding
    _writeFile(p.join(featurePath, 'bindings', '${snakeName}_binding.dart'), '''
import 'package:get/get.dart';
import 'package:$packageName/features/$snakeName/controllers/${snakeName}_controller.dart';

class ${pascalName}Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ${pascalName}Controller());
  }
}
''');

    // 4. Pages
    _generatePages(featurePath, featureName, config, packageName);

    // 5. DI
    _registerInDI(featureName, config, packageName);

    // 6. Router
    _registerInRouter(featureName, config, packageName);

    // 7. Tests
    if (config.tests) {
      _generateFeatureTest(featureName, config, packageName);
    }
  }

  static Future<void> _generateProviderFeature(String featureName,
      GeneratorConfig config, String packageName, String featurePath) async {
    final pascalName = StringUtils.toPascalCase(featureName);
    final snakeName = StringUtils.toSnakeCase(featureName);

    // 1. Model
    _writeFile(p.join(featurePath, 'models', '${snakeName}_model.dart'), '''
class ${pascalName}Model {
  final int id;
  const ${pascalName}Model({required this.id});
}
''');

    // 2. Provider
    _generateStateManagementContent(
        featurePath, featureName, config, packageName);

    // 3. Pages
    _generatePages(featurePath, featureName, config, packageName);

    // 4. DI
    _registerInDI(featureName, config, packageName);

    // 5. Router
    _registerInRouter(featureName, config, packageName);

    // 6. Tests
    if (config.tests) {
      _generateFeatureTest(featureName, config, packageName);
    }
  }

  static void _generatePages(String featurePath, String featureName,
      GeneratorConfig config, String packageName) {
    final pascalName = StringUtils.toPascalCase(featureName);
    final snakeName = StringUtils.toSnakeCase(featureName);
    final isAutoRoute = config.routing == Routing.autoRoute;
    final autoRouteImport =
        isAutoRoute ? "import 'package:auto_route/auto_route.dart';\n" : '';
    final routeAnnotation = isAutoRoute ? '@RoutePage()\n' : '';

    final pageDir = config.getPagesDirectory();
    final fullPagePath = p.join(featurePath, pageDir);

    if (featureName == 'auth') {
      _generateAuthPages(featurePath, config, packageName);
    } else {
      _writeFile(p.join(fullPagePath, '${snakeName}_page.dart'), '''
import 'package:flutter/material.dart';
$autoRouteImport
$routeAnnotation
class ${pascalName}Page extends StatelessWidget {
  const ${pascalName}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$pascalName')),
      body: const Center(child: Text('$pascalName Page')),
    );
  }
}
''');
    }
  }

  static void _generateFeatureTest(
      String name, GeneratorConfig config, String packageName) {
    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);
    final testPath = p.join('test', 'features', snakeName);

    if (config.architecture == Architecture.clean) {
      _writeFile(p.join(testPath, '${snakeName}_repository_test.dart'), '''
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
    } else if (config.architecture == Architecture.mvvm) {
      _writeFile(p.join(testPath, '${snakeName}_view_model_test.dart'), '''
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
    } else if (config.architecture == Architecture.bloc) {
      _writeFile(p.join(testPath, '${snakeName}_bloc_test.dart'), '''
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
    } else if (config.architecture == Architecture.getx) {
      _writeFile(p.join(testPath, '${snakeName}_controller_test.dart'), '''
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
    } else if (config.architecture == Architecture.provider) {
      _writeFile(p.join(testPath, '${snakeName}_provider_test.dart'), '''
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

  static void _writeFile(String path, String content) {
    final file = File(path);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    file.writeAsStringSync(content);
  }

  static void _registerInRouter(
      String name, GeneratorConfig config, String packageName) {
    if (config.routing == Routing.navigator) return;

    final routerFile = File(p.join('lib', 'routes', 'app_router.dart'));
    if (!routerFile.existsSync()) return;

    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);
    final pageDir = config.getPagesDirectory();
    final importPath = 'package:$packageName/features/$snakeName/$pageDir/';

    if (name == 'auth') {
      String contents = routerFile.readAsStringSync();
      if (config.routing == Routing.autoRoute) {
        final loginImport = "import '$importPath" "login_page.dart';";
        final registerImport = "import '$importPath" "register_page.dart';";
        if (!contents.contains(loginImport)) {
          contents = '$loginImport\n$contents';
        }
        if (!contents.contains(registerImport)) {
          contents = '$registerImport\n$contents';
        }

        final loginRoute =
            '      AutoRoute(page: LoginRoute.page, initial: true),\n';
        final registerRoute = '      AutoRoute(page: RegisterRoute.page),\n';

        if (!contents.contains('LoginRoute.page')) {
          contents = contents.replaceFirst('List<AutoRoute> get routes => [',
              'List<AutoRoute> get routes => [\n$loginRoute$registerRoute');
        }
      } else {
        final loginImport = "import '$importPath" "login_page.dart';";
        final registerImport = "import '$importPath" "register_page.dart';";
        if (!contents.contains(loginImport)) {
          contents = '$loginImport\n$contents';
        }
        if (!contents.contains(registerImport)) {
          contents = '$registerImport\n$contents';
        }

        final routes = '''
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
''';
        if (!contents.contains("path: '/login'")) {
          contents = contents.replaceFirst('routes: [', 'routes: [\n$routes');
        }
      }
      routerFile.writeAsStringSync(contents);
      return;
    }

    if (config.routing == Routing.autoRoute) {
      String contents = routerFile.readAsStringSync();
      final pageImport = "import '$importPath${snakeName}_page.dart';";
      if (!contents.contains(pageImport)) {
        contents = '$pageImport\n$contents';
      }
      final route = '      AutoRoute(page: ${pascalName}Route.page),\n';
      if (!contents.contains('${pascalName}Route.page')) {
        contents = contents.replaceFirst('List<AutoRoute> get routes => [',
            'List<AutoRoute> get routes => [\n$route');
      }
      routerFile.writeAsStringSync(contents);
    } else {
      String contents = routerFile.readAsStringSync();
      final pageImport = "import '$importPath${snakeName}_page.dart';";
      if (!contents.contains(pageImport)) {
        contents = '$pageImport\n$contents';
      }

      final route = '''
    GoRoute(
      path: '/$snakeName',
      builder: (context, state) => const ${pascalName}Page(),
    ),
''';
      if (!contents.contains("path: '/$snakeName'")) {
        contents = contents.replaceFirst('routes: [', 'routes: [\n$route');
      }
      routerFile.writeAsStringSync(contents);
    }
  }

  static void _generateStateManagementContent(
      String path, String name, GeneratorConfig config, String packageName) {
    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);
    final camelName = StringUtils.toCamelCase(name);

    String smPath;

    switch (config.architecture) {
      case Architecture.clean:
        smPath = p.join(path, 'presentation', config.stateManagement.name);
        break;
      case Architecture.mvvm:
        smPath = p.join(path, 'view_models');
        break;
      case Architecture.bloc:
        smPath = p.join(path, 'bloc');
        break;
      case Architecture.getx:
        smPath = p.join(path, 'controllers');
        break;
      case Architecture.provider:
        smPath = p.join(path, 'providers');
        break;
    }

    switch (config.stateManagement) {
      case StateManagement.bloc:
        String blocImport;
        String depType;
        String depField;
        String usageLine;
        if (config.architecture == Architecture.clean) {
          blocImport =
              "import 'package:$packageName/features/$snakeName/domain/usecases/get_${snakeName}_usecase.dart';";
          depType = 'Get${pascalName}UseCase';
          depField = 'get${pascalName}UseCase';
          usageLine =
              'final data = await $depField();\n        emit(${pascalName}Loaded(data: data.id.toString()));';
        } else {
          blocImport =
              "import 'package:$packageName/features/$snakeName/repositories/${snakeName}_repository.dart';";
          depType = '${pascalName}Repository';
          depField = 'repository';
          usageLine =
              'final data = await $depField.getData();\n        emit(${pascalName}Loaded(data: data.toString()));';
        }
        _writeFile(p.join(smPath, '${snakeName}_bloc.dart'), '''
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
$blocImport

part '${snakeName}_event.dart';
part '${snakeName}_state.dart';

class ${pascalName}Bloc extends Bloc<${pascalName}Event, ${pascalName}State> {
  final $depType $depField;
  ${pascalName}Bloc(this.$depField) : super(${pascalName}Initial()) {
    on<Get${pascalName}DataEvent>((event, emit) async {
      emit(${pascalName}Loading());
      try {
        $usageLine
      } catch (e) {
        emit(${pascalName}Error(message: e.toString()));
      }
    });
  }
}
''');
        _writeFile(p.join(smPath, '${snakeName}_event.dart'), '''
part of '${snakeName}_bloc.dart';

abstract class ${pascalName}Event extends Equatable {
  const ${pascalName}Event();

  @override
  List<Object> get props => [];
}

class Get${pascalName}DataEvent extends ${pascalName}Event {}
''');
        _writeFile(p.join(smPath, '${snakeName}_state.dart'), '''
part of '${snakeName}_bloc.dart';

abstract class ${pascalName}State extends Equatable {
  const ${pascalName}State();
  
  @override
  List<Object> get props => [];
}

class ${pascalName}Initial extends ${pascalName}State {}
class ${pascalName}Loading extends ${pascalName}State {}
class ${pascalName}Loaded extends ${pascalName}State {
  final String data;
  const ${pascalName}Loaded({required this.data});
}
class ${pascalName}Error extends ${pascalName}State {
  final String message;
  const ${pascalName}Error({required this.message});
}
''');
        break;
      case StateManagement.riverpod:
        _writeFile(p.join(smPath, '${snakeName}_provider.dart'), '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ${camelName}Provider = StateProvider<String>((ref) => 'Initial Data');
''');
        break;
      case StateManagement.provider:
        _writeFile(p.join(smPath, '${snakeName}_provider.dart'), '''
import 'package:flutter/material.dart';

class ${pascalName}Provider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();
    // Implementation
    _isLoading = false;
    notifyListeners();
  }
}
''');
        break;
      case StateManagement.getx:
        _writeFile(p.join(smPath, '${snakeName}_controller.dart'), '''
import 'package:get/get.dart';

class ${pascalName}Controller extends GetxController {
  final isLoading = false.obs;
  final data = Rxn<String>();
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchData() async {
    isLoading.value = true;
    _errorMessage = null;
    try {
      // Implementation — fetch from API
      data.value = 'Sample Data';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
''');
        break;
    }
  }

  static void _generateAuthPages(
      String path, GeneratorConfig config, String packageName) {
    final isAutoRoute = config.routing == Routing.autoRoute;
    final autoRouteImport =
        isAutoRoute ? "import 'package:auto_route/auto_route.dart';\n" : '';
    final routeAnnotation = isAutoRoute ? '@RoutePage()\n' : '';

    final pageDir = config.getPagesDirectory();

    _writeFile(p.join(path, pageDir, 'login_page.dart'), '''
import 'package:flutter/material.dart';
$autoRouteImport
$routeAnnotation
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome Back',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Login to continue your journey',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 48),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Login', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {},
                child: const Text('Don\\'t have an account? Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
''');

    _writeFile(p.join(path, pageDir, 'register_page.dart'), '''
import 'package:flutter/material.dart';
$autoRouteImport
$routeAnnotation
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: const Center(child: Text('Register Page')),
    );
  }
}
''');
  }

  static void _registerInDI(
      String name, GeneratorConfig config, String packageName) {
    final diFile = File(p.join('lib', 'di', 'injection_container.dart'));
    if (!diFile.existsSync()) return;

    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);

    String contents = diFile.readAsStringSync();

    final imports = <String>[];
    String registration = '';

    switch (config.architecture) {
      case Architecture.clean:
        imports.addAll([
          "import 'package:$packageName/features/$snakeName/domain/repositories/${snakeName}_repository.dart';",
          "import 'package:$packageName/features/$snakeName/domain/usecases/get_${snakeName}_usecase.dart';",
          "import 'package:$packageName/features/$snakeName/data/datasources/${snakeName}_remote_datasource.dart';",
          "import 'package:$packageName/features/$snakeName/data/repositories/${snakeName}_repository_impl.dart';",
        ]);
        registration = '''
  // $pascalName Feature
  sl.registerLazySingleton<I${pascalName}RemoteDataSource>(() => ${pascalName}RemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<I${pascalName}Repository>(() => ${pascalName}RepositoryImpl(sl()));
  sl.registerLazySingleton(() => Get${pascalName}UseCase(sl()));
''';
        break;
      case Architecture.mvvm:
        imports.addAll([
          "import 'package:$packageName/features/$snakeName/services/${snakeName}_service.dart';",
          "import 'package:$packageName/features/$snakeName/view_models/${snakeName}_view_model.dart';",
        ]);
        registration = '''
  // $pascalName Feature (MVVM)
  sl.registerLazySingleton(() => ${pascalName}Service(sl()));
  sl.registerFactory(() => ${pascalName}ViewModel(sl()));
''';
        break;
      case Architecture.bloc:
        imports.addAll([
          "import 'package:$packageName/features/$snakeName/repositories/${snakeName}_repository.dart';",
          "import 'package:$packageName/features/$snakeName/bloc/${snakeName}_bloc.dart';",
        ]);
        registration = '''
  // $pascalName Feature (BLoC)
  sl.registerLazySingleton(() => ${pascalName}Repository(sl()));
  sl.registerFactory(() => ${pascalName}Bloc(sl()));
''';
        break;
      case Architecture.getx:
        imports.addAll([
          "import 'package:$packageName/features/$snakeName/controllers/${snakeName}_controller.dart';",
        ]);
        registration = '''
  // $pascalName Feature (GetX)
  sl.registerFactory(() => ${pascalName}Controller());
''';
        break;
      case Architecture.provider:
        imports.addAll([
          "import 'package:$packageName/features/$snakeName/providers/${snakeName}_provider.dart';",
        ]);
        registration = '''
  // $pascalName Feature (Provider)
  sl.registerFactory(() => ${pascalName}Provider());
''';
        break;
    }

    for (var imp in imports) {
      if (!contents.contains(imp)) {
        contents = '$imp\n$contents';
      }
    }

    if (!contents.contains('// $pascalName Feature')) {
      contents =
          contents.replaceFirst('// Features', '// Features\n$registration');
    }

    diFile.writeAsStringSync(contents);
  }
}
