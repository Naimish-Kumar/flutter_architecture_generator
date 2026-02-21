// ignore_for_file: public_member_api_docs
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import '../utils/file_helper.dart';
import '../utils/pubspec_helper.dart';
import '../utils/string_utils.dart';
import '../models/generator_config.dart';

class GeneratePageCommand extends Command<int> {

  GeneratePageCommand({required Logger logger}) : _logger = logger {
    argParser.addOption('feature',
        abbr: 'f', help: 'Target feature for the page');
  }
  final Logger _logger;

  @override
  String get name => 'page';

  @override
  String get description => 'Generate a new page.';

  @override
  Future<int> run() async {
    final pageName =
        argResults?.rest.isNotEmpty == true ? argResults?.rest.first : null;

    if (pageName == null) {
      _logger.err('Please provide a page name.');
      return ExitCode.usage.code;
    }

    final featureName = argResults?['feature'] as String?;
    final progress = _logger.progress('📄 Generating page: $pageName...');

    try {
      final fileName = StringUtils.toSnakeCase(pageName);
      final className = StringUtils.toPascalCase(pageName);
      final config = FileHelper.loadConfig();
      final packageName = PubspecHelper.getPackageName();

      final isAutoRoute = config?.routing == Routing.autoRoute;
      final autoRouteImport =
          isAutoRoute ? "import 'package:auto_route/auto_route.dart';\n" : '';
      final routeAnnotation = isAutoRoute ? '@RoutePage()\n' : '';

      final content = '''
import 'package:flutter/material.dart';
$autoRouteImport
$routeAnnotation
class ${className}Page extends StatelessWidget {
  const ${className}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$className'),
      ),
      body: const Center(
        child: Text('$className Page'),
      ),
    );
  }
}
''';

      final targetPath = featureName != null
          ? p.join('lib', 'features', StringUtils.toSnakeCase(featureName),
              'presentation', 'pages')
          : p.join('lib', 'presentation', 'pages');

      final file = File(
          p.join(Directory.current.path, targetPath, '${fileName}_page.dart'));
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      file.writeAsStringSync(content);

      // Auto-register in router if applicable
      if (config != null) {
        if (config.routing == Routing.goRouter) {
          _registerInGoRouter(pageName, targetPath, packageName);
        } else if (config.routing == Routing.autoRoute) {
          _registerInAutoRoute(pageName, targetPath, packageName);
        }
      }

      progress.complete('Page ${className}Page generated in $targetPath! ✅');
      return ExitCode.success.code;
    } catch (e) {
      progress.fail('Failed to generate page: $e');
      return ExitCode.software.code;
    }
  }

  /// Normalizes a path from p.join (which uses OS separators) into a
  /// forward-slash import-style path and strips the leading `lib/`.
  static String _toImportRelativePath(String targetPath) {
    return targetPath.replaceAll('\\', '/').replaceFirst('lib/', '');
  }

  void _registerInGoRouter(String name, String targetPath, String packageName) {
    final routerFile = File(p.join('lib', 'routes', 'app_router.dart'));
    if (!routerFile.existsSync()) return;

    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);
    final pageClass = '${pascalName}Page';

    final relativePath = _toImportRelativePath(targetPath);
    final importPath =
        'package:$packageName/$relativePath/${snakeName}_page.dart';
    final import = "import '$importPath';";

    String contents = routerFile.readAsStringSync();
    if (!contents.contains(import)) {
      contents = '$import\n$contents';
    }

    final route = '''
    GoRoute(
      path: '/$snakeName',
      builder: (context, state) => const $pageClass(),
    ),
''';
    if (!contents.contains("path: '/$snakeName'")) {
      contents = contents.replaceFirst('routes: [', 'routes: [\n$route');
    }
    routerFile.writeAsStringSync(contents);
  }

  void _registerInAutoRoute(
      String name, String targetPath, String packageName) {
    final routerFile = File(p.join('lib', 'routes', 'app_router.dart'));
    if (!routerFile.existsSync()) return;

    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);

    final relativePath = _toImportRelativePath(targetPath);
    final importPath =
        'package:$packageName/$relativePath/${snakeName}_page.dart';
    final import = "import '$importPath';";

    String contents = routerFile.readAsStringSync();
    if (!contents.contains(import)) {
      contents = '$import\n$contents';
    }

    final route = '      AutoRoute(page: ${pascalName}Route.page),\n';
    if (!contents.contains('${pascalName}Route.page')) {
      contents = contents.replaceFirst('List<AutoRoute> get routes => [',
          'List<AutoRoute> get routes => [\n$route');
    }
    routerFile.writeAsStringSync(contents);
  }
}
