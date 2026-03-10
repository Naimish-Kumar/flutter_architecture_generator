/// DI (Dependency Injection) registration logic.
///
/// Handles auto-wiring of feature dependencies into `injection_container.dart`.
library;

import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/generator_config.dart';
import '../utils/string_utils.dart';
import 'base_generator.dart';

/// Registers feature dependencies in the GetIt DI container.
class DIRegistrar {
  /// Registers the given feature's dependencies in `injection_container.dart`.
  static void register(String name, GeneratorConfig config, String packageName,
      {String? baseDir}) {
    final root = baseDir ?? Directory.current.path;
    final diPath = p.join(root, 'lib', 'di', 'injection_container.dart');
    final diFile = File(diPath);
    if (!diFile.existsSync()) return;

    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);

    String contents = diFile.readAsStringSync();

    final imports = <String>[];
    String registration = '';

    // Special handling for the premium Chat feature
    if (snakeName == 'chat') {
      final servicesDir = config.getServicesDirectory();
      final stateDir = config.getStateManagementDirectory();
      imports.addAll([
        "import 'package:$packageName/features/chat/$servicesDir/socket_service.dart';",
        "import 'package:$packageName/features/chat/$servicesDir/chat_service.dart';",
        if (config.architecture == Architecture.clean) ...[
          "import 'package:$packageName/features/chat/domain/repositories/chat_repository.dart';",
          "import 'package:$packageName/features/chat/data/repositories/chat_repository_impl.dart';",
          "import 'package:$packageName/features/chat/domain/usecases/get_messages_usecase.dart';",
        ],
        if (config.stateManagement == StateManagement.bloc ||
            config.stateManagement == StateManagement.cubit)
          "import 'package:$packageName/features/chat/$stateDir/chat_bloc.dart';",
        if (config.stateManagement == StateManagement.provider)
          "import 'package:$packageName/features/chat/$stateDir/chat_provider.dart';",
        if (config.stateManagement == StateManagement.getx)
          "import 'package:$packageName/features/chat/$stateDir/chat_controller.dart';",
      ]);

      registration = '''
  // Chat Feature
  sl.registerLazySingleton(() => SocketService()..init());
  sl.registerLazySingleton(() => ChatService(sl()));
''';

      if (config.architecture == Architecture.clean) {
        registration += '''
  sl.registerLazySingleton<IChatRepository>(() => ChatRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetMessagesUseCase(sl()));
''';
      }

      if (config.stateManagement == StateManagement.bloc ||
          config.stateManagement == StateManagement.cubit) {
        registration +=
            '  sl.registerFactory(() => ChatBloc(chatService: sl(), socketService: sl()));\n';
      } else if (config.stateManagement == StateManagement.provider) {
        registration +=
            '  sl.registerFactory(() => ChatProvider(chatService: sl(), socketService: sl()));\n';
      } else if (config.stateManagement == StateManagement.getx) {
        registration +=
            '  sl.registerFactory(() => ChatController(chatService: sl(), socketService: sl(), roomId: ""));\n';
      }
    } else {
      // Standard feature registration logic
      // 1. Architecture-specific (Backend Layers)
      switch (config.architecture) {
        case Architecture.clean:
          imports.addAll([
            "import 'package:{{packageName}}/features/{{fileName}}/domain/repositories/{{fileName}}_repository.dart';",
            "import 'package:{{packageName}}/features/{{fileName}}/domain/usecases/get_{{fileName}}_usecase.dart';",
            "import 'package:{{packageName}}/features/{{fileName}}/data/datasources/{{fileName}}_remote_datasource.dart';",
            "import 'package:{{packageName}}/features/{{fileName}}/data/repositories/{{fileName}}_repository_impl.dart';",
          ]);
          registration += '''
  // {{className}} Feature (Clean)
  sl.registerLazySingleton<I{{className}}RemoteDataSource>(() => {{className}}RemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<I{{className}}Repository>(() => {{className}}RepositoryImpl(sl()));
  sl.registerLazySingleton(() => Get{{className}}UseCase(sl()));
''';
          break;
        case Architecture.mvvm:
          imports.addAll([
            "import 'package:{{packageName}}/features/{{fileName}}/services/{{fileName}}_service.dart';",
          ]);
          registration += '''
  // {{className}} Feature (MVVM)
  sl.registerLazySingleton(() => {{className}}Service(sl()));
''';
          break;
        case Architecture.bloc:
          imports.addAll([
            "import 'package:{{packageName}}/features/{{fileName}}/repositories/{{fileName}}_repository.dart';",
          ]);
          registration += '''
  // {{className}} Feature (BLoC Architecture)
  sl.registerLazySingleton(() => {{className}}Repository(sl()));
''';
          break;
        case Architecture.getx:
          // GetX architecture standard structure
          break;
        case Architecture.provider:
          // Provider architecture standard structure
          break;
      }

      // 2. State Management Specific (Frontend Logic)
      final stateDir = config.getStateManagementDirectory();
      switch (config.stateManagement) {
        case StateManagement.bloc:
        case StateManagement.cubit:
          final smName =
              config.stateManagement == StateManagement.bloc ? 'Bloc' : 'Cubit';
          imports.add(
              "import 'package:{{packageName}}/features/{{fileName}}/$stateDir/{{fileName}}_${smName.toLowerCase()}.dart';");
          registration +=
              '  sl.registerFactory(() => {{className}}$smName(sl()));\n';
          break;
        case StateManagement.provider:
          imports.add(
              "import 'package:{{packageName}}/features/{{fileName}}/providers/{{fileName}}_provider.dart';");
          registration +=
              '  sl.registerFactory(() => {{className}}Provider());\n';
          break;
        case StateManagement.getx:
          imports.add(
              "import 'package:{{packageName}}/features/{{fileName}}/controllers/{{fileName}}_controller.dart';");
          registration +=
              '  sl.registerFactory(() => {{className}}Controller());\n';
          break;
        case StateManagement.riverpod:
          // Riverpod doesn't usually use GetIt
          break;
      }

      // If MVVM architecture, we also need the ViewModel if not already covered
      if (config.architecture == Architecture.mvvm &&
          config.stateManagement != StateManagement.getx &&
          config.stateManagement != StateManagement.bloc &&
          config.stateManagement != StateManagement.cubit) {
        if (!imports.contains(
            "import 'package:{{packageName}}/features/{{fileName}}/view_models/{{fileName}}_view_model.dart';")) {
          imports.add(
              "import 'package:{{packageName}}/features/{{fileName}}/view_models/{{fileName}}_view_model.dart';");
          registration +=
              '  sl.registerFactory(() => {{className}}ViewModel(sl()));\n';
        }
      }
    }

    // Replace placeholders
    for (var i = 0; i < imports.length; i++) {
      imports[i] = imports[i]
          .replaceAll('{{packageName}}', packageName)
          .replaceAll('{{fileName}}', snakeName);
    }
    registration = registration
        .replaceAll('{{className}}', pascalName)
        .replaceAll('{{fileName}}', snakeName);

    for (var imp in imports) {
      if (!contents.contains(imp)) {
        contents = '$imp\n$contents';
      }
    }

    if (!contents.contains('// $pascalName Feature')) {
      contents =
          contents.replaceFirst('// Features', '// Features\n$registration');
    }

    BaseGenerator.writeFile(diPath, contents);
  }

  /// Registers an API integration's dependencies in `injection_container.dart`.
  static void registerApi(
    String apiName,
    String featureName,
    GeneratorConfig config,
    String packageName, {
    String? baseDir,
  }) {
    final root = baseDir ?? Directory.current.path;
    final diPath = p.join(root, 'lib', 'di', 'injection_container.dart');
    final diFile = File(diPath);
    if (!diFile.existsSync()) return;

    final pascalName = StringUtils.toPascalCase(apiName);
    final snakeName = StringUtils.toSnakeCase(apiName);
    final snakeFeature = StringUtils.toSnakeCase(featureName);

    String contents = diFile.readAsStringSync();

    final imports = <String>[
      "import 'package:$packageName/features/$snakeFeature/services/${snakeName}_service.dart';",
      if (config.architecture == Architecture.clean) ...[
        "import 'package:$packageName/features/$snakeFeature/domain/repositories/${snakeName}_repository.dart';",
        "import 'package:$packageName/features/$snakeFeature/data/repositories/${snakeName}_repository_impl.dart';",
        "import 'package:$packageName/features/$snakeFeature/domain/usecases/get_${snakeName}_usecase.dart';",
      ] else ...[
        "import 'package:$packageName/features/$snakeFeature/repositories/${snakeName}_repository.dart';",
      ],
    ];

    String registration = '\n  // $pascalName API Integration\n';
    registration +=
        '  sl.registerLazySingleton(() => ${pascalName}Service(sl()));\n';

    if (config.architecture == Architecture.clean) {
      registration +=
          '  sl.registerLazySingleton<I${pascalName}Repository>(() => ${pascalName}RepositoryImpl(sl()));\n';
      registration +=
          '  sl.registerLazySingleton(() => Get${pascalName}UseCase(sl()));\n';
    } else {
      registration +=
          '  sl.registerLazySingleton(() => ${pascalName}Repository(sl()));\n';
    }

    // Add imports
    for (var imp in imports) {
      if (!contents.contains(imp)) {
        contents = '$imp\n$contents';
      }
    }

    // Add registration
    if (!contents.contains('// $pascalName API Integration')) {
      contents =
          contents.replaceFirst('// Features', '// Features\n$registration');
    }

    BaseGenerator.writeFile(diPath, contents);
  }
}
