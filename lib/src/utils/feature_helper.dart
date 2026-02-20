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

    final directories = [
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

    for (var dir in directories) {
      await Directory(p.join(featurePath, dir)).create(recursive: true);
    }

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
      // Best practice: Map exceptions to Failures
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
    final isAutoRoute = config.routing == Routing.autoRoute;
    final autoRouteImport =
        isAutoRoute ? "import 'package:auto_route/auto_route.dart';\n" : "";
    final routeAnnotation = isAutoRoute ? "@RoutePage()\n" : "";

    if (featureName == 'auth') {
      _generateAuthPages(featurePath, config, packageName);
    } else {
      _writeFile(
          p.join(
              featurePath, 'presentation', 'pages', '${snakeName}_page.dart'),
          '''
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

    // 9. DI Registration
    _registerInDI(featureName, config, packageName);

    // 10. Router Registration
    _registerInRouter(featureName, config, packageName);

    // 11. Feature Tests
    if (config.tests) {
      _generateFeatureTest(featureName, config, packageName);
    }
  }

  static void _generateFeatureTest(
      String name, GeneratorConfig config, String packageName) {
    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);
    final testPath = p.join('test', 'features', snakeName);

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

    if (config.routing == Routing.autoRoute) {
      _registerInAutoRoute(name, packageName);
      return;
    }

    final routerFile = File(p.join('lib', 'routes', 'app_router.dart'));
    if (!routerFile.existsSync()) return;

    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);
    final pageClass = "${pascalName}Page";
    final pagePath =
        "package:$packageName/features/$snakeName/presentation/pages/";
    final import = "import '$pagePath${snakeName}_page.dart';";

    if (name == 'auth') {
      // Auth has login and register
      final loginImport = "import '${pagePath}login_page.dart';";
      final registerImport = "import '${pagePath}register_page.dart';";
      String contents = routerFile.readAsStringSync();
      if (!contents.contains(loginImport)) {
        contents = "$loginImport\n$contents";
      }
      if (!contents.contains(registerImport)) {
        contents = "$registerImport\n$contents";
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
        contents = contents.replaceFirst("routes: [", "routes: [\n$routes");
      }
      routerFile.writeAsStringSync(contents);
    } else {
      String contents = routerFile.readAsStringSync();
      if (!contents.contains(import)) {
        contents = "$import\n$contents";
      }

      final route = '''
    GoRoute(
      path: '/$snakeName',
      builder: (context, state) => const $pageClass(),
    ),
''';
      if (!contents.contains("path: '/$snakeName'")) {
        contents = contents.replaceFirst("routes: [", "routes: [\n$route");
      }
      routerFile.writeAsStringSync(contents);
    }
  }

  static void _registerInAutoRoute(String name, String packageName) {
    final routerFile = File(p.join('lib', 'routes', 'app_router.dart'));
    if (!routerFile.existsSync()) return;

    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);

    if (name == 'auth') {
      // Auth has login and register pages
      final loginImport =
          "import 'package:$packageName/features/$snakeName/presentation/pages/login_page.dart';";
      final registerImport =
          "import 'package:$packageName/features/$snakeName/presentation/pages/register_page.dart';";
      String contents = routerFile.readAsStringSync();
      if (!contents.contains(loginImport)) {
        contents = "$loginImport\n$contents";
      }
      if (!contents.contains(registerImport)) {
        contents = "$registerImport\n$contents";
      }
      final routes = '''
      AutoRoute(page: LoginRoute.page),
      AutoRoute(page: RegisterRoute.page),
''';
      if (!contents.contains('LoginRoute.page')) {
        contents = contents.replaceFirst('List<AutoRoute> get routes => [',
            'List<AutoRoute> get routes => [\n$routes');
      }
      routerFile.writeAsStringSync(contents);
    } else {
      final pageImport =
          "import 'package:$packageName/features/$snakeName/presentation/pages/${snakeName}_page.dart';";
      String contents = routerFile.readAsStringSync();
      if (!contents.contains(pageImport)) {
        contents = "$pageImport\n$contents";
      }
      final route = '      AutoRoute(page: ${pascalName}Route.page),\n';
      if (!contents.contains('${pascalName}Route.page')) {
        contents = contents.replaceFirst('List<AutoRoute> get routes => [',
            'List<AutoRoute> get routes => [\n$route');
      }
      routerFile.writeAsStringSync(contents);
    }
  }

  static void _generateStateManagementContent(
      String path, String name, GeneratorConfig config, String packageName) {
    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);
    final camelName = StringUtils.toCamelCase(name);
    final smPath = p.join(path, 'presentation', config.stateManagement.name);

    switch (config.stateManagement) {
      case StateManagement.bloc:
        _writeFile(p.join(smPath, '${snakeName}_bloc.dart'), '''
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:$packageName/features/$snakeName/domain/usecases/get_${snakeName}_usecase.dart';

part '${snakeName}_event.dart';
part '${snakeName}_state.dart';

class ${pascalName}Bloc extends Bloc<${pascalName}Event, ${pascalName}State> {
  final Get${pascalName}UseCase get${pascalName}UseCase;

  ${pascalName}Bloc({required this.get${pascalName}UseCase}) : super(${pascalName}Initial()) {
    on<Get${pascalName}DataEvent>((event, emit) async {
      emit(${pascalName}Loading());
      try {
        final data = await get${pascalName}UseCase();
        emit(${pascalName}Loaded(data: data.id.toString()));
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
import 'package:$packageName/features/$snakeName/domain/usecases/get_${snakeName}_usecase.dart';
import 'package:$packageName/di/injection_container.dart';

final ${camelName}Provider = FutureProvider((ref) async {
  final usecase = sl<Get${pascalName}UseCase>();
  return await usecase();
});
''');
        break;
      case StateManagement.provider:
        _writeFile(p.join(smPath, '${snakeName}_provider.dart'), '''
import 'package:flutter/material.dart';
import 'package:$packageName/features/$snakeName/domain/usecases/get_${snakeName}_usecase.dart';

class ${pascalName}Provider extends ChangeNotifier {
  final Get${pascalName}UseCase get${pascalName}UseCase;

  ${pascalName}Provider({required this.get${pascalName}UseCase});

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
import 'package:$packageName/features/$snakeName/domain/usecases/get_${snakeName}_usecase.dart';

class ${pascalName}Controller extends GetxController {
  final Get${pascalName}UseCase get${pascalName}UseCase;

  ${pascalName}Controller({required this.get${pascalName}UseCase});

  final isLoading = false.obs;
  
  Future<void> fetchData() async {
    isLoading.value = true;
    // Implementation
    isLoading.value = false;
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
        isAutoRoute ? "import 'package:auto_route/auto_route.dart';\n" : "";
    final routeAnnotation = isAutoRoute ? "@RoutePage()\n" : "";

    _writeFile(p.join(path, 'presentation', 'pages', 'login_page.dart'), '''
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

    _writeFile(p.join(path, 'presentation', 'pages', 'register_page.dart'), '''
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

    // Add imports
    final imports = [
      "import 'package:$packageName/features/$snakeName/domain/repositories/${snakeName}_repository.dart';",
      "import 'package:$packageName/features/$snakeName/domain/usecases/get_${snakeName}_usecase.dart';",
      "import 'package:$packageName/features/$snakeName/data/datasources/${snakeName}_remote_datasource.dart';",
      "import 'package:$packageName/features/$snakeName/data/repositories/${snakeName}_repository_impl.dart';",
    ];

    switch (config.stateManagement) {
      case StateManagement.bloc:
        imports.add(
            "import 'package:$packageName/features/$snakeName/presentation/bloc/${snakeName}_bloc.dart';");
        break;
      case StateManagement.provider:
        imports.add(
            "import 'package:$packageName/features/$snakeName/presentation/provider/${snakeName}_provider.dart';");
        break;
      case StateManagement.getx:
        imports.add(
            "import 'package:$packageName/features/$snakeName/presentation/getx/${snakeName}_controller.dart';");
        break;
      default:
        break;
    }

    for (var imp in imports) {
      if (!contents.contains(imp)) {
        contents = "$imp\n$contents";
      }
    }

    // Add registrations
    final registrations = '''
  // $pascalName Feature
  sl.registerLazySingleton<I${pascalName}RemoteDataSource>(() => ${pascalName}RemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<I${pascalName}Repository>(() => ${pascalName}RepositoryImpl(sl()));
  sl.registerLazySingleton(() => Get${pascalName}UseCase(sl()));
''';

    String logicReg = "";
    switch (config.stateManagement) {
      case StateManagement.bloc:
        logicReg =
            "  sl.registerFactory(() => ${pascalName}Bloc(get${pascalName}UseCase: sl()));\n";
        break;
      case StateManagement.provider:
        logicReg =
            "  sl.registerFactory(() => ${pascalName}Provider(get${pascalName}UseCase: sl()));\n";
        break;
      case StateManagement.getx:
        logicReg =
            "  sl.registerFactory(() => ${pascalName}Controller(get${pascalName}UseCase: sl()));\n";
        break;
      default:
        break;
    }

    final fullReg = registrations + logicReg;

    if (!contents.contains("// $pascalName Feature")) {
      contents = contents.replaceFirst("// Features", "// Features\n$fullReg");
    }

    diFile.writeAsStringSync(contents);
  }
}
