import '../models/generator_config.dart';

class BaseTemplates {
  static String mainContent(GeneratorConfig config, String packageName) {
    final firebaseImport = config.firebase
        ? "import 'package:firebase_core/firebase_core.dart';\nimport 'firebase_options.dart';"
        : "";
    final firebaseInit = config.firebase
        ? "\n  await Firebase.initializeApp(\n    options: DefaultFirebaseOptions.currentPlatform,\n  );"
        : "";
    final isAutoRoute = config.routing == Routing.autoRoute;
    final myAppConst = isAutoRoute ? '' : 'const ';

    return '''
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
$firebaseImport
import 'package:$packageName/app.dart';
import 'package:$packageName/di/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load environment variables
  await dotenv.load(fileName: ".env.dev");
  $firebaseInit

  await di.init();
  
  runApp(${myAppConst}MyApp());
}
''';
  }

  static String appContent(GeneratorConfig config, String packageName) {
    final useRouter = config.routing != Routing.navigator;
    final isRiverpod = config.stateManagement == StateManagement.riverpod;

    final routerImport = useRouter
        ? "import 'package:$packageName/routes/app_router.dart';"
        : "";
    final themeImport =
        "import 'package:$packageName/core/theme/app_theme.dart';";
    final riverpodImport = isRiverpod
        ? "import 'package:flutter_riverpod/flutter_riverpod.dart';"
        : "";
    final l10nImport = config.localization
        ? "import 'package:flutter_localizations/flutter_localizations.dart';"
        : "";

    final homeProp = useRouter
        ? "routerConfig: router,"
        : "home: const Scaffold(body: Center(child: Text('Welcome'))),";

    final isAutoRoute = config.routing == Routing.autoRoute;

    final l10nConfig = config.localization
        ? '''
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
      ],'''
        : "";

    var materialApp = '''
    MaterialApp${useRouter ? '.router' : ''}(
      title: 'Flutter Clean Architecture',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      $l10nConfig
      ${isAutoRoute ? 'routerConfig: _appRouter.config(),' : homeProp}
    )''';

    if (isRiverpod) {
      materialApp = 'ProviderScope(child: $materialApp)';
    }

    final autoRouteField =
        isAutoRoute ? '\n  final _appRouter = AppRouter();' : '';

    return '''
import 'package:flutter/material.dart';
$riverpodImport
$routerImport
$themeImport
$l10nImport

class MyApp extends StatelessWidget {
  ${isAutoRoute ? '' : 'const '}MyApp({super.key});
  $autoRouteField

  @override
  Widget build(BuildContext context) {
    return $materialApp;
  }
}
''';
  }

  static String diContent(GeneratorConfig config, String packageName) {
    return '''
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:$packageName/core/network/api_client.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  sl.registerLazySingleton(() => Dio());

  // Core
  sl.registerLazySingleton(() => ApiClient(sl()));

  // Features
}
''';
  }

  static String apiClientContent() {
    return '''
import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;

  ApiClient(this.dio) {
    dio.options.baseUrl = 'https://api.example.com';
    dio.options.connectTimeout = const Duration(seconds: 5);
    dio.options.receiveTimeout = const Duration(seconds: 3);
    
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }
}
''';
  }

  static String errorContent() {
    return '''
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server Error']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache Error']);
}

class GeneralFailure extends Failure {
  const GeneralFailure([super.message = 'Unexpected Error']);
}
''';
  }

  static String themeContent() {
    return '''
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}
''';
  }

  static String l10nYamlContent() {
    return '''
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
''';
  }

  static String arbContent() {
    return '''
{
  "@@locale": "en",
  "appTitle": "Flutter Clean Arch",
  "@appTitle": {
    "description": "The title of the application"
  }
}
''';
  }

  static String testContent() {
    return '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Sample unit test', () {
    expect(1 + 1, 2);
  });
}
''';
  }

  static String routerContent(GeneratorConfig config) {
    if (config.routing == Routing.autoRoute) {
      return '''
import 'package:auto_route/auto_route.dart';

@AutoRouterConfig()
class AppRouter extends _\$AppRouter {
  @override
  List<AutoRoute> get routes => [
    // AutoRoute(page: HomeRoute.page, initial: true),
  ];
}
''';
    } else if (config.routing == Routing.goRouter) {
      return '''
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Home')),
      ),
    ),
  ],
);
''';
    }
    return '// Navigator 2.0 configuration';
  }

  static String constantsContent() {
    return '''
class AppConstants {
  static const String appName = 'Flutter Clean Architecture';
}
''';
  }
}
