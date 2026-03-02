# 🏗️ Flutter Architecture Generator

[![pub package](https://img.shields.io/pub/v/flutter_architecture_generator.svg)](https://pub.dev/packages/flutter_architecture_generator)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Dart 3](https://img.shields.io/badge/Dart-3-blue.svg)](https://dart.dev)

> **A powerful, transactional CLI tool to instantly scaffold and maintain professional Flutter applications with your choice of architecture — Clean Architecture, MVVM, BLoC, GetX, or Provider.**

Stop wasting hours on boilerplate. Generate a complete, scalable project architecture in **seconds** — with a transactional engine that lets you preview every change before it hits your disk.

---

## ✨ Why This Tool?

| | Feature |
|---|---------|
| 🚀 | **Zero to Production** — Generates a complete architecture with DI, Networking, Routing, and Material 3 Theming in seconds |
| 🛡️ | **Transactional Safety** — New Plan -> Confirm -> Execute engine. Review a tree-diff of all changes before they are applied. |
| ⏪ | **Undo / Rollback** — One command to revert any destructive generation or rename operation. |
| 🧱 | **5 Architectures** — Clean Architecture, MVVM, BLoC, GetX, and Provider — each with idiomatic directory structures |
| 🧠 | **Context-Aware** — Remembers your project config so subsequent commands "just work" |
| ⚡ | **Auto-Wiring** — New features auto-register in your DI container and router — no manual wiring |
| 📦 | **Mono-repo Support** — Native `--output` support for generating features into specific packages. |
| 🎨 | **Modular Templates** — Drop `.template` files into `.flutter_arch_gen/templates/` to override defaults project-wide. |
| 🧪 | **Test Ready** — Generates repository tests with mock data sources for every feature |
| 🔒 | **Secure by Default** — `.gitignore` auto-generated to protect `.env` secrets |

---

## 📋 Table of Contents

- [Supported Features](#-supported-features)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Commands Reference](#-commands-reference)
- [Maintenance & Management](#-maintenance--management)
- [Advanced Features](#-advanced-features)
- [Generated Structure](#-generated-structure)
- [FAQ](#-faq)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Supported Features

### Architectures
| Architecture | Generated Structure | Key Components |
|---|---|---|
| **Clean Architecture** | `domain/` → `data/` → `presentation/` | Entity, Repository Interface, UseCase, DataSource, Repo Impl, BLoC/Provider |
| **MVVM** | `models/` → `services/` → `view_models/` → `views/` | Model, Service, ViewModel (ChangeNotifier), View |
| **BLoC Architecture** | `models/` → `repositories/` → `bloc/` → `pages/` | Model, Repository, Bloc + Event + State, Page |
| **GetX Architecture** | `models/` → `controllers/` → `bindings/` → `views/` | Model, Controller (GetxController), Binding, View |
| **Provider / Simple** | `models/` → `providers/` → `pages/` | Model, Provider (ChangeNotifier), Page |

### State Management
| Option | Generated Code |
|--------|---------------|
| **BLoC** | `Bloc` + `Event` + `State` files with `Equatable`, `part` directives |
| **Riverpod** | `FutureProvider` with proper `camelCase` naming |
| **Provider** | `ChangeNotifier` with loading state pattern |
| **GetX** | `GetxController` with `.obs` reactive variables |

### Routing
| Option | Generated Code |
|--------|---------------|
| **GoRouter** | `GoRouter` config with `GoRoute` entries, auto-registration of new pages |
| **AutoRoute** | `@AutoRouterConfig` with `@RoutePage()` annotations, auto-registration |
| **Navigator** | `onGenerateRoute` with named route constants and 404 fallback |

---

## 🚀 Installation

### Global Activation

```bash
dart pub global activate flutter_architecture_generator
```

---

## ⚡ Quick Start

### 1. Create a Flutter project
```bash
flutter create my_awesome_app
cd my_awesome_app
```

### 2. Initialize the architecture
```bash
flutter_arch_gen init
```

### 3. Review the Plan
The transactional engine will show you exactly what will happen:
```bash
🏗️  Planned Changes:
--------------------------------------------------
[+] CREATE  lib/main.dart
[+] CREATE  lib/app.dart
[+] CREATE  lib/core/network/api_client.dart
[M] MODIFY  pubspec.yaml (added 12 dependencies)

? Do you want to apply these changes? (y/N) 
```

### 4. Install dependencies & generate code
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

---

## 📖 Commands Reference

### `flutter_arch_gen init`
Initializes the complete project architecture with interactive prompts and a transactional plan preview.

**Flags:**
- `-a, --arch`: Architecture pattern (`clean`, `mvvm`, etc.)
- `-s, --state`: State management (`bloc`, `riverpod`, etc.)
- `-r, --routing`: Routing strategy (`goRouter`, `autoRoute`, etc.)
- `-n, --dry-run`: Preview changes without applying them.
- `-c, --config`: Specify a profile name (e.g., `-c dev`).
- `-o, --output`: Custom output directory for monorepos.

---

### `flutter_arch_gen feature <name>`
Generates a complete feature module (Domain, Data, Presentation) with auto-wiring.

**Flags:**
- `-n, --dry-run`: Preview feature files.
- `-o, --output`: Target a specific directory.
- `-c, --config`: Use a configuration profile.
- `-f, --force`: Overwrite existing feature files.

---

### `flutter_arch_gen model <name>`
Generates a Freezed model with JSON serialization. Supports standalone or feature-bound generation.

---

### `flutter_arch_gen api <url>`
**New in v1.1.1!** Generates Model, Repository, and Service from an endpoint URL or OpenAPI spec.

---

### `flutter_arch_gen screen <name>`
**New in v1.1.1!** Generates a complex screen (List, Form, Detail) with pre-wired state management.

---

### `flutter_arch_gen bloc <name>`
Generates a standalone BLoC or Cubit (`--cubit` flag supported).

---

## 🛠️ Maintenance & Management

| Command | Description |
|---------|-------------|
| `update` | Transactionally update your project core files and architecture logic. |
| `undo` | Revert the last successful command using the project's history log. |
| `migrate` | Switch state management or architecture mid-project. |
| `rename` | Rename a feature across directories, classes, DI, and routes. |
| `delete` | Transitionally delete a feature and un-register its bindings. |
| `list` | List all features and current project configuration. |
| `doctor` | Diagnose project health and confirm generator compatibility. |

---

## 🛡️ Advanced Features

### 1. Transactional Execution Engine
Every command that modifies more than one file runs through our transactional engine. It generates a **Plan**, displays a **Diff**, and waits for your **Confirmation** before touching any files.

### 2. Undo/Rollback System
Made a mistake? `flutter_arch_gen undo` restores the state of your project before the last command. We maintain a `.flutter_arch_gen_history.json` to keep your project safe.

### 3. Modular Template System
You can now override default templates by dropping `.template` files into a `.flutter_arch_gen/templates/` directory in your project root. The generator will prioritize your custom templates over the built-in ones.

---

## 📂 Generated Structure

```
lib/
├── main.dart                          # App entry point
├── core/                              # Shared core logic (network, theme, errors)
├── di/                                # GetIt Dependency Injection DI setup
├── features/                          # Feature-first modules
├── routes/                            # Routing configuration
└── .flutter_arch_gen.json             # Persisted project config
```

---

## ❓ FAQ

### Q: Can I use this on an existing project?
**A:** Yes! Run `flutter_arch_gen init`. Our transactional engine will show you exactly what will be added or modified before you confirm.

### Q: Does it support Cubit?
**A:** Yes! Use `flutter_arch_gen bloc <name> --cubit` to generate a Cubit instead of a BLoC.

### Q: How do I handle monorepos?
**A:** Use the `--output` (or `-o`) flag to target specific packages within your monorepo.

---

## 🤝 Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License
This project is licensed under the MIT License.

---
<p align="center">Made with ❤️ for the Flutter community</p>
