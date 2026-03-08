/// State management file generation logic.
///
/// Generates state management files (BLoC, Riverpod, Provider, GetX)
/// for each feature based on the architecture and config.
library;

import '../models/generator_config.dart';
import '../utils/string_utils.dart';
import '../utils/template_loader.dart';
import 'base_generator.dart';

/// Generates state management files based on the config.
class StateManagementGenerator {
  /// Generates state management files for the given feature.
  static void generate(
      String path, String name, GeneratorConfig config, String packageName) {
    final pascalName = StringUtils.toPascalCase(name);
    final snakeName = StringUtils.toSnakeCase(name);
    final camelName = StringUtils.toCamelCase(name);

    String smPath;

    switch (config.architecture) {
      case Architecture.clean:
        smPath = '$path/presentation/${config.stateManagement.name}';
        break;
      case Architecture.mvvm:
        smPath = '$path/view_models';
        break;
      case Architecture.bloc:
        smPath = '$path/bloc';
        break;
      case Architecture.getx:
        smPath = '$path/controllers';
        break;
      case Architecture.provider:
        smPath = '$path/providers';
        break;
    }

    switch (config.stateManagement) {
      case StateManagement.bloc:
        _generateBloc(smPath, snakeName, pascalName, config, packageName);
        break;
      case StateManagement.cubit:
        _generateCubit(smPath, snakeName, pascalName, config, packageName);
        break;
      case StateManagement.riverpod:
        _generateRiverpod(smPath, snakeName, camelName);
        break;
      case StateManagement.provider:
        _generateProvider(smPath, snakeName, pascalName);
        break;
      case StateManagement.getx:
        _generateGetx(smPath, snakeName, pascalName);
        break;
    }
  }

  static void _generateBloc(String smPath, String snakeName, String pascalName,
      GeneratorConfig config, String packageName) {
    String blocImport;
    String depType;
    String depField;
    String usageLine;
    if (config.architecture == Architecture.clean) {
      blocImport =
          "import 'package:$packageName/features/$snakeName/domain/usecases/get_${snakeName}_usecase.dart';";
      depType = 'Get${pascalName}UseCase';
      depField = 'get${pascalName}UseCase';
      usageLine =
          'final data = await $depField();\n        emit(${pascalName}Loaded(data: data.id.toString()));';
    } else {
      blocImport =
          "import 'package:$packageName/features/$snakeName/repositories/${snakeName}_repository.dart';";
      depType = '${pascalName}Repository';
      depField = 'repository';
      usageLine =
          'final data = await $depField.getData();\n        emit(${pascalName}Loaded(data: data.toString()));';
    }

    final blocContent = TemplateLoader.load(
      'bloc',
      defaultContent: '''
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
{{blocImport}}

part '{{fileName}}_event.dart';
part '{{fileName}}_state.dart';

class {{className}}Bloc extends Bloc<{{className}}Event, {{className}}State> {
  final {{depType}} {{depField}};
  {{className}}Bloc(this.{{depField}}) : super({{className}}Initial()) {
    on<Get{{className}}DataEvent>((event, emit) async {
      emit({{className}}Loading());
      try {
        {{usageLine}}
      } catch (e) {
        emit({{className}}Error(message: e.toString()));
      }
    });
  }
}
''',
      replacements: {
        '{{className}}': pascalName,
        '{{fileName}}': snakeName,
        '{{packageName}}': packageName,
        '{{blocImport}}': blocImport,
        '{{depType}}': depType,
        '{{depField}}': depField,
        '{{usageLine}}': usageLine,
      },
    );

    final eventContent = TemplateLoader.load(
      'bloc_event',
      defaultContent: '''
part of '{{fileName}}_bloc.dart';

abstract class {{className}}Event extends Equatable {
  const {{className}}Event();

  @override
  List<Object> get props => [];
}

class Get{{className}}DataEvent extends {{className}}Event {}
''',
      replacements: {
        '{{className}}': pascalName,
        '{{fileName}}': snakeName,
      },
    );

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
  final String data;
  const {{className}}Loaded({required this.data});

  @override
  List<Object> get props => [data];
}
class {{className}}Error extends {{className}}State {
  final String message;
  const {{className}}Error({required this.message});

  @override
  List<Object> get props => [message];
}
''',
      replacements: {
        '{{className}}': pascalName,
        '{{fileName}}': snakeName,
      },
    );

    BaseGenerator.writeFile('$smPath/${snakeName}_bloc.dart', blocContent);
    BaseGenerator.writeFile('$smPath/${snakeName}_event.dart', eventContent);
    BaseGenerator.writeFile('$smPath/${snakeName}_state.dart', stateContent);
  }

  static void _generateCubit(String smPath, String snakeName, String pascalName,
      GeneratorConfig config, String packageName) {
    String cubitImport;
    String depType;
    String depField;
    String usageLine;
    if (config.architecture == Architecture.clean) {
      cubitImport =
          "import 'package:$packageName/features/$snakeName/domain/usecases/get_${snakeName}_usecase.dart';";
      depType = 'Get${pascalName}UseCase';
      depField = 'get${pascalName}UseCase';
      usageLine =
          'final data = await $depField();\n      emit(${pascalName}Loaded(data: data.id.toString()));';
    } else {
      cubitImport =
          "import 'package:$packageName/features/$snakeName/repositories/${snakeName}_repository.dart';";
      depType = '${pascalName}Repository';
      depField = 'repository';
      usageLine =
          'final data = await $depField.getData();\n      emit(${pascalName}Loaded(data: data.toString()));';
    }

    final cubitContent = TemplateLoader.load(
      'cubit',
      defaultContent: '''
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
{{cubitImport}}

part '{{fileName}}_state.dart';

class {{className}}Cubit extends Cubit<{{className}}State> {
  final {{depType}} {{depField}};
  {{className}}Cubit(this.{{depField}}) : super({{className}}Initial()) {}

  Future<void> fetchData() async {
    emit({{className}}Loading());
    try {
      {{usageLine}}
    } catch (e) {
      emit({{className}}Error(message: e.toString()));
    }
  }
}
''',
      replacements: {
        '{{className}}': pascalName,
        '{{fileName}}': snakeName,
        '{{packageName}}': packageName,
        '{{cubitImport}}': cubitImport,
        '{{depType}}': depType,
        '{{depField}}': depField,
        '{{usageLine}}': usageLine,
      },
    );

    final stateContent = TemplateLoader.load(
      'cubit_state',
      defaultContent: '''
part of '{{fileName}}_cubit.dart';

abstract class {{className}}State extends Equatable {
  const {{className}}State();
  
  @override
  List<Object> get props => [];
}

class {{className}}Initial extends {{className}}State {}
class {{className}}Loading extends {{className}}State {}
class {{className}}Loaded extends {{className}}State {
  final String data;
  const {{className}}Loaded({required this.data});

  @override
  List<Object> get props => [data];
}
class {{className}}Error extends {{className}}State {
  final String message;
  const {{className}}Error({required this.message});

  @override
  List<Object> get props => [message];
}
''',
      replacements: {
        '{{className}}': pascalName,
        '{{fileName}}': snakeName,
      },
    );

    BaseGenerator.writeFile('$smPath/${snakeName}_cubit.dart', cubitContent);
    BaseGenerator.writeFile('$smPath/${snakeName}_state.dart', stateContent);
  }

  static void _generateRiverpod(
      String smPath, String snakeName, String camelName) {
    final content = TemplateLoader.load(
      'riverpod',
      defaultContent: '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

final {{camelName}}Provider = FutureProvider<String>((ref) async {
  // TODO: Replace with actual data fetching logic.
  return 'Initial Data';
});
''',
      replacements: {
        '{{camelName}}': camelName,
        '{{fileName}}': snakeName,
      },
    );
    BaseGenerator.writeFile('$smPath/${snakeName}_provider.dart', content);
  }

  static void _generateProvider(
      String smPath, String snakeName, String pascalName) {
    final content = TemplateLoader.load(
      'provider',
      defaultContent: '''
import 'package:flutter/material.dart';

class {{className}}Provider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // TODO: Add implementation
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
      },
    );
    BaseGenerator.writeFile('$smPath/${snakeName}_provider.dart', content);
  }

  static void _generateGetx(
      String smPath, String snakeName, String pascalName) {
    final content = TemplateLoader.load(
      'getx_controller',
      defaultContent: '''
import 'package:get/get.dart';

class {{className}}Controller extends GetxController {
  final isLoading = false.obs;
  final data = Rxn<String>();
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchData() async {
    isLoading.value = true;
    _errorMessage = null;
    try {
      // TODO: Fetch from API
      data.value = 'Sample Data';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
''',
      replacements: {
        '{{className}}': pascalName,
        '{{fileName}}': snakeName,
      },
    );
    BaseGenerator.writeFile('$smPath/${snakeName}_controller.dart', content);
  }
}
