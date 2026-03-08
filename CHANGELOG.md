## 1.2.3

### 🐞 Bug Fixes
- **Constructor Syntax**: Fixed syntax errors in generated `app.dart` and Chat module where non-const constructors were missing required bodies `{}`.
- **AutoRoute Compatibility**: Ensured `MyApp` constructor correctly handles the presence of the `AppRouter` final field.

## 1.2.2

### 🐞 Bug Fixes
- **Template Interpolation**: Fixed syntax errors in generated Use Cases and Riverpod providers caused by incorrect string escaping in templates.
- **Base Architecture**: Resolved "const" and "title" interpolation errors in the base `app.dart` and `main.dart` files.

## 1.2.1

### 📦 Automated Dependency Management
- **Smart Pubspec Updates**: Project initialization and feature generation now automatically add required dependencies to `pubspec.yaml`.
- **Automatic Cleanup**: Deleting features (like the Chat module) now automatically removes their specific dependencies from `pubspec.yaml`.
- **Plan Preview**: Dependency changes are now included in the execution plan for review before applying.

## 1.2.0
- **Interactive CLI Prompts**: `init` command now uses high-end interactive selection for architecture and state management if flags are omitted.
- **Smart Code Refactoring**: New `refactor model` command to safely inject fields into existing Freezed models without overwriting logic.

### 🎨 Design System & Theming
- **Theme Generator**: New `theme` command to generate a full premium Design System with Dark/Light mode, semantic tokens, and HSL gradients.
- **Theme Extensions**: Specialized tokens for Chat and components now part of the default generated theme.

### 💬 Professional Chat Module
- **Socket.io Pro**: Resilient real-time engine with connection status, auth tokens, and dedicated event pipelines.
- **Message Lifecycle**: Full status tick system (Sending -> Sent -> Delivered -> Read).
- **Typing Indicators**: Real-time "Typing..." feedback in AppBar and Message List.
- **Threaded Replies**: Native swipe-to-reply logic with quoted context UI.

### 📚 Documentation & Community
- **Documentation Portal**: Full overhaul with deep-dive guides for all core modules.
- **Support**: Added community support link ("Buy Me A Coffee").

## 1.1.1

### 🏗️ Major Refactoring & Transactional Engine
- **Transactional Architecture**: Introduced a new `FileAction` system. Every command now follows a **Plan -> Confirm -> Execute** lifecycle.
- **Undo / Rollback**: Added the `undo` command to revert the last 10 operations using a persistent history log.
- **Modular Template System**: Users can now override default templates by placing `.template` files in `.flutter_arch_gen/templates/`.
- **Refactored Core**: Split the monolithic `feature_helper.dart` into specialized modules (Generators, Registrars, Helpers).

### ✨ New Commands
- `api` — Generate Model + Repository + Service from an endpoint URL or spec.
- `screen` — Generate pre-wired screens (List, Form, Detail) for a feature.
- `widget` — Generate StatelessWidget or StatefulWidget.
- `service` — Generate standalone Services.
- `repository` — Generate standalone repository interfaces and implementations.
- `bloc` — Generate standalone BLoCs or Cubits with events and states.
- `delete` — Safely remove a feature and clean up its registrations.
- `rename` — Rename an existing feature with full import/directory updates.
- `migrate` — Switch architecture or state management mid-project.
- `undo` — Revert the last destructive command.

### 🚀 Improvements & Features
- **Dry Run Support**: Added `--dry-run` to all destructive commands to preview changes.
- **Monorepo Support**: Added `--output` flag to target specific packages.
- **Config Profiles**: Support for multiple configurations via `--config`.
- **Enhanced Initialization**: `init` now supports dry-runs, overwrite protection, and automated template setup.
- **Routing**: Added support for AutoRoute, GoRouter, and standard Navigator registration.
- Fixed redundant imports and improved documentation across the entire package.

### 🧪 Testing & Quality
- Expanded test suite to 40+ tests covering versioning, config, and string utilities.
- Resolved all lint and static analysis warnings for a 100% clean check.

## 1.1.0

- Multi-architecture support: Clean, MVVM, BLoC, GetX, Provider
- State management: BLoC, Riverpod, Provider, GetX
- Routing: GoRouter, AutoRoute
- Firebase integration
- Localization support
- Custom feature generation

## 1.0.2

- Bug fixes and improvements

## 1.0.1

- Bug fixes and improvements

## 1.0.0

- Initial release
