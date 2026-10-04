/// One recorded fast. Timestamps are stored as UTC instants and are the only
/// source of truth: elapsed time is always derived, never stored or counted.
class FastingSession {
  const FastingSession({
    this.id,
    required this.startedAt,
    this.endedAt,
    required this.targetMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int targetMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => endedAt == null;
  Duration get target => Duration(minutes: targetMinutes);
  DateTime get plannedEnd => startedAt.add(target);

  /// Elapsed time at [now] for an active session, or the final duration.
  Duration elapsedAt(DateTime now) {
    final d = (endedAt ?? now).difference(startedAt);
    return d.isNegative ? Duration.zero : d;
  }

  /// "Target reached" vs simply "ended". A shorter session is not a failure.
  bool targetReachedAt(DateTime now) => elapsedAt(now) >= target;

  FastingSession copyWith({
    int? id,
    DateTime? startedAt,
    DateTime? Function()? endedAt,
    int? targetMinutes,
    DateTime? updatedAt,
  }) => FastingSession(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt != null ? endedAt() : this.endedAt,
    targetMinutes: targetMinutes ?? this.targetMinutes,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

/// Validates an edited session. Returns an error message, or null when valid.
String? validateSessionTimes({required DateTime start, DateTime? end, required DateTime now}) {
  if (start.isAfter(now)) return 'Start time can’t be in the future.';
  if (end != null) {
    if (end.isAfter(now)) return 'End time can’t be in the future.';
    if (!end.isAfter(start)) return 'End time must be after the start time.';
  }
  return null;
}

/// The "Edit start time" sheet picks a clock time only. It resolves to the most
/// recent occurrence of that time at or before [now] (local time), so 19:00
/// picked at 07:24 means yesterday evening.
DateTime resolveStartFromClockTime({required int hour, required int minute, required DateTime now}) {
  final local = now.toLocal();
  var d = DateTime(local.year, local.month, local.day, hour, minute);
  if (d.isAfter(local)) d = DateTime(local.year, local.month, local.day - 1, hour, minute);
  return d.toUtc();
}
