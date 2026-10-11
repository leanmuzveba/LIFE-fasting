import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/domain/food.dart';
import 'package:life_fasting/domain/kitchen.dart';
import 'package:life_fasting/domain/recipe.dart';
import 'package:life_fasting/state/providers.dart';

import '../widget_test.dart' show pumpApp, recipeApi;

final _t = DateTime.utc(2026, 10, 1);

void main() {
  testWidgets('write a recipe offline; it matches My Kitchen, filters, edits and deletes', (tester) async {
    await pumpApp(tester);
    tester.view.physicalSize = const Size(390, 3200);
    recipeApi.offline = true; // your own recipes don't need the internet
    final c = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    await c
        .read(kitchenRepositoryProvider)
        .insert(
          Ingredient(
            name: 'Eggs',
            categories: const {IngredientCategory.protein},
            quantity: 6,
            unit: 'pcs',
            state: FoodState.fresh,
            createdAt: _t,
            updatedAt: _t,
          ),
        );
    c.invalidate(kitchenProvider);
    await tester.tap(find.bySemanticsLabel('Nutrition').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recipes'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New recipe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save recipe'));
    await tester.pumpAndSettle();
    expect(find.text('Give the recipe a name.'), findsOneWidget);

    final f = find.byType(TextField);
    await tester.enterText(f.at(0), 'Gogo’s eggs');
    await tester.enterText(f.at(2), '15'); // minutes
    await tester.enterText(f.at(3), '2'); // servings
    await tester.enterText(f.at(4), 'Eggs');
    await tester.enterText(f.at(5), '4');
    await tester.tap(find.text('Add ingredient'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(6), 'Tomatoes');
    await tester.enterText(find.byType(TextField).at(7), '2');
    await tester.enterText(find.byType(TextField).at(8), 'Whisk the eggs.\n\nCook gently.');
    await tester.tap(find.text('Save recipe'));
    await tester.pumpAndSettle();

    expect(find.text('Gogo’s eggs'), findsOneWidget);
    expect(find.text('Your recipe'), findsOneWidget);
    expect(find.text('1/2 ingredients'), findsOneWidget);
    await tester.tap(find.text('My recipes'));
    await tester.pumpAndSettle();
    expect(find.text('Gogo’s eggs'), findsOneWidget);

    await tester.tap(find.text('Gogo’s eggs'));
    await tester.pumpAndSettle();
    expect(find.text('15 min'), findsOneWidget);
    expect(find.text('2 servings'), findsOneWidget);
    expect(find.text('Cook gently.'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit recipe'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Gogo’s scrambled eggs');
    await tester.tap(find.text('Save recipe'));
    await tester.pumpAndSettle();
    expect(find.text('Gogo’s scrambled eggs'), findsOneWidget);

    await tester.tap(find.text('Delete recipe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete recipe').last);
    await tester.pumpAndSettle();
    expect(await c.read(myRecipeRepositoryProvider).all(), isEmpty);
    expect(find.text('You haven’t written any recipes yet — tap “New recipe”.'), findsOneWidget);
  });

  testWidgets('recipes show in a two-column grid, 10 per page', (tester) async {
    await pumpApp(tester);
    tester.view.physicalSize = const Size(390, 3200);
    recipeApi.offline = true;
    final c = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    for (var i = 1; i <= 12; i++) {
      await c
          .read(myRecipeRepositoryProvider)
          .save(
            Recipe(
              id: 'mine:',
              name: 'Dish ${i.toString().padLeft(2, '0')}',
              ingredients: const [RecipeIngredient('Rice', '1 cup')],
            ),
          );
    }
    await tester.tap(find.bySemanticsLabel('Nutrition').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recipes'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Dish '), findsNWidgets(10));
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Dish '), findsNWidgets(2));
  });

  testWidgets('save a logged meal as a recipe with a photo and its macros', (tester) async {
    await pumpApp(tester);
    tester.view.physicalSize = const Size(390, 3600);
    recipeApi.offline = true;
    final c = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    final food = c.read(foodActionsProvider);
    const oats = Food(key: 'custom:1', name: 'Oats', per100g: {Nutrient.energy: 380, Nutrient.protein: 13});
    const milk = Food(key: 'custom:2', name: 'Milk', per100g: {Nutrient.energy: 60, Nutrient.protein: 3.2}, unit: 'ml');
    await food.log(oats, 50, meal: Meal.breakfast, at: DateTime(2026, 10, 4, 7));
    await food.log(milk, 200, meal: Meal.breakfast, at: DateTime(2026, 10, 4, 7));
    await tester.tap(find.bySemanticsLabel('Nutrition').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Save Breakfast as a recipe'));
    await tester.pumpAndSettle();
    expect(find.text('New recipe'), findsOneWidget);
    expect(find.widgetWithText(TextField, '200 ml'), findsOneWidget);
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Morning oats');
    await tester.ensureVisible(find.text('Save recipe'));
    await tester.tap(find.text('Save recipe'));
    await tester.pumpAndSettle();

    final r = (await c.read(myRecipeRepositoryProvider).all()).single;
    expect((r.name, r.category, r.servings), ('Morning oats', 'Breakfast', 1));
    expect(r.image, isNotNull);
    expect(r.nutrients[Nutrient.energy], closeTo(310, 0.001)); // 190 + 120
    expect(r.ingredients.map((i) => (i.name, i.measure)), [('Oats', '50 g'), ('Milk', '200 ml')]);

    // Logging it again carries the macros.
    await c.read(recipeActionsProvider).logToDiary(r, Meal.lunch, DateTime(2026, 10, 4, 12), servingLabel: '1 serving');
    final lunch = (await c.read(foodRepositoryProvider).forDay(DateTime(2026, 10, 4))).last;
    expect(lunch.nutrients[Nutrient.protein], closeTo(12.9, 0.001));
  });
}
