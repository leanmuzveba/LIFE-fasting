# MagnaVita

A calm, offline-first personal wellness app for Android (iOS project included), built with Flutter. It grew out of the Fasting Companion app (and was briefly called RUVA): the circular fasting timer is still the centrepiece, and food, kitchen, recipes, activity, water and body measurements sit around it.

> **Not a medical device.** Milestone times and nutrition values are general estimates. The app cannot detect ketosis, fat burning or any other metabolic state, and BMI is shown with its limitations. Talk to a qualified healthcare professional before changing your eating patterns.

## Features

- **Fasting timer**: circular ring with fat-burning (yellow) and ketosis (red) milestone markers you can tap for an explanation. Elapsed time comes from saved timestamps, so it survives restarts
- **Home dashboard**: fasting ring, water, steps and food tiles, plus a day summary you can export as an image
- **Food diary**: breakfast, lunch, dinner and snacks; search the bundled USDA food list, scan barcodes (Open Food Facts), save foods, or estimate a meal from a photo (camera or gallery, Gemini, reviewed before saving). Export a meal's calories and macros as a PNG
- **My Kitchen**: ingredient inventory with categories, quantities, units, expiry and low-stock flags, grocery-photo import, and a monthly review that updates stock without wiping it
- **Recipes**: TheMealDB recipes matched to your kitchen, showing available and missing ingredients, with allergy and diet filters, servings, substitutions, a shopping list, mark as cooked, and log to diary. You can write your own recipes or let Gemini draft one from a photo or description
- **Activity and water**: workouts, steps (the higher of the phone pedometer and Health Connect/watch), and water entries with reminders
- **Profile**: optional height, weigh-ins with a chart, body measurements, and BMI with its caveats. Weight tracking can be switched off, and under-18s get no adult classifications or fasting plans
- **History**: fasting sessions in a list and calendar, plus food, activity, water and measurement history
- **Privacy**: all data stays on the phone in SQLite. You can delete everything from Settings

## Repository structure

```
LIFE-fasting/
├── frontend/   Flutter app (see frontend/README.md)
│   ├── tool/release.py   builds the APK and publishes it
│   └── release_site/     generated download page (deployed, not hand-edited)
├── backend/    Unused; the app needs no server (see backend/README.md)
└── docs/       PRDs (original + RUVA v1.2), Phase 0 audit, brand assets
```

## Tech stack

| Layer | Choice |
|---|---|
| UI | Flutter / Dart, Material 3, `CustomPainter` ring |
| State | Riverpod 3 (no code generation) |
| Storage | sqflite, database `life_fasting.db` with tested migrations |
| Notifications | `flutter_local_notifications` |
| Health | `health` (Health Connect), `pedometer` |
| Online (optional) | TheMealDB, Open Food Facts, Google Gemini |

## Brand

Forest `#135D44`, lime `#B9F36C`, mint `#F6FCEF`, ink `#1A2A20`. Fonts are Lexend, DM Sans and JetBrains Mono (OFL, bundled). Tokens live in `frontend/lib/core/theme/tokens.dart`. The MagnaVita logo and icon files are in `docs/BRANDING/new` (the colour guide is still `docs/BRANDING/Ruva_Brand_Guide.pdf`).

## Getting started

```bash
cd frontend
flutter pub get
flutter run
flutter test
```

Photo estimates and AI recipes need a Gemini API key, entered on the phone in **Settings → Meal photo estimates**. Release builds never include a key.

## Releasing

Commit first, then from `frontend/`:

```bash
python tool/release.py "What changed"
```

This builds an arm64 APK (build number = git commit count) and deploys it to https://ruva-releases.vercel.app. The installed app checks `version.json` on launch and offers the update on Home.

## Principles

- Saved timestamps are the source of truth for the timer, never the displayed counter
- Neutral copy: no streaks, no guilt, and you can end a fast at any time
- Estimates are labelled as estimates. Charts only show recorded data
- Package id `com.leanmuzveba.life_fasting` and the database name stay unchanged so existing data survives
- Accessible: WCAG AA contrast, screen-reader labels, scalable text, and state is never shown by colour alone
