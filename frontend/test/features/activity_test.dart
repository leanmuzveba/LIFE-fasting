import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/domain/activity.dart';
import 'package:life_fasting/domain/body.dart';
import 'package:life_fasting/state/providers.dart';

import '../widget_test.dart' show pumpApp;

/// Tall screen so the whole form is laid out without scrolling.
Future<void> _openActivity(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 2600);
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Quick add'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Log activity'));
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('log an activity: type, duration, optional intensity and notes', (tester) async {
    await pumpApp(tester);
    await _openActivity(tester);
    expect(find.text('No activities logged yet.'), findsOneWidget);

    await _scrollTo(tester, find.bySemanticsLabel('Run'));
    await tester.tap(find.bySemanticsLabel('Run'));
    await _scrollTo(tester, find.byTooltip('1 minute more'));
    await tester.tap(find.byTooltip('1 minute more'));
    await tester.tap(find.byTooltip('1 minute more'));
    await tester.pump();
    expect(find.text('32 min'), findsOneWidget);
    await _scrollTo(tester, find.bySemanticsLabel('Moderate'));
    await tester.tap(find.bySemanticsLabel('Moderate'));
    await _scrollTo(tester, find.byType(TextField).last);
    await tester.enterText(find.byType(TextField).last, 'Easy pace');
    await _scrollTo(tester, find.text('Log activity'));
    await tester.tap(find.text('Log activity'));
    await tester.pumpAndSettle();
    expect(find.text('Run logged — 32 min'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Run, 32 min · moderate')), findsOneWidget);
  });

  testWidgets('edit and delete a logged activity', (tester) async {
    await pumpApp(tester);
    await _openActivity(tester);
    await _scrollTo(tester, find.text('Log activity'));
    await tester.tap(find.text('Log activity'));
    await tester.pumpAndSettle();
    final card = find.bySemanticsLabel(RegExp(r'^Walk, 30 min'));
    await _scrollTo(tester, card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.text('Edit activity'), findsOneWidget);
    final delete = find.widgetWithText(TextButton, 'Delete');
    await _scrollTo(tester, delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(find.text('No activities logged yet.'), findsOneWidget);
  });

  test('calories from MET: (MET − 1) × kg × hours, moderate by default', () {
    expect(activityKcal(ActivityType.run, Intensity.moderate, 30, 72), closeTo(316.8, 0.01));
    expect(activityKcal(ActivityType.run, null, 30, 72), closeTo(316.8, 0.01));
    expect(activityKcal(ActivityType.walk, Intensity.light, 60, 80), closeTo(144, 0.01));
    expect(activityKcal(ActivityType.cycle, Intensity.heavy, 45, 60), closeTo(405, 0.01));
  });

  testWidgets('logging an activity estimates calories from your weight; Home adds them up', (tester) async {
    await pumpApp(tester);
    await _openActivity(tester);
    expect(find.text('Add your weight in Profile to estimate calories burned.'), findsOneWidget);

    final c = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    await c.read(bodyActionsProvider).addWeighIn(WeighIn(at: DateTime.utc(2026, 10, 1), weightKg: 72));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.bySemanticsLabel('Run'));
    await tester.tap(find.bySemanticsLabel('Run'));
    await tester.pump();
    expect(find.text('≈ 317 kcal burned (est.) · at 72 kg'), findsOneWidget);
    await _scrollTo(tester, find.bySemanticsLabel('Heavy'));
    await tester.tap(find.bySemanticsLabel('Heavy'));
    await tester.pump();
    expect(find.text('≈ 378 kcal burned (est.) · at 72 kg'), findsOneWidget);
    await _scrollTo(tester, find.text('Log activity'));
    await tester.tap(find.text('Log activity'));
    await tester.pumpAndSettle();
    expect((await c.read(activityRepositoryProvider).all()).single.kcal, closeTo(378, 0.01));

    await tester.tap(find.byTooltip('Back').first);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Calories burned: 378 kcal. From activities you logged · estimated'), findsOneWidget);
  });

  testWidgets('a gym session lists its exercises: sets × reps', (tester) async {
    await pumpApp(tester);
    await _openActivity(tester);
    expect(find.text('Add exercise'), findsNothing); // walk: no exercises
    await _scrollTo(tester, find.bySemanticsLabel('Strength'));
    await tester.tap(find.bySemanticsLabel('Strength'));
    await tester.pump();

    await _scrollTo(tester, find.text('Add exercise'));
    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'cru');
    await tester.pump();
    await tester.tap(find.text('Crunches'));
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byTooltip('1 rep more'));
    }
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Crunches 3 × 15'), findsOneWidget);

    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Leg raises');
    await tester.pump();
    await tester.tap(find.byTooltip('1 set less'));
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text('Log activity'));
    await tester.tap(find.text('Log activity'));
    await tester.pumpAndSettle();
    final c = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    expect((await c.read(activityRepositoryProvider).all()).single.exercises.map((x) => '$x'), [
      'Crunches 3 × 15',
      'Leg raises 2 × 10',
    ]);
    expect(find.bySemanticsLabel(RegExp(r'Crunches 3 × 15, Leg raises 2 × 10')), findsOneWidget);
  });
}
