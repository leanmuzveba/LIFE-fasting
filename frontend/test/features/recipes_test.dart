import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/domain/food.dart';
import 'package:life_fasting/domain/kitchen.dart';
import 'package:life_fasting/domain/profile.dart';
import 'package:life_fasting/domain/recipe.dart';
import 'package:life_fasting/state/providers.dart';

import '../widget_test.dart' show pumpApp, recipeApi;

final _t = DateTime.utc(2026, 10, 1);
final _today = DateTime(2026, 10, 4);
Ingredient _k(String name, {DateTime? expires}) => Ingredient(
  name: name,
  categories: const {},
  quantity: 1,
  unit: 'pcs',
  state: FoodState.fresh,
  expiresOn: expires,
  createdAt: _t,
  updatedAt: _t,
);

Map<String, dynamic> _meal(String id, String name, List<(String, String)> ingredients, {String steps = 'Cook.'}) => {
  'idMeal': id,
  'strMeal': name,
  'strCategory': 'Breakfast',
  'strArea': 'British',
  'strInstructions': steps,
  'strMealThumb': null,
  for (final (i, (n, m)) in ingredients.indexed) ...{'strIngredient${i + 1}': n, 'strMeasure${i + 1}': m},
};

Recipe _r(List<String> ingredients) =>
    Recipe(id: '1', name: 'x', ingredients: [for (final i in ingredients) RecipeIngredient(i, '')]);

Future<void> _dismissSnack(WidgetTester tester) async {
  ScaffoldMessenger.of(tester.element(find.byType(Scaffold).last)).removeCurrentSnackBar();
  await tester.pumpAndSettle();
}

void main() {
  test('ingredient matching folds plurals and uses head nouns only', () {
    expect(sameIngredient('Baby spinach', 'Spinach'), isTrue);
    expect(sameIngredient('Eggs', 'Egg'), isTrue);
    expect(sameIngredient('Tomatoes', 'tomato'), isTrue);
    expect(sameIngredient('Apples', 'Apple'), isTrue);
    expect(sameIngredient('Rice', 'Rice vinegar'), isFalse);
    expect(sameIngredient('Rice vinegar', 'Rice'), isFalse);
    expect(sameIngredient('Brown rice', 'Rice'), isTrue);
  });

  test('matches: expired items are not available; ranking prefers complete and expiring', () {
    final kitchen = [
      _k('Eggs', expires: DateTime(2026, 10, 5)),
      _k('Spinach'),
      _k('Milk', expires: DateTime(2026, 10, 1)), // expired
    ];
    final a = RecipeMatch(_r(['Eggs', 'Spinach']), kitchen, _today);
    final b = RecipeMatch(_r(['Eggs', 'Milk']), kitchen, _today);
    expect(a.complete, isTrue);
    expect(a.usesExpiring, 1);
    expect(b.missing.map((i) => i.name), ['Milk']);
    expect(rankMatches([b, a]).first, same(a));
  });

  test('allergens and diets are judged from ingredient names', () {
    expect(allergensIn(_r(['Peanut Butter', 'Bread'])), {Allergen.peanuts, Allergen.dairy, Allergen.gluten});
    expect(allergensIn(_r(['Nutmeg', 'Coconut Milk'])).contains(Allergen.treeNuts), isFalse);
    expect(allergensIn(_r(['Walnuts'])), contains(Allergen.treeNuts));
    expect(fitsDiet(_r(['Chicken Breast', 'Rice']), DietPreference.vegetarian), isFalse);
    expect(fitsDiet(_r(['Eggs', 'Spinach']), DietPreference.vegetarian), isTrue);
    expect(fitsDiet(_r(['Eggs', 'Spinach']), DietPreference.vegan), isFalse);
    expect(fitsDiet(_r(['Salmon']), DietPreference.pescatarian), isTrue);
    expect(fitsDiet(_r(['Bacon']), DietPreference.halal), isFalse);
  });

  test('batch scaling handles whole numbers, fractions and words', () {
    expect(scaleMeasure('1 1/2 cups', 2), '3 cups');
    expect(scaleMeasure('1/2 tsp', 2), '1 tsp');
    expect(scaleMeasure('½ cup', 3), '1.5 cup');
    expect(scaleMeasure('200g', 0.5), '100g');
    expect(scaleMeasure('1 cup', 2), '2 cup');
    expect(scaleMeasure('to taste', 2), 'to taste');
    expect(scaleMeasure('2 tbs', 1), '2 tbs');
  });

  test('parses a TheMealDB meal; blank ingredients and step numbers dropped', () {
    final r = Recipe.fromMealDb({
      ..._meal('7', 'Shakshuka', [('Eggs', '4'), ('Tomatoes', '400g')], steps: 'STEP 1\r\nFry onions.\r\n2. Add eggs.'),
      'strIngredient3': '',
      'strMeasure3': ' ',
    });
    expect(r.ingredients.map((i) => i.name), ['Eggs', 'Tomatoes']);
    expect(r.steps, ['Fry onions.', 'Add eggs.']);
  });

  testWidgets('suggests from the kitchen, hides allergens, logs to diary once, fills the shopping list', (
    tester,
  ) async {
    await pumpApp(tester);
    tester.view.physicalSize = const Size(390, 3200);
    final c = ProviderScope.containerOf(tester.element(find.text('RUVA')));
    await c.read(kitchenRepositoryProvider).insert(_k('Eggs', expires: DateTime(2026, 10, 5)));
    await c.read(kitchenRepositoryProvider).insert(_k('Baby spinach'));
    c.invalidate(kitchenProvider);
    await c.read(settingsProvider.notifier).change((s) => s.copyWith(allergies: {Allergen.peanuts}));
    recipeApi.responses
      ..['filter.php?i=eggs'] = {
        'meals': [
          {'idMeal': '1'},
          {'idMeal': '2'},
        ],
      }
      ..['filter.php?i=spinach'] = {
        'meals': [
          {'idMeal': '1'},
          {'idMeal': '3'},
        ],
      }
      ..['lookup.php?i=1'] = {
        'meals': [
          _meal('1', 'Spinach scrambled eggs', [('Eggs', '2'), ('Spinach', '1 cup'), ('Butter', '1 tbs')]),
        ],
      }
      ..['lookup.php?i=2'] = {
        'meals': [
          _meal('2', 'Peanut egg noodles', [('Eggs', '2'), ('Peanut Butter', '2 tbs')]),
        ],
      }
      ..['lookup.php?i=3'] = {
        'meals': [
          _meal('3', 'Spinach dal', [('Spinach', '200g'), ('Red Lentils', '1 cup'), ('Onion', '1')]),
        ],
      };

    await tester.tap(find.bySemanticsLabel('Nutrition').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recipes'));
    await tester.pumpAndSettle();
    expect(recipeApi.requests, contains('filter.php?i=baby_spinach')); // then falls back to "spinach"
    expect(find.text('Spinach scrambled eggs'), findsOneWidget);
    expect(find.text('Spinach dal'), findsOneWidget);
    expect(find.text('Peanut egg noodles'), findsNothing);
    expect(find.textContaining('Hiding recipes with: Peanuts'), findsOneWidget);
    expect(find.text('2 of 3 ingredients available'), findsOneWidget);
    expect(find.text('Missing: butter'), findsOneWidget);

    await tester.tap(find.text('Spinach scrambled eggs'));
    await tester.pumpAndSettle();
    expect(find.text('Butter'), findsOneWidget);
    await tester.tap(find.text('2×'));
    await tester.pumpAndSettle();
    expect(find.text('2 cup'), findsOneWidget);

    await tester.tap(find.text('Add missing to shopping list'));
    await tester.pumpAndSettle();
    expect((await c.read(reviewRepositoryProvider).shoppingList()).map((i) => i.name), ['Butter']);
    await _dismissSnack(tester);

    for (final expected in ['Logged to Breakfast', 'Already in today’s Breakfast']) {
      await tester.tap(find.text('Log to Food Diary'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Breakfast').last);
      await tester.pump();
      expect(find.text(expected), findsOneWidget);
      await _dismissSnack(tester);
    }
    final diary = await c.read(foodRepositoryProvider).forDay(DateTime(2026, 10, 4));
    expect(diary.single.name, 'Spinach scrambled eggs');
    expect(diary.single.grams, isNull);
    expect(diary.single.nutrients, isEmpty);
    expect(diary.single.meal, Meal.breakfast);

    await tester.tap(find.text('Mark as cooked'));
    await tester.pumpAndSettle();
    expect((await c.read(recipeRepositoryProvider).lastCooked()).keys, ['1']);
  });

  testWidgets('offline with nothing cached shows a retry', (tester) async {
    await pumpApp(tester);
    final c = ProviderScope.containerOf(tester.element(find.text('RUVA')));
    await c.read(kitchenRepositoryProvider).insert(_k('Eggs'));
    c.invalidate(kitchenProvider);
    recipeApi.offline = true;
    await tester.tap(find.bySemanticsLabel('Nutrition').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recipes'));
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
  });
}
