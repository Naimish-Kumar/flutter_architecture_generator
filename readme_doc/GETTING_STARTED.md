# 🏁 Getting Started

Welcome to the **Flutter Architecture Generator**! This guide will help you go from zero to a production-ready application in minutes.

---

## 🛠️ Installation

Global activation is the recommended way to use the CLI. This makes the `flutter_arch_gen` command available everywhere on your system.

```bash
dart pub global activate flutter_architecture_generator
```

> [!TIP]
> Ensure your Dart SDK `bin` folder is in your system's PATH. If not, follow the [official Dart documentation](https://dart.dev/get-dart).

---

## 🏗️ Initializing Your Project

The `init` command is the heart of the generator. It doesn't just create folders; it understands your project and prepares a **Transactional Plan**.

### 1. Create your Flutter app
```bash
flutter create my_app
cd my_app
```

### 2. Run the initializer
```bash
flutter_arch_gen init
```

### 3. Interactive Setup
The tool will prompt you for your preferences:
- **Architecture**: Clean Architecture, MVVM, BLoC, GetX, or Provider.
- **State Management**: BLoC, Riverpod, Provider, or GetX.
- **Routing**: GoRouter, AutoRoute, or standard Navigator.

### 4. Review the Plan
The generator will display a detailed tree-diff:
- `[+]` Files to be created.
- `[M]` Files to be modified (e.g., adding dependencies to `pubspec.yaml`).
- `[R]` Files to be renamed.

---

## 📦 Core Dependencies
When you initialize a project, the generator automatically injects essential production libraries:
- 💉 **Dependency Injection**: `get_it`, `injectable`
- 🌐 **Networking**: `dio`, `retrofit`
- 🔒 **Data Modeling**: `freezed`, `json_serializable`
- 🎨 **Styling**: `google_fonts`, `flutter_svg`

---

## 🚦 Next Steps
- [Explore Architecture Patterns](./ARCHITECTURE_PATTERNS.md)
- [Add a Chat Module](./CORE_FEATURES.md#💬-chat-module)
- [Generate a Design System](./CORE_FEATURES.md#🎨-theme-generator)
