/// MVVM Architecture feature generator.
///
/// Generates a feature following the Model–View–ViewModel pattern
/// with Services, ViewModels, and Views.
library;

import '../models/generator_config.dart';
import '../utils/string_utils.dart';
import '../utils/template_loader.dart';
import 'base_generator.dart';

/// Generates features following MVVM architecture.
class MvvmGenerator extends BaseGenerator {
  /// Creates a [MvvmGenerator].
  const MvvmGenerator();

  @override
  List<String> getDirectories(GeneratorConfig config) {
    return [
      'models',
      'views/pages',
      'views/widgets',
      'view_models',
      'services',
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

    final replacements = {
      '{{className}}': pascalName,
      '{{fileName}}': snakeName,
      '{{packageName}}': packageName,
    };

    // 1. Model
    final modelContent = TemplateLoader.load(
      'mvvm_model',
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
      replacements: replacements,
    );
    BaseGenerator.writeFile(
        '$featurePath/models/${snakeName}_model.dart', modelContent);

    // 2. Service
    final serviceContent = TemplateLoader.load(
      'mvvm_service',
      defaultContent: '''
import 'package:{{packageName}}/core/network/api_client.dart';
import 'package:{{packageName}}/features/{{fileName}}/models/{{fileName}}_model.dart';

class {{className}}Service {
  final ApiClient apiClient;
  {{className}}Service(this.apiClient);

  Future<{{className}}Model> fetch{{className}}() async {
    final response = await apiClient.dio.get('/{{fileName}}');
    return {{className}}Model.fromJson(response.data);
  }
}
''',
      replacements: replacements,
    );
    BaseGenerator.writeFile(
        '$featurePath/services/${snakeName}_service.dart', serviceContent);

    // 3. ViewModel
    final viewModelContent = TemplateLoader.load(
      'mvvm_view_model',
      defaultContent: '''
import 'package:flutter/material.dart';
import 'package:{{packageName}}/features/{{fileName}}/services/{{fileName}}_service.dart';
import 'package:{{packageName}}/features/{{fileName}}/models/{{fileName}}_model.dart';

class {{className}}ViewModel extends ChangeNotifier {
  final {{className}}Service service;
  {{className}}ViewModel(this.service);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  {{className}}Model? _data;
  {{className}}Model? get data => _data;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _data = await service.fetch{{className}}();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
''',
      replacements: replacements,
    );
    BaseGenerator.writeFile(
        '$featurePath/view_models/${snakeName}_view_model.dart',
        viewModelContent);
  }
}
