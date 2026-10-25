import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/data/health_source.dart';
import 'package:life_fasting/domain/activity.dart';
import 'package:life_fasting/state/providers.dart';

import '../widget_test.dart' show pumpApp, watch;

Future<void> _openWatchSheet(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Profile').last);
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text('Connect your watch'), 200, scrollable: find.byType(Scrollable).first);
  await tester.tap(find.text('Connect your watch'));
  await tester.pumpAndSettle();
}

void main() {
  test('reads one app only: Mi Fitness when present, else the one with most data', () {
    expect(preferredSource({'com.google.android.apps.fitness': 9000, 'com.mi.health': 6200}), 'com.mi.health');
    expect(
      preferredSource({'com.sec.android.app.shealth': 4100, 'com.google.android.apps.fitness': 5200}),
      'com.google.android.apps.fitness',
    );
    expect(preferredSource({}), isNull);
  });

  testWidgets('Settings → Watch lists what each app wrote, marking the one used', (tester) async {
    await pumpApp(tester);
    tester.view.physicalSize = const Size(390, 2400);
    watch.apps = const [
      SourceTotals(name: 'Mi Fitness', steps: 6240, activeKcal: 312, used: true),
      SourceTotals(name: 'Google Fit', steps: 6511),
    ];
    await _openWatchSheet(tester);
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    await _openWatchSheet(tester);
    expect(find.text('✓ Mi Fitness · 6240 steps · 312 active kcal'), findsOneWidget);
    expect(find.text('Google Fit · 6511 steps'), findsOneWidget);
  });

  testWidgets('connect a watch: calories burned appear on Home', (tester) async {
    await pumpApp(tester);
    tester.view.physicalSize = const Size(390, 2400);
    watch.calories = 312.4;
    expect(find.text('Calories burned'), findsNothing, reason: 'nothing until you connect');

    await _openWatchSheet(tester);
    expect(find.textContaining('Mi Fitness'), findsOneWidget);
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    expect(find.text('Watch connected'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Home').last);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp(r'^Calories burned: 312 kcal')), findsOneWidget);

    // Steps: the watch's whole-day count replaces the phone sensor's.
    final c = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    final today = DateTime(2026, 10, 4); // the fake clock's day
    final sub = c.listen(dayStatsProvider(today), (_, _) {}); // the export screen's numbers
    await tester.runAsync(() => c.read(dayStatsProvider(today).future));
    watch.stepCount = 8421;
    watch.syncedAt = DateTime(2026, 10, 4, 14, 32);
    c.read(watchActionsProvider).refresh();
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Today’s steps: 8,421, 84% of goal'), findsOneWidget);
    expect(find.textContaining('· watch'), findsOneWidget);
    expect(find.textContaining('Watch last synced 2:32'), findsOneWidget);
    expect((await tester.runAsync(() => c.read(dayStatsProvider(today).future)))!.steps, 8421);
    sub.close();
  });

  testWidgets('connected but nothing synced yet: the row still shows, saying so', (tester) async {
    await pumpApp(tester);
    tester.view.physicalSize = const Size(390, 2400);
    watch.calories = null;
    await _openWatchSheet(tester);
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Home').last);
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Calories burned: 0 kcal. Connected · nothing synced from your watch yet today'),
      findsOneWidget,
    );
  });

  testWidgets('declined permission or no Health Connect: clear messages', (tester) async {
    await pumpApp(tester);
    tester.view.physicalSize = const Size(390, 2400);
    watch.grants = false;
    await _openWatchSheet(tester);
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    expect(find.textContaining('wasn’t given access'), findsOneWidget);

    watch.isAvailable = false;
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    expect(find.text('Install Health Connect'), findsOneWidget);
  });

  testWidgets('watch workouts import once into Activity; deleting keeps them gone', (tester) async {
    await pumpApp(tester);
    tester.view.physicalSize = const Size(390, 2400);
    watch.workoutList = [
      WatchWorkout(
        id: 'hc-run-1',
        type: ActivityType.run,
        start: DateTime(2026, 10, 3, 18),
        end: DateTime(2026, 10, 3, 18, 32),
        kcal: 281.6,
      ),
    ];
    await _openWatchSheet(tester);
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Home').last);
    await tester.pumpAndSettle();

    final c = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    final repo = c.read(activityRepositoryProvider);
    expect((await repo.all()).single.kcal, closeTo(281.6, 0.01));

    // A second sync (e.g. returning to the app) adds nothing new.
    c.read(watchActionsProvider).refresh();
    await tester.pumpAndSettle();
    expect(await repo.all(), hasLength(1));

    await tester.tap(find.byTooltip('Quick add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log activity'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp(r'^Run, 32 min · 282 kcal.*From your watch')), findsOneWidget);

    await repo.delete((await repo.all()).single);
    c.read(watchActionsProvider).refresh();
    await tester.pumpAndSettle();
    expect(await repo.all(), isEmpty, reason: 'hidden, not re-imported');
  });
}
