import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../data/session_repository.dart';
import '../data/settings_repository.dart';
import '../domain/fasting_session.dart';
import '../domain/fasting_timer.dart';
import '../domain/settings.dart';

/// Opened in main() and injected with an override.
final databaseProvider = Provider<Database>((ref) => throw UnimplementedError('override databaseProvider'));

final sessionRepositoryProvider = Provider((ref) => SessionRepository(ref.watch(databaseProvider)));
final settingsRepositoryProvider = Provider((ref) => SettingsRepository(ref.watch(databaseProvider)));

/// Current instant. Overridden in tests for a fixed clock.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Ticks once a second. The displayed time is recomputed from stored
/// timestamps on every tick, so pausing (app in background) never drifts.
final nowProvider = StreamProvider<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  final controller = StreamController<DateTime>();
  controller.add(clock());
  final timer = Timer.periodic(const Duration(seconds: 1), (_) => controller.add(clock()));
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });
  return controller.stream;
});

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> save(AppSettings next) async {
    await ref.read(settingsRepositoryProvider).save(next);
    state = AsyncData(next);
  }

  Future<void> change(AppSettings Function(AppSettings) edit) async => save(edit(await future));
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// Thrown when an action is blocked by the safety rules (FR-12).
class NotEligibleError extends StateError {
  NotEligibleError() : super('Fasting sessions are only available to confirmed adults.');
}

class ActiveSessionNotifier extends AsyncNotifier<FastingSession?> {
  @override
  Future<FastingSession?> build() => ref.watch(sessionRepositoryProvider).active();

  SessionRepository get _repo => ref.read(sessionRepositoryProvider);
  DateTime _now() => ref.read(clockProvider)().toUtc();

  Future<void> start() async {
    final settings = await ref.read(settingsProvider.future);
    if (!settings.canFast) throw NotEligibleError();
    if (await future != null) return;
    final now = _now();
    final s = await _repo.insert(
      FastingSession(startedAt: now, targetMinutes: settings.targetMinutes, createdAt: now, updatedAt: now),
    );
    state = AsyncData(s);
    ref.invalidate(historyProvider);
  }

  /// Ends the session and returns it as saved.
  Future<FastingSession?> end() async {
    final s = await future;
    if (s == null) return null;
    final now = _now();
    // Guard against a device clock that moved behind the start time.
    final endAt = now.isAfter(s.startedAt) ? now : s.startedAt.add(const Duration(seconds: 1));
    final ended = s.copyWith(endedAt: () => endAt, updatedAt: now);
    await _repo.update(ended);
    state = const AsyncData(null);
    ref.invalidate(historyProvider);
    return ended;
  }

  /// Returns a validation error, or null when saved.
  Future<String?> editStart(DateTime startedAt) async {
    final s = await future;
    if (s == null) return null;
    final now = _now();
    final error = validateSessionTimes(start: startedAt, now: now);
    if (error != null) return error;
    final edited = s.copyWith(startedAt: startedAt.toUtc(), updatedAt: now);
    await _repo.update(edited);
    state = AsyncData(edited);
    ref.invalidate(historyProvider);
    return null;
  }
}

final activeSessionProvider = AsyncNotifierProvider<ActiveSessionNotifier, FastingSession?>(ActiveSessionNotifier.new);

/// All sessions, newest first.
final historyProvider = FutureProvider<List<FastingSession>>((ref) => ref.watch(sessionRepositoryProvider).all());

/// Derived timer state for the Home screen; null until data has loaded.
final timerSnapshotProvider = Provider.family<TimerSnapshot?, double>((ref, gapFraction) {
  final session = ref.watch(activeSessionProvider).value;
  final settings = ref.watch(settingsProvider).value;
  final now = ref.watch(nowProvider).value;
  if (settings == null || now == null || ref.watch(activeSessionProvider).isLoading) return null;
  return TimerSnapshot.compute(
    session: session,
    idleTargetMinutes: settings.targetMinutes,
    now: now,
    gapFraction: gapFraction,
  );
});
