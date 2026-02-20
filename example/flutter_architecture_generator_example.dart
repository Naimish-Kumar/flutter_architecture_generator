/// # Flutter Architecture Generator — Example Usage
///
library;

///
/// This package is a CLI tool and is intended to be activated globally.
///
/// ## Installation
///
/// ```bash
/// dart pub global activate flutter_architecture_generator
/// ```
///
/// ## Quick Start
///
/// ### 1. Initialize a new project architecture
///
/// Navigate to your Flutter project root and run:
///
/// ```bash
/// flutter_arch_gen init
/// ```
///
/// This will interactively prompt you to select:
/// - **State Management**: BLoC, Riverpod, Provider, or GetX
/// - **Routing**: GoRouter or AutoRoute
/// - **Localization**: Enable/disable L10n support
/// - **Firebase**: Enable/disable Firebase integration
/// - **Tests**: Enable/disable test scaffolding
///
/// ### 2. Generate a feature
///
/// ```bash
/// flutter_arch_gen feature user_profile
/// ```
///
/// This creates a complete Clean Architecture feature with:
/// - Domain layer (entity, repository interface, use case)
/// - Data layer (model, data source, repository implementation)
/// - Presentation layer (page, state management)
/// - Auto-registers in DI container and router
///
/// ### 3. Generate a model
///
/// ```bash
/// flutter_arch_gen model Product -f shop
/// ```
///
/// Generates a Freezed model inside the specified feature.
///
/// ### 4. Generate a page
///
/// ```bash
/// flutter_arch_gen page settings -f settings
/// ```
///
/// Generates a StatelessWidget page and auto-registers it in the router.
///
/// ## Programmatic Usage
///
/// You can also use the runner programmatically:

import 'package:flutter_architecture_generator/flutter_architecture_generator.dart';

Future<void> main() async {
  // Create the CLI runner
  final runner = FlutterArchGenRunner();

  // Run with arguments — same as CLI usage
  // Example: Initialize a project
  await runner.run(['init']);

  // Example: Generate a feature
  await runner.run(['feature', 'products']);

  // Example: Generate a model inside a feature
  await runner.run(['model', 'Product', '-f', 'products']);

  // Example: Generate a standalone page
  await runner.run(['page', 'About']);
}
