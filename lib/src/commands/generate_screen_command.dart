import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:flutter_architecture_generator/src/utils/pubspec_helper.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import '../models/generator_config.dart';
import '../utils/file_helper.dart';
import '../utils/string_utils.dart';
import '../utils/validation_utils.dart';
import '../utils/template_loader.dart';
import '../generators/base_generator.dart';
import '../generators/router_registrar.dart';

/// The `screen` command — generates a complex screen with pre-wired boilerplate.
class GenerateScreenCommand extends Command<int> {
  /// Creates a [GenerateScreenCommand].
  GenerateScreenCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'feature',
      abbr: 'f',
      help: 'Target feature for the screen.',
      mandatory: true,
    );
    argParser.addOption(
      'type',
      abbr: 't',
      help: 'Screen template type.',
      allowed: ['empty', 'list', 'form', 'detail'],
      defaultsTo: 'empty',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Custom output directory (monorepo support).',
    );
    argParser.addOption(
      'config',
      abbr: 'c',
      help: 'Configuration profile name.',
    );
    argParser.addFlag(
      'dry-run',
      abbr: 'n',
      negatable: false,
      help: 'Preview changes without applying them.',
    );
  }

  final Logger _logger;

  @override
  String get name => 'screen';

  @override
  String get description =>
      'Generate a pre-wired screen (List, Form, Detail) for a feature.';

  @override
  Future<int> run() async {
    final screenName =
        argResults?.rest.isNotEmpty == true ? argResults!.rest.first : null;

    if (screenName == null) {
      _logger.err('Please provide a screen name.');
      _logger
          .info('Usage: flutter_arch_gen screen <name> -f <feature> [-t type]');
      return ExitCode.usage.code;
    }

    final validationError = ValidationUtils.validateName(screenName, 'screen');
    if (validationError != null) {
      _logger.err(validationError);
      return ExitCode.usage.code;
    }

    final featureName = argResults?['feature'] as String;
    final type = argResults?['type'] as String;
    final outputDir = argResults?['output'] as String?;
    final configName = argResults?['config'] as String?;
    final dryRun = argResults?['dry-run'] == true;

    final config = FileHelper.loadConfig(baseDir: outputDir, name: configName);
    if (config == null) {
      _logger.err('No .flutter_arch_gen configuration found.');
      return ExitCode.usage.code;
    }

    final progress = _logger.progress('🎨 Designing screen: $screenName...');

    try {
      final baseDir = outputDir ?? Directory.current.path;
      final snakeScreen = StringUtils.toSnakeCase(screenName);
      final pascalScreen = StringUtils.toPascalCase(screenName);
      final snakeFeature = StringUtils.toSnakeCase(featureName);
      final packageName = PubspecHelper.getPackageName(baseDir: baseDir);

      final pageDir = config.getPagesDirectory();
      final targetPath =
          p.join(baseDir, 'lib', 'features', snakeFeature, pageDir);

      BaseGenerator.beginTracking();

      final content = _generateScreenContent(
        pascalScreen,
        snakeScreen,
        snakeFeature,
        type,
        config,
        packageName,
      );

      BaseGenerator.writeFile(
          p.join(targetPath, '${snakeScreen}_page.dart'), content);

      // Register in router
      RouterRegistrar.register(
        '$snakeFeature/$snakeScreen',
        config,
        packageName,
        baseDir: baseDir,
      );

      final actions = BaseGenerator.endTracking();
      progress.complete('Screen design complete! ✅');

      FileHelper.renderPlan(actions, _logger, baseDir: baseDir);

      if (dryRun) {
        _logger.info('✅ Dry run complete.');
        return ExitCode.success.code;
      }

      final confirm =
          _logger.confirm('Apply these changes?', defaultValue: true);
      if (!confirm) {
        _logger.info('Cancelled.');
        return ExitCode.success.code;
      }

      FileHelper.applyPlan(actions, command: 'screen $screenName');
      return ExitCode.success.code;
    } catch (e) {
      progress.fail('Failed to generate screen: $e');
      return ExitCode.software.code;
    }
  }

  String _generateScreenContent(
    String className,
    String fileName,
    String featureName,
    String type,
    GeneratorConfig config,
    String packageName,
  ) {
    final isAutoRoute = config.routing == Routing.autoRoute;
    final annotation = isAutoRoute ? '@RoutePage()\n' : '';
    final importAutoRoute =
        isAutoRoute ? "import 'package:auto_route/auto_route.dart';\n" : '';

    final replacements = {
      '{{className}}': className,
      '{{fileName}}': fileName,
      '{{featureName}}': featureName,
      '{{packageName}}': packageName,
      '{{routeAnnotation}}': annotation,
      '{{importAutoRoute}}': importAutoRoute,
    };

    return TemplateLoader.load(
      'screen_$type',
      defaultContent: _getDefaultContent(type, config),
      replacements: replacements,
    );
  }

  String _getDefaultContent(String type, GeneratorConfig config) {
    switch (type) {
      case 'list':
        return '''
import 'package:flutter/material.dart';
{{importAutoRoute}}
{{routeAnnotation}}class {{className}}Page extends StatelessWidget {
  const {{className}}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{{className}}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: 10,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(child: Text('\${index + 1}')),
            title: Text('Item \${index + 1}'),
            subtitle: const Text('Description goes here'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          );
        },
      ),
    );
  }
}
''';
      case 'form':
        return '''
import 'package:flutter/material.dart';
{{importAutoRoute}}
{{routeAnnotation}}class {{className}}Page extends StatefulWidget {
  const {{className}}Page({super.key});

  @override
  State<{{className}}Page> createState() => _{{className}}PageState();
}

class _{{className}}PageState extends State<{{className}}Page> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{{className}} Form')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => 
                    value?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Processing...')),
                    );
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
''';
      case 'detail':
        return '''
import 'package:flutter/material.dart';
{{importAutoRoute}}
{{routeAnnotation}}class {{className}}Page extends StatelessWidget {
  const {{className}}Page({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 250,
              color: theme.colorScheme.primaryContainer,
              child: const Icon(Icons.image, size: 100),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '{{className}} Title',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                    'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share),
                    label: const Text('Share Content'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
''';
      default:
        return '''
import 'package:flutter/material.dart';
{{importAutoRoute}}
{{routeAnnotation}}class {{className}}Page extends StatelessWidget {
  const {{className}}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{{className}}')),
      body: const Center(child: Text('{{className}} Page')),
    );
  }
}
''';
    }
  }
}
