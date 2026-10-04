import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/data/notification_service.dart';

import '../widget_test.dart' show notifications, pumpApp, tick;

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Settings').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('24-hour clock changes the home cards', (tester) async {
    await pumpApp(tester);
    await _openSettings(tester);
    await tester.tap(find.text('24-hour clock'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Timer'));
    await tester.pumpAndSettle();
    expect(find.text('23:24'), findsOneWidget); // IF STARTED NOW
  });

  testWidgets('target notification is opt-in and follows the session', (tester) async {
    final clock = await pumpApp(tester);
    await tester.tap(find.text('Start fast'));
    await tester.pumpAndSettle();
    expect(notifications.scheduled, isEmpty, reason: 'nothing scheduled until opted in');

    await _openSettings(tester);
    await tester.tap(find.text('Target time reached'));
    await tester.pumpAndSettle();
    expect(
      notifications.scheduled[NotificationService.targetReachedId],
      clock.now.toUtc().add(const Duration(hours: 16)),
    );

    await tester.tap(find.text('Target time reached'));
    await tester.pumpAndSettle();
    expect(notifications.scheduled, isEmpty, reason: 'opt-out cancels');
  });

  testWidgets('ending a session cancels its target notification', (tester) async {
    final clock = await pumpApp(tester);
    await _openSettings(tester);
    await tester.tap(find.text('Target time reached'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Timer'));
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
    await tester.tap(find.text('Daily reminder'));
    await tester.pumpAndSettle();
    expect(notifications.scheduled, isEmpty);
    expect(find.textContaining('turned off for this app'), findsOneWidget);

    notifications.permission = true;
    await tester.tap(find.text('Daily reminder'));
    await tester.pumpAndSettle();
    expect(notifications.scheduled[NotificationService.dailyReminderId]!.hour, 20);
    expect(find.text('Every day at 8:00 PM'), findsOneWidget);
  });

  testWidgets('delete all data wipes everything and returns to onboarding', (tester) async {
    final clock = await pumpApp(tester);
    await tester.tap(find.text('Start fast'));
    await tester.pumpAndSettle();
    await tick(tester, clock, const Duration(hours: 1));
    await _openSettings(tester);
    await tester.tap(find.text('Delete all data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete all'));
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsOneWidget);
    expect(notifications.scheduled, isEmpty);
  });
}
