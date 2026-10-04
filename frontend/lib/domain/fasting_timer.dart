import 'dart:math' as math;

import 'fasting_session.dart';
import 'milestone.dart';

enum MarkerState { upcoming, passed, current }

class MarkerPlacement {
  const MarkerPlacement(this.milestone, this.fraction, this.state);

  final Milestone milestone;

  /// Position around the ring, 0..1 clockwise from 12 o'clock.
  final double fraction;
  final MarkerState state;
}

/// Everything the Home screen and ring need, derived from a session (or none)
/// and the current instant. Pure: same inputs, same output.
class TimerSnapshot {
  TimerSnapshot._({
    required this.running,
    required this.elapsed,
    required this.target,
    required this.markers,
    required this.beyondTarget,
  });

  /// [gapFraction] is the minimum spacing between markers as a fraction of the
  /// ring's circumference, so tap targets never overlap (UI supplies it).
  factory TimerSnapshot.compute({
    required FastingSession? session,
    required int idleTargetMinutes,
    required DateTime now,
    List<Milestone> milestones = defaultMilestones,
    double gapFraction = 0,
  }) {
    final running = session != null && session.isActive;
    final target = Duration(minutes: math.max(1, running ? session.targetMinutes : idleTargetMinutes));
    final elapsed = running ? session.elapsedAt(now) : Duration.zero;

    final enabled = milestones.where((m) => m.enabled).toList()..sort((a, b) => a.offset.compareTo(b.offset));
    final onRing = enabled.where((m) => m.offset <= target).toList();
    final beyond = enabled.where((m) => m.offset > target).toList();

    final reached = running ? onRing.where((m) => elapsed >= m.offset).toList() : const <Milestone>[];
    final current = reached.isEmpty ? null : reached.last;

    var prev = -1.0;
    final markers = <MarkerPlacement>[];
    for (final m in onRing) {
      var f = math.min(m.offset.inSeconds / target.inSeconds, 1 - gapFraction);
      if (f < prev + gapFraction) f = prev + gapFraction;
      prev = f;
      final state = identical(m, current)
          ? MarkerState.current
          : reached.contains(m)
          ? MarkerState.passed
          : MarkerState.upcoming;
      markers.add(MarkerPlacement(m, f, state));
    }

    return TimerSnapshot._(running: running, elapsed: elapsed, target: target, markers: markers, beyondTarget: beyond);
  }

  final bool running;
  final Duration elapsed;
  final Duration target;
  final List<MarkerPlacement> markers;

  /// Milestones estimated after the user's target: shown as chips, never as a
  /// reason to keep going.
  final List<Milestone> beyondTarget;

  bool get targetReached => running && elapsed >= target;

  /// Remaining planned time; zero once the target is reached.
  Duration get remaining {
    final r = target - elapsed;
    return r.isNegative ? Duration.zero : r;
  }

  /// Ring fill 0..1, capped at 1 while elapsed keeps counting (FR-05).
  double get progress => running ? math.min(elapsed.inMilliseconds / target.inMilliseconds, 1.0) : 0;
}
