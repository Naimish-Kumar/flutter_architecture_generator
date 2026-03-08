/// BLoC Architecture feature generator.
///
/// Generates a feature following the BLoC Architecture pattern
/// with Models, Repositories, Bloc, and Pages.
library;

import '../models/generator_config.dart';
import '../utils/string_utils.dart';
import '../utils/template_loader.dart';
import 'base_generator.dart';

/// Generates features following BLoC Architecture.
class BlocGenerator extends BaseGenerator {
  /// Creates a [BlocGenerator].
  const BlocGenerator();

  @override
  List<String> getDirectories(GeneratorConfig config) {
    return [
      'bloc',
      'models',
      'repositories',
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
      'bloc_model',
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

    // 2. Repository
    final repoContent = TemplateLoader.load(
      'bloc_repository',
      defaultContent: '''
import 'package:{{packageName}}/core/network/api_client.dart';
import 'package:{{packageName}}/features/{{fileName}}/models/{{fileName}}_model.dart';

class {{className}}Repository {
  final ApiClient apiClient;
  {{className}}Repository(this.apiClient);

  Future<{{className}}Model> getData() async {
    final response = await apiClient.dio.get('/{{fileName}}');
    return {{className}}Model.fromJson(response.data);
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
        '$featurePath/repositories/${snakeName}_repository.dart', repoContent);

    // 3. Bloc
    final blocContent = TemplateLoader.load(
      'bloc',
      defaultContent: '''
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:{{packageName}}/features/{{fileName}}/repositories/{{fileName}}_repository.dart';
import 'package:{{packageName}}/features/{{fileName}}/models/{{fileName}}_model.dart';

part '{{fileName}}_event.dart';
part '{{fileName}}_state.dart';

class {{className}}Bloc extends Bloc<{{className}}Event, {{className}}State> {
  final {{className}}Repository repository;

  {{className}}Bloc(this.repository) : super({{className}}Initial()) {
    on<Load{{className}}Event>((event, emit) async {
      emit({{className}}Loading());
      try {
        final data = await repository.getData();
        emit({{className}}Loaded(data));
      } catch (e) {
        emit({{className}}Error(e.toString()));
      }
    });
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
        '$featurePath/bloc/${snakeName}_bloc.dart', blocContent);

    // 4. Event
    final eventContent = TemplateLoader.load(
      'bloc_event',
      defaultContent: '''
part of '{{fileName}}_bloc.dart';

abstract class {{className}}Event extends Equatable {
  const {{className}}Event();

  @override
  List<Object> get props => [];
}

class Load{{className}}Event extends {{className}}Event {}
''',
      replacements: {
        '{{className}}': pascalName,
        '{{fileName}}': snakeName,
      },
    );
    BaseGenerator.writeFile(
        '$featurePath/bloc/${snakeName}_event.dart', eventContent);

    // 5. State
    final stateContent = TemplateLoader.load(
      'bloc_state',
      defaultContent: '''
part of '{{fileName}}_bloc.dart';

abstract class {{className}}State extends Equatable {
  const {{className}}State();
  
  @override
  List<Object> get props => [];
}

class {{className}}Initial extends {{className}}State {}
class {{className}}Loading extends {{className}}State {}
class {{className}}Loaded extends {{className}}State {
  final {{className}}Model data;
  const {{className}}Loaded(this.data);

  @override
  List<Object> get props => [data];
}
class {{className}}Error extends {{className}}State {
  final String message;
  const {{className}}Error(this.message);

  @override
  List<Object> get props => [message];
}
''',
      replacements: {
        '{{className}}': pascalName,
        '{{fileName}}': snakeName,
      },
    );
    BaseGenerator.writeFile(
        '$featurePath/bloc/${snakeName}_state.dart', stateContent);
  }
}
