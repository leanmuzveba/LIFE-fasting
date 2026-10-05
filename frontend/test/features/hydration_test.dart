import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/data/notification_service.dart';

import '../widget_test.dart' show notifications, pumpApp, tick;

Future<void> _openWater(WidgetTester tester) async {
  await tester.tap(find.text('WATER TODAY'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('quick-add on Today updates the total', (tester) async {
    await pumpApp(tester);
    expect(find.text('0 ml'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Add 250 ml'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Add 500 ml'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Add 500 ml'));
    await tester.pumpAndSettle();
    expect(find.text('1.25 L'), findsOneWidget);
  });

  testWidgets('Activity & Water: ring against the goal, +200/+300/+500 quick-adds', (tester) async {
    await pumpApp(tester);
    await _openWater(tester);
    expect(find.text('Activity & Water'), findsOneWidget);
    expect(find.text('No water logged yet today.'), findsOneWidget);
    expect(find.text('OF 2 L GOAL'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Add 300 ml'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Add 500 ml'));
    await tester.pumpAndSettle();
    expect(find.text('800 ml'), findsWidgets);
    expect(find.textContaining('every glass counts'), findsOneWidget);
  });

  testWidgets('custom amount, then edit and delete from the entry menu', (tester) async {
    await pumpApp(tester);
    await _openWater(tester);
    await tester.tap(find.text('Custom amount'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '330');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('330 ml'), findsWidgets);

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '400');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('400 ml'), findsWidgets);

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('No water logged yet today.'), findsOneWidget);
  });

  testWidgets('invalid amounts are rejected with a message', (tester) async {
    await pumpApp(tester);
    await _openWater(tester);
    await tester.tap(find.text('Custom amount'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Enter an amount between 1 and 3000 ml'), findsOneWidget);
  });

  testWidgets('daily goal can be changed and is kept', (tester) async {
    await pumpApp(tester);
    await _openWater(tester);
    await tester.tap(find.bySemanticsLabel(RegExp(r'of 2 L goal')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Needs vary'), findsOneWidget);
    await tester.tap(find.byTooltip('+250 ml'));
    await tester.tap(find.byTooltip('+250 ml'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('OF 2.5 L GOAL'), findsOneWidget);
  });

  testWidgets('a new day starts at zero', (tester) async {
    final clock = await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel('Add 500 ml'));
    await tester.pumpAndSettle();
    await tick(tester, clock, const Duration(days: 1));
    expect(find.text('0 ml'), findsOneWidget);
  });

  testWidgets('fl oz setting changes display and quick-adds', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel('Settings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('fl oz'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Today'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Add 8 fl oz'));
    await tester.pumpAndSettle();
    expect(find.text('8 fl oz'), findsOneWidget);
  });

  testWidgets('water reminders are opt-in and can be turned off', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel('Settings').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Water reminders'), 200);
    await tester.tap(find.text('Water reminders'));
    await tester.pumpAndSettle();
    final waterIds = notifications.scheduled.keys.where((id) => id >= NotificationService.waterReminderBaseId);
    expect(waterIds, hasLength(7));
    await tester.tap(find.text('Water reminders'));
    await tester.pumpAndSettle();
    expect(notifications.scheduled, isEmpty);
  });
}
