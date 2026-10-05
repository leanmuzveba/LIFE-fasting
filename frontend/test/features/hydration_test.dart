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

  testWidgets('water page: add a custom amount, edit it, delete it', (tester) async {
    await pumpApp(tester);
    await _openWater(tester);
    expect(find.text('No water recorded for this day.'), findsOneWidget);

    await tester.tap(find.text('Add amount'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '330');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('330 ml'), findsWidgets);
    expect(find.text('1 entry'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(RegExp(r'^330 ml at')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '400');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('400 ml'), findsWidgets);

    await tester.tap(find.bySemanticsLabel(RegExp(r'^400 ml at')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('No water recorded for this day.'), findsOneWidget);
  });

  testWidgets('invalid amounts are rejected with a message', (tester) async {
    await pumpApp(tester);
    await _openWater(tester);
    await tester.tap(find.text('Add amount'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Enter an amount between 1 and 3000 ml'), findsOneWidget);
  });

  testWidgets('previous days keep their own entries', (tester) async {
    final clock = await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel('Add 500 ml'));
    await tester.pumpAndSettle();
    await tick(tester, clock, const Duration(days: 1));
    expect(find.text('0 ml'), findsOneWidget, reason: 'a new day starts at zero');
    await _openWater(tester);
    await tester.tap(find.byTooltip('Previous day'));
    await tester.pumpAndSettle();
    expect(find.text('500 ml'), findsWidgets);
    expect(find.text('Add amount'), findsOneWidget);
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
    expect(notifications.scheduled[NotificationService.waterReminderBaseId]!.hour, 8);
    await tester.tap(find.text('Water reminders'));
    await tester.pumpAndSettle();
    expect(notifications.scheduled, isEmpty);
  });
}
