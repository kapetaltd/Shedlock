# Shedlock

*Shed your tail. Lock your prey.*

A modern take on Snake, built with Flutter + Flame. See [docs/PLAN.md](docs/PLAN.md)
for the architecture and roadmap. Full setup and release instructions land in Phase 6.

## Quick start

```sh
flutter pub get
flutter test                      # core logic tests (Dart VM)
flutter test --platform chrome \
  test/core/seed_determinism_test.dart   # same tests compiled to JS
```
