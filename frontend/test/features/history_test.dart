import 'package:flutter_test/flutter_test.dart';

import '../widget_test.dart' show pumpApp, tick;

Future<void> _fast(WidgetTester tester, dynamic clock, Duration d) async {
  await tester.tap(find.text('Start fast'));
  await tester.pumpAndSettle();
  await tick(tester, clock, d);
  await tester.tap(find.text('End fast'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('End session'));
  await tester.pumpAndSettle();
}

Future<void> _openHistory(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('History'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty state', (tester) async {
    await pumpApp(tester);
    await _openHistory(tester);
    expect(find.text('No sessions yet'), findsOneWidget);
  });

  testWidgets('ended sessions are listed; short ones are "ended", not failures', (tester) async {
    final clock = await pumpApp(tester);
    await _fast(tester, clock, const Duration(hours: 16, minutes: 5));
    await tick(tester, clock, const Duration(hours: 2));
    await _fast(tester, clock, const Duration(hours: 9, minutes: 30));
    await _openHistory(tester);
    expect(find.text('Target reached'), findsOneWidget);
    expect(find.text('Session ended'), findsOneWidget);
    expect(find.text('9 h 30 m'), findsOneWidget);
    expect(find.text('16 h 5 m'), findsOneWidget);
    expect(find.textContaining('fail'), findsNothing);
  });

  testWidgets('delete asks for confirmation then removes the session', (tester) async {
    final clock = await pumpApp(tester);
    await _fast(tester, clock, const Duration(hours: 3));
    await _openHistory(tester);
    await tester.tap(find.text('3 h 0 m'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this session?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('No sessions yet'), findsOneWidget);
  });

  testWidgets('calendar marks days with sessions and lists them', (tester) async {
    final clock = await pumpApp(tester);
    await _fast(tester, clock, const Duration(hours: 5));
    await _openHistory(tester);
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    expect(find.text('October 2026'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Sunday 4 October, 1 session'));
    await tester.pumpAndSettle();
    expect(find.text('5 h 0 m'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Monday 5 October, no sessions'));
    await tester.pumpAndSettle();
    expect(find.text('No sessions on Monday 5 October.'), findsOneWidget);
  });
}
