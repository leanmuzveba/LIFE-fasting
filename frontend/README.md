# Frontend — Flutter app

Flutter (Dart) app for Android and iOS.

```bash
flutter pub get
flutter run          # run on a connected device
flutter test         # unit + widget tests
flutter analyze      # lints
```

## Layout

```
lib/
├── core/       theme, design tokens, icons, formatting helpers
├── domain/     pure-Dart models and timer logic (no Flutter imports)
├── data/       SQLite database and repositories
└── features/   one folder per screen (home, history, settings, ...)
```
