import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import '../utils/history_helper.dart';

/// The `undo` command — reverts the last command's file changes.
class UndoCommand extends Command<int> {
  /// Creates an [UndoCommand].
  UndoCommand({required Logger logger}) : _logger = logger {
    argParser.addOption('output',
        abbr: 'o', help: 'Custom output directory (monorepo support)');
  }

  final Logger _logger;

  @override
  String get name => 'undo';

  @override
  String get description => 'Revert the last destructive operation.';

  @override
  Future<int> run() async {
    final outputDir = argResults?['output'] as String?;
    final baseDir = outputDir ?? Directory.current.path;

    final lastEntry = HistoryHelper.getLastEntry(baseDir: baseDir);
    if (lastEntry == null) {
      _logger.err('No command history found to undo.');
      return ExitCode.usage.code;
    }

    _logger.info('🔄 Last command: ${lastEntry.command}');
    _logger.info('   Executed on: ${lastEntry.timestamp}');
    _logger.info('');

    final confirm = _logger.confirm(
      '⚠️  This will revert ${lastEntry.actions.length} file changes. Proceed?',
      defaultValue: false,
    );

    if (!confirm) {
      _logger.info('Cancelled.');
      return ExitCode.success.code;
    }

    final progress = _logger.progress('⏪ Rolling back changes...');

    try {
      // Revert in reverse order (stack)
      for (final action in lastEntry.actions.reversed) {
        final filePath = p.isAbsolute(action.path)
            ? action.path
            : p.join(baseDir, action.path);
        final file = File(filePath);

        if (action.action == 'CREATE') {
          // Reverting CREATE -> DELETE
          if (file.existsSync()) {
            file.deleteSync();
            progress.update(
                'Deleted created file: ${p.relative(filePath, from: baseDir)}');
          }
        } else if (action.action == 'MODIFY') {
          // Reverting MODIFY -> RESTORE OLD CONTENT
          if (action.oldContent != null) {
            file.writeAsStringSync(action.oldContent!);
            progress.update(
                'Restored modified file: ${p.relative(filePath, from: baseDir)}');
          }
        } else if (action.action == 'DELETE') {
          // Reverting DELETE -> RECREATE WITH OLD CONTENT
          if (action.oldContent != null) {
            Directory(p.dirname(filePath)).createSync(recursive: true);
            file.writeAsStringSync(action.oldContent!);
            progress.update(
                'Restored deleted file: ${p.relative(filePath, from: baseDir)}');
          }
        }
      }

      HistoryHelper.removeLastEntry(baseDir: baseDir);
      progress.complete('Undo successful! 🎉');
      return ExitCode.success.code;
    } catch (e) {
      progress.fail('Undo failed: $e');
      return ExitCode.software.code;
    }
  }
}
