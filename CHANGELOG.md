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
