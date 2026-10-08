import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/domain/fasting_session.dart';
import 'package:life_fasting/domain/history.dart';

import '../widget_test.dart' show pumpApp, tick, quickAdd;

Future<void> _fast(WidgetTester tester, dynamic clock, Duration d) async {
  await quickAdd(tester, 'Start fast');
  await tick(tester, clock, d);
  await quickAdd(tester, 'End fast');
  await tester.tap(find.text('End session'));
  await tester.pumpAndSettle();
}

Future<void> _openHistory(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 2400); // whole page laid out
  await tester.tap(find.bySemanticsLabel('History'));
  await tester.pumpAndSettle();
}

void main() {
  test('trend: completed fasts only, by start day, with gaps for empty days', () {
    final today = DateTime(2026, 10, 14, 9);
    FastingSession s(int day, int hours) {
      final start = DateTime(2026, 10, day, 19).toUtc();
      return FastingSession(
        startedAt: start,
        endedAt: start.add(Duration(hours: hours)),
        targetMinutes: 960,
        createdAt: start,
        updatedAt: start,
      );
    }

    final active = FastingSession(
      startedAt: DateTime(2026, 10, 13, 20).toUtc(),
      targetMinutes: 960,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    final t = FastingTrend.of([s(1, 14), s(5, 16), s(6, 18), s(20 - 30, 10), active], today: today);
    expect(t.days.first, DateTime(2026, 10, 1));
    expect(t.days.last, DateTime(2026, 10, 14));
    expect(t.points, {0: 14.0, 4: 16.0, 5: 18.0}, reason: 'only completed fasts in the window');
    expect(t.fastCount, 3);
    expect(t.average, 16.0);
    expect(t.longest, 18.0);
    expect(FastingTrend.of(const [], today: today).isEmpty, isTrue);
  });

  testWidgets('empty history is calm and invents nothing', (tester) async {
    await pumpApp(tester);
    await _openHistory(tester);
    expect(find.text('No sessions yet'), findsOneWidget);
    expect(find.text('No completed fasts in the last 14 days.'), findsOneWidget);
    expect(find.textContaining('Trends are guides'), findsOneWidget);
  });

  testWidgets('a completed fast shows on the calendar, trend and recent days', (tester) async {
    final clock = await pumpApp(tester);
    await _fast(tester, clock, const Duration(hours: 16, minutes: 5));
    await quickAdd(tester, 'Drink water');
    await quickAdd(tester, 'Drink water');
    await _openHistory(tester);
    expect(find.bySemanticsLabel('Sunday 4 October: Fasting, Water'), findsOneWidget);
    expect(find.text('16.1 h'), findsNWidgets(2)); // average and longest
    expect(find.text('1 fast'), findsOneWidget);
    expect(find.text('16 h 5 m fast · target reached'), findsOneWidget);
    expect(find.text('500 ml water'), findsOneWidget);
  });

  testWidgets('a short fast reads "ended", never as a failure', (tester) async {
    final clock = await pumpApp(tester);
    await _fast(tester, clock, const Duration(hours: 9, minutes: 30));
    await _openHistory(tester);
    expect(find.text('9 h 30 m fast · session ended'), findsOneWidget);
    expect(find.textContaining('fail'), findsNothing);
  });

  testWidgets('filters change which markers show', (tester) async {
    final clock = await pumpApp(tester);
    await _fast(tester, clock, const Duration(hours: 12));
    await quickAdd(tester, 'Drink water');
    await _openHistory(tester);
    await tester.tap(find.bySemanticsLabel('Water').first);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Sunday 4 October: Water'), findsOneWidget);
    expect(find.text('No completed fasts in the last 14 days.'), findsNothing, reason: 'trend hidden');
  });

  testWidgets('tap a day for its summary; edit and delete a fast from there', (tester) async {
    final clock = await pumpApp(tester);
    await _fast(tester, clock, const Duration(hours: 3));
    await _openHistory(tester);
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Sunday 4 October: Fasting')));
    await tester.pumpAndSettle();
    expect(find.text('Day summary'), findsOneWidget);
    await tester.tap(find.text('3 h 0 m'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this session?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing logged'), findsWidgets);
  });

  testWidgets('an empty day says skipping is fine', (tester) async {
    await pumpApp(tester);
    await _openHistory(tester);
    await tester.tap(find.bySemanticsLabel('Monday 5 October, Nothing logged'));
    await tester.pumpAndSettle();
    expect(find.text('Skipping a day is completely fine.'), findsOneWidget);
  });
}
