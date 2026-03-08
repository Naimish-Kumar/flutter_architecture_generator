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

## 🌐 API-to-Model Engine
Generate full feature code directly from a live API endpoint.

```bash
flutter_arch_gen api User --url https://api.example.com/users --feature auth
```

### Why it's smart:
- **Live Analysis**: It hits the URL to check real data types and nullability.
- **Auth Support**: Prompts for a token if the API is secured.
- **End-to-End**: Generates the Model, Service, and Repository in one go.
