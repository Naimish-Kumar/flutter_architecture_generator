import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import '../utils/file_helper.dart';
import '../utils/pubspec_helper.dart';
import '../utils/string_utils.dart';
import '../utils/validation_utils.dart';
import '../utils/template_loader.dart';
import '../generators/base_generator.dart';

/// The `bloc` command — generates a standalone BLoC or Cubit.
class GenerateBlocCommand extends Command<int> {
  /// Creates a [GenerateBlocCommand].
  GenerateBlocCommand({required Logger logger}) : _logger = logger {
    argParser.addOption('feature',
        abbr: 'f', help: 'Target feature for the BLoC/Cubit');
    argParser.addFlag('cubit',
        abbr: 'c',
        negatable: false,
        help: 'Generate a Cubit instead of a BLoC');
    argParser.addOption('output',
        abbr: 'o', help: 'Custom output directory (monorepo support)');
    argParser.addOption('config', help: 'Configuration profile name');
    argParser.addFlag('dry-run',
        abbr: 'n', negatable: false, help: 'Preview changes');
  }

  final Logger _logger;

  @override
  String get name => 'bloc';

  @override
  String get description =>
      'Generate a standalone BLoC (with events+states) or Cubit (--cubit).';

  @override
  Future<int> run() async {
    final blocName =
        argResults?.rest.isNotEmpty == true ? argResults!.rest.first : null;

    if (blocName == null) {
      _logger.err('Please provide a BLoC/Cubit name.');
      return ExitCode.usage.code;
    }

    final validationError = ValidationUtils.validateName(blocName, 'BLoC');
    if (validationError != null) {
      _logger.err(validationError);
      return ExitCode.usage.code;
    }

    final featureName = argResults?['feature'] as String?;
    final isCubit = argResults?['cubit'] == true;
    final outputDir = argResults?['output'] as String?;
    final configName = argResults?['config'] as String?;
    final dryRun = argResults?['dry-run'] == true;
    final type = isCubit ? 'Cubit' : 'BLoC';

    final baseDir = outputDir ?? Directory.current.path;
    final config = FileHelper.loadConfig(baseDir: baseDir, name: configName);
    final packageName = PubspecHelper.getPackageName(baseDir: baseDir);

    BaseGenerator.beginTracking();

    final fileName = StringUtils.toSnakeCase(blocName);
    final className = StringUtils.toPascalCase(blocName);

    String targetDir;
    if (featureName != null) {
      final snakeFeature = StringUtils.toSnakeCase(featureName);
      final smDir =
          config?.getStateManagementDirectory() ?? (isCubit ? 'cubit' : 'bloc');
      targetDir = p.join(baseDir, 'lib', 'features', snakeFeature, smDir);
    } else {
      targetDir = p.join(baseDir, 'lib', 'core', isCubit ? 'cubits' : 'blocs');
    }

    if (isCubit) {
      _generateCubit(targetDir, fileName, className, packageName);
    } else {
      _generateBloc(targetDir, fileName, className, packageName);
    }

    final actions = BaseGenerator.endTracking();
    FileHelper.renderPlan(actions, _logger, baseDir: baseDir);

    if (dryRun) {
      _logger.info('✅ Dry run complete.');
      return ExitCode.success.code;
    }

    if (actions.isNotEmpty) {
      final confirm = _logger.confirm('Generate $type?', defaultValue: true);
      if (confirm) {
        FileHelper.applyPlan(actions, command: 'bloc $blocName');
        _logger.success('$type $className generated successfully! 🎉');
      }
    }

    return ExitCode.success.code;
  }

  void _generateBloc(
      String dir, String fileName, String className, String packageName) {
    final blocContent = TemplateLoader.load(
      'bloc',
      defaultContent: '''
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part '${fileName}_event.dart';
part '${fileName}_state.dart';

class ${className}Bloc extends Bloc<${className}Event, ${className}State> {
  ${className}Bloc() : super(${className}Initial()) {
    on<${className}LoadRequested>((event, emit) async {
      emit(${className}Loading());
      try {
        emit(${className}Loaded());
      } catch (e) {
        emit(${className}Error(message: e.toString()));
      }
    });
  }
}
''',
      replacements: {
        '{{className}}': className,
        '{{fileName}}': fileName,
        '{{packageName}}': packageName
      },
    );

    final eventContent = TemplateLoader.load(
      'bloc_event',
      defaultContent: '''
part of '${fileName}_bloc.dart';
abstract class ${className}Event extends Equatable {
  const ${className}Event();
  @override
  List<Object?> get props => [];
}
class ${className}LoadRequested extends ${className}Event {}
''',
      replacements: {'{{className}}': className, '{{fileName}}': fileName},
    );

    final stateContent = _buildStateContent(fileName, className, false);

    BaseGenerator.writeFile(p.join(dir, '${fileName}_bloc.dart'), blocContent);
    BaseGenerator.writeFile(
        p.join(dir, '${fileName}_event.dart'), eventContent);
    BaseGenerator.writeFile(
        p.join(dir, '${fileName}_state.dart'), stateContent);
  }

  void _generateCubit(
      String dir, String fileName, String className, String packageName) {
    final cubitContent = TemplateLoader.load(
      'cubit',
      defaultContent: '''
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part '${fileName}_state.dart';

class ${className}Cubit extends Cubit<${className}State> {
  ${className}Cubit() : super(${className}Initial());

  Future<void> loadData() async {
    emit(${className}Loading());
    try {
      emit(${className}Loaded());
    } catch (e) {
      emit(${className}Error(message: e.toString()));
    }
  }
}
''',
      replacements: {
        '{{className}}': className,
        '{{fileName}}': fileName,
        '{{packageName}}': packageName
      },
    );

    final stateContent = _buildStateContent(fileName, className, true);

    BaseGenerator.writeFile(
        p.join(dir, '${fileName}_cubit.dart'), cubitContent);
    BaseGenerator.writeFile(
        p.join(dir, '${fileName}_state.dart'), stateContent);
  }

  String _buildStateContent(String fileName, String className, bool isCubit) {
    final partOf = isCubit ? '${fileName}_cubit.dart' : '${fileName}_bloc.dart';
    return TemplateLoader.load(
      '${isCubit ? 'cubit' : 'bloc'}_state',
      defaultContent: '''
part of '$partOf';
abstract class ${className}State extends Equatable {
  const ${className}State();
  @override
  List<Object?> get props => [];
}
class ${className}Initial extends ${className}State {}
class ${className}Loading extends ${className}State {}
class ${className}Loaded extends ${className}State {}
class ${className}Error extends ${className}State {
  final String message;
  const ${className}Error({required this.message});
  @override
  List<Object?> get props => [message];
}
''',
      replacements: {'{{className}}': className, '{{fileName}}': fileName},
    );
  }
}
