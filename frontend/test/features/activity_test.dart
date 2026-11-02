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
  swimTests();
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

    await tester.tap(find.bySemanticsLabel('Home').last);
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

void swimTests() {
  test('swims: pace → minutes, Mifflin-St Jeor BMR, BMR ÷ 1440 × MET × minutes', () {
    expect(swimMinutes(20, 90), 30);
    expect(swimMinutes(1, 10), minActivityMinutes, reason: 'never under a minute');
    expect(bmr(weightKg: 72, heightCm: 175, age: 36, sex: Sex.male), closeTo(1638.75, 0.001));
    expect(bmr(weightKg: 60, heightCm: 165, age: 30, sex: Sex.female), closeTo(1320.25, 0.001));
    double kcal(Intensity i) => swimKcal(i, 30, weightKg: 72, heightCm: 175, age: 36, sex: Sex.male);
    expect(kcal(Intensity.light), closeTo(1638.75 / 1440 * 6 * 30, 0.001));
    expect(kcal(Intensity.moderate), closeTo(273.125, 0.001));
    expect(kcal(Intensity.heavy), closeTo(375.547, 0.001));
  });

  testWidgets('log a swim: pool, laps and pace give the time and a personal calorie estimate', (tester) async {
    await pumpApp(tester);
    final c = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    await c.read(bodyActionsProvider).addWeighIn(WeighIn(at: DateTime.utc(2026, 10, 1), weightKg: 72));
    await c.read(bodyActionsProvider).saveProfile(const BodyProfile(heightCm: 175, birthYear: 1990, sex: Sex.male));
    await _openActivity(tester);

    await _scrollTo(tester, find.bySemanticsLabel('Swim'));
    await tester.tap(find.bySemanticsLabel('Swim'));
    await tester.pump();
    expect(find.text('25 yd'), findsOneWidget);
    expect(find.bySemanticsLabel('Leisurely'), findsOneWidget); // swim intensity names
    await tester.tap(find.text('50 m'));
    await tester.tap(find.text('Pace per lap'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(0), '20'); // laps
    await tester.enterText(find.byType(TextField).at(1), '90'); // seconds per lap
    await tester.pump();
    expect(find.text('≈ 30 min in the water'), findsOneWidget);
    expect(find.text('≈ 273 kcal burned (est.) · from your weight, height, age and sex'), findsOneWidget);
    await _scrollTo(tester, find.bySemanticsLabel('Vigorous'));
    await tester.tap(find.bySemanticsLabel('Vigorous'));
    await tester.pump();
    expect(find.text('≈ 376 kcal burned (est.) · from your weight, height, age and sex'), findsOneWidget);

    await _scrollTo(tester, find.text('Log activity'));
    await tester.tap(find.text('Log activity'));
    await tester.pumpAndSettle();
    final swim = (await c.read(activityRepositoryProvider).all()).single;
    expect((swim.type, swim.minutes, swim.laps, swim.poolM), (ActivityType.swim, 30, 20, 50.0));
    expect(swim.kcal, closeTo(375.5, 0.1));
    expect(find.bySemanticsLabel(RegExp(r'^Swim, 30 min · 20 laps · 1000 m · vigorous')), findsOneWidget);
  });
}
