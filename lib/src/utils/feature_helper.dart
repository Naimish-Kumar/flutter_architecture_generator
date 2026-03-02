/// Feature generation helper.
///
/// Provides a unified entry point to generate features for any supported
/// architecture. Delegates to architecture-specific generators.
library;

import 'package:mason_logger/mason_logger.dart';
import '../models/generator_config.dart';
import '../generators/base_generator.dart';
import '../generators/clean_generator.dart';
import '../generators/mvvm_generator.dart';
import '../generators/bloc_generator.dart';
import '../generators/getx_generator.dart';
import '../generators/provider_generator.dart';
import '../utils/history_helper.dart';

/// Helper class to generate features by delegating to the appropriate
/// architecture-specific generator.
class FeatureHelper {
  /// Generates a feature for the given architecture and returns a list of actions.
  static Future<List<FileAction>> generateFeature(
    String featureName, {
    required GeneratorConfig config,
    Logger? logger,
    bool force = false,
    String? outputDir,
  }) async {
    final generator = _getGenerator(config.architecture);
    return generator.generateFeature(
      featureName,
      config: config,
      logger: logger,
      force: force,
      outputDir: outputDir,
    );
  }

  static BaseGenerator _getGenerator(Architecture architecture) {
    switch (architecture) {
      case Architecture.clean:
        return const CleanGenerator();
      case Architecture.mvvm:
        return const MvvmGenerator();
      case Architecture.bloc:
        return const BlocGenerator();
      case Architecture.getx:
        return const GetxGenerator();
      case Architecture.provider:
        return const ProviderGenerator();
    }
  }
}
