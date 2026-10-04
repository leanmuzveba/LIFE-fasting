import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/core/format.dart';
import 'package:life_fasting/domain/fasting_session.dart';
import 'package:life_fasting/domain/fasting_timer.dart';
import 'package:life_fasting/domain/milestone.dart';

FastingSession session(DateTime start, {int targetMinutes = 16 * 60, DateTime? end}) =>
    FastingSession(startedAt: start, endedAt: end, targetMinutes: targetMinutes, createdAt: start, updatedAt: start);

TimerSnapshot snap(FastingSession? s, DateTime now, {int idle = 16 * 60}) =>
    TimerSnapshot.compute(session: s, idleTargetMinutes: idle, now: now);

void main() {
  final start = DateTime.utc(2026, 10, 3, 17); // 19:00 in UTC+2

  group('elapsed time', () {
    test('is now minus start', () {
      final s = snap(session(start), start.add(const Duration(hours: 12, minutes: 24, seconds: 36)));
      expect(formatHms(s.elapsed), '12:24:36');
      expect(formatHms(s.remaining), '03:35:24');
      expect(s.progress, closeTo(44676 / 57600, 1e-9));
      expect(s.targetReached, isFalse);
    });

    test('crosses midnight without resetting', () {
      final late = DateTime.utc(2026, 10, 3, 23, 30);
      final s = snap(session(late), DateTime.utc(2026, 10, 4, 1, 15));
      expect(s.elapsed, const Duration(hours: 1, minutes: 45));
    });

    test('is the same instant whatever the device time zone', () {
      final nowUtc = start.add(const Duration(hours: 5));
      final nowOffset = nowUtc.toLocal(); // same instant, local representation
      expect(snap(session(start), nowUtc).elapsed, snap(session(start), nowOffset).elapsed);
    });

    test('never goes negative if the clock moves backwards', () {
      expect(snap(session(start), start.subtract(const Duration(minutes: 5))).elapsed, Duration.zero);
    });

    test('hours keep counting past 24', () {
      expect(formatHms(const Duration(hours: 27, minutes: 3, seconds: 9)), '27:03:09');
    });
  });

  group('target', () {
    test('reached caps ring progress at 100% while elapsed continues', () {
      final s = snap(session(start), start.add(const Duration(hours: 17)));
      expect(s.targetReached, isTrue);
      expect(s.progress, 1.0);
      expect(s.remaining, Duration.zero);
      expect(s.elapsed, const Duration(hours: 17));
    });

    test('idle shows the configured target and no progress', () {
      final s = snap(null, start, idle: 14 * 60);
      expect(s.running, isFalse);
      expect(s.target, const Duration(hours: 14));
      expect(s.progress, 0);
      expect(s.markers.every((m) => m.state == MarkerState.upcoming), isTrue);
    });

    test('an ended session is not "running"', () {
      final s = snap(session(start, end: start.add(const Duration(hours: 2))), start.add(const Duration(hours: 3)));
      expect(s.running, isFalse);
    });

    test('a short ended session is "ended", not a failure, and keeps its duration', () {
      final s = session(start, end: start.add(const Duration(hours: 9)));
      expect(s.targetReachedAt(DateTime.now()), isFalse);
      expect(s.elapsedAt(DateTime.now()), const Duration(hours: 9));
    });
  });

  group('milestones', () {
    test('current marker is the latest one reached', () {
      final s = snap(session(start), start.add(const Duration(hours: 12, minutes: 24)));
      final states = {for (final m in s.markers) m.milestone.id: m.state};
      expect(states, {'start': MarkerState.passed, 'fuel': MarkerState.current, 'ketosis': MarkerState.upcoming});
      expect(s.beyondTarget.map((m) => m.id), ['later']);
    });

    test('target shorter than a milestone moves it off the ring, never extends the target', () {
      final s = snap(session(start, targetMinutes: 12 * 60), start.add(const Duration(hours: 11)));
      expect(s.markers.map((m) => m.milestone.id), ['start', 'fuel']);
      expect(s.beyondTarget.map((m) => m.id), ['ketosis', 'later']);
      expect(s.target, const Duration(hours: 12));
    });

    test('marker positions follow offset / target', () {
      final s = snap(session(start), start);
      final f = {for (final m in s.markers) m.milestone.id: m.fraction};
      expect(f['start'], 0);
      expect(f['fuel'], closeTo(10 / 16, 1e-9));
      expect(f['ketosis'], closeTo(14 / 16, 1e-9));
    });

    test('markers keep a minimum gap so tap targets never overlap', () {
      const close = [
        Milestone(id: 'a', kind: MilestoneKind.clock, title: 'a', short: 'a', offsetMinutes: 0, window: '', body: ''),
        Milestone(id: 'b', kind: MilestoneKind.bolt, title: 'b', short: 'b', offsetMinutes: 5, window: '', body: ''),
        Milestone(id: 'c', kind: MilestoneKind.drop, title: 'c', short: 'c', offsetMinutes: 960, window: '', body: ''),
      ];
      final s = TimerSnapshot.compute(
        session: session(start),
        idleTargetMinutes: 960,
        now: start,
        milestones: close,
        gapFraction: 0.05,
      );
      final f = s.markers.map((m) => m.fraction).toList();
      expect(f[1] - f[0], greaterThanOrEqualTo(0.05 - 1e-9));
      expect(f[2], lessThanOrEqualTo(0.95 + 1e-9)); // never overlaps the start at 12 o'clock
    });

    test('disabled milestones are hidden', () {
      final list = [
        ...defaultMilestones.take(1),
        const Milestone(
          id: 'x',
          kind: MilestoneKind.bolt,
          title: 'x',
          short: 'x',
          offsetMinutes: 60,
          window: '',
          body: '',
          enabled: false,
        ),
      ];
      final s = TimerSnapshot.compute(session: null, idleTargetMinutes: 960, now: start, milestones: list);
      expect(s.markers.map((m) => m.milestone.id), ['start']);
    });
  });

  group('editing start time', () {
    test('a clock time later than now means yesterday', () {
      final now = DateTime(2026, 10, 4, 7, 24); // local
      final r = resolveStartFromClockTime(hour: 19, minute: 0, now: now).toLocal();
      expect(r, DateTime(2026, 10, 3, 19, 0));
    });

    test('a clock time earlier than now means today', () {
      final now = DateTime(2026, 10, 4, 7, 24);
      expect(resolveStartFromClockTime(hour: 6, minute: 5, now: now).toLocal(), DateTime(2026, 10, 4, 6, 5));
    });

    test('edited start recalculates elapsed', () {
      final now = start.add(const Duration(hours: 10));
      final s = session(start).copyWith(startedAt: start.add(const Duration(hours: 2)));
      expect(snap(s, now).elapsed, const Duration(hours: 8));
    });

    test('validation rejects future and inverted times', () {
      final now = start.add(const Duration(hours: 1));
      expect(validateSessionTimes(start: now.add(const Duration(minutes: 1)), now: now), isNotNull);
      expect(validateSessionTimes(start: start, end: start, now: now), isNotNull);
      expect(validateSessionTimes(start: start, end: now.add(const Duration(minutes: 1)), now: now), isNotNull);
      expect(validateSessionTimes(start: start, end: now, now: now), isNull);
    });
  });

  test('formatting helpers', () {
    expect(formatTarget(const Duration(hours: 16)), '16 h');
    expect(formatTarget(const Duration(hours: 13, minutes: 30)), '13 h 30 m');
    expect(formatHoursMinutes(const Duration(hours: 12, minutes: 24)), '12 h 24 m');
  });
}
