import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Represents a single file action in history.
class FileAction {

  /// Creates a [FileAction].
  FileAction({
    required this.path,
    required this.action,
    this.oldContent,
    this.newContent,
  });

  /// Creates a [FileAction] from a JSON map.
  factory FileAction.fromJson(Map<String, dynamic> json) => FileAction(
        path: json['path'] as String,
        action: json['action'] as String,
        oldContent: json['oldContent'] as String?,
        newContent: json['newContent'] as String?,
      );
  /// The path of the file.
  final String path;

  /// The action performed: CREATE, MODIFY, or DELETE.
  final String action;

  /// The original content (if MODIFY or DELETE).
  final String? oldContent;

  /// The new content (if CREATE or MODIFY).
  final String? newContent;

  /// Converts the [FileAction] to a JSON map.
  Map<String, dynamic> toJson() => {
        'path': path,
        'action': action,
        'oldContent': oldContent,
        'newContent': newContent,
      };
}

/// Represents a history entry for a command execution.
class HistoryEntry {

  /// Creates a [HistoryEntry].
  HistoryEntry({
    required this.timestamp,
    required this.command,
    required this.actions,
  });

  /// Creates a [HistoryEntry] from a JSON map.
  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        timestamp: DateTime.parse(json['timestamp'] as String),
        command: json['command'] as String,
        actions: (json['actions'] as List)
            .map((a) => FileAction.fromJson(a as Map<String, dynamic>))
            .toList(),
      );
  /// The time the command was executed.
  final DateTime timestamp;

  /// The command string that was executed.
  final String command;

  /// The list of file actions performed by the command.
  final List<FileAction> actions;

  /// Converts the [HistoryEntry] to a JSON map.
  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'command': command,
        'actions': actions.map((a) => a.toJson()).toList(),
      };
}

/// Helper to manage command history and undo operations.
class HistoryHelper {
  static const String _historyFile = '.flutter_arch_gen_history.json';

  /// Saves a new history entry.
  static void saveEntry(HistoryEntry entry, {String? baseDir}) {
    final historyPath = p.join(baseDir ?? Directory.current.path, _historyFile);
    final file = File(historyPath);

    List<HistoryEntry> history = [];
    if (file.existsSync()) {
      try {
        final json = jsonDecode(file.readAsStringSync()) as List;
        history = json
            .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    history.add(entry);

    // Keep only last 10 entries to avoid bloat
    if (history.length > 10) {
      history.removeAt(0);
    }

    file.writeAsStringSync(jsonEncode(history.map((e) => e.toJson()).toList()));
  }

  /// Gets the last history entry.
  static HistoryEntry? getLastEntry({String? baseDir}) {
    final historyPath = p.join(baseDir ?? Directory.current.path, _historyFile);
    final file = File(historyPath);
    if (!file.existsSync()) return null;

    try {
      final json = jsonDecode(file.readAsStringSync()) as List;
      if (json.isEmpty) return null;
      return HistoryEntry.fromJson(json.last as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Removes the last history entry.
  static void removeLastEntry({String? baseDir}) {
    final historyPath = p.join(baseDir ?? Directory.current.path, _historyFile);
    final file = File(historyPath);
    if (!file.existsSync()) return;

    try {
      final json = jsonDecode(file.readAsStringSync()) as List;
      if (json.isEmpty) return;
      json.removeLast();
      file.writeAsStringSync(jsonEncode(json));
    } catch (_) {}
  }
}
