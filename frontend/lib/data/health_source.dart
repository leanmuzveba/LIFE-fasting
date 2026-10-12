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

  /// Shows Health Connect's permission screen; true when RUVA may read.
  Future<bool> connect() async {
    await _init();
    return _health.requestAuthorization(_types, permissions: [for (final _ in _types) HealthDataAccess.READ]);
  }

  Future<bool> connected() async {
    await _init();
    return await _health.hasPermissions(_types, permissions: [for (final _ in _types) HealthDataAccess.READ]) ?? false;
  }

  Future<int?> steps(DateTime from, DateTime to) async {
    await _init();
    return _health.getTotalStepsInInterval(from, to);
  }

  /// Calories burned between [from] and [to]: active calories if the watch
  /// app writes them, else its "total" calories (Mi Fitness's exclude resting
  /// energy), else the sum of its workouts. Null when there's no data at all.
  // ponytail: apps that write true total (incl. resting) calories would show
  // more than activity alone; fine for Mi Fitness, revisit for other watches.
  Future<double?> caloriesBurned(DateTime from, DateTime to) async {
    await _init();
    for (final type in const [HealthDataType.ACTIVE_ENERGY_BURNED, HealthDataType.TOTAL_CALORIES_BURNED]) {
      final points = await _health.getHealthDataFromTypes(types: [type], startTime: from, endTime: to);
      if (points.isNotEmpty) {
        return points.fold<double>(0, (a, p) => a + (p.value as NumericHealthValue).numericValue.toDouble());
      }
    }
    final fromWorkouts = (await workouts(from, to)).fold<double>(0, (a, w) => a + (w.kcal ?? 0));
    return fromWorkouts > 0 ? fromWorkouts : null;
  }

  Future<List<WatchWorkout>> workouts(DateTime from, DateTime to) async {
    await _init();
    final points = await _health.getHealthDataFromTypes(
      types: const [HealthDataType.WORKOUT],
      startTime: from,
      endTime: to,
    );
    return [
      for (final p in points)
        if (p.value case final WorkoutHealthValue w)
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

/// Maps Health Connect exercise types onto RUVA's activity types.
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
