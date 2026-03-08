import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import '../generators/theme_generator.dart';

/// The `theme` command — generates a premium design system.
class GenerateThemeCommand extends Command<int> {
  /// Creates a [GenerateThemeCommand].
  GenerateThemeCommand({required Logger logger}) : _logger = logger;

  @override
  String get description =>
      'Generates a premium Design System and ThemeData for your project.';

  @override
  String get name => 'theme';

  final Logger _logger;

  @override
  Future<int> run() async {
    final progress = _logger.progress('Generating premium theme...');
    try {
      await ThemeGenerator.generate();
      progress.complete('Design system generated successfully! 🎨');
      _logger.info('Add the following to your MaterialApp:');
      _logger.info('  theme: AppTheme.lightTheme,');
      _logger.info('  darkTheme: AppTheme.darkTheme,');
      return 0;
    } catch (e) {
      progress.fail('Failed to generate theme: \$e');
      return 1;
    }
  }
}
