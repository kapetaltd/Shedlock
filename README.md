# Shedlock

*Shed your tail. Lock your prey.*

A modern take on Snake, built with Flutter + Flame. See [docs/PLAN.md](docs/PLAN.md)
for the architecture and roadmap. Full setup and release instructions land in Phase 6.

## Quick start

Requires Flutter stable (3.47+).

```sh
flutter pub get
flutter run                       # on a connected Android device or emulator
flutter run -d chrome             # quick check in a browser
```

Controls: swipe anywhere to turn, tap anywhere to shed. In a browser or
emulator with a keyboard: arrows/WASD to turn, Space to shed, P to pause.

## Tests

```sh
flutter test                      # all tests (Dart VM)
flutter test --platform chrome \
  test/core/seed_determinism_test.dart   # same tests compiled to JS
```
