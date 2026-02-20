enum StateManagement { bloc, riverpod, provider, getx }

enum Routing { goRouter, autoRoute, navigator }

class GeneratorConfig {
  final StateManagement stateManagement;
  final Routing routing;
  final bool localization;
  final bool firebase;
  final bool tests;

  GeneratorConfig({
    required this.stateManagement,
    required this.routing,
    required this.localization,
    required this.firebase,
    required this.tests,
  });

  Map<String, dynamic> toJson() => {
        'stateManagement': stateManagement.name,
        'routing': routing.name,
        'localization': localization,
        'firebase': firebase,
        'tests': tests,
      };

  factory GeneratorConfig.fromJson(Map<String, dynamic> json) =>
      GeneratorConfig(
        stateManagement: StateManagement.values
            .firstWhere((e) => e.name == json['stateManagement']),
        routing: Routing.values.firstWhere((e) => e.name == json['routing']),
        localization: json['localization'] as bool,
        firebase: json['firebase'] as bool,
        tests: json['tests'] as bool,
      );
}
