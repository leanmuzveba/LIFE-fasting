import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/domain/kitchen.dart';
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
    await tester.enterText(find.byType(TextField).last, 'Whisk the eggs.\n\nCook gently.');
    await tester.tap(find.text('Save recipe'));
    await tester.pumpAndSettle();

    expect(find.text('Gogo’s eggs'), findsOneWidget);
    expect(find.text('Your recipe'), findsOneWidget);
    expect(find.text('1 of 2 ingredients available'), findsOneWidget);
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
}
