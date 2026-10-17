import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/domain/food.dart';
import 'package:life_fasting/features/food/meal_export_screen.dart';
import 'package:life_fasting/state/providers.dart';

import '../widget_test.dart' show pumpApp;

void main() {
  testWidgets('export one meal: calories, macros and foods; meals switch', (tester) async {
    await pumpApp(tester);
    tester.view.physicalSize = const Size(390, 2400);
    final c = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    for (final (name, kcal, protein) in [('Rice', 200.0, 4.0), ('Chicken', 250.0, 30.0)]) {
      await c
          .read(foodRepositoryProvider)
          .insert(
            FoodEntry(
              day: DateTime(2026, 10, 4),
              meal: Meal.lunch,
              loggedAt: DateTime.utc(2026, 10, 4, 12),
              name: name,
              grams: 100,
              nutrients: {Nutrient.energy: kcal, Nutrient.protein: protein, Nutrient.fat: 5},
            ),
          );
    }
    c.invalidate(diaryDayProvider);
    await tester.tap(find.bySemanticsLabel('Nutrition').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip("Export a meal's nutrition"));
    await tester.pumpAndSettle();

    final card = find.byType(MealCard);
    expect(tester.widget<MealCard>(card).meal, Meal.lunch); // the first meal with food
    expect(find.descendant(of: card, matching: find.text('450 kcal')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('34 g')), findsOneWidget); // protein
    expect(find.descendant(of: card, matching: find.text('—')), findsNWidgets(2)); // carbs, fibre unknown
    expect(find.descendant(of: card, matching: find.text('Chicken · 250 kcal')), findsOneWidget);

    await tester.tap(find.text('Dinner'));
    await tester.pump();
    expect(find.byType(MealCard), findsNothing);
    expect(find.text('Nothing logged for Dinner on this day.'), findsOneWidget);
  });
}
