import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/domain/plan.dart';
import 'package:life_fasting/domain/workout.dart';
import 'package:life_fasting/state/providers.dart';

import '../widget_test.dart' show pumpApp, tick;

List<LibraryExercise> _library() => [
  for (final j in jsonDecode(File('assets/exercises/exercises.json').readAsStringSync()) as List)
    LibraryExercise.fromJson(j as Map<String, dynamic>),
];

void main() {
  final library = _library();
  final byId = {for (final x in library) x.id: x};

  test('a plan gives each day different muscles, with sets and reps for the goal', () {
    for (final days in [3, 4, 5]) {
      final p = buildPlan(
        library,
        goal: PlanGoal.muscle,
        daysPerWeek: days,
        level: PlanLevel.intermediate,
        equipment: PlanEquipment.gym,
      );
      expect(p.days.map((d) => d.focus), splits[days]);
      expect(p.days.map((d) => d.focus).toSet(), hasLength(days), reason: 'a different focus every day');
      for (final d in p.days) {
        expect(d.exercises, isNotEmpty);
        expect(d.exercises.map((x) => x.libraryId).toSet(), hasLength(d.exercises.length), reason: 'no repeats');
        expect('${d.exercises.first.sets} × ${d.exercises.first.log.first.reps}', '4 × 8');
        expect('${d.exercises.last.sets} × ${d.exercises.last.log.first.reps}', '3 × 10');
      }
    }
    final push = buildPlan(
      library,
      goal: PlanGoal.strength,
      daysPerWeek: 3,
      level: PlanLevel.beginner,
      equipment: PlanEquipment.gym,
    );
    expect(push.days.first.exercises.first.name, 'Barbell Bench Press - Medium Grip');
    expect(push.days.first.exercises.first.sets, 3, reason: 'beginners do at most 3 sets');
    expect(push.rest, 150);
    // Round trip.
    final back = WorkoutPlan.fromJson(jsonDecode(jsonEncode(push.toJson())) as Map<String, dynamic>);
    expect(back.days[1].exercises.map((x) => '$x'), push.days[1].exercises.map((x) => '$x'));
  });

  test('home plans only use what you have, at your level', () {
    final p = buildPlan(
      library,
      goal: PlanGoal.fatLoss,
      daysPerWeek: 5,
      level: PlanLevel.beginner,
      equipment: PlanEquipment.bodyweight,
    );
    for (final x in p.days.expand((d) => d.exercises)) {
      final e = byId[x.libraryId]!;
      expect(const {null, 'body only'}, contains(e.equipment), reason: x.name);
      expect(e.level, 'beginner', reason: x.name);
    }
    final dumbbells = buildPlan(
      library,
      goal: PlanGoal.muscle,
      daysPerWeek: 3,
      level: PlanLevel.expert,
      equipment: PlanEquipment.dumbbells,
    );
    expect(dumbbells.days.first.exercises.first.name, 'Dumbbell Bench Press');
  });

  testWidgets('make a plan, start its first day prefilled, finish it: day 2 is up next', (tester) async {
    final clock = await pumpApp(tester);
    tester.view.physicalSize = const Size(390, 2400);
    final c = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    await tester.runAsync(() => c.read(exerciseLibraryProvider.future));
    await tester.tap(find.bySemanticsLabel('Activity').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Make a workout plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get stronger'));
    await tester.tap(find.text('4 days'));
    await tester.pump();
    expect(find.text('Chest & triceps · Back & biceps · Legs · Shoulders & core'), findsOneWidget);
    await tester.tap(find.text('Create my plan'));
    await tester.pumpAndSettle();
    expect(find.text('Get stronger · 4 days a week · 150 s rest between sets'), findsOneWidget);
    expect(find.text('DAY 1 · CHEST & TRICEPS'), findsOneWidget);
    expect(find.text('Barbell Bench Press - Medium Grip'), findsOneWidget);

    // Change an exercise's sets and reps.
    await tester.tap(find.text('Barbell Bench Press - Medium Grip'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('1 rep more'));
    await tester.pumpAndSettle();
    expect(find.text('6 reps'), findsOneWidget);
    await tester.tapAt(const Offset(195, 20)); // close the sheet
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start day 1'));
    await tester.pumpAndSettle();
    final w = (await c.read(workoutProvider.future))!;
    expect(
      (w.planDay, w.exercises.first.name, w.exercises.first.log.length),
      (0, 'Barbell Bench Press - Medium Grip', 3),
    );
    expect(w.exercises.first.log.first.reps, 6);
    expect(await c.read(restSecondsProvider.future), 150);
    await tester.tap(find.byTooltip('Mark set 1 done').first);
    await tester.pump();
    await tick(tester, clock, const Duration(minutes: 30));
    await tester.ensureVisible(find.text('Finish workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish workout'));
    await tester.pumpAndSettle();
    expect((await c.read(planProvider.future))!.next, 1);
    await tester.pageBack(); // the plan screen
    await tester.pumpAndSettle();
    expect(find.text('Up next: Day 2 · Back & biceps'), findsOneWidget);
    expect(find.text('Start day 2'), findsOneWidget);
  });
}
