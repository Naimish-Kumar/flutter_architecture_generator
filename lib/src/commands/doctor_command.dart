/// Command to diagnose project health.
///
/// Checks configuration, dependencies, DI registrations, and router
/// entries to identify potential issues in the generated project.
library;

import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import '../utils/file_helper.dart';

/// The `doctor` command — runs diagnostic checks on the project.
class DoctorCommand extends Command<int> {
  /// Creates a [DoctorCommand].
  DoctorCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  String get name => 'doctor';

  @override
  String get description => 'Run diagnostic checks on the generated project.';

  @override
  Future<int> run() async {
    _logger.info('');
    _logger.info('🩺 Flutter Architecture Generator — Doctor');
    _logger.info('');

    var issues = 0;
    var warnings = 0;

    // 1. Check pubspec.yaml
    final pubspecFile = File('pubspec.yaml');
    if (pubspecFile.existsSync()) {
      _logger.info('  ✅ pubspec.yaml found');
    } else {
      _logger.err('  ❌ pubspec.yaml not found — not a Flutter project root');
      issues++;
    }

    // 2. Check config file
    final config = FileHelper.loadConfig();
    final configFile =
        File(p.join(Directory.current.path, '.flutter_arch_gen.json'));
    if (configFile.existsSync() && config != null) {
      _logger.info('  ✅ .flutter_arch_gen.json found and valid');
      _logger.info('     Architecture: ${config.architecture.displayName}');
      _logger.info('     State Mgmt:   ${config.stateManagement.name}');
      _logger.info('     Routing:      ${config.routing.name}');
    } else if (configFile.existsSync()) {
      _logger.warn('  ⚠️  .flutter_arch_gen.json found but invalid');
      warnings++;
    } else {
      _logger.warn(
          '  ⚠️  .flutter_arch_gen.json not found — run `flutter_arch_gen init` first');
      warnings++;
    }

    // 3. Check features directory
    final featuresDir =
        Directory(p.join(Directory.current.path, 'lib', 'features'));
    if (featuresDir.existsSync()) {
      final features = featuresDir
          .listSync()
          .whereType<Directory>()
          .map((d) => p.basename(d.path))
          .toList();
      _logger.info('  ✅ lib/features/ found (${features.length} feature(s))');
    } else {
      _logger.warn('  ⚠️  lib/features/ not found');
      warnings++;
    }

    // 4. Check DI container
    final diFile = File(p.join('lib', 'di', 'injection_container.dart'));
    if (diFile.existsSync()) {
      final diContent = diFile.readAsStringSync();
      if (diContent.contains('GetIt')) {
        _logger.info('  ✅ injection_container.dart found with GetIt setup');
      } else {
        _logger.warn(
            '  ⚠️  injection_container.dart exists but may be misconfigured');
        warnings++;
      }

      // Check for orphaned registrations
      if (featuresDir.existsSync()) {
        final features = featuresDir
            .listSync()
            .whereType<Directory>()
            .map((d) => p.basename(d.path))
            .toSet();
        final orphanPattern = RegExp(r'features/(\w+)/');
        final diMatches = orphanPattern.allMatches(diContent);
        for (final match in diMatches) {
          final featureName = match.group(1)!;
          if (!features.contains(featureName)) {
            _logger.warn(
                '  ⚠️  DI references feature "$featureName" which does not exist');
            warnings++;
          }
        }
      }
    } else {
      _logger.warn('  ⚠️  injection_container.dart not found');
      warnings++;
    }

    // 5. Check router
    final routerFile = File(p.join('lib', 'routes', 'app_router.dart'));
    if (routerFile.existsSync()) {
      _logger.info('  ✅ app_router.dart found');

      // Check for orphaned routes
      if (featuresDir.existsSync()) {
        final features = featuresDir
            .listSync()
            .whereType<Directory>()
            .map((d) => p.basename(d.path))
            .toSet();
        final routerContent = routerFile.readAsStringSync();
        final routePattern = RegExp(r'features/(\w+)/');
        final routeMatches = routePattern.allMatches(routerContent);
        for (final match in routeMatches) {
          final featureName = match.group(1)!;
          if (!features.contains(featureName)) {
            _logger.warn(
                '  ⚠️  Router references feature "$featureName" which does not exist');
            warnings++;
          }
        }
      }
    } else {
      _logger.warn('  ⚠️  app_router.dart not found');
      warnings++;
    }

    // 6. Check core structure
    final coreChecks = {
      'lib/core/network/api_client.dart': 'API client',
      'lib/core/errors/failures.dart': 'Error handling',
      'lib/core/theme/app_theme.dart': 'Theme configuration',
      'lib/app.dart': 'App entry widget',
      'lib/main.dart': 'Main entry point',
    };

    for (final entry in coreChecks.entries) {
      final file = File(p.join(Directory.current.path, entry.key));
      if (file.existsSync()) {
        _logger.info('  ✅ ${entry.value} (${entry.key})');
      } else {
        _logger.warn('  ⚠️  ${entry.value} missing (${entry.key})');
        warnings++;
      }
    }

    // 7. Check env files
    final envDev = File(p.join(Directory.current.path, '.env.dev'));
    final envProd = File(p.join(Directory.current.path, '.env.prod'));
    if (envDev.existsSync() && envProd.existsSync()) {
      _logger.info('  ✅ Environment files (.env.dev, .env.prod)');
    } else {
      _logger.warn('  ⚠️  Missing environment file(s)');
      warnings++;
    }

    // Summary
    _logger.info('');
    if (issues == 0 && warnings == 0) {
      _logger.success('🎉 No issues found! Your project looks healthy.');
    } else {
      if (issues > 0) {
        _logger.err('Found $issues critical issue(s).');
      }
      if (warnings > 0) {
        _logger.warn('Found $warnings warning(s).');
      }
    }

    return issues > 0 ? ExitCode.software.code : ExitCode.success.code;
  }
}
