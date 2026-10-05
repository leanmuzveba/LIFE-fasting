import 'activity.dart';
import 'fasting_session.dart';
import 'hydration.dart';

/// Everything recorded on one local calendar day (PRD v1.2 §10). Built only
/// from real records — a day with nothing recorded simply has no summary.
class DaySummary {
  DaySummary(this.day);

  /// Local midnight.
  final DateTime day;
  final List<FastingSession> fasts = []; // sessions that started this day
  final List<HydrationEntry> water = [];
  final List<ActivityEntry> activities = [];

  double get waterMl => totalMl(water);
  int get activityMinutes => totalMinutes(activities);
  bool get hasFast => fasts.isNotEmpty;
  bool get hasWater => water.isNotEmpty;
  bool get hasActivity => activities.isNotEmpty;
  bool get isEmpty => !hasFast && !hasWater && !hasActivity;
}

DateTime _localDay(DateTime t) {
  final l = t.toLocal();
  return DateTime(l.year, l.month, l.day);
}

/// Groups records by the local day they started/were logged on.
Map<DateTime, DaySummary> summariseByDay({
  required Iterable<FastingSession> sessions,
  required Iterable<HydrationEntry> water,
  required Iterable<ActivityEntry> activities,
}) {
  final out = <DateTime, DaySummary>{};
  DaySummary at(DateTime t) => out.putIfAbsent(_localDay(t), () => DaySummary(_localDay(t)));
  for (final s in sessions) {
    at(s.startedAt).fasts.add(s);
  }
  for (final w in water) {
    at(w.loggedAt).water.add(w);
  }
  for (final a in activities) {
    at(a.startedAt).activities.add(a);
  }
  return out;
}

/// Completed fasts that started in the last [length] days. Chart points are
/// hours fasted per start day; days without a completed fast are absent
/// (charts must not invent data, PRD §10).
class FastingTrend {
  FastingTrend._(this.days, this.points, this.fastHours);

  /// Every day in the window, oldest first (for the x axis).
  final List<DateTime> days;

  /// Day index in [days] -> total hours fasted (completed fasts started that day).
  final Map<int, double> points;

  /// Length of each completed fast in the window, in hours.
  final List<double> fastHours;

  factory FastingTrend.of(Iterable<FastingSession> sessions, {required DateTime today, int length = 14}) {
    final end = _localDay(today);
    final days = [for (var i = length - 1; i >= 0; i--) DateTime(end.year, end.month, end.day - i)];
    final points = <int, double>{};
    final hours = <double>[];
    for (final s in sessions) {
      if (s.isActive) continue;
      final i = days.indexOf(_localDay(s.startedAt));
      if (i < 0) continue;
      final h = s.endedAt!.difference(s.startedAt).inMinutes / 60;
      hours.add(h);
      points[i] = (points[i] ?? 0) + h;
    }
    return FastingTrend._(days, points, hours);
  }

  bool get isEmpty => fastHours.isEmpty;
  int get fastCount => fastHours.length;

  /// Mean length of a completed fast in the window (null if none).
  double? get average => isEmpty ? null : fastHours.reduce((a, b) => a + b) / fastHours.length;
  double? get longest => isEmpty ? null : fastHours.reduce((a, b) => a > b ? a : b);
}
