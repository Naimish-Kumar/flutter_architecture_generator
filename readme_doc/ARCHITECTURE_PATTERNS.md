# 🏗️ Architecture Patterns

The generator supports 5 idiomatic architecture patterns. Each one is implemented following industry best practices and community-standard directory structures.

---

## 🛡️ Clean Architecture
**Recommended for complex, long-term enterprise projects.**

Clean Architecture separates your code into three distinct layers:
- **Domain Layer**: The heart of your app. Contains Entities, Repository Interfaces, and Use Cases. No dependencies on other layers.
- **Data Layer**: Implementation details. Contains DataSources (Local/Remote), Repository Implementations, and Models (DTOs).
- **Presentation Layer**: The UI and State Management. BLoCs/Providers and Pages.

### Directory Structure
```text
lib/
└── features/
    └── <feature_name>/
        ├── domain/
        │   ├── entities/
        │   ├── repositories/
        │   └── usecases/
        ├── data/
        │   ├── datasources/
        │   ├── models/
        │   └── repositories/
        └── presentation/
            ├── bloc/
            └── pages/
```

---

## 📦 MVVM (Model-View-ViewModel)
**Great for medium-sized apps that prioritize simple data binding.**

- **Model**: Data structures and business logic.
- **View**: The UI (Widgets/Pages).
- **ViewModel**: Bridging the Model and View using `ChangeNotifier` or `StateNotifier`.

### Directory Structure
```text
lib/
└── features/
    └── <feature_name>/
        ├── models/
        ├── services/
        ├── view_models/
        └── views/
```

---

## 🧱 BLoC Architecture
**Optimized for predictable state management and reactive streams.**

- **Models**: Simple data objects.
- **Repositories**: Data fetching logic.
- **BLoC**: The core logic controller.
- **Pages**: The UI that consumes BLoC states.

### Directory Structure
```text
lib/
└── features/
    └── <feature_name>/
        ├── models/
        ├── repositories/
        ├── bloc/
        └── pages/
```

---

## 🚀 GetX Architecture
**High-performance, minimal-boilerplate reactive development.**

- **Models**: Data objects.
- **Controllers**: Reactive logic using `.obs`.
- **Bindings**: Dependency injection configuration.
- **Views**: The UI.

### Directory Structure
```text
lib/
└── features/
    └── <feature_name>/
        ├── models/
        ├── controllers/
        ├── bindings/
        └── views/
```

---

## ☁️ Provider / Simple
**The standard Flutter "built-in" feel. Minimalist and fast.**

- **Models**: Data objects.
- **Providers**: ChangeNotifiers for state.
- **Pages**: UI widgets.

### Directory Structure
```text
lib/
└── features/
    └── <feature_name>/
        ├── models/
        ├── providers/
        └── pages/
```
