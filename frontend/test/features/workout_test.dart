import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/data/notification_service.dart';
import 'package:life_fasting/domain/activity.dart';
import 'package:life_fasting/domain/body.dart';
import 'package:life_fasting/domain/workout.dart';
import 'package:life_fasting/state/providers.dart';

import '../widget_test.dart' show notifications, pumpApp, tick;

const _bench = 'Barbell Bench Press - Medium Grip';

Future<void> _addBench(WidgetTester tester) async {
  await tester.tap(find.text('Add exercise'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), 'barbell bench press - medium');
  await tester.pumpAndSettle();
  await tester.tap(find.text(_bench));
  await tester.pumpAndSettle();
}

void main() {
  test('sets: old "3 × 10" activities still load; each set keeps its weight', () {
    final old = Exercise.fromJson({'name': 'Crunches', 'sets': 3, 'reps': 15});
    expect('$old', 'Crunches 3 × 15');
    const mixed = Exercise.logged('Squat', [SetLog(reps: 8, kg: 100), SetLog(reps: 6, kg: 110)], libraryId: 'sq');
    final back = Exercise.fromJson(jsonDecode(jsonEncode(mixed.toJson())) as Map<String, dynamic>);
    expect((back.libraryId, '$back'), ('sq', 'Squat 100 kg × 8, 110 kg × 6'));
    expect(Exercise('Bench', sets: 3, reps: 5, kg: 60).describe(imperial: true), 'Bench 3 × 5 · 132.3 lb');
    expect(oneRepMax(100, 10), closeTo(133.3, 0.1));
  });

  test('a workout in progress keeps planned sets but saves only ticked ones', () {
    final w = Workout(
      startedAt: DateTime.utc(2026, 11, 2, 17),
      exercises: const [
        Exercise.logged('Row', [SetLog(kg: 50), SetLog(kg: 50, done: false)]),
        Exercise.logged('Curl', [SetLog(done: false)]),
      ],
    );
    final back = Workout.fromJson(jsonDecode(jsonEncode(w.toJson())) as Map<String, dynamic>);
    expect(back.exercises[0].log[1].done, isFalse);
    expect(back.doneSets, 1);
    expect(back.completed.map((x) => '$x'), ['Row 1 × 10 · 50 kg']);
  });

  testWidgets('a strength workout: pick from the library, log sets, rest, finish; next time starts from last time', (
    tester,
  ) async {
    final clock = await pumpApp(tester);
    tester.view.physicalSize = const Size(390, 1400);
    final c = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    await c.read(bodyActionsProvider).addWeighIn(WeighIn(at: DateTime.utc(2026, 10, 1), weightKg: 80));
    await tester.runAsync(() => c.read(exerciseLibraryProvider.future)); // a big asset: parsed off the fake clock
    await tester.tap(find.bySemanticsLabel('Activity').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Add your first exercise'), findsOneWidget);

    await _addBench(tester);
    expect(find.text(_bench), findsOneWidget);
    for (final i in [0, 2, 4]) {
      await tester.enterText(find.byType(TextField).at(i), '60'); // kg for sets 1–3
    }
    await tester.tap(find.byTooltip('Mark set 1 done'));
    await tester.pump();
    expect(find.text('Rest 1:30'), findsOneWidget);
    expect(notifications.scheduled[NotificationService.restOverId], clock().toUtc().add(const Duration(seconds: 90)));
    await tester.tap(find.byTooltip('15 seconds more rest'));
    await tester.pump();
    expect(find.text('Rest 1:45'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pump();
    expect(find.textContaining('Rest '), findsNothing);
    expect(notifications.scheduled.containsKey(NotificationService.restOverId), isFalse);
    await tester.tap(find.byTooltip('Mark set 2 done'));
    await tester.pump();

    // Closing the app mid-workout loses nothing.
    c.invalidate(workoutProvider);
    expect((await c.read(workoutProvider.future))!.doneSets, 2);

    await tick(tester, clock, const Duration(minutes: 40));
    await tester.ensureVisible(find.text('Finish workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish workout'));
    await tester.pumpAndSettle();
    expect(find.text('Workout saved — 40 min, 2 sets'), findsOneWidget);
    final saved = (await c.read(activityRepositoryProvider).all()).single;
    expect(
      (saved.type, saved.minutes, saved.exercises.single.libraryId),
      (ActivityType.strength, 40, 'Barbell_Bench_Press_-_Medium_Grip'),
    );
    expect('${saved.exercises.single}', '$_bench 2 × 10 · 60 kg');
    expect(saved.kcal, closeTo((5 - 1) * 80 * 40 / 60, 0.01));
    expect(find.bySemanticsLabel(RegExp('$_bench 2 × 10 · 60 kg')), findsOneWidget); // in Recent activity
    expect(await c.read(workoutProvider.future), isNull);

    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();
    await _addBench(tester);
    expect(find.text('Last time: $_bench 2 × 10 · 60 kg'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text, '60');
    expect(find.byTooltip('Mark set 3 done'), findsNothing, reason: 'two sets, like last time');
  });
}
