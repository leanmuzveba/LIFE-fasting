import 'dart:math' as math;

import 'package:health/health.dart';

import '../domain/activity.dart';

/// A workout recorded by your watch (via Mi Fitness → Health Connect).
class WatchWorkout {
  const WatchWorkout({
    required this.id,
    required this.type,
    required this.start,
    required this.end,
    this.kcal,
    this.source = '',
  });

  final String id; // Health Connect record id: used to avoid duplicates
  final ActivityType type;
  final DateTime start;
  final DateTime end;
  final double? kcal;
  final String source;
}

/// Reads (never writes) Health Connect: workouts, calories burned, steps.
class HealthSource {
  final _health = Health();
  bool _configured = false;

  static const _types = [
    HealthDataType.WORKOUT,
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.DISTANCE_DELTA,
  ];

  Future<void> _init() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Health Connect is installed and usable on this phone.
  Future<bool> available() async {
    await _init();
    return await _health.isHealthConnectAvailable();
  }

  /// Opens the Play Store page for Health Connect.
  Future<void> install() async {
    await _init();
    await _health.installHealthConnect();
  }

  /// Shows Health Connect's permission screen; true when MagnaVita may read.
  Future<bool> connect() async {
    await _init();
    return _health.requestAuthorization(_types, permissions: [for (final _ in _types) HealthDataAccess.READ]);
  }

  Future<bool> connected() async {
    await _init();
    return await _health.hasPermissions(_types, permissions: [for (final _ in _types) HealthDataAccess.READ]) ?? false;
  }

  /// Sum of [type] per app that wrote it (by app id), and each app's name.
  Future<(Map<String, double>, Map<String, String>)> _bySource(HealthDataType type, DateTime from, DateTime to) async {
    final points = _health.removeDuplicates(
      await _health.getHealthDataFromTypes(types: [type], startTime: from, endTime: to),
    );
    final totals = <String, double>{}, names = <String, String>{};
    for (final p in points) {
      if (p.value case final NumericHealthValue v) {
        totals[p.sourceId] = (totals[p.sourceId] ?? 0) + v.numericValue.toDouble();
        names[p.sourceId] = p.sourceName;
      }
    }
    return (totals, names);
  }

  /// One app's total: several apps writing the same steps would otherwise be
  /// counted twice.
  Future<double?> _total(HealthDataType type, DateTime from, DateTime to) async {
    final (totals, _) = await _bySource(type, from, to);
    final id = preferredSource(totals);
    return id == null ? null : totals[id];
  }

  Future<int?> steps(DateTime from, DateTime to) async {
    await _init();
    return (await _total(HealthDataType.STEPS, from, to))?.round();
  }

  /// When your watch app's latest step record ends: how fresh the count is.
  Future<DateTime?> lastStepsAt(DateTime from, DateTime to) async {
    await _init();
    final points = _health.removeDuplicates(
      await _health.getHealthDataFromTypes(types: const [HealthDataType.STEPS], startTime: from, endTime: to),
    );
    final id = preferredSource({for (final p in points) p.sourceId: 1});
    DateTime? last;
    for (final p in points) {
      if (p.sourceId == id && (last == null || p.dateTo.isAfter(last))) last = p.dateTo;
    }
    return last;
  }

  /// Active time (minutes) from your watch app's step records: each record
  /// counts its length, capped at steps ÷ 60 so slow or sparse steps don't
  /// count as a full minute. Null when there are none.
  // ponytail: Health Connect has no "active minutes" record, so this
  // approximates Mi Fitness's figure; workouts without steps aren't counted.
  Future<int?> activeMinutes(DateTime from, DateTime to) async {
    await _init();
    final points = _health.removeDuplicates(
      await _health.getHealthDataFromTypes(types: const [HealthDataType.STEPS], startTime: from, endTime: to),
    );
    final totals = <String, double>{};
    for (final p in points) {
      if (p.value case final NumericHealthValue v) {
        final minutes = math.min(p.dateTo.difference(p.dateFrom).inSeconds / 60, v.numericValue / 60);
        totals[p.sourceId] = (totals[p.sourceId] ?? 0) + minutes;
      }
    }
    final id = preferredSource(totals);
    return id == null ? null : totals[id]!.round();
  }

  /// Calories burned between [from] and [to] from your watch app: active
  /// calories if it writes them, else its "total" calories (Mi Fitness's
  /// exclude resting energy), else the sum of its workouts. Null when none.
  // ponytail: apps that write true total (incl. resting) calories would show
  // more than activity alone; fine for Mi Fitness, revisit for other watches.
  Future<double?> caloriesBurned(DateTime from, DateTime to) async {
    await _init();
    for (final type in const [HealthDataType.ACTIVE_ENERGY_BURNED, HealthDataType.TOTAL_CALORIES_BURNED]) {
      final kcal = await _total(type, from, to);
      if (kcal != null && kcal > 0) return kcal;
    }
    final fromWorkouts = (await workouts(from, to)).fold<double>(0, (a, w) => a + (w.kcal ?? 0));
    return fromWorkouts > 0 ? fromWorkouts : null;
  }

  /// What each app wrote today — for troubleshooting in Settings → Watch.
  Future<List<SourceTotals>> breakdown(DateTime from, DateTime to) async {
    await _init();
    final (steps, n1) = await _bySource(HealthDataType.STEPS, from, to);
    final (active, n2) = await _bySource(HealthDataType.ACTIVE_ENERGY_BURNED, from, to);
    final (total, n3) = await _bySource(HealthDataType.TOTAL_CALORIES_BURNED, from, to);
    final names = {...n1, ...n2, ...n3};
    final chosen = preferredSource(steps) ?? preferredSource(active) ?? preferredSource(total);
    return [
      for (final id in names.keys)
        SourceTotals(
          name: names[id]!.isEmpty ? id : names[id]!,
          steps: steps[id]?.round(),
          activeKcal: active[id]?.round(),
          totalKcal: total[id]?.round(),
          used: id == chosen,
        ),
    ];
  }

  Future<List<WatchWorkout>> workouts(DateTime from, DateTime to) async {
    await _init();
    final points = await _health.getHealthDataFromTypes(
      types: const [HealthDataType.WORKOUT],
      startTime: from,
      endTime: to,
    );
    final counts = <String, double>{};
    for (final p in points) {
      counts[p.sourceId] = (counts[p.sourceId] ?? 0) + 1;
    }
    final keep = preferredSource(counts);
    return [
      for (final p in points)
        if (p.value case final WorkoutHealthValue w when p.sourceId == keep)
          WatchWorkout(
            id: p.uuid,
            type: workoutType(w.workoutActivityType),
            start: p.dateFrom,
            end: p.dateTo,
            kcal: (w.totalEnergyBurned ?? 0) > 0 ? w.totalEnergyBurned!.toDouble() : null,
            source: p.sourceName,
          ),
    ];
  }
}

/// Maps Health Connect exercise types onto MagnaVita's activity types.
ActivityType workoutType(HealthWorkoutActivityType t) {
  final n = t.name.toLowerCase();
  if (n.contains('walk') || n.contains('hik')) return ActivityType.walk;
  if (n.contains('run')) return ActivityType.run;
  if (n.contains('bik') || n.contains('cycl')) return ActivityType.cycle;
  if (n.contains('yoga') || n.contains('pilates')) return ActivityType.yoga;
  if (n.contains('strength') || n.contains('weight') || n.contains('functional') || n.contains('core')) {
    return ActivityType.strength;
  }
  return ActivityType.other;
}

/// Xiaomi's apps (Mi Fitness and older names).
const _xiaomiApps = ['com.mi.health', 'com.xiaomi.wearable', 'com.xiaomi.hm.health'];

/// The app to trust: Mi Fitness if present, else the one with the most data.
String? preferredSource(Map<String, double> totals) {
  if (totals.isEmpty) return null;
  for (final id in totals.keys) {
    if (_xiaomiApps.any(id.startsWith)) return id;
  }
  return (totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
}

class SourceTotals {
  const SourceTotals({required this.name, this.steps, this.activeKcal, this.totalKcal, this.used = false});
  final String name;
  final int? steps;
  final int? activeKcal;
  final int? totalKcal;
  final bool used; // the app MagnaVita reads from
}
