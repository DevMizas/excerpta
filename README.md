# ✂️ excerpta

A smart, high-confidence dead code detector for Dart and Flutter projects, with native support for **MobX**, **GetIt**, and clean architecture patterns.

Finds unused and never-referenced declarations (classes, stores, view models, methods, and functions) without throwing false positives on code generation or dependency injection graphs.

---

## 💡 About the name

**"Excerpta"** — derived from the Latin *excerptum* — means "selected passages" or "excerpts". 

Fitting for a tool that isolates the essential parts of your codebase and highlights dead code waiting to be pruned.

---

## ⚡ Why Excerpta?

Generic dead code detectors often struggle with Flutter apps using code generators or Service Locators. They frequently flag:
- **MobX Stores** as unused because they are written as `abstract class _MyStoreBase` and generated into `_$MyStore`.
- **GetIt Dependencies** as unused because they are injected dynamically via generic type arguments (e.g., `GetIt.I.get<MyStore>()`).

**Excerpta understands these patterns natively.** It traverses the Abstract Syntax Tree (AST) using Dart's official `analyzer` engine to give you high-confidence results without false alarms.

---

## 📦 Installation

There are two ways to get the `excerpta` CLI:

### 1. Global Activation (Recommended)
Available everywhere on your machine, independent of any specific project:

```bash
dart pub global activate excerpta