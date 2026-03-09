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

## 🌐 API-to-Code Engine (Overhauled)
Generate full feature code directly from a live API endpoint or a local JSON file. It fetches a sample response, infers types, and builds your **Domain (Entities, Interfaces)** and **Data (Models, Repositories, Services)** layers.

```bash
# From a live URL
flutter_arch_gen api Product --url https://fakestoreapi.com/products/1 --feature shop

# From a local file
flutter_arch_gen api Product --url file:///Users/me/data/product.json --feature shop
```

### Why it's smart:
- **Architecture Aware**: In Clean Architecture, it generates Entities and ensures Models extend them for perfect type safety.
- **Type Inference**: Hits the URL (or reads the file) to infer real data types and nullability for `@JsonSerializable` models.
- **End-to-End**: Generates the **Entity**, **Model**, **Service**, **Repository Interface**, and **Repository Implementation** in one transaction.
- **Support**: Supports secured APIs via automated token prompts and respects the `--force` flag for CI/CD.
