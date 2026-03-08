/// Base file templates for project initialization.
///
/// Contains template generators for core files created during `init`:
/// main.dart, app.dart, DI container, API client, theme, router, etc.
library;

import '../models/generator_config.dart';
import '../utils/template_loader.dart';

/// Provides static template methods for generating base project files.
class BaseTemplates {
  /// Generates the content for `main.dart`.
  static String mainContent(GeneratorConfig config, String packageName) {
    final firebaseImport = config.firebase
        ? "import 'package:firebase_core/firebase_core.dart';\nimport 'firebase_options.dart';"
        : '';
    final firebaseInit = config.firebase
        ? '\n  await Firebase.initializeApp(\n    options: DefaultFirebaseOptions.currentPlatform,\n  );'
        : '';
    final isAutoRoute = config.routing == Routing.autoRoute;
    final myAppConst = isAutoRoute ? '' : 'const ';

    return TemplateLoader.load(
      'main',
      defaultContent: '''
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
{{firebaseImport}}
import 'package:{{packageName}}/app.dart';
import 'package:{{packageName}}/di/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load environment variables
  await dotenv.load(fileName: kReleaseMode ? ".env.prod" : ".env.dev");
  {{firebaseInit}}

  await di.init();
  
  runApp({{myAppConst}}MyApp());
}
''',
      replacements: {
        '{{packageName}}': packageName,
        '{{firebaseImport}}': firebaseImport,
        '{{firebaseInit}}': firebaseInit,
        '{{myAppConst}}': myAppConst,
      },
    );
  }

  /// Generates the content for `app.dart`.
  /// Generates the content for `app.dart`.
  static String appContent(GeneratorConfig config, String packageName) {
    final useRouter = config.routing != Routing.navigator;
    final isRiverpod = config.stateManagement == StateManagement.riverpod;
    final isGetX = config.stateManagement == StateManagement.getx;
    final isAutoRoute = config.routing == Routing.autoRoute;

    final routerImport = useRouter
        ? "import 'package:$packageName/routes/app_router.dart';"
        : "import 'package:$packageName/core/constants/app_routes.dart';";
    final themeImport =
        "import 'package:$packageName/core/theme/app_theme.dart';";
    final riverpodImport = isRiverpod
        ? "import 'package:flutter_riverpod/flutter_riverpod.dart';"
        : '';
    final getxImport = isGetX ? "import 'package:get/get.dart';" : '';
    final l10nImport = config.localization
        ? "import 'package:flutter_localizations/flutter_localizations.dart';"
        : '';

    // Initialize variables for the Material App configuration
    final String l10nConfig = config.localization
        ? '''
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
      ],'''
        : '';

    final routerField = useRouter ? '\n  final _appRouter = AppRouter();' : '';

    String homeProp;
    if (isAutoRoute) {
      homeProp = 'routerConfig: _appRouter.config(),';
    } else if (config.routing == Routing.goRouter) {
      homeProp = 'routerConfig: _appRouter.router,';
    } else {
      homeProp =
          'initialRoute: AppRoutes.home,\n      onGenerateRoute: AppRoutes.onGenerateRoute,';
    }

    // GetMaterialApp does NOT support .router() constructor,
    // so fall back to regular MaterialApp.router when using a declarative router.
    final appClass = (isGetX && !useRouter) ? 'GetMaterialApp' : 'MaterialApp';

    var materialApp = '''
    $appClass${useRouter ? '.router' : ''}(
      title: 'Flutter {{archName}}',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      $l10nConfig
      $homeProp
    )''';

    if (isRiverpod) {
      materialApp = 'ProviderScope(child: $materialApp)';
    }

    return TemplateLoader.load(
      'app',
      defaultContent: '''
import 'package:flutter/material.dart';
{{riverpodImport}}
{{getxImport}}
{{routerImport}}
{{themeImport}}
{{l10nImport}}

class MyApp extends StatelessWidget {
  {{appConstructor}}
  {{routerField}}

  @override
  Widget build(BuildContext context) {
    return {{materialApp}};
  }
}
''',
      replacements: {
        '{{packageName}}': packageName,
        '{{riverpodImport}}': riverpodImport,
        '{{getxImport}}': getxImport,
        '{{routerImport}}': routerImport,
        '{{themeImport}}': themeImport,
        '{{l10nImport}}': l10nImport,
        '{{routerField}}': routerField,
        '{{materialApp}}': materialApp,
        '{{archName}}': config.architecture.displayName,
        '{{appConstructor}}':
            isAutoRoute ? 'MyApp({super.key}) {}' : 'const MyApp({super.key});',
      },
    );
  }

  /// Generates the content for `injection_container.dart`.
  static String diContent(GeneratorConfig config, String packageName) {
    return TemplateLoader.load(
      'injection_container',
      defaultContent: '''
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:{{packageName}}/core/network/api_client.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  sl.registerLazySingleton(() => Dio());

  // Core
  sl.registerLazySingleton(() => ApiClient(sl()));

  // Features
}
''',
      replacements: {
        '{{packageName}}': packageName,
      },
    );
  }

  /// Generates the content for `api_client.dart`.
  static String apiClientContent() {
    return TemplateLoader.load(
      'api_client',
      defaultContent: '''
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  final Dio dio;

  ApiClient(this.dio) {
    dio.options.baseUrl =
        dotenv.env['API_BASE_URL'] ?? 'https://api.example.com';
    dio.options.connectTimeout = const Duration(seconds: 5);
    dio.options.receiveTimeout = const Duration(seconds: 3);

    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  // GET Method
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // POST Method
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // PUT Method
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // DELETE Method
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // PATCH Method
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // Multipart/Form-data Method
  Future<Response> postMultipart(
    String path, {
    required Map<String, dynamic> data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
  }) async {
    final formData = FormData.fromMap(data);
    return await dio.post(
      path,
      data: formData,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
    );
  }
}
''',
      replacements: {},
    );
  }

  /// Generates the content for `failures.dart`.
  static String errorContent() {
    return TemplateLoader.load(
      'failures',
      defaultContent: '''
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => '\$runtimeType: \$message';
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server Error']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache Error']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No Internet Connection']);
}

class GeneralFailure extends Failure {
  const GeneralFailure([super.message = 'Unexpected Error']);
}
''',
      replacements: {},
    );
  }

  /// Generates the content for `app_theme.dart`.
  static String themeContent() {
    return TemplateLoader.load(
      'theme',
      defaultContent: '''
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
''',
      replacements: {},
    );
  }

  /// Generates the content for `l10n.yaml`.
  static String l10nYamlContent() {
    return '''
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
''';
  }

  /// Generates the content for the initial ARB localization file.
  static String arbContent(GeneratorConfig config) {
    return TemplateLoader.load(
      'arb',
      defaultContent: '''
{
  "@@locale": "en",
  "appTitle": "Flutter {{archName}}",
  "@appTitle": {
    "description": "The title of the application"
  }
}
''',
      replacements: {
        '{{archName}}': config.architecture.displayName,
      },
    );
  }

  /// Generates the content for `sample_test.dart`.
  static String testContent() {
    return TemplateLoader.load(
      'sample_test',
      defaultContent: '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Sample unit test', () {
    expect(1 + 1, 2);
  });
}
''',
      replacements: {},
    );
  }

  /// Generates the content for `app_router.dart`.
  static String routerContent(GeneratorConfig config) {
    if (config.routing == Routing.autoRoute) {
      return TemplateLoader.load(
        'router_auto_route',
        defaultContent: '''
import 'package:auto_route/auto_route.dart';
part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends _\$AppRouter {
  @override
  List<AutoRoute> get routes => [
    // AutoRoute(page: HomeRoute.page, initial: true),
  ];
}
''',
        replacements: {},
      );
    } else if (config.routing == Routing.goRouter) {
      return TemplateLoader.load(
        'router_go_router',
        defaultContent: '''
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class AppRouter {
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
}
''',
        replacements: {},
      );
    }
    return TemplateLoader.load(
      'router_navigator',
      defaultContent: '''
import 'package:flutter/material.dart';

class AppRoutes {
  static const String home = '/';

  static Map<String, WidgetBuilder> get routes => {
    home: (context) => const Scaffold(
      body: Center(child: Text('Home')),
    ),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final builder = routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(builder: builder, settings: settings);
    }
    return MaterialPageRoute(
      builder: (context) => const Scaffold(
        body: Center(child: Text('Page not found')),
      ),
    );
  }
}
''',
      replacements: {},
    );
  }

  /// Generates the content for `app_constants.dart`.
  static String constantsContent(GeneratorConfig config) {
    return TemplateLoader.load(
      'constants',
      defaultContent: '''
class AppConstants {
  static const String appName = 'Flutter {{archName}}';
}
''',
      replacements: {
        '{{archName}}': config.architecture.displayName,
      },
    );
  }

  /// Generates GitHub Actions CI/CD workflow content.
  static String githubActionsContent() {
    return TemplateLoader.load(
      'github_actions',
      defaultContent: '''
name: Flutter CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  analyze-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: stable

      - name: Install dependencies
        run: flutter pub get

      - name: Verify formatting
        run: dart format --output=none --set-exit-if-changed .

      - name: Analyze project source
        run: flutter analyze --fatal-infos

      - name: Run tests
        run: flutter test --coverage

  build-android:
    runs-on: ubuntu-latest
    needs: analyze-and-test
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 17

      - uses: subosito/flutter-action@v2
        with:
          channel: stable

      - run: flutter pub get
      - run: flutter build apk --release

  build-ios:
    runs-on: macos-latest
    needs: analyze-and-test
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: stable

      - run: flutter pub get
      - run: flutter build ios --release --no-codesign
''',
      replacements: {},
    );
  }
}
