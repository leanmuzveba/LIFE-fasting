import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/domain/settings.dart';
import 'package:life_fasting/main.dart';
import 'package:life_fasting/state/providers.dart';

import 'helpers.dart';

late StreamController<DateTime> _ticks;
late FakeNotifications notifications;

/// Boots the real app on an in-memory database with a fake clock.

Future<FakeClock> pumpApp(WidgetTester tester, {AgeEligibility eligibility = AgeEligibility.adult}) async {
  await loadAppFonts();
  final clock = FakeClock(DateTime(2026, 10, 4, 7, 24, 36));
  final db = await openTestDb();
  _ticks = StreamController<DateTime>.broadcast();
  notifications = FakeNotifications();
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(clock.call),
      notificationServiceProvider.overrideWithValue(notifications),
      // Test-driven ticks instead of a real periodic timer.
      nowProvider.overrideWith((ref) async* {
        yield clock();
        yield* _ticks.stream;
      }),
    ],
  );
  await container
      .read(settingsRepositoryProvider)
      .save(AppSettings(eligibility: eligibility, onboardingComplete: eligibility != AgeEligibility.unknown));
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const LifeFastingApp()));
  await tester.pumpAndSettle();
  addTearDown(() async {
    container.dispose();
    unawaited(_ticks.close());
    await db.close();
  });
  return clock;
}

Future<void> tick(WidgetTester tester, FakeClock clock, Duration d) async {
  clock.advance(d);
  _ticks.add(clock());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('idle home matches the mockup copy', (tester) async {
    await pumpApp(tester);
    expect(find.text('RUVA'), findsOneWidget);
    expect(find.text('Sunday 4 October'), findsOneWidget);
    expect(find.text('READY WHEN YOU ARE'), findsOneWidget);
    expect(find.text('TARGET'), findsNothing, reason: 'cards live in the pop-up now');
    await tester.tap(find.text('00:00:00'));
    await tester.pumpAndSettle();
    expect(find.text('TARGET'), findsOneWidget);
    expect(find.text('16 hours'), findsOneWidget);
    expect(find.text('IF STARTED NOW'), findsOneWidget);
    expect(find.text('11:24 PM'), findsOneWidget);
    expect(find.text('Start fast'), findsOneWidget);
    expect(find.text('Change target'), findsOneWidget);
  });

  testWidgets('start → running → end saves to history', (tester) async {
    final clock = await pumpApp(tester);
    await tester.tap(find.text('Start fast'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('00:00:00'));
    await tester.pumpAndSettle();
    expect(find.text('FAST STARTED'), findsOneWidget);
    expect(find.text('PLANNED END'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Sunday 4 October · Session in progress'), findsOneWidget);

    await tick(tester, clock, const Duration(hours: 12, minutes: 24));
    expect(find.text('12:24:00'), findsOneWidget);
    expect(find.textContaining('remaining', findRichText: true), findsNothing);

    await tester.tap(find.text('End fast'));
    await tester.pumpAndSettle();
    expect(find.text('End this session?'), findsOneWidget);
    expect(find.textContaining('Recorded so far: 12 h 24 m', findRichText: true), findsOneWidget);
    await tester.tap(find.text('End session'));
    await tester.pumpAndSettle();
    expect(find.text('Start fast'), findsOneWidget);
    expect(find.text('00:00:00'), findsOneWidget);
  });

  testWidgets('target reached keeps counting and never asks to continue', (tester) async {
    final clock = await pumpApp(tester);
    await tester.tap(find.text('Start fast'));
    await tester.pumpAndSettle();
    await tick(tester, clock, const Duration(hours: 17));
    expect(find.text('TARGET REACHED'), findsOneWidget);
    expect(find.text('17:00:00'), findsOneWidget);
  });

  testWidgets('milestone sheet shows the uncertainty disclaimer', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Ketosis may begin')));
    await tester.pumpAndSettle();
    expect(find.text('Roughly 12–18 hours (estimate)'), findsOneWidget);
    expect(find.textContaining('cannot measure ketones'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Roughly 12–18 hours (estimate)'), findsNothing);
  });

  testWidgets('edit start time sheet previews the resolved start', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Start fast'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit start time'));
    await tester.pumpAndSettle();
    expect(find.text('STARTED AT'), findsOneWidget);
    expect(find.text('Will start Sun 4 Oct at 7:24 AM.'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('STARTED AT'), findsNothing);
  });

  testWidgets('bottom nav switches tabs', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel('History'));
    await tester.pumpAndSettle();
    expect(find.text('Start fast'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Timer'));
    await tester.pumpAndSettle();
    expect(find.text('Start fast'), findsOneWidget);
  });
}
