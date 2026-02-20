import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import '../models/generator_config.dart';
import '../utils/file_helper.dart';
import '../utils/feature_helper.dart';
import '../utils/pubspec_helper.dart';

class GenerateArchCommand extends Command<int> {
  final Logger _logger;

  @override
  String get name => 'init';

  @override
  String get description => 'Initialize Flutter project architecture.';

  GenerateArchCommand({required Logger logger}) : _logger = logger;

  @override
  Future<int> run() async {
    final packageName = PubspecHelper.getPackageName();
    _logger
        .info('🚀 Initializing Flutter Architecture for package: $packageName');

    // Interactive setup
    final stateManagement = _logger.chooseOne(
      'Select state management:',
      choices: StateManagement.values.map((e) => e.name).toList(),
      defaultValue: StateManagement.bloc.name,
    );

    final routing = _logger.chooseOne(
      'Select routing:',
      choices: Routing.values.map((e) => e.name).toList(),
      defaultValue: Routing.goRouter.name,
    );

    final localization =
        _logger.confirm('Enable localization?', defaultValue: true);
    final firebase = _logger.confirm('Enable Firebase?', defaultValue: false);
    final tests = _logger.confirm('Enable tests?', defaultValue: true);

    final config = GeneratorConfig(
      stateManagement:
          StateManagement.values.firstWhere((e) => e.name == stateManagement),
      routing: Routing.values.firstWhere((e) => e.name == routing),
      localization: localization,
      firebase: firebase,
      tests: tests,
    );

    final progress = _logger.progress('Generating structure...');

    try {
      await FileHelper.generateBaseStructure(config);

      // Generate an example feature: auth
      progress.update('Generating example feature: auth...');
      await FeatureHelper.generateFeature('auth',
          config: config, logger: _logger);

      progress.complete('Architecture and example feature generated! ✅');

      _logger.info('\nNext steps:');
      _logger.info('1. Run `flutter pub get`');
      _logger.info(
          '2. Run `dart run build_runner build --delete-conflicting-outputs`');
      _logger.info('3. Configure your environments in .env files');
      _logger.info('4. Happy coding! 🚀');

      return ExitCode.success.code;
    } catch (e) {
      progress.fail('Failed to generate architecture: $e');
      return ExitCode.software.code;
    }
  }
}
