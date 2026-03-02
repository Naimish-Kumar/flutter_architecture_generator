/// Configuration model for the Flutter Architecture Generator.
///
/// Stores the user's choices for architecture, state management, routing,
/// and optional features. Persisted to `.flutter_arch_gen.json`.
library;

/// Supported state management options.
enum StateManagement {
  /// BLoC pattern with events and states.
  bloc,

  /// Cubit pattern (simplified BLoC without events).
  cubit,

  /// Riverpod for reactive state management.
  riverpod,

  /// Provider with ChangeNotifier.
  provider,

  /// GetX reactive state management.
  getx;
}

/// Supported routing strategies.
enum Routing {
  /// GoRouter declarative routing.
  goRouter,

  /// AutoRoute code-generated routing.
  autoRoute,

  /// Navigator 1.0 with onGenerateRoute.
  navigator;
}

/// Supported architecture patterns.
enum Architecture {
  /// Clean Architecture with domain/data/presentation layers.
  clean,

  /// Model–View–ViewModel pattern.
  mvvm,

  /// BLoC Architecture with repos and blocs.
  bloc,

  /// GetX Architecture with controllers and bindings.
  getx,

  /// Provider / Simple Architecture.
  provider;

  /// Returns a human-readable display name.
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

/// Current config version for future migration support.
const int configVersion = 2;

/// Holds all configuration options for the generator.
class GeneratorConfig {
  /// Creates a [GeneratorConfig] with the required options.
  GeneratorConfig({
    required this.architecture,
    required this.stateManagement,
    required this.routing,
    required this.localization,
    required this.firebase,
    required this.tests,
    this.version = configVersion,
  });

  /// Creates a [GeneratorConfig] from a JSON map.
  ///
  /// Uses safe parsing with fallbacks for invalid enum values.
  factory GeneratorConfig.fromJson(Map<String, dynamic> json) {
    return GeneratorConfig(
      architecture: _parseEnum(
        Architecture.values,
        json['architecture'] as String?,
        Architecture.clean,
      ),
      stateManagement: _parseEnum(
        StateManagement.values,
        json['stateManagement'] as String?,
        StateManagement.bloc,
      ),
      routing: _parseEnum(
        Routing.values,
        json['routing'] as String?,
        Routing.goRouter,
      ),
      localization: json['localization'] as bool? ?? true,
      firebase: json['firebase'] as bool? ?? false,
      tests: json['tests'] as bool? ?? true,
      version: json['version'] as int? ?? 1,
    );
  }

  /// The selected architecture pattern.
  final Architecture architecture;

  /// The selected state management solution.
  final StateManagement stateManagement;

  /// The selected routing strategy.
  final Routing routing;

  /// Whether localization (L10n) support is enabled.
  final bool localization;

  /// Whether Firebase integration is enabled.
  final bool firebase;

  /// Whether test scaffolding is enabled.
  final bool tests;

  /// Config version for migration support.
  final int version;

  /// Converts this config to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
        'architecture': architecture.name,
        'stateManagement': stateManagement.name,
        'routing': routing.name,
        'localization': localization,
        'firebase': firebase,
        'tests': tests,
        'version': version,
      };

  /// Returns the pages directory path for the selected architecture.
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

  /// Returns the models directory path for the selected architecture.
  String getModelsDirectory() {
    switch (architecture) {
      case Architecture.clean:
        return 'data/models';
      default:
        return 'models';
    }
  }

  /// Returns the widgets directory path for the selected architecture.
  String getWidgetsDirectory() {
    switch (architecture) {
      case Architecture.clean:
        return 'presentation/widgets';
      default:
        return 'widgets';
    }
  }

  /// Returns the services directory path for the selected architecture.
  String getServicesDirectory() {
    switch (architecture) {
      case Architecture.clean:
        return 'data/services';
      default:
        return 'services';
    }
  }

  /// Returns the state management directory for the selected architecture.
  String getStateManagementDirectory() {
    switch (architecture) {
      case Architecture.clean:
        return 'presentation/${stateManagement.name}';
      case Architecture.mvvm:
        return 'view_models';
      case Architecture.bloc:
        return stateManagement == StateManagement.cubit ? 'cubit' : 'bloc';
      case Architecture.getx:
        return 'controllers';
      case Architecture.provider:
        return 'providers';
    }
  }

  /// Safely parses an enum value from a string with a fallback default.
  static T _parseEnum<T extends Enum>(
      List<T> values, String? name, T defaultValue) {
    if (name == null) return defaultValue;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return defaultValue;
  }
}
