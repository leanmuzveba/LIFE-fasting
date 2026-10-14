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

enum SessionTimeError { startInFuture, endInFuture, endBeforeStart, overlaps }

/// Validates an edited session. Returns the problem, or null when valid.
/// [others] are your other fasts (the one being edited is skipped by id): an
/// edited fast may not overlap any of them; an open fast runs until [now].
SessionTimeError? validateSessionTimes({
  required DateTime start,
  DateTime? end,
  required DateTime now,
  int? id,
  Iterable<FastingSession> others = const [],
}) {
  if (start.isAfter(now)) return SessionTimeError.startInFuture;
  if (end != null) {
    if (end.isAfter(now)) return SessionTimeError.endInFuture;
    if (!end.isAfter(start)) return SessionTimeError.endBeforeStart;
  }
  final until = end ?? now;
  for (final o in others) {
    if (o.id == id) continue;
    if (start.isBefore(o.endedAt ?? now) && o.startedAt.isBefore(until)) return SessionTimeError.overlaps;
  }
  return null;
}
