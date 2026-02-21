## 1.1.0 - 2026-02-22

- 🏗️ **Multi-Architecture Support** — Added 4 new architectures alongside Clean Architecture:
  - **MVVM**: Models, Services, ViewModels (ChangeNotifier), Views
  - **BLoC Architecture**: Models, Repositories, Bloc + Event + State, Pages
  - **GetX Architecture**: Models, Controllers (GetxController), Bindings, Views
  - **Provider / Simple**: Models, Providers (ChangeNotifier), Pages
- 🧭 **Navigator Routing** — Replaced placeholder with full `onGenerateRoute` implementation including named route constants and 404 fallback.
- 🎯 **Typed BLoC Dependencies** — BLoC template now uses architecture-aware typed dependencies (`GetXUseCase` for Clean, `Repository` for BLoC).
- 🧪 **Expanded Test Generation** — All 5 architectures now generate feature-specific tests (ViewModel, BLoC, Controller, Provider tests).
- 🔗 **GetX Consistency** — Fixed controller/binding/DI alignment so constructor signatures match across all generated files.
- 📝 **Updated README** — Added architecture comparison table, directory structure examples for all architectures, and architecture selection prompt in Quick Start guide.
- ⚙️ **Architecture-Aware Commands** — `feature`, `model`, and `page` commands now respect the selected architecture's directory structure.
- 🏷️ Updated package description to reflect multi-architecture support.

## 1.0.1 - 2026-02-21

- ✨ Improved: `ApiClient` now uses environment variables (`flutter_dotenv`) for the base URL instead of a hardcoded string.

## 1.0.0 - 2026-02-21

- 🏗️ Clean Architecture scaffolding with domain, data, and presentation layers.
- ⚡ Four state management options: BLoC, Riverpod, Provider, and GetX.
- 🗺️ Routing support: GoRouter and AutoRoute with auto-registration.
- 🔌 Dependency Injection with GetIt — auto-wired for every feature.
- 🌐 Dio HTTP client with interceptors, timeouts, and base configuration.
- ❄️ Freezed & JSON Serializable model generation.
- 🔐 Auth feature scaffolding with premium Login & Register pages.
- 🌍 Localization (L10n) with ARB files and `flutter_localizations`.
- 🔥 Firebase integration support (optional).
- 🎨 Material 3 theming with light and dark mode.
- 🔒 Environment files (.env.dev / .env.prod) with auto-generated .gitignore.
- 🧪 Unit tests with repository test scaffolding.
- 📦 Latest package versions from pub.dev.
