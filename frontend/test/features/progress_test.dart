import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/domain/activity.dart';
import 'package:life_fasting/domain/workout.dart';
import 'package:life_fasting/state/providers.dart';

import '../widget_test.dart' show pumpApp;

const _bench = 'Barbell Bench Press - Medium Grip';
const _benchId = 'Barbell_Bench_Press_-_Medium_Grip';

void main() {
  test('weeks: counted Monday to Sunday; the streak survives a week not over yet', () {
    final now = DateTime(2026, 10, 4, 7); // Sunday
    final counts = weeklyCounts(
      [
        DateTime(2026, 9, 28, 6), // this week's Monday
        DateTime(2026, 10, 4, 6),
        DateTime(2026, 9, 27, 20), // last week's Sunday
        DateTime(2026, 9, 9),
      ],
      now,
      weeks: 4,
    );
    expect(counts, [1, 0, 1, 2]);
    expect(weekStreak(counts), 2);
    expect(weekStreak([1, 1, 0]), 2, reason: 'nothing yet this week');
    expect(weekStreak([1, 0, 0]), 0);
    final series = oneRepMaxSeries([
      (DateTime(2026, 10, 2), const Exercise.logged('Squat', [SetLog(reps: 5, kg: 100)])),
      (DateTime(2026, 9, 30), const Exercise.logged('Squat', [SetLog(reps: 10)])), // no weight: skipped
      (DateTime(2026, 9, 25), const Exercise.logged('Squat', [SetLog(reps: 5, kg: 90)])),
    ]);
    expect([for (final (_, v) in series) v.toStringAsFixed(1)], ['105.0', '116.7']);
  });

  testWidgets('progress: workouts a week, streak, personal bests; the chart on an exercise', (tester) async {
    await pumpApp(tester);
    tester.view.physicalSize = const Size(390, 2400);
    final c = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    await tester.runAsync(() => c.read(exerciseLibraryProvider.future));
    Future<void> log(DateTime t, List<Exercise> exercises) => c
        .read(activityRepositoryProvider)
        .insert(
          ActivityEntry(
            type: ActivityType.strength,
            startedAt: t,
            minutes: 40,
            createdAt: t,
            updatedAt: t,
            exercises: exercises,
          ),
        );
    await log(DateTime.utc(2026, 9, 24, 17), const [
      Exercise.logged(_bench, [SetLog(reps: 5, kg: 60)], libraryId: _benchId),
    ]);
    await log(DateTime.utc(2026, 10, 2, 17), const [
      Exercise.logged(_bench, [SetLog(reps: 5, kg: 70), SetLog(reps: 8, kg: 50, done: false)], libraryId: _benchId),
      Exercise.logged('Pull-ups at the park', [SetLog(reps: 8), SetLog(reps: 11)]),
    ]);
    c.invalidate(recentActivitiesProvider);
    await tester.tap(find.bySemanticsLabel('Activity').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.text('2 weeks'), findsOneWidget); // streak
    expect(find.bySemanticsLabel(RegExp('Workouts per week, last 8 weeks: 0, 0, 0, 0, 0, 0, 1, 1')), findsOneWidget);
    expect(find.text('Pull-ups at the park'), findsOneWidget);
    expect(find.text('Most reps in a set: 11 · Fri 2 Oct'), findsOneWidget);
    expect(find.text('Best estimated 1-rep max 81.7 kg · Fri 2 Oct'), findsOneWidget); // the unticked set doesn't count

    await tester.tap(find.text(_bench));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('Estimated 1-rep max went from 70 kg to 81.7 kg')), findsOneWidget);
  });

  testWidgets('progress before any workout says how to start', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel('Activity').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.text('Finish a strength workout and your progress shows here.'), findsOneWidget);
  });
}
