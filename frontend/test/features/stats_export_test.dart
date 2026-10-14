import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/domain/activity.dart';
import 'package:life_fasting/features/today/stats_export_screen.dart';
import 'package:life_fasting/state/providers.dart';

import '../widget_test.dart' show pumpApp, watch;

void main() {
  testWidgets('export a day: steps, distance, kcal and active time; styles; any day', (tester) async {
    await pumpApp(tester);
    tester.view.physicalSize = const Size(390, 2000);
    final c = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    watch
      ..granted = true
      ..stepCount = 8432
      ..km = 6.1
      ..calories = 380
      ..active = 57;
    await c.read(settingsRepositoryProvider).setFlag('watch.linked', true);
    final t = DateTime.utc(2026, 10, 4, 5);
    await c
        .read(activityRepositoryProvider)
        .insert(
          ActivityEntry(
            type: ActivityType.strength,
            startedAt: t,
            minutes: 45,
            kcal: 40,
            createdAt: t,
            updatedAt: t,
            exercises: const [Exercise('Crunches', sets: 3, reps: 15)],
          ),
        );
    c.invalidate(watchStatusProvider);
    c.invalidate(activityDayProvider);

    await tester.tap(find.byTooltip("Export the day's stats"));
    await tester.pumpAndSettle();
    expect(find.text('SUNDAY · 4 OCT 2026'), findsOneWidget);
    expect(find.text('8,432'), findsOneWidget);
    expect(find.text('6.10 km'), findsOneWidget);
    expect(find.text('420 kcal'), findsOneWidget); // watch 380 + logged 40
    expect(find.text('Active time'), findsOneWidget);
    expect(find.text('57 min'), findsOneWidget); // the watch's figure, not the logged 45
    expect(find.bySemanticsLabel('RUVA'), findsWidgets); // wordmark
    await tester.tap(find.text('Badge'));
    await tester.pump();
    expect(find.byType(Image), findsWidgets);
    await tester.tap(find.text('Route first'));
    await tester.pump();
    expect(tester.widget<StatsCard>(find.byType(StatsCard)).layout, ExportLayout.poster);
    expect(find.text('57 min'), findsOneWidget);
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_right_rounded)).onPressed, isNull);

    await tester.tap(find.byTooltip('Previous day'));
    await tester.pumpAndSettle();
    expect(find.text('SATURDAY · 3 OCT 2026'), findsOneWidget);
    expect(find.text('420 kcal'), findsNothing); // nothing logged that day; the fake watch still says 380
    expect(find.text('380 kcal'), findsOneWidget);
  });
}
