# ✂️ Excerpta

A smart, CLI-based dead code detector for Dart and Flutter projects, specially tailored for **MobX**, **GetIt**, and clean architecture patterns.

## 🚀 Features

- **MobX Aware:** Understands `Store` classes and generated `_$Class` mixins, avoiding false positives.
- **GetIt Compatible:** Detects dependency injection registrations via generic types (e.g., `GetIt.I.get<MyViewModel>()`).
- **Zero Configuration:** Works out of the box using Dart's native `analyzer`.

## 📦 Installation

Activate the CLI globally using `dart pub`:

```bash
dart pub global activate excerpta