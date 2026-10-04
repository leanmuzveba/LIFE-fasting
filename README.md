# LIFE - fasting

A calm, offline-first intermittent fasting tracker for Android and iOS, built with Flutter. Inspired by the discontinued LIFE Fasting app, it centres on a large circular timer with milestone markers and a light-blue interface.

> **Not a medical device.** Milestone times are general educational estimates. The app cannot detect ketosis, autophagy or any other metabolic state. Talk to a qualified healthcare professional before changing your eating patterns.

## Features (MVP)

- **Circular progress ring** showing elapsed time (HH:MM:SS), planned target, remaining time and estimated end time
- **Milestone markers** around the ring; tap one for a short explanation with an uncertainty disclaimer
- **Session history** in a list and a calendar, with edit and delete
- **Opt-in local notifications** using neutral wording, with no pressure to extend a fast
- **Safety onboarding** with an adult eligibility check: users under 18 get no active fasting plans
- **Offline-first**: all data stays on the device

## Repository structure

```
LIFE-fasting/
├── frontend/   Flutter (Dart) mobile app for Android and iOS
├── backend/    Reserved; none is needed for the MVP (see backend/README.md)
└── docs/       Product requirements and design documentation
```

## Tech stack

| Layer | Choice |
|---|---|
| UI | Flutter / Dart |
| State management | Provider, Riverpod or Bloc (to be chosen) |
| Timer logic | Pure Dart domain service; elapsed time is derived from stored UTC timestamps |
| Ring rendering | `CustomPainter` |
| Local storage | SQLite (or Isar/Hive after evaluation) |
| Notifications | Local notification plugin |

## Design tokens

| Token | Value |
|---|---|
| Primary sky blue | `#65BFE8` |
| Deep blue | `#246B8E` |
| Pale blue | `#EAF7FC` |
| Background | `#F5FBFE` |
| Ring track | `#D8EDF6` |
| Body text | `#203443` |
| Secondary text | `#526775` |

These colours are approximations and will be confirmed against reference imagery.

## Getting started

The Flutter app hasn't been scaffolded yet. Once it is:

```bash
cd frontend
flutter pub get
flutter run
```

## Documentation

- [Product Requirements Document](docs/Intermittent_Fasting_Companion_PRD.txt)

## Principles

- Persisted timestamps are the source of truth for the timer, never the displayed counter
- Neutral copy: no streaks, no guilt, and users can end a session at any time
- No proprietary LIFE Fasting assets, icons, code or branding are used
- Accessible: WCAG AA contrast, screen-reader labels, scalable text, and state is never shown by colour alone
