import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/domain/settings.dart';
import 'package:life_fasting/state/providers.dart';

import '../helpers.dart';

void main() {
  final t0 = DateTime.utc(2026, 10, 3, 17);

  test('start / edit / end flow persists and feeds history', () async {
    final db = await openTestDb();
    final clock = FakeClock(t0);
    final c = await testContainer(db, clock);
    await c.read(settingsProvider.notifier).change((s) => s.copyWith(eligibility: AgeEligibility.adult));

    await c.read(activeSessionProvider.notifier).start();
    expect(c.read(activeSessionProvider).value!.startedAt, t0);

    // Starting twice is a no-op, not a second session.
    await c.read(activeSessionProvider.notifier).start();
    expect(await c.read(historyProvider.future), hasLength(1));

    clock.advance(const Duration(hours: 3));
    final early = t0.subtract(const Duration(hours: 1));
    expect(await c.read(activeSessionProvider.notifier).editStart(early), isNull);
    expect(c.read(activeSessionProvider).value!.startedAt, early);
    expect(
      await c.read(activeSessionProvider.notifier).editStart(clock.now.add(const Duration(minutes: 5))),
      isNotNull,
      reason: 'future start rejected',
    );

    final ended = await c.read(activeSessionProvider.notifier).end();
    expect(ended!.elapsedAt(clock.now), const Duration(hours: 4));
    expect(c.read(activeSessionProvider).value, isNull);
    final history = await c.read(historyProvider.future);
    expect(history.single.endedAt, clock.now);
    c.dispose();
    await db.close();
  });

  test('app restart restores the running session from the database', () async {
    final db = await openTestDb();
    final clock = FakeClock(t0);
    var c = await testContainer(db, clock);
    await c.read(settingsProvider.notifier).change((s) => s.copyWith(eligibility: AgeEligibility.adult));
    await c.read(activeSessionProvider.notifier).start();
    c.dispose(); // app killed

    clock.advance(const Duration(hours: 5, minutes: 2));
    c = await testContainer(db, clock); // app reopened
    final s = c.read(activeSessionProvider).value!;
    expect(s.elapsedAt(clock.now), const Duration(hours: 5, minutes: 2));
    c.dispose();
    await db.close();
  });

  test('under-18 and unconfirmed users cannot start a session', () async {
    final db = await openTestDb();
    final c = await testContainer(db, FakeClock(t0));
    await expectLater(c.read(activeSessionProvider.notifier).start(), throwsA(isA<NotEligibleError>()));
    await c.read(settingsProvider.notifier).change((s) => s.copyWith(eligibility: AgeEligibility.under18));
    await expectLater(c.read(activeSessionProvider.notifier).start(), throwsA(isA<NotEligibleError>()));
    expect(await c.read(historyProvider.future), isEmpty);
    c.dispose();
    await db.close();
  });
}
