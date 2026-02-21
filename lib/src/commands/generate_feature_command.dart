// ignore_for_file: public_member_api_docs
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import '../utils/feature_helper.dart';
import '../utils/file_helper.dart';
import '../models/generator_config.dart';

class GenerateFeatureCommand extends Command<int> {

  GenerateFeatureCommand({required Logger logger}) : _logger = logger {
    argParser.addOption('name', abbr: 'n', help: 'Name of the feature');
    argParser.addOption(
      'state',
      abbr: 's',
      help: 'State management to use',
      allowed: StateManagement.values.map((e) => e.name).toList(),
      defaultsTo: StateManagement.bloc.name,
    );
  }
  final Logger _logger;

  @override
  String get name => 'feature';

  @override
  String get description => 'Generate a new feature module.';

  @override
  Future<int> run() async {
    final featureName = argResults?['name'] ??
        (argResults?.rest.isNotEmpty == true ? argResults?.rest.first : null);

    if (featureName == null) {
      _logger.err('Please provide a feature name.');
      return ExitCode.usage.code;
    }

    final stateName = argResults?['state'] as String;
    final stateManagement =
        StateManagement.values.firstWhere((e) => e.name == stateName);

    // Try to load existing config
    final savedConfig = FileHelper.loadConfig();

    final progress = _logger.progress('🏗 Generating feature: $featureName...');

    try {
      final config = savedConfig ??
          GeneratorConfig(
            stateManagement: stateManagement,
            routing: Routing.goRouter, // Default
            localization: true,
            firebase: false,
            tests: true,
          );

      await FeatureHelper.generateFeature(featureName,
          config: config, logger: _logger);
      progress.complete(
          'Feature $featureName generated with Clean Architecture! ✅');
      return ExitCode.success.code;
    } catch (e) {
      progress.fail('Failed to generate feature: $e');
      return ExitCode.software.code;
    }
  }
}
