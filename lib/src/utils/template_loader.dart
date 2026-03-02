/// Modular template loading system.
///
/// Allows users to override default templates by placing custom `.template`
/// files in `.flutter_arch_gen/templates/`. Falls back to built-in defaults.
library;

import 'dart:io';
import 'package:path/path.dart' as p;

/// Loads templates from the project's custom template directory or falls
/// back to built-in defaults.
class TemplateLoader {
  /// The directory where custom templates are stored.
  static const String templateDirName = '.flutter_arch_gen/templates';

  /// Loads a template by [name].
  ///
  /// 1. Checks for a custom template at `.flutter_arch_gen/templates/<name>.template`
  /// 2. Falls back to [defaultContent] if no custom template exists.
  /// 3. Applies [replacements] to substitute placeholders.
  static String load(
    String name, {
    required String defaultContent,
    Map<String, String> replacements = const {},
    String? baseDir,
  }) {
    var content = _loadCustomTemplate(name, baseDir: baseDir) ?? defaultContent;

    // Apply replacements
    for (final entry in replacements.entries) {
      content = content.replaceAll(entry.key, entry.value);
    }

    return content;
  }

  /// Checks if a custom template exists for [name].
  static bool hasCustomTemplate(String name, {String? baseDir}) {
    final templateFile = _getTemplateFile(name, baseDir: baseDir);
    return templateFile.existsSync();
  }

  /// Lists all available custom templates.
  static List<String> listCustomTemplates({String? baseDir}) {
    final root = baseDir ?? Directory.current.path;
    final dir = Directory(p.join(root, templateDirName));
    if (!dir.existsSync()) return [];

    return dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.template'))
        .map((f) => p.basenameWithoutExtension(f.path))
        .toList()
      ..sort();
  }

  /// Creates the template directory and a sample template file.
  static void initTemplateDir({String? baseDir}) {
    final root = baseDir ?? Directory.current.path;
    final dir = Directory(p.join(root, templateDirName));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    // Create a README explaining the template system
    final readmePath = p.join(dir.path, 'README.md');
    if (!File(readmePath).existsSync()) {
      File(readmePath).writeAsStringSync('''
# Custom Templates

Place `.template` files here to override default code generation templates.

## Available Template Names

| Name | Used For |
|------|----------|
| `repository_interface` | Repository abstract class |
| `repository_impl` | Repository implementation |
| `remote_datasource` | Remote data source |
| `bloc` | BLoC class |
| `bloc_event` | BLoC events |
| `bloc_state` | BLoC states |
| `cubit` | Cubit class |
| `cubit_state` | Cubit states |
| `model` | Data model |
| `page` | Page widget |

## Placeholders

Use these placeholders in your templates:

- `{{className}}` — PascalCase name (e.g., `UserProfile`)
- `{{fileName}}` — snake_case name (e.g., `user_profile`)
- `{{packageName}}` — Package name from pubspec.yaml

## Example

Create `repository_interface.template`:

```dart
abstract class I{{className}}Repository {
  Future<List<{{className}}Entity>> getAll();
  Future<{{className}}Entity?> getById(String id);
  Future<void> create({{className}}Entity entity);
  Future<void> update({{className}}Entity entity);
  Future<void> delete(String id);
}
```
''');
    }

    // Create a sample template
    final samplePath =
        p.join(dir.path, 'repository_interface.template.example');
    if (!File(samplePath).existsSync()) {
      File(samplePath).writeAsStringSync('''
abstract class I{{className}}Repository {
  Future<List<dynamic>> getAll();
  Future<dynamic> getById(String id);
  Future<void> create(dynamic data);
  Future<void> update(String id, dynamic data);
  Future<void> delete(String id);
}
''');
    }
  }

  static String? _loadCustomTemplate(String name, {String? baseDir}) {
    final file = _getTemplateFile(name, baseDir: baseDir);
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
    return null;
  }

  static File _getTemplateFile(String name, {String? baseDir}) {
    final root = baseDir ?? Directory.current.path;
    return File(p.join(root, templateDirName, '$name.template'));
  }
}
