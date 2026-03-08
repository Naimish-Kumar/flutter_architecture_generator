/// The main library for the Flutter Architecture Generator CLI tool.
///
/// This library exposes the [FlutterArchGenRunner] which registers all
/// available commands: `init`, `feature`, `model`, `page`, `widget`,
/// `service`, `repository`, `bloc`, `migrate`, `screen`, `api`, `undo`,
/// `delete`, `update`, `list`, `doctor`, and `rename`.
library;

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'src/commands/generate_arch_command.dart';
import 'src/commands/generate_feature_command.dart';
import 'src/commands/generate_model_command.dart';
import 'src/commands/generate_page_command.dart';
import 'src/commands/generate_widget_command.dart';
import 'src/commands/generate_service_command.dart';
import 'src/commands/generate_repository_command.dart';
import 'src/commands/generate_bloc_command.dart';
import 'src/commands/delete_feature_command.dart';
import 'src/commands/update_deps_command.dart';
import 'src/commands/list_features_command.dart';
import 'src/commands/doctor_command.dart';
import 'src/commands/rename_feature_command.dart';
import 'src/commands/migrate_command.dart';
import 'src/commands/undo_command.dart';
import 'src/commands/generate_screen_command.dart';
import 'src/commands/generate_api_command.dart';
import 'src/commands/generate_theme_command.dart';
import 'src/commands/refactor_command.dart';

/// The current version of the Flutter Architecture Generator.
const String packageVersion = '1.2.0';

/// The command runner for the Flutter Architecture Generator CLI.
///
/// Provides commands for scaffolding Flutter projects with various
/// architecture patterns, state management, and routing strategies.
class FlutterArchGenRunner extends CommandRunner<int> {
  /// Creates a new instance of [FlutterArchGenRunner].
  ///
  /// Takes an optional [logger] for styled output.
  FlutterArchGenRunner({Logger? logger})
      : _logger = logger ?? Logger(),
        super(
          'flutter_arch_gen',
          'A powerful CLI tool to instantly generate a production-ready Flutter project architecture.',
        ) {
    argParser.addFlag(
      'version',
      negatable: false,
      help: 'Print the current version.',
    );

    // Core commands
    addCommand(GenerateArchCommand(logger: _logger));
    addCommand(GenerateFeatureCommand(logger: _logger));
    addCommand(GenerateModelCommand(logger: _logger));
    addCommand(GeneratePageCommand(logger: _logger));
    addCommand(GenerateWidgetCommand(logger: _logger));
    addCommand(GenerateServiceCommand(logger: _logger));
    addCommand(GenerateRepositoryCommand(logger: _logger));
    addCommand(GenerateBlocCommand(logger: _logger));
    addCommand(GenerateScreenCommand(logger: _logger));
    addCommand(GenerateApiCommand(logger: _logger));
    addCommand(GenerateThemeCommand(logger: _logger));
    addCommand(RefactorCommand(logger: _logger));

    // Utility commands
    addCommand(UndoCommand(logger: _logger));
    addCommand(DeleteFeatureCommand(logger: _logger));
    addCommand(UpdateDepsCommand(logger: _logger));
    addCommand(ListFeaturesCommand(logger: _logger));
    addCommand(DoctorCommand(logger: _logger));
    addCommand(RenameFeatureCommand(logger: _logger));
    addCommand(MigrateCommand(logger: _logger));
  }

  final Logger _logger;

  @override
  Future<int?> run(Iterable<String> args) async {
    try {
      final topLevelResults = parse(args);

      if (topLevelResults['version'] == true) {
        _logger.info('flutter_arch_gen version $packageVersion');
        return ExitCode.success.code;
      }

      if (args.isEmpty) {
        return await super.run(['init']);
      }

      return await runCommand(topLevelResults);
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
