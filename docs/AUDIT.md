# RUVA v1.2 — Phase 0 audit of the existing app

Snapshot of the Flutter app in `frontend/` before the RUVA expansion (PRD v1.2 §12, §17 Phase 0).

## Screens and navigation

| Screen | File | Notes |
|---|---|---|
| Splash (heartbeat ring, loading) | `features/splash/splash_screen.dart` | Shown by the root gate until settings load (min 1.6 s) |
| Onboarding + age check / under-18 info | `features/onboarding/onboarding.dart` | Under-18s never reach fasting controls |
| Shell with bottom nav (Timer · History · Settings) | `features/shell/app_shell.dart` | `IndexedStack`, sub-pages pushed with `Navigator` |
| Timer (ring, Start/End, edit start, times pop-up) | `features/home/*`, `features/ring/fasting_ring.dart` | Ring = `CustomPainter`, phase colours yellow/red |
| Milestone detail | `features/milestones/milestone_detail_screen.dart` | |
| Target setup | `features/setup/target_setup_screen.dart` | Presets 12/14/16/18 h + custom, 1–24 h |
| History list + calendar + session edit | `features/history/*` | |
| Settings | `features/settings/settings_screen.dart` | Target, 24 h clock, notifications, delete-all |

## Timer logic

- Pure Dart in `domain/fasting_timer.dart` + `domain/fasting_session.dart`: elapsed = now − stored UTC start; never a running counter (PRD §2.1 satisfied).
- Milestones are data (`domain/milestone.dart`), placed by `TimerSnapshot.compute`.
- 1 s tick from `nowProvider`; app restart restores the active session from the database.

## State management

Riverpod 3 (`state/providers.dart`), no code generation: `AsyncNotifier`s for settings, active session and notification prefs; `SessionActions` for edits; injectable clock for tests. **Reuse for all new modules.**

## Storage and backend

- sqflite, database `life_fasting.db`, **schema version 1**: `sessions`, `settings` (key/value), `notification_prefs`. Constraints: one active session, `ended_at > started_at`.
- No backend, no network calls, no accounts. Milestone copy and UI strings are in-app (`lib/l10n/app_en.arb`).
- Notifications: `flutter_local_notifications` (target reached, daily reminder), re-synced on launch.

## Dependencies

flutter_riverpod, sqflite, path, intl, flutter_svg, flutter_local_notifications, timezone, flutter_localizations. Dev: flutter_lints, sqflite_common_ffi, flutter_launcher_icons, flutter_native_splash. Fonts bundled: Manrope, Inter (OFL).

## Tests

67 tests across domain (timer maths), data (repositories, constraints, reopen), state (start/edit/end, restart, age gate), widgets (ring, home, history, settings, onboarding, splash) and accessibility (tap targets, contrast pairs, text scaling).

## Data-migration risks for v1.2

1. **Existing installs are on schema v1.** v2 must add tables with `onUpgrade` only — never drop or rewrite `sessions`, `settings`, `notification_prefs`. Covered by a v1→v2 upgrade test that seeds v1 data first.
2. **Stable identifiers.** Existing rows use integer autoincrement ids; new entities will also use integer ids plus `created_at`/`updated_at` (PRD §13). No id rewrite of old rows.
3. **Package id stays** `com.leanmuzveba.life_fasting` so the phone keeps its data across the RUVA rename; only the display name changes.
4. **Database file name stays** `life_fasting.db` for the same reason.
5. **Notification ids 1–2 are taken**; new reminders (hydration, monthly review) use new ids.
6. **Rebrand touches theme tokens used everywhere** — contrast tests must be updated to the new palette and must pass before release.
