/// Router registration logic.
///
/// Handles auto-registration of feature pages into the app router
/// for GoRouter, AutoRoute, and Navigator routing strategies.
library;

import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/generator_config.dart';
import '../utils/string_utils.dart';
import 'base_generator.dart';

/// Registers feature routes in the router configuration file.
class RouterRegistrar {
  /// Registers the given feature's pages in `app_router.dart`.
  static void register(String name, GeneratorConfig config, String packageName,
      {String? baseDir}) {
    final root = baseDir ?? Directory.current.path;
    final routerPath = p.join(root, 'lib', 'routes', 'app_router.dart');

    if (config.routing == Routing.navigator) {
      _registerInNavigator(name, config, packageName, baseDir: root);
      return;
    }

    final routerFile = File(routerPath);
    if (!routerFile.existsSync()) return;

    final snakeName = StringUtils.toSnakeCase(name);
    final pageDir = config.getPagesDirectory();
    final importPath = 'package:$packageName/features/$snakeName/$pageDir/';

    if (name == 'auth') {
      _registerAuthRoutes(routerPath, config, importPath);
    } else if (name == 'chat') {
      _registerChatRoutes(routerPath, config, importPath, packageName);
    } else {
      if (config.routing == Routing.autoRoute) {
        _registerAutoRoute(routerPath, name, importPath);
      } else {
        _registerGoRoute(routerPath, name, importPath);
      }
    }
  }

  static void _registerChatRoutes(String routerPath, GeneratorConfig config,
      String importPath, String packageName) {
    final routerFile = File(routerPath);
    String contents = routerFile.readAsStringSync();

    final modelsDir = config.getModelsDirectory();
    final roomsImport = "import '${importPath}chat_rooms_page.dart';";
    final chatImport = "import '${importPath}chat_page.dart';";
    final modelImport =
        "import 'package:$packageName/features/chat/$modelsDir/chat_message.dart';";

    if (!contents.contains(roomsImport)) contents = '$roomsImport\n$contents';
    if (!contents.contains(chatImport)) contents = '$chatImport\n$contents';
    if (!contents.contains(modelImport)) contents = '$modelImport\n$contents';

    if (config.routing == Routing.goRouter) {
      const chatRoutes = '''
    GoRoute(
      path: '/chat-rooms',
      builder: (context, state) => const ChatRoomsPage(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) {
        final room = state.extra as ChatRoom;
        return ChatPage(room: room);
      },
    ),
''';
      if (!contents.contains("path: '/chat-rooms'")) {
        contents = contents.replaceFirst('routes: [', 'routes: [\n$chatRoutes');
      }
    } else if (config.routing == Routing.autoRoute) {
      const chatRoutes = '''
      AutoRoute(page: ChatRoomsRoute.page),
      AutoRoute(page: ChatRoute.page),
''';
      if (!contents.contains('ChatRoomsRoute.page')) {
        contents = contents.replaceFirst('List<AutoRoute> get routes => [',
            'List<AutoRoute> get routes => [\n$chatRoutes');
      }
    }
    BaseGenerator.writeFile(routerPath, contents);
  }

  static void _registerAuthRoutes(
      String routerPath, GeneratorConfig config, String importPath) {
    final routerFile = File(routerPath);
    String contents = routerFile.readAsStringSync();

    if (config.routing == Routing.autoRoute) {
      final loginImport = "import '${importPath}login_page.dart';";
      final registerImport = "import '${importPath}register_page.dart';";
      if (!contents.contains(loginImport)) {
        contents = '$loginImport\n$contents';
      }
      if (!contents.contains(registerImport)) {
        contents = '$registerImport\n$contents';
      }

      const loginRoute =
          '      AutoRoute(page: LoginRoute.page, initial: true),\n';
      const registerRoute = '      AutoRoute(page: RegisterRoute.page),\n';

      if (!contents.contains('LoginRoute.page')) {
        contents = contents.replaceFirst('List<AutoRoute> get routes => [',
            'List<AutoRoute> get routes => [\n$loginRoute$registerRoute');
      }
    } else {
      final loginImport = "import '${importPath}login_page.dart';";
      final registerImport = "import '${importPath}register_page.dart';";
      if (!contents.contains(loginImport)) {
        contents = '$loginImport\n$contents';
      }
      if (!contents.contains(registerImport)) {
        contents = '$registerImport\n$contents';
      }

      const routes = '''
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
    BaseGenerator.writeFile(routerPath, contents);
  }

  static void _registerAutoRoute(
      String routerPath, String name, String importPath) {
    final routerFile = File(routerPath);
    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);

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
    BaseGenerator.writeFile(routerPath, contents);
  }

  static void _registerGoRoute(
      String routerPath, String name, String importPath) {
    final routerFile = File(routerPath);
    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);

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
    BaseGenerator.writeFile(routerPath, contents);
  }

  /// Registers a page in the Navigator routing strategy.
  static void _registerInNavigator(
      String name, GeneratorConfig config, String packageName,
      {String? baseDir}) {
    final root = baseDir ?? Directory.current.path;
    final routerPath = p.join(root, 'lib', 'routes', 'app_router.dart');
    final routerFile = File(routerPath);
    if (!routerFile.existsSync()) return;

    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);
    final pageDir = config.getPagesDirectory();
    final importPath = 'package:$packageName/features/$snakeName/$pageDir/';

    String contents = routerFile.readAsStringSync();

    if (name == 'auth') {
      final loginImport = "import '${importPath}login_page.dart';";
      final registerImport = "import '${importPath}register_page.dart';";
      if (!contents.contains(loginImport)) {
        contents = '$loginImport\n$contents';
      }
      if (!contents.contains(registerImport)) {
        contents = '$registerImport\n$contents';
      }

      // Add route constants
      if (!contents.contains('static const String login')) {
        contents = contents.replaceFirst(
          "static const String home = '/';",
          "static const String home = '/';\n  static const String login = '/login';\n  static const String register = '/register';",
        );
      }

      // Add route builders
      if (!contents.contains('LoginPage')) {
        contents = contents.replaceFirst(
          'static Map<String, WidgetBuilder> get routes => {',
          'static Map<String, WidgetBuilder> get routes => {\n    login: (context) => const LoginPage(),\n    register: (context) => const RegisterPage(),',
        );
      }
    } else {
      final pageImport = "import '$importPath${snakeName}_page.dart';";
      if (!contents.contains(pageImport)) {
        contents = '$pageImport\n$contents';
      }

      // Add route constant
      if (!contents.contains('static const String $snakeName')) {
        contents = contents.replaceFirst(
          "static const String home = '/';",
          "static const String home = '/';\n  static const String $snakeName = '/$snakeName';",
        );
      }

      // Add route builder
      if (!contents.contains('${pascalName}Page')) {
        contents = contents.replaceFirst(
          'static Map<String, WidgetBuilder> get routes => {',
          'static Map<String, WidgetBuilder> get routes => {\n    $snakeName: (context) => const ${pascalName}Page(),',
        );
      }
    }

    BaseGenerator.writeFile(routerPath, contents);
  }
}
