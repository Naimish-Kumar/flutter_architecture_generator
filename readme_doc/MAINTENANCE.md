# 🛠️ Maintenance & Management

Developing an app is a journey of constant change. We provide the tools to navigate it safely.

---

## ⏪ Undo & Rollback
Mistakes happen. The generator keeps a history of every transaction.

```bash
flutter_arch_gen undo
```

- **How it works**: Every command that modifies files creates a snapshot in `.flutter_arch_gen_history.json`.
- **Scope**: Reverts file creations, modifications, and deletions for the last command.

---

## ✏️ Rename Command
Refactoring is painful; we make it instant.

```bash
flutter_arch_gen rename old_feature_name new_feature_name
```

- **Deep Refactor**: Renames folders, class names, file imports, and even DI registrations.
- **Transactional**: Shows you a plan of every renaming change before execution.

---

## 🗑️ Delete Command
Cleanly remove features and their dependencies.

```bash
flutter_arch_gen delete feature_name
```

- **Un-wiring**: Not only deletes the files but also un-registers the feature from your DI container and global routes.

---

## 🩺 Doctor Command
Check the health of your project setup.

```bash
flutter_arch_gen doctor
```

- **Validation**: Ensures all required dependencies are in `pubspec.yaml`.
- **Compatibility**: Checks if the current project structure matches the generated arch config.
