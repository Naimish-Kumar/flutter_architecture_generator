# 🏗️ Flutter Architecture Generator

[![pub package](https://img.shields.io/pub/v/flutter_architecture_generator.svg)](https://pub.dev/packages/flutter_architecture_generator)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Dart 3](https://img.shields.io/badge/Dart-3-blue.svg)](https://dart.dev)

> **A powerful, production-ready CLI tool to instantly scaffold professional Flutter applications with your choice of architecture — Clean Architecture, MVVM, BLoC, GetX, or Provider.**

Stop wasting hours on boilerplate. Generate a complete, scalable project architecture in **seconds** — with dependency injection, networking, routing, state management, theming, and tests all wired up and ready to go.

---

## ✨ Why This Tool?

| | Feature |
|---|---------|
| 🚀 | **Zero to Production** — Generates a complete architecture with DI, Networking, Routing, and Material 3 Theming in seconds |
| 🧱 | **5 Architectures** — Clean Architecture, MVVM, BLoC, GetX, and Provider — each with idiomatic directory structures |
| 🧠 | **Context-Aware** — Remembers your project config (architecture, state management, routing) so subsequent commands "just work" |
| ⚡ | **Auto-Wiring** — New features auto-register in your DI container and router — no manual wiring |
| 🎨 | **Premium Auth UI** — Includes polished Login & Register pages out of the box |
| 📦 | **Latest Packages** — All dependencies pinned to the most recent stable versions on pub.dev |
| 🧪 | **Test Ready** — Generates repository tests with mock data sources for every feature |
| 🔒 | **Secure by Default** — `.gitignore` auto-generated to protect `.env` secrets |

---

## 📋 Table of Contents

- [Supported Features](#-supported-features)
- [Package Versions](#-package-versions-latest)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Commands Reference](#-commands-reference)
- [Generated Structure](#-generated-structure)
- [Generated Code Examples](#-generated-code-examples)
- [How Auto-Wiring Works](#-how-auto-wiring-works)
- [Configuration Persistence](#-configuration-persistence)
- [Post-Generation Steps](#-post-generation-steps)
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

### Networking & Data
| Feature | Details |
|---------|---------|
| **Dio HTTP Client** | Pre-configured with `connectTimeout`, `receiveTimeout`, `LogInterceptor` |
| **GetIt DI** | Service locator pattern with lazy singleton and factory registrations |
| **Freezed Models** | `@freezed` models with `fromJson` / `toJson` via `json_serializable` |
| **Environment Config** | `.env.dev` and `.env.prod` with `flutter_dotenv` |

### Additional Features
| Feature | Details |
|---------|---------|
| **Firebase** | `firebase_core` initialization in `main.dart` |
| **Localization (L10n)** | ARB files, `l10n.yaml`, `flutter_localizations` delegates |
| **Material 3 Theming** | Light + Dark theme with `ColorScheme.fromSeed` |
| **Error Handling** | `Failure` abstract class + `ServerFailure`, `CacheFailure`, `GeneralFailure` |
| **Unit Tests** | Repository tests with mock data sources generated per feature |
| **Security** | `.gitignore` with `.env*`, IDE files, and generated code exclusions |

---

## 📦 Package Versions (Latest)

All generated dependencies use the **latest stable versions** from pub.dev:

| Package | Version | Purpose |
|---------|---------|---------|
| `dio` | ^5.9.1 | HTTP networking |
| `get_it` | ^9.2.1 | Dependency injection |
| `flutter_bloc` | ^9.1.1 | BLoC state management |
| `equatable` | ^2.0.8 | Value equality for BLoC states |
| `flutter_riverpod` | ^3.2.1 | Riverpod state management |
| `provider` | ^6.1.5 | Provider state management |
| `get` | ^4.7.3 | GetX state management |
| `go_router` | ^17.1.0 | Declarative routing |
| `auto_route` | ^11.1.0 | Code-generated routing |
| `freezed_annotation` | ^3.1.0 | Immutable models (annotations) |
| `json_annotation` | ^4.11.0 | JSON serialization (annotations) |
| `flutter_dotenv` | ^6.0.0 | Environment variables |
| `firebase_core` | ^4.4.0 | Firebase initialization |
| `intl` | ^0.20.2 | Internationalization |
| `build_runner` | ^2.11.1 | Code generation runner |
| `freezed` | ^3.0.6 | Immutable models (generator) |
| `json_serializable` | ^6.13.0 | JSON serialization (generator) |
| `auto_route_generator` | ^11.0.1 | AutoRoute code generator |

---

## 🚀 Installation

### Global Activation (Recommended)

```bash
dart pub global activate flutter_architecture_generator
```

This adds the `flutter_arch_gen` command to your PATH.

### Verify Installation

```bash
flutter_arch_gen --help
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

You'll be prompted to choose:
```
? Select architecture: (Use arrow keys)
❯ Clean Architecture (Feature-First)
  MVVM
  BLoC Architecture
  GetX Architecture
  Provider / Simple Architecture

? Select state management: (Use arrow keys)
❯ bloc
  riverpod
  provider
  getx

? Select routing:
❯ goRouter
  autoRoute
  navigator

? Enable localization? (Y/n)
? Enable Firebase? (y/N)
? Enable tests? (Y/n)
```

### 3. Install dependencies & generate code

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 4. Run your app

```bash
flutter run
```

**That's it!** You now have a complete Clean Architecture project with DI, routing, theming, networking, and an example auth feature — all production-ready.

---

## 📖 Commands Reference

### `flutter_arch_gen init`

Initializes the complete project architecture with interactive prompts.

```bash
flutter_arch_gen init
```

**What it generates:**
- Directory structure (`core/`, `features/`, `routes/`, `di/`)
- `main.dart` with initialization pipeline
- `app.dart` with `MaterialApp.router` configuration
- `injection_container.dart` with GetIt setup
- `api_client.dart` with Dio configuration
- `app_theme.dart` with Material 3 light/dark themes
- `app_router.dart` with routing configuration
- `failures.dart` with error hierarchy
- `.env.dev` / `.env.prod` environment files
- `.gitignore` with security exclusions
- Example `auth` feature with Login & Register pages
- Localization files (if enabled)
- Test scaffolding (if enabled)

---

### `flutter_arch_gen feature <name>`

Generates a complete Clean Architecture feature module.

```bash
# Basic usage
flutter_arch_gen feature products

# With positional arg
flutter_arch_gen feature user_profile

# PascalCase input is auto-normalized
flutter_arch_gen feature UserProfile  # → features/user_profile/
```

**What it generates:**
```
features/user_profile/
├── data/
│   ├── datasources/user_profile_remote_datasource.dart
│   ├── models/user_profile_model.dart
│   └── repositories/user_profile_repository_impl.dart
├── domain/
│   ├── entities/user_profile_entity.dart
│   ├── repositories/user_profile_repository.dart
│   └── usecases/get_user_profile_usecase.dart
└── presentation/
    ├── bloc/             # (or riverpod/ or provider/ or getx/)
    │   ├── user_profile_bloc.dart
    │   ├── user_profile_event.dart
    │   └── user_profile_state.dart
    ├── pages/user_profile_page.dart
    └── widgets/
```

**Auto-wiring:**
- ✅ Registers `DataSource`, `Repository`, `UseCase`, and `Bloc` in `injection_container.dart`
- ✅ Adds route + import to `app_router.dart` (GoRouter or AutoRoute)
- ✅ Generates repository test in `test/features/user_profile/`

<details>
<summary><strong>📂 MVVM Architecture Structure</strong></summary>

```
features/user_profile/
├── models/user_profile_model.dart
├── services/user_profile_service.dart
├── view_models/user_profile_view_model.dart
└── views/
    ├── pages/user_profile_page.dart
    └── widgets/
```
</details>

<details>
<summary><strong>📂 BLoC Architecture Structure</strong></summary>

```
features/user_profile/
├── bloc/
│   ├── user_profile_bloc.dart
│   ├── user_profile_event.dart
│   └── user_profile_state.dart
├── models/user_profile_model.dart
├── repositories/user_profile_repository.dart
├── pages/user_profile_page.dart
└── widgets/
```
</details>

<details>
<summary><strong>📂 GetX Architecture Structure</strong></summary>

```
features/user_profile/
├── bindings/user_profile_binding.dart
├── controllers/user_profile_controller.dart
├── models/user_profile_model.dart
└── views/
    ├── pages/user_profile_page.dart
    └── widgets/
```
</details>

<details>
<summary><strong>📂 Provider Architecture Structure</strong></summary>

```
features/user_profile/
├── models/user_profile_model.dart
├── providers/user_profile_provider.dart
├── pages/user_profile_page.dart
└── widgets/
```
</details>

---

### `flutter_arch_gen model <name> [-f feature]`

Generates a Freezed model with JSON serialization.

```bash
# Inside a feature
flutter_arch_gen model Product -f shop

# Standalone (in lib/core/models/)
flutter_arch_gen model AppUser
```

**Generated code:**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
class Product with _$Product {
  const factory Product({
    required int id,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
}
```

---

### `flutter_arch_gen page <name> [-f feature]`

Generates a new page with optional router auto-registration.

```bash
# Inside a feature
flutter_arch_gen page Settings -f settings

# Standalone page
flutter_arch_gen page About
```

**Auto-wiring:**
- ✅ GoRouter: Adds `GoRoute` with path and import to `app_router.dart`
- ✅ AutoRoute: Adds `@RoutePage()` annotation and `AutoRoute(page: ...)` entry

---

## 📂 Generated Structure

```
lib/
├── main.dart                          # App entry point with initialization
├── app.dart                           # MaterialApp with theme & routing
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # Global constants
│   ├── errors/
│   │   └── failures.dart              # Failure hierarchy (Server, Cache, General)
│   ├── network/
│   │   └── api_client.dart            # Dio HTTP client with interceptors
│   ├── services/                      # Shared services
│   ├── theme/
│   │   └── app_theme.dart             # Material 3 light + dark themes
│   └── utils/                         # Shared utilities
├── di/
│   └── injection_container.dart       # GetIt DI setup (auto-updated)
├── features/
│   └── auth/                          # Example auth feature
│       ├── data/
│       │   ├── datasources/
│       │   ├── models/
│       │   └── repositories/
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       └── presentation/
│           ├── bloc/                  # State management (BLoC/Riverpod/etc.)
│           ├── pages/                 # Login & Register pages
│           └── widgets/
├── routes/
│   └── app_router.dart                # GoRouter or AutoRoute config
├── .env.dev                           # Dev environment variables
├── .env.prod                          # Prod environment variables
├── .gitignore                         # Security exclusions
└── .flutter_arch_gen.json             # Persisted project config

test/
├── features/
│   └── auth/
│       └── auth_repository_test.dart  # Auto-generated repository test
├── unit/
│   └── sample_test.dart
├── widget/
└── integration/
```

---

## 💡 Generated Code Examples

### main.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_app/app.dart';
import 'package:my_app/di/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await dotenv.load(fileName: ".env.dev");
  await di.init();
  
  runApp(const MyApp());
}
```

### injection_container.dart (after generating features)
```dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:my_app/core/network/api_client.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  sl.registerLazySingleton(() => Dio());

  // Core
  sl.registerLazySingleton(() => ApiClient(sl()));

  // Features
  // Auth Feature
  sl.registerLazySingleton<IAuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<IAuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetAuthUseCase(sl()));
  sl.registerFactory(() => AuthBloc(getAuthUseCase: sl()));
}
```

### BLoC (auto-generated)
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_app/features/auth/domain/usecases/get_auth_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetAuthUseCase getAuthUseCase;

  AuthBloc({required this.getAuthUseCase}) : super(AuthInitial()) {
    on<GetAuthDataEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        final data = await getAuthUseCase();
        emit(AuthLoaded(data: data.id.toString()));
      } catch (e) {
        emit(AuthError(message: e.toString()));
      }
    });
  }
}
```

---

## 🔗 How Auto-Wiring Works

When you run `flutter_arch_gen feature <name>`, three things happen automatically:

### 1. DI Registration
New imports and registrations are injected into `injection_container.dart`:
```dart
// Imports added at top
import 'package:my_app/features/products/data/datasources/products_remote_datasource.dart';
import 'package:my_app/features/products/data/repositories/products_repository_impl.dart';
// ...

// Registrations added under "// Features"
sl.registerLazySingleton<IProductsRemoteDataSource>(() => ProductsRemoteDataSourceImpl(sl()));
sl.registerLazySingleton<IProductsRepository>(() => ProductsRepositoryImpl(sl()));
sl.registerLazySingleton(() => GetProductsUseCase(sl()));
sl.registerFactory(() => ProductsBloc(getProductsUseCase: sl()));
```

### 2. Router Registration

**GoRouter:**
```dart
// Import added
import 'package:my_app/features/products/presentation/pages/products_page.dart';

// Route added
GoRoute(
  path: '/products',
  builder: (context, state) => const ProductsPage(),
),
```

**AutoRoute:**
```dart
// Import added
import 'package:my_app/features/products/presentation/pages/products_page.dart';

// Route added
AutoRoute(page: ProductsRoute.page),
```

### 3. Test Generation
A repository test is created at `test/features/products/products_repository_test.dart` with a mock data source.

---

## 💾 Configuration Persistence

After running `init`, your choices are saved in `.flutter_arch_gen.json`:

```json
{
  "architecture": "clean",
  "stateManagement": "bloc",
  "routing": "goRouter",
  "localization": true,
  "firebase": false,
  "tests": true
}
```

All subsequent commands (`feature`, `model`, `page`) automatically read this config — no need to pass flags for state management or routing every time.

---

## 🔧 Post-Generation Steps

After running `flutter_arch_gen init`:

```bash
# 1. Install all dependencies
flutter pub get

# 2. Generate Freezed models and AutoRoute (if applicable)
dart run build_runner build --delete-conflicting-outputs

# 3. Configure your API base URL
# Edit .env.dev and .env.prod with your actual endpoints

# 4. Run your app
flutter run
```

---

## ❓ FAQ

### Q: Can I use this on an existing project?
**A:** Yes! Run `flutter_arch_gen init` in your existing Flutter project root. It will add files alongside your existing code. Existing files with the same names will be overwritten, so commit first.

### Q: Does it modify my existing pubspec.yaml?
**A:** Yes, it adds the required dependencies under `dependencies` and `dev_dependencies`. Existing dependencies are not overwritten — only new ones are added.

### Q: Can I generate features with different state management?
**A:** The tool uses the state management from your saved config (`.flutter_arch_gen.json`). To change it, re-run `flutter_arch_gen init` or manually edit the config file.

### Q: Does it support Cubit?
**A:** Currently, BLoC with `Bloc` (event-driven) is generated. You can easily convert the generated `Bloc` to a `Cubit` since both come from `flutter_bloc`.

### Q: What naming convention is used?
**A:** All file names and directory names use `snake_case`. Class names use `PascalCase`. Variable names use `camelCase`. Input like `UserProfile` or `user_profile` both work correctly.

### Q: Does it work on Windows?
**A:** Yes! All path handling uses cross-platform normalization to ensure correct imports on Windows, macOS, and Linux.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Made with ❤️ for the Flutter community
</p>
