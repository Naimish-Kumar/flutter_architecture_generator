/// Pubspec.yaml helper utilities.
///
/// Reads and modifies the target Flutter project's `pubspec.yaml` file
/// to add required dependencies and configuration.
library;

import 'dart:io';
import 'package:yaml_edit/yaml_edit.dart';
import 'package:path/path.dart' as p;
import '../models/generator_config.dart';
import '../generators/base_generator.dart';

/// Provides utilities for reading and modifying `pubspec.yaml`.
class PubspecHelper {
  /// Returns the package name from `pubspec.yaml`.
  ///
  /// Throws a [StateError] if no `pubspec.yaml` is found in the current
  /// directory, prompting the user to run the command from a Flutter project.
  static String getPackageName({String? baseDir}) {
    final path =
        baseDir != null ? p.join(baseDir, 'pubspec.yaml') : 'pubspec.yaml';
    final file = File(path);
    if (!file.existsSync()) {
      throw StateError(
        'No pubspec.yaml found in the current directory.\n'
        'Please run this command from the root of a Flutter project.',
      );
    }
    final contents = file.readAsStringSync();
    final editor = YamlEditor(contents);
    try {
      final node = editor.parseAt(['name']);
      return node.value as String;
    } catch (_) {
      throw StateError(
        'Could not read the package name from pubspec.yaml.\n'
        'Ensure your pubspec.yaml has a valid "name" field.',
      );
    }
  }

  /// Adds the required dependencies to `pubspec.yaml` based on [config].
  ///
  /// If [forceUpdate] is true, existing dependency versions will be updated
  /// to the latest bundled versions. Otherwise, existing deps are preserved.
  static Future<void> addDependencies(GeneratorConfig config,
      {bool forceUpdate = false, String? baseDir}) async {
    final path =
        baseDir != null ? p.join(baseDir, 'pubspec.yaml') : 'pubspec.yaml';
    final file = File(path);
    if (!file.existsSync()) return;

    final contents = file.readAsStringSync();
    final editor = YamlEditor(contents);

    // Common dependencies
    final dependencies = <String, dynamic>{
      'dio': '^5.9.1',
      'get_it': '^9.2.1',
      'freezed_annotation': '^3.1.0',
      'json_annotation': '^4.11.0',
      'flutter_dotenv': '^6.0.0',
    };

    // State management dependencies
    switch (config.stateManagement) {
      case StateManagement.bloc:
      case StateManagement.cubit:
        dependencies['flutter_bloc'] = '^9.1.1';
        dependencies['equatable'] = '^2.0.8';
        break;
      case StateManagement.riverpod:
        dependencies['flutter_riverpod'] = '^3.2.1';
        break;
      case StateManagement.provider:
        dependencies['provider'] = '^6.1.5';
        break;
      case StateManagement.getx:
        dependencies['get'] = '^4.7.3';
        break;
    }

    // Routing dependencies
    switch (config.routing) {
      case Routing.goRouter:
        dependencies['go_router'] = '^17.1.0';
        break;
      case Routing.autoRoute:
        dependencies['auto_route'] = '^11.1.0';
        break;
      case Routing.navigator:
        break;
    }

    if (config.firebase) {
      dependencies['firebase_core'] = '^4.4.0';
    }

    if (config.localization) {
      dependencies['flutter_localizations'] = {'sdk': 'flutter'};
      dependencies['intl'] = '^0.20.2';
    }

    // Dev dependencies
    final devDependencies = <String, String>{
      'build_runner': '^2.11.1',
      'freezed': '^3.0.6',
      'json_serializable': '^6.13.0',
    };

    if (config.routing == Routing.autoRoute) {
      devDependencies['auto_route_generator'] = '^11.0.1';
    }

    // Ensure sections are maps
    _ensureMap(editor, 'dependencies');
    _ensureMap(editor, 'dev_dependencies');

    // Apply changes
    for (var entry in dependencies.entries) {
      _addDependency(editor, 'dependencies', entry.key, entry.value,
          forceUpdate: forceUpdate);
    }

    for (var entry in devDependencies.entries) {
      _addDependency(editor, 'dev_dependencies', entry.key, entry.value,
          forceUpdate: forceUpdate);
    }

    // Flutter section
    _ensureMap(editor, 'flutter');

    if (config.localization) {
      editor.update(['flutter', 'generate'], true);
    }

    // Assets
    final assets = [
      'assets/images/',
      'assets/translations/',
    ];
    editor.update(['flutter', 'assets'], assets);

    BaseGenerator.writeFile(path, editor.toString());
  }

  /// Removes dependencies from `pubspec.yaml` based on [config].
  static Future<void> removeDependencies(GeneratorConfig config,
      {String? baseDir}) async {
    final path =
        baseDir != null ? p.join(baseDir, 'pubspec.yaml') : 'pubspec.yaml';
    final file = File(path);
    if (!file.existsSync()) return;

    final contents = file.readAsStringSync();
    final editor = YamlEditor(contents);

    final depsToRemove = <String>[];
    final devDepsToRemove = <String>[];

    // State management dependencies
    switch (config.stateManagement) {
      case StateManagement.bloc:
      case StateManagement.cubit:
        depsToRemove.addAll(['flutter_bloc', 'equatable']);
        break;
      case StateManagement.riverpod:
        depsToRemove.add('flutter_riverpod');
        break;
      case StateManagement.provider:
        depsToRemove.add('provider');
        break;
      case StateManagement.getx:
        depsToRemove.add('get');
        break;
    }

    // Routing dependencies
    switch (config.routing) {
      case Routing.goRouter:
        depsToRemove.add('go_router');
        break;
      case Routing.autoRoute:
        depsToRemove.add('auto_route');
        devDepsToRemove.add('auto_route_generator');
        break;
      case Routing.navigator:
        break;
    }

    for (final name in depsToRemove) {
      _removeDependency(editor, 'dependencies', name);
    }
    for (final name in devDepsToRemove) {
      _removeDependency(editor, 'dev_dependencies', name);
    }

    BaseGenerator.writeFile(path, editor.toString());
  }

  /// Adds or updates a dependency in the given [section].
  ///
  /// If [forceUpdate] is true, existing versions are overwritten.
  static void _addDependency(
      YamlEditor editor, String section, String name, dynamic version,
      {bool forceUpdate = false}) {
    try {
      editor.parseAt([section, name]);
      // Dependency already exists — update only if forced.
      if (forceUpdate) {
        editor.update([section, name], version);
      }
    } catch (_) {
      editor.update([section, name], version);
    }
  }

  /// Removes a dependency from the given [section].
  static void _removeDependency(
      YamlEditor editor, String section, String name) {
    try {
      editor.remove([section, name]);
    } catch (_) {
      // Dependency doesn't exist, ignore
    }
  }

  /// Adds custom dependencies to `pubspec.yaml`.
  static void addCustomDependencies(Map<String, dynamic> dependencies,
      {String? baseDir}) {
    final path =
        baseDir != null ? p.join(baseDir, 'pubspec.yaml') : 'pubspec.yaml';
    final file = File(path);
    if (!file.existsSync()) return;

    final contents = file.readAsStringSync();
    final editor = YamlEditor(contents);

    _ensureMap(editor, 'dependencies');

    for (var entry in dependencies.entries) {
      _addDependency(editor, 'dependencies', entry.key, entry.value);
    }

    BaseGenerator.writeFile(path, editor.toString());
  }

  /// Removes custom dependencies from `pubspec.yaml`.
  static void removeCustomDependencies(List<String> dependencies,
      {String? baseDir}) {
    final path =
        baseDir != null ? p.join(baseDir, 'pubspec.yaml') : 'pubspec.yaml';
    final file = File(path);
    if (!file.existsSync()) return;

    final contents = file.readAsStringSync();
    final editor = YamlEditor(contents);

    for (var name in dependencies) {
      _removeDependency(editor, 'dependencies', name);
    }

    BaseGenerator.writeFile(path, editor.toString());
  }

  static void _ensureMap(YamlEditor editor, String key) {
    try {
      final node = editor.parseAt([key]);
      if (node.value is! Map) {
        editor.update([key], {});
      }
    } catch (_) {
      editor.update([key], {});
    }
  }
}
