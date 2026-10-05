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

## Translations

All UI text lives in `lib/l10n/app_en.arb` (read in code via `context.l10n`).
To add a language, copy it to e.g. `app_es.arb`, translate the values and run
`flutter gen-l10n`. Milestone education copy is content data in
`lib/domain/milestone.dart` and goes through health review before translation.
