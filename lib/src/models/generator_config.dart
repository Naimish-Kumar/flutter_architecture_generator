// ignore_for_file: public_member_api_docs
enum StateManagement { bloc, riverpod, provider, getx }

enum Routing { goRouter, autoRoute, navigator }

enum Architecture {
  clean,
  mvvm,
  bloc,
  getx,
  provider;

  String get displayName {
    switch (this) {
      case Architecture.clean:
        return 'Clean Architecture';
      case Architecture.mvvm:
        return 'MVVM';
      case Architecture.bloc:
        return 'BLoC';
      case Architecture.getx:
        return 'GetX';
      case Architecture.provider:
        return 'Provider';
    }
  }
}

class GeneratorConfig {
  GeneratorConfig({
    required this.architecture,
    required this.stateManagement,
    required this.routing,
    required this.localization,
    required this.firebase,
    required this.tests,
  });

  factory GeneratorConfig.fromJson(Map<String, dynamic> json) =>
      GeneratorConfig(
        architecture: Architecture.values
            .firstWhere((e) => e.name == (json['architecture'] ?? 'clean')),
        stateManagement: StateManagement.values
            .firstWhere((e) => e.name == json['stateManagement']),
        routing: Routing.values.firstWhere((e) => e.name == json['routing']),
        localization: json['localization'] as bool,
        firebase: json['firebase'] as bool,
        tests: json['tests'] as bool,
      );
  final Architecture architecture;
  final StateManagement stateManagement;
  final Routing routing;
  final bool localization;
  final bool firebase;
  final bool tests;

  Map<String, dynamic> toJson() => {
        'architecture': architecture.name,
        'stateManagement': stateManagement.name,
        'routing': routing.name,
        'localization': localization,
        'firebase': firebase,
        'tests': tests,
      };

  String getPagesDirectory() {
    switch (architecture) {
      case Architecture.clean:
        return 'presentation/pages';
      case Architecture.mvvm:
      case Architecture.getx:
        return 'views/pages';
      case Architecture.bloc:
      case Architecture.provider:
        return 'pages';
    }
  }

  String getModelsDirectory() {
    switch (architecture) {
      case Architecture.clean:
        return 'data/models';
      default:
        return 'models';
    }
  }
}
