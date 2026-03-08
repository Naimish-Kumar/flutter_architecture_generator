import 'package:flutter_architecture_generator/flutter_architecture_generator.dart';
import 'package:test/test.dart';
import 'package:flutter_architecture_generator/src/utils/string_utils.dart';
import 'package:flutter_architecture_generator/src/utils/validation_utils.dart';
import 'package:flutter_architecture_generator/src/models/generator_config.dart';

void main() {
  group('FlutterArchGenRunner', () {
    late FlutterArchGenRunner runner;

    setUp(() {
      runner = FlutterArchGenRunner();
    });

    test('runner has correct executable name', () {
      expect(runner.executableName, 'flutter_arch_gen');
    });

    test('runner has correct description', () {
      expect(runner.description, contains('CLI tool'));
    });

    test('runner has all expected commands', () {
      expect(
        runner.commands.keys,
        containsAll([
          'init',
          'feature',
          'model',
          'page',
          'widget',
          'service',
          'repository',
          'bloc',
          'screen',
          'api',
          'theme',
          'refactor',
          'delete',
          'update',
          'list',
          'doctor',
          'rename',
          'migrate',
          'undo',
        ]),
      );
    });

    test('runner supports --version flag', () {
      final argParser = runner.argParser;
      expect(argParser.options.containsKey('version'), isTrue);
    });
  });

  group('StringUtils', () {
    group('toSnakeCase', () {
      test('converts PascalCase to snake_case', () {
        expect(StringUtils.toSnakeCase('UserProfile'), 'user_profile');
      });

      test('converts camelCase to snake_case', () {
        expect(StringUtils.toSnakeCase('userProfile'), 'user_profile');
      });

      test('handles already snake_case', () {
        expect(StringUtils.toSnakeCase('user_profile'), 'user_profile');
      });

      test('handles single word', () {
        expect(StringUtils.toSnakeCase('Auth'), 'auth');
      });

      test('handles acronyms correctly', () {
        expect(StringUtils.toSnakeCase('HTMLParser'), 'html_parser');
      });

      test('handles acronyms in middle of word', () {
        expect(StringUtils.toSnakeCase('getHTTPResponse'), 'get_http_response');
      });

      test('handles single acronym', () {
        expect(StringUtils.toSnakeCase('API'), 'api');
      });

      test('handles empty string', () {
        expect(StringUtils.toSnakeCase(''), '');
      });

      test('collapses multiple underscores', () {
        expect(StringUtils.toSnakeCase('user__profile'), 'user_profile');
      });
    });

    group('toPascalCase', () {
      test('converts snake_case to PascalCase', () {
        expect(StringUtils.toPascalCase('user_profile'), 'UserProfile');
      });

      test('handles already PascalCase', () {
        expect(StringUtils.toPascalCase('UserProfile'), 'UserProfile');
      });

      test('handles single word', () {
        expect(StringUtils.toPascalCase('auth'), 'Auth');
      });

      test('handles empty string', () {
        expect(StringUtils.toPascalCase(''), '');
      });
    });

    group('toCamelCase', () {
      test('converts snake_case to camelCase', () {
        expect(StringUtils.toCamelCase('user_profile'), 'userProfile');
      });

      test('converts PascalCase to camelCase', () {
        expect(StringUtils.toCamelCase('UserProfile'), 'userProfile');
      });

      test('handles single word', () {
        expect(StringUtils.toCamelCase('auth'), 'auth');
      });

      test('handles empty string', () {
        expect(StringUtils.toCamelCase(''), '');
      });
    });
  });

  group('ValidationUtils', () {
    test('accepts valid names', () {
      expect(ValidationUtils.validateName('userProfile', 'Feature'), isNull);
      expect(ValidationUtils.validateName('auth', 'Feature'), isNull);
      expect(ValidationUtils.validateName('my_feature', 'Feature'), isNull);
      expect(ValidationUtils.validateName('Feature123', 'Feature'), isNull);
      expect(ValidationUtils.validateName('_private', 'Feature'), isNull);
    });

    test('rejects empty names', () {
      expect(ValidationUtils.validateName('', 'Feature'),
          contains('cannot be empty'));
    });

    test('rejects names with spaces', () {
      expect(ValidationUtils.validateName('user profile', 'Feature'),
          contains('invalid characters'));
    });

    test('rejects names with special characters', () {
      expect(ValidationUtils.validateName('user-profile', 'Feature'),
          contains('invalid characters'));
      expect(ValidationUtils.validateName('user.profile', 'Feature'),
          contains('invalid characters'));
      expect(ValidationUtils.validateName('user@profile', 'Feature'),
          contains('invalid characters'));
    });

    test('rejects names starting with numbers', () {
      expect(ValidationUtils.validateName('123feature', 'Feature'),
          contains('invalid characters'));
    });

    test('rejects Dart reserved keywords', () {
      expect(ValidationUtils.validateName('class', 'Feature'),
          contains('reserved keyword'));
      expect(ValidationUtils.validateName('import', 'Feature'),
          contains('reserved keyword'));
      expect(ValidationUtils.validateName('void', 'Feature'),
          contains('reserved keyword'));
      expect(ValidationUtils.validateName('return', 'Feature'),
          contains('reserved keyword'));
    });

    test('rejects names that are too long', () {
      final longName = 'a' * 101;
      expect(ValidationUtils.validateName(longName, 'Feature'),
          contains('too long'));
    });

    test('includes type name in error message', () {
      expect(ValidationUtils.validateName('', 'Model'), contains('Model'));
      expect(ValidationUtils.validateName('', 'Page'), contains('Page'));
      expect(ValidationUtils.validateName('', 'Widget'), contains('Widget'));
    });
  });

  group('GeneratorConfig', () {
    test('serializes to JSON correctly', () {
      final config = GeneratorConfig(
        architecture: Architecture.clean,
        stateManagement: StateManagement.bloc,
        routing: Routing.goRouter,
        localization: true,
        firebase: false,
        tests: true,
      );

      final json = config.toJson();
      expect(json['architecture'], 'clean');
      expect(json['stateManagement'], 'bloc');
      expect(json['routing'], 'goRouter');
      expect(json['localization'], true);
      expect(json['firebase'], false);
      expect(json['tests'], true);
      expect(json['version'], configVersion);
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'architecture': 'mvvm',
        'stateManagement': 'provider',
        'routing': 'autoRoute',
        'localization': false,
        'firebase': true,
        'tests': false,
      };

      final config = GeneratorConfig.fromJson(json);
      expect(config.architecture, Architecture.mvvm);
      expect(config.stateManagement, StateManagement.provider);
      expect(config.routing, Routing.autoRoute);
      expect(config.localization, false);
      expect(config.firebase, true);
      expect(config.tests, false);
    });

    test('handles cubit state management', () {
      final config = GeneratorConfig(
        architecture: Architecture.clean,
        stateManagement: StateManagement.cubit,
        routing: Routing.goRouter,
        localization: false,
        firebase: false,
        tests: true,
      );

      final json = config.toJson();
      expect(json['stateManagement'], 'cubit');

      final restored = GeneratorConfig.fromJson(json);
      expect(restored.stateManagement, StateManagement.cubit);
    });

    test('handles invalid enum values with defaults', () {
      final json = {
        'architecture': 'invalid_arch',
        'stateManagement': 'invalid_sm',
        'routing': 'invalid_routing',
        'localization': true,
        'firebase': false,
        'tests': true,
      };

      final config = GeneratorConfig.fromJson(json);
      expect(config.architecture, Architecture.clean);
      expect(config.stateManagement, StateManagement.bloc);
      expect(config.routing, Routing.goRouter);
    });

    test('handles null values with defaults', () {
      final config = GeneratorConfig.fromJson({});
      expect(config.architecture, Architecture.clean);
      expect(config.stateManagement, StateManagement.bloc);
      expect(config.routing, Routing.goRouter);
      expect(config.localization, true);
      expect(config.firebase, false);
      expect(config.tests, true);
    });

    test('handles config version migration', () {
      // Old config without version field
      final oldConfig = GeneratorConfig.fromJson({
        'architecture': 'clean',
        'stateManagement': 'bloc',
        'routing': 'goRouter',
      });
      expect(oldConfig.version, 1);

      // New config with version field
      final newConfig = GeneratorConfig.fromJson({
        'architecture': 'clean',
        'stateManagement': 'bloc',
        'routing': 'goRouter',
        'version': configVersion,
      });
      expect(newConfig.version, configVersion);
    });

    test('roundtrip JSON serialization', () {
      final original = GeneratorConfig(
        architecture: Architecture.getx,
        stateManagement: StateManagement.getx,
        routing: Routing.navigator,
        localization: false,
        firebase: true,
        tests: true,
      );

      final json = original.toJson();
      final restored = GeneratorConfig.fromJson(json);

      expect(restored.architecture, original.architecture);
      expect(restored.stateManagement, original.stateManagement);
      expect(restored.routing, original.routing);
      expect(restored.localization, original.localization);
      expect(restored.firebase, original.firebase);
      expect(restored.tests, original.tests);
      expect(restored.version, original.version);
    });

    group('getPagesDirectory', () {
      test('returns correct path for Clean Architecture', () {
        final config = GeneratorConfig(
          architecture: Architecture.clean,
          stateManagement: StateManagement.bloc,
          routing: Routing.goRouter,
          localization: false,
          firebase: false,
          tests: false,
        );
        expect(config.getPagesDirectory(), 'presentation/pages');
      });

      test('returns correct path for MVVM', () {
        final config = GeneratorConfig(
          architecture: Architecture.mvvm,
          stateManagement: StateManagement.provider,
          routing: Routing.goRouter,
          localization: false,
          firebase: false,
          tests: false,
        );
        expect(config.getPagesDirectory(), 'views/pages');
      });

      test('returns correct path for BLoC Architecture', () {
        final config = GeneratorConfig(
          architecture: Architecture.bloc,
          stateManagement: StateManagement.bloc,
          routing: Routing.goRouter,
          localization: false,
          firebase: false,
          tests: false,
        );
        expect(config.getPagesDirectory(), 'pages');
      });

      test('returns correct path for GetX', () {
        final config = GeneratorConfig(
          architecture: Architecture.getx,
          stateManagement: StateManagement.getx,
          routing: Routing.goRouter,
          localization: false,
          firebase: false,
          tests: false,
        );
        expect(config.getPagesDirectory(), 'views/pages');
      });

      test('returns correct path for Provider', () {
        final config = GeneratorConfig(
          architecture: Architecture.provider,
          stateManagement: StateManagement.provider,
          routing: Routing.goRouter,
          localization: false,
          firebase: false,
          tests: false,
        );
        expect(config.getPagesDirectory(), 'pages');
      });
    });

    group('getModelsDirectory', () {
      test('returns data/models for Clean Architecture', () {
        final config = GeneratorConfig(
          architecture: Architecture.clean,
          stateManagement: StateManagement.bloc,
          routing: Routing.goRouter,
          localization: false,
          firebase: false,
          tests: false,
        );
        expect(config.getModelsDirectory(), 'data/models');
      });

      test('returns models for other architectures', () {
        final config = GeneratorConfig(
          architecture: Architecture.mvvm,
          stateManagement: StateManagement.provider,
          routing: Routing.goRouter,
          localization: false,
          firebase: false,
          tests: false,
        );
        expect(config.getModelsDirectory(), 'models');
      });
    });

    group('getStateManagementDirectory', () {
      test('returns correct path for Clean + Bloc', () {
        final config = GeneratorConfig(
          architecture: Architecture.clean,
          stateManagement: StateManagement.bloc,
          routing: Routing.goRouter,
          localization: false,
          firebase: false,
          tests: false,
        );
        expect(config.getStateManagementDirectory(), 'presentation/bloc');
      });

      test('returns correct path for Clean + Cubit', () {
        final config = GeneratorConfig(
          architecture: Architecture.clean,
          stateManagement: StateManagement.cubit,
          routing: Routing.goRouter,
          localization: false,
          firebase: false,
          tests: false,
        );
        expect(config.getStateManagementDirectory(), 'presentation/cubit');
      });

      test('returns correct path for BLoC arch + Cubit', () {
        final config = GeneratorConfig(
          architecture: Architecture.bloc,
          stateManagement: StateManagement.cubit,
          routing: Routing.goRouter,
          localization: false,
          firebase: false,
          tests: false,
        );
        expect(config.getStateManagementDirectory(), 'cubit');
      });

      test('returns correct path for MVVM', () {
        final config = GeneratorConfig(
          architecture: Architecture.mvvm,
          stateManagement: StateManagement.provider,
          routing: Routing.goRouter,
          localization: false,
          firebase: false,
          tests: false,
        );
        expect(config.getStateManagementDirectory(), 'view_models');
      });
    });
  });

  group('Architecture', () {
    test('displayName returns correct values', () {
      expect(Architecture.clean.displayName, 'Clean Architecture');
      expect(Architecture.mvvm.displayName, 'MVVM');
      expect(Architecture.bloc.displayName, 'BLoC');
      expect(Architecture.getx.displayName, 'GetX');
      expect(Architecture.provider.displayName, 'Provider');
    });
  });

  group('StateManagement', () {
    test('includes cubit option', () {
      expect(StateManagement.values, contains(StateManagement.cubit));
    });

    test('all values are present', () {
      expect(StateManagement.values.length, 5);
      expect(
        StateManagement.values.map((e) => e.name),
        containsAll(['bloc', 'cubit', 'riverpod', 'provider', 'getx']),
      );
    });
  });

  group('Package version', () {
    test('packageVersion is defined', () {
      expect(packageVersion, isNotEmpty);
    });

    test('packageVersion follows semver format', () {
      expect(
        RegExp(r'^\d+\.\d+\.\d+').hasMatch(packageVersion),
        isTrue,
      );
    });

    test('packageVersion is 1.2.0', () {
      expect(packageVersion, '1.2.0');
    });
  });
}
