/// Provider Architecture feature generator.
///
/// Generates a feature following the Provider / Simple Architecture pattern
/// with Models, Providers, and Pages.
library;

import '../models/generator_config.dart';
import '../utils/template_loader.dart';
import 'base_generator.dart';
import '../utils/string_utils.dart';

/// Generates features following Provider Architecture.
class ProviderGenerator extends BaseGenerator {
  /// Creates a [ProviderGenerator].
  const ProviderGenerator();

  @override
  List<String> getDirectories(GeneratorConfig config) {
    return [
      'providers',
      'models',
      'pages',
      'widgets',
    ];
  }

  @override
  Future<void> generateFiles(
    String featureName,
    GeneratorConfig config,
    String packageName,
    String featurePath,
  ) async {
    final pascalName = StringUtils.toPascalCase(featureName);
    final snakeName = StringUtils.toSnakeCase(featureName);

    // 1. Model
    final modelContent = TemplateLoader.load(
      'provider_model',
      defaultContent: '''
class {{className}}Model {
  final int id;
  const {{className}}Model({required this.id});

  factory {{className}}Model.fromJson(Map<String, dynamic> json) {
    return {{className}}Model(id: json['id'] as int);
  }

  Map<String, dynamic> toJson() => {'id': id};
}
''',
      replacements: {
        '{{className}}': pascalName,
        '{{fileName}}': snakeName,
      },
    );
    BaseGenerator.writeFile(
        '$featurePath/models/${snakeName}_model.dart', modelContent);

    // 2. Provider
    final providerContent = TemplateLoader.load(
      'provider',
      defaultContent: '''
import 'package:flutter/material.dart';
import 'package:{{packageName}}/features/{{fileName}}/models/{{fileName}}_model.dart';

class {{className}}Provider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  {{className}}Model? _data;
  {{className}}Model? get data => _data;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      // TODO: Implement actual data fetching
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
''',
      replacements: {
        '{{className}}': pascalName,
        '{{fileName}}': snakeName,
        '{{packageName}}': packageName,
      },
    );
    BaseGenerator.writeFile(
        '$featurePath/providers/${snakeName}_provider.dart', providerContent);
  }
}
