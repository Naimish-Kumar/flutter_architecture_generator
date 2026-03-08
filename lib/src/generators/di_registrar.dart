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
      }
    } else {
      // Standard feature registration logic...
      switch (config.architecture) {
        case Architecture.clean:
          imports.addAll([
            "import 'package:{{packageName}}/features/{{fileName}}/domain/repositories/{{fileName}}_repository.dart';",
            "import 'package:{{packageName}}/features/{{fileName}}/domain/usecases/get_{{fileName}}_usecase.dart';",
            "import 'package:{{packageName}}/features/{{fileName}}/data/datasources/{{fileName}}_remote_datasource.dart';",
            "import 'package:{{packageName}}/features/{{fileName}}/data/repositories/{{fileName}}_repository_impl.dart';",
          ]);
          registration = '''
  // {{className}} Feature
  sl.registerLazySingleton<I{{className}}RemoteDataSource>(() => {{className}}RemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<I{{className}}Repository>(() => {{className}}RepositoryImpl(sl()));
  sl.registerLazySingleton(() => Get{{className}}UseCase(sl()));
''';
          break;
        case Architecture.mvvm:
          imports.addAll([
            "import 'package:{{packageName}}/features/{{fileName}}/services/{{fileName}}_service.dart';",
            "import 'package:{{packageName}}/features/{{fileName}}/view_models/{{fileName}}_view_model.dart';",
          ]);
          registration = '''
  // {{className}} Feature (MVVM)
  sl.registerLazySingleton(() => {{className}}Service(sl()));
  sl.registerFactory(() => {{className}}ViewModel(sl()));
''';
          break;
        case Architecture.bloc:
          imports.addAll([
            "import 'package:{{packageName}}/features/{{fileName}}/repositories/{{fileName}}_repository.dart';",
            "import 'package:{{packageName}}/features/{{fileName}}/bloc/{{fileName}}_bloc.dart';",
          ]);
          registration = '''
  // {{className}} Feature (BLoC)
  sl.registerLazySingleton(() => {{className}}Repository(sl()));
  sl.registerFactory(() => {{className}}Bloc(sl()));
''';
          break;
        case Architecture.getx:
          imports.addAll([
            "import 'package:{{packageName}}/features/{{fileName}}/controllers/{{fileName}}_controller.dart';",
          ]);
          registration = '''
  // {{className}} Feature (GetX)
  sl.registerFactory(() => {{className}}Controller());
''';
          break;
        case Architecture.provider:
          imports.addAll([
            "import 'package:{{packageName}}/features/{{fileName}}/providers/{{fileName}}_provider.dart';",
          ]);
          registration = '''
  // {{className}} Feature (Provider)
  sl.registerFactory(() => {{className}}Provider());
''';
          break;
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
}
