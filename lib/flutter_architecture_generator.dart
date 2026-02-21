/// A powerful CLI tool to instantly generate a production-ready Flutter project
/// architecture following Clean Architecture principles.
library;

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'src/commands/generate_arch_command.dart';
import 'src/commands/generate_feature_command.dart';
import 'src/commands/generate_model_command.dart';
import 'src/commands/generate_page_command.dart';

/// The command runner for the Flutter Architecture Generator CLI.
class FlutterArchGenRunner extends CommandRunner<int> {
  /// Creates a new instance of [FlutterArchGenRunner].
  ///
  /// Takes an optional [logger] for output.
  FlutterArchGenRunner({Logger? logger})
      : _logger = logger ?? Logger(),
        super(
          'flutter_arch_gen',
          'A powerful CLI tool to instantly generate a production-ready Flutter project architecture.',
        ) {
    addCommand(GenerateArchCommand(logger: _logger));
    addCommand(GenerateFeatureCommand(logger: _logger));
    addCommand(GenerateModelCommand(logger: _logger));
    addCommand(GeneratePageCommand(logger: _logger));
  }

  final Logger _logger;

  @override
  Future<int?> run(Iterable<String> args) async {
    try {
      if (args.isEmpty) {
        return await super.run(['init']);
      }
      final argResults = parse(args);
      return await runCommand(argResults);
    } on UsageException catch (e) {
      _logger.err(e.message);
      _logger.info('');
      _logger.info(usage);
      return ExitCode.usage.code;
    } catch (e) {
      _logger.err(e.toString());
      return ExitCode.software.code;
    }
  }
}
