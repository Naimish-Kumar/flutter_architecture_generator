import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// The `refactor` command — provides smart refactoring tools.
class RefactorCommand extends Command<int> {
  /// Creates a [RefactorCommand].
  RefactorCommand({required Logger logger}) : _logger = logger {
    addSubcommand(ModelRefactorCommand(logger: _logger));
  }

  @override
  String get description =>
      'Smart refactoring tools to safely update your code.';

  @override
  String get name => 'refactor';

  final Logger _logger;
}

/// The `refactor model` subcommand — safely injects fields into models.
class ModelRefactorCommand extends Command<int> {
  /// Creates a [ModelRefactorCommand].
  ModelRefactorCommand({required Logger logger}) : _logger = logger {
    argParser.addOption('name', abbr: 'n', help: 'The name of the new field');
    argParser.addOption('type',
        abbr: 't',
        help: 'The type of the new field (e.g. String, int)',
        defaultsTo: 'String');
    argParser.addFlag('required',
        abbr: 'r', help: 'Whether the field is required', defaultsTo: true);
  }

  @override
  String get description =>
      'Safely injects a new field into an existing Freezed model.';

  @override
  String get name => 'model';

  final Logger _logger;

  @override
  Future<int> run() async {
    final modelFile =
        argResults?.rest.isNotEmpty == true ? argResults!.rest.first : null;
    if (modelFile == null) {
      _logger.err('Please provide the path to the model file.');
      return ExitCode.usage.code;
    }

    final fieldName = argResults?['name'] as String?;
    final fieldType = argResults?['type'] as String?;
    final isRequired = argResults?['required'] == true;

    if (fieldName == null) {
      _logger.err('Please provide a field name using --name.');
      return ExitCode.usage.code;
    }

    final file = File(modelFile);
    if (!file.existsSync()) {
      _logger.err('File not found: $modelFile');
      return ExitCode.noInput.code;
    }

    final content = file.readAsStringSync();
    if (!content.contains('@freezed')) {
      _logger.err('This command only supports @freezed models.');
      return ExitCode.usage.code;
    }

    final progress =
        _logger.progress('Injecting field "$fieldName" into $modelFile...');

    try {
      final updatedContent =
          _injectField(content, fieldName, fieldType!, isRequired);
      file.writeAsStringSync(updatedContent);
      progress.complete('Field injected successfully! 💉');
      _logger.info(
          '💡 Remember to run `dart run build_runner build` to update the generated code.');
      return 0;
    } catch (e) {
      progress.fail('Failed to update model: $e');
      return 1;
    }
  }

  String _injectField(
      String content, String name, String type, bool isRequired) {
    // Regex to find the factory constructor of the Freezed class
    final regex =
        RegExp(r'const factory\s+\w+\s*\({\s*([\s\S]*?)\s*}\)\s*=\s*_\w+;');
    final match = regex.firstMatch(content);

    if (match == null) {
      throw Exception('Could not find a valid Freezed factory constructor.');
    }

    final existingFields = match.group(1)!;
    final prefix = isRequired ? 'required ' : '';
    final suffix = isRequired ? '' : '?';

    final newField = '    $prefix$type$suffix $name,';

    if (existingFields.contains('$name,')) {
      throw Exception('Field "$name" already exists in the model.');
    }

    final updatedFields =
        existingFields.isEmpty ? newField : '$existingFields\n$newField';

    return content.replaceFirst(match.group(0)!,
        match.group(0)!.replaceFirst(existingFields, updatedFields));
  }
}
