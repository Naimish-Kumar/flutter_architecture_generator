// ignore_for_file: public_member_api_docs
import 'dart:io';
import 'package:yaml_edit/yaml_edit.dart';
import '../models/generator_config.dart';

class PubspecHelper {
  static String getPackageName() {
    final file = File('pubspec.yaml');
    if (!file.existsSync()) return 'flutter_project';
    final contents = file.readAsStringSync();
    final editor = YamlEditor(contents);
    try {
      final node = editor.parseAt(['name']);
      return node.value as String;
    } catch (_) {
      return 'flutter_project';
    }
  }

  static Future<void> addDependencies(GeneratorConfig config) async {
    final file = File('pubspec.yaml');
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
      default:
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
    final devDependencies = {
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
      _addDependency(editor, 'dependencies', entry.key, entry.value);
    }

    for (var entry in devDependencies.entries) {
      _addDependency(editor, 'dev_dependencies', entry.key, entry.value);
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

    file.writeAsStringSync(editor.toString());
  }

  static void _addDependency(
      YamlEditor editor, String section, String name, dynamic version) {
    try {
      editor.parseAt([section, name]);
      // If no error, dependency already exists.
    } catch (_) {
      editor.update([section, name], version);
    }
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
