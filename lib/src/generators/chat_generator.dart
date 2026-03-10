import 'dart:io';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import '../models/generator_config.dart';
import '../templates/chat_templates.dart';
import '../utils/pubspec_helper.dart';
import '../utils/string_utils.dart';
import 'base_generator.dart';
import 'di_registrar.dart';
import 'router_registrar.dart';
import 'theme_generator.dart';

/// A generator that scaffolds a complete real-time chat module.
class ChatGenerator {
  /// Generates the chat module with the specified [featureName] and [config].
  static Future<void> generate(
    String featureName, {
    required GeneratorConfig config,
    Logger? logger,
    bool force = false,
    String? outputDir,
  }) async {
    final baseDir = outputDir ?? Directory.current.path;
    final snakeFeatureName = StringUtils.toSnakeCase(featureName);
    final featurePath = p.join(baseDir, 'lib', 'features', snakeFeatureName);
    final packageName = PubspecHelper.getPackageName(baseDir: baseDir);

    // 1. Generate premium theme with ChatThemeExtension
    await ThemeGenerator.generate(baseDir: baseDir);

    // 2. Add Dependencies
    PubspecHelper.addCustomDependencies({
      'socket_io_client': '^3.1.1',
      'intl': '^0.19.0',
      'equatable': '^2.0.5',
    }, baseDir: baseDir);

    // 2. Create architecture-specific directories
    final modelsDir = config.getModelsDirectory();
    final servicesDir = config.getServicesDirectory();
    final pagesDir = config.getPagesDirectory();
    final widgetsDir = config.getWidgetsDirectory();
    final stateDir = config.getStateManagementDirectory();

    final dirs = [
      modelsDir,
      servicesDir,
      pagesDir,
      widgetsDir,
      stateDir,
      if (config.architecture == Architecture.clean) ...[
        'domain/entities',
        'domain/repositories',
        'domain/usecases',
        'data/repositories',
      ],
    ];

    for (final dir in dirs) {
      final path = p.join(featurePath, dir);
      Directory(path).createSync(recursive: true);
    }

    // 3. Generate Models
    BaseGenerator.writeFile(
      p.join(featurePath, modelsDir, 'chat_message.dart'),
      ChatTemplates.chatModelContent(packageName),
    );

    // 4. Generate Services (incl. Socket)
    BaseGenerator.writeFile(
      p.join(featurePath, servicesDir, 'socket_service.dart'),
      ChatTemplates.socketServiceContent(),
    );
    BaseGenerator.writeFile(
      p.join(featurePath, servicesDir, 'chat_service.dart'),
      ChatTemplates.chatServiceContent(packageName),
    );

    // 5. Generate Pages
    BaseGenerator.writeFile(
      p.join(featurePath, pagesDir, 'chat_page.dart'),
      ChatTemplates.chatPageContent(config, packageName),
    );
    BaseGenerator.writeFile(
      p.join(featurePath, pagesDir, 'chat_rooms_page.dart'),
      ChatTemplates.chatRoomPageContent(packageName, modelsDir: modelsDir),
    );

    // 6. Generate State Management
    _generateStateManagement(featurePath, featureName, config, packageName,
        stateDir, modelsDir, servicesDir);

    // 7. Clean Architecture Specifics
    if (config.architecture == Architecture.clean) {
      _generateCleanSpecificFiles(featurePath, packageName);
    }

    // 8. DI & Routes
    DIRegistrar.register(featureName, config, packageName, baseDir: baseDir);
    RouterRegistrar.register(featureName, config, packageName,
        baseDir: baseDir);
  }

  static void _generateStateManagement(
      String featurePath,
      String featureName,
      GeneratorConfig config,
      String packageName,
      String stateDir,
      String modelsDir,
      String servicesDir) {
    final pascalName = StringUtils.toPascalCase(featureName);
    final snakeName = StringUtils.toSnakeCase(featureName);

    if (config.stateManagement == StateManagement.bloc ||
        config.stateManagement == StateManagement.cubit) {
      BaseGenerator.writeFile(
        p.join(featurePath, stateDir, 'chat_bloc.dart'),
        ChatTemplates.chatBlocContent(packageName, snakeName, pascalName,
            modelsDir: modelsDir, servicesDir: servicesDir),
      );
      BaseGenerator.writeFile(
        p.join(featurePath, stateDir, 'chat_event.dart'),
        ChatTemplates.chatEventContent(pascalName),
      );
      BaseGenerator.writeFile(
        p.join(featurePath, stateDir, 'chat_state.dart'),
        ChatTemplates.chatStateContent(pascalName),
      );
    } else if (config.stateManagement == StateManagement.provider) {
      BaseGenerator.writeFile(
        p.join(featurePath, stateDir, 'chat_provider.dart'),
        ChatTemplates.chatViewModelProviderContent(packageName,
            modelsDir: modelsDir, servicesDir: servicesDir),
      );
    } else if (config.stateManagement == StateManagement.riverpod) {
      BaseGenerator.writeFile(
        p.join(featurePath, stateDir, 'chat_provider.dart'),
        ChatTemplates.chatRiverpodProviderContent(packageName,
            modelsDir: modelsDir, servicesDir: servicesDir),
      );
    } else if (config.stateManagement == StateManagement.getx) {
      BaseGenerator.writeFile(
        p.join(featurePath, stateDir, 'chat_controller.dart'),
        ChatTemplates.chatGetXControllerContent(packageName,
            modelsDir: modelsDir, servicesDir: servicesDir),
      );
    }
  }

  static void _generateCleanSpecificFiles(
      String featurePath, String packageName) {
    // Entities
    BaseGenerator.writeFile(
      p.join(featurePath, 'domain/entities/chat_message_entity.dart'),
      ChatTemplates.chatEntityContent(),
    );

    // Repositories Interface
    BaseGenerator.writeFile(
      p.join(featurePath, 'domain/repositories/chat_repository.dart'),
      ChatTemplates.chatRepoInterfaceContent(packageName),
    );

    // Repository Implementation
    BaseGenerator.writeFile(
      p.join(featurePath, 'data/repositories/chat_repository_impl.dart'),
      ChatTemplates.chatRepoImplContent(packageName),
    );

    // Use Cases
    BaseGenerator.writeFile(
      p.join(featurePath, 'domain/usecases/get_messages_usecase.dart'),
      ChatTemplates.chatUseCaseContent(packageName, 'GetMessages'),
    );
  }
}
