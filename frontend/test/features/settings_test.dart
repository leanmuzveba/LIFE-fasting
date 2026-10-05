import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/data/notification_service.dart';

import '../widget_test.dart' show notifications, openTimer, pumpApp, tick;

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Settings').last);
  await tester.pumpAndSettle();
}

/// Scrolls a Settings row on-screen before tapping it.
Future<void> _tapRow(WidgetTester tester, String text) async {
  final f = find.text(text);
  await tester.scrollUntilVisible(f, 200);
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('24-hour clock changes the home cards', (tester) async {
    await pumpApp(tester);
    await _openSettings(tester);
    await _tapRow(tester, '24-hour clock');
    await tester.tap(find.bySemanticsLabel('Today'));
    await tester.pumpAndSettle();
    expect(find.text('16 h target · ends 23:24 if you start now'), findsOneWidget);
    await openTimer(tester);
    await tester.tap(find.text('00:00:00'));
    await tester.pumpAndSettle();
    expect(find.text('23:24'), findsOneWidget); // IF STARTED NOW
  });

  testWidgets('target notification is opt-in and follows the session', (tester) async {
    final clock = await pumpApp(tester);
    await tester.tap(find.text('Start fast'));
    await tester.pumpAndSettle();
    expect(notifications.scheduled, isEmpty, reason: 'nothing scheduled until opted in');

    await _openSettings(tester);
    await _tapRow(tester, 'Target time reached');
    expect(
      notifications.scheduled[NotificationService.targetReachedId],
      clock.now.toUtc().add(const Duration(hours: 16)),
    );

    await _tapRow(tester, 'Target time reached');
    expect(notifications.scheduled, isEmpty, reason: 'opt-out cancels');
  });

  testWidgets('ending a session cancels its target notification', (tester) async {
    final clock = await pumpApp(tester);
    await _openSettings(tester);
    await _tapRow(tester, 'Target time reached');
    await tester.tap(find.bySemanticsLabel('Today'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start fast'));
    await tester.pumpAndSettle();
    expect(notifications.scheduled, contains(NotificationService.targetReachedId));
    await tick(tester, clock, const Duration(hours: 2));
    await tester.tap(find.text('End fast'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End session'));
    await tester.pumpAndSettle();
    expect(notifications.scheduled, isEmpty);
  });

  testWidgets('daily reminder: refused permission keeps it off; allowed schedules 8 PM', (tester) async {
    await pumpApp(tester);
    await _openSettings(tester);
    notifications.permission = false;
    await _tapRow(tester, 'Daily reminder');
    expect(notifications.scheduled, isEmpty);
    expect(find.textContaining('turned off for this app'), findsOneWidget);

    notifications.permission = true;
    await _tapRow(tester, 'Daily reminder');
    expect(notifications.scheduled[NotificationService.dailyReminderId]!.hour, 20);
    expect(find.text('Every day at 8:00 PM'), findsOneWidget);
  });

  testWidgets('delete all data wipes everything and returns to onboarding', (tester) async {
    final clock = await pumpApp(tester);
    await tester.tap(find.text('Start fast'));
    await tester.pumpAndSettle();
    await tick(tester, clock, const Duration(hours: 1));
    await _openSettings(tester);
    await tester.scrollUntilVisible(find.text('Delete all data'), 200);
    await tester.ensureVisible(find.text('Delete all data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete all data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete all'));
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsOneWidget);
    expect(notifications.scheduled, isEmpty);
  });

  testWidgets('profile name is optional; member-since date is shown', (tester) async {
    await pumpApp(tester);
    await _openSettings(tester);
    expect(find.text('Add your name'), findsOneWidget);
    expect(find.text('MEMBER SINCE OCT 2026'), findsOneWidget);
    await tester.tap(find.text('Add your name'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ruvarashe M');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Ruvarashe M'), findsOneWidget);
    expect(find.text('RM'), findsOneWidget);
  });

  testWidgets('diet and allergies are recorded', (tester) async {
    await pumpApp(tester);
    await _openSettings(tester);
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Dietary preferences, No preference')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vegetarian'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp(r'^Dietary preferences, Vegetarian')), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(RegExp(r'^Allergies, None')));
    await tester.pumpAndSettle();
    expect(find.textContaining('never be suggested'), findsOneWidget);
    await tester.tap(find.text('Eggs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dairy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp(r'^Allergies, Eggs, Dairy')), findsOneWidget);
  });
}
