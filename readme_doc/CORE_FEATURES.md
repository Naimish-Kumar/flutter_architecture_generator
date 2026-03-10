# 🚀 Core Premium Features

Beyond boilerplate, the generator provides "High-Level" modules that are fully production-ready.

---

## 🎨 Theme Generator
Generate a complete, high-end Design System with one command.

```bash
flutter_arch_gen theme
```

### Highlights:
- ✅ **Dynamic Mode**: Full Dark/Light mode support out of the box.
- ✅ **Design Tokens**: Generated `AppColors` and `AppTheme` with semantic tokens.
- ✅ **Typography**: Integrated with `google_fonts` (Outfit & Inter).
- ✅ **Theme Extensions**: Includes specialized extensions for modules like Chat.

---

## 💬 Chat Module
Generate a complete real-time communication feature.

```bash
flutter_arch_gen feature chat
```

### Advanced Features:
- **SocketService Pro**: Resilient Socket.io integration with auto-reconnect and auth support.
- **Message Lifecycle**: Automatic status ticks (Sending → Sent → Delivered → Read).
- **Typing Indicators**: Real-time "Typing..." feedback in AppBar and message list.
- **Threaded Replies**: Native swipe-to-reply logic with quoted message bubbles.
- **Media Support**: Built-in support for Image, Video, Audio, and Document messages.

---

## 🧠 Smart Refactor
Inject fields into existing models without losing your custom logic.

```bash
flutter_arch_gen refactor model User --add "String? profileUrl"
```

### How it works:
- **Intelligent Injection**: Parses your `freezed` models and safely adds new parameters to the constructor.
- **Safety First**: It never overwrites your manually added methods or imports.
- **Auto-Sync**: Reminds you to run `build_runner` to sync the changes.

---

## 🌐 API-to-Code Engine (Pro)
Generate full feature code directly from a live API endpoint or a local JSON file. It fetches a sample response, infers types, and builds your **Domain (Entities, UseCases)** and **Data (Models, Repositories, Services)** layers.

```bash
# Basic GET request
flutter_arch_gen api Product -u https://api.com/products/1 -f shop

# POST request with custom body for type inference
flutter_arch_gen api CreateUser -u https://api.com/users -m POST -b '{"name":"Naimish"}' -f auth
```

### 🧠 Advanced Capabilities:
- 🔄 **Recursive Nested Models**: Automatically detects nested objects or lists in your JSON and generates separate model/entity files for them. No manual refactoring required!
- ⚡ **Full CRUD Support**: Supports `GET`, `POST`, `PUT`, `DELETE`, and `PATCH` with the `-m` flag.
- 📬 **Request Body & Queries**: Use the `-b` flag to pass a JSON body. Generated code automatically supports both `data` and `queryParameters` via named parameters.
- 💉 **Auto-DI Registration**: Generated Services, Repositories, and UseCases are automatically registered in your `injection_container.dart` (GetIt).
- 🧪 **Unit Test Scaffolding**: Automatically generates specialized unit tests for your Services and Repositories in the `test/` folder.
- 🏗️ **Architecture Aware**: 
  - **Clean**: Generates Entities, Models (extending entities), Repositories, and UseCases.
  - **MVVM/Standard**: Generates Models, Repositories, and Services tailored to your config.
- 🔒 **Secured API Support**: Interactive prompts for Authorization tokens and headers if the endpoint requires them.
