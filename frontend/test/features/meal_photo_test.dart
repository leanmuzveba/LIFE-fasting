import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/data/meal_photo_api.dart';
import 'package:life_fasting/domain/food.dart';
import 'package:life_fasting/domain/meal_estimate.dart';
import 'package:life_fasting/state/providers.dart';

import '../widget_test.dart' as app show mealPhoto;
import '../widget_test.dart' show pumpApp;

Future<void> _openPhoto(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Nutrition').last);
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Add to Lunch'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Snap a meal photo'));
  await tester.pumpAndSettle();
}

void main() {
  test('parses the structured reply; bad items dropped, missing values unavailable', () {
    final e = parseMealEstimate({
      'is_food': true,
      'note': ' Looks like pap and stew. ',
      'items': [
        {'name': 'Pap', 'grams': 250, 'kcal': 280, 'protein_g': 6, 'carbs_g': 60, 'fat_g': 1, 'fibre_g': 3},
        {'name': 'Beef stew', 'grams': 200, 'kcal': 300},
        {'name': '', 'grams': 50, 'kcal': 10},
        {'name': 'Air', 'grams': 0, 'kcal': 0},
      ],
    });
    expect(e.note, 'Looks like pap and stew.');
    expect(e.items.map((i) => i.name), ['Pap', 'Beef stew']);
    expect(e.items[1].nutrients.containsKey(Nutrient.protein), isFalse);
    expect(e.items[0].withGrams(125).nutrients[Nutrient.energy], 140);
  });

  testWidgets('photo → review and edit → logged as labelled estimates', (tester) async {
    await pumpApp(tester);
    tester.view.physicalSize = const Size(390, 3000);
    final c = ProviderScope.containerOf(tester.element(find.text('RUVA')));
    app.mealPhoto!.reply = const MealEstimate(
      isFood: true,
      note: 'Rice may be larger than it looks.',
      items: [
        EstimatedItem(name: 'White rice', grams: 200, nutrients: {Nutrient.energy: 260, Nutrient.protein: 5}),
        EstimatedItem(name: 'Chicken curry', grams: 150, nutrients: {Nutrient.energy: 240}),
        EstimatedItem(name: 'Salad', grams: 80, nutrients: {Nutrient.energy: 20}),
      ],
    );
    await _openPhoto(tester);
    expect(find.text('3 items found'.toUpperCase()), findsOneWidget);
    expect(find.text('520 kcal (est.)'), findsOneWidget);
    expect(find.textContaining('AI estimate — check every item'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove Salad'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Rename Chicken curry'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Chicken stew');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More').first); // rice 200 → 210 g
    await tester.pumpAndSettle();
    expect(find.text('210 g'), findsOneWidget);

    await tester.tap(find.text('Add 2 items to Lunch'));
    await tester.pumpAndSettle();
    final entries = await c.read(foodRepositoryProvider).forDay(DateTime(2026, 10, 4));
    expect(entries.map((e) => (e.name, e.grams, e.portion, e.meal)), [
      ('White rice', 210.0, 'photo estimate', Meal.lunch),
      ('Chicken stew', 150.0, 'photo estimate', Meal.lunch),
    ]);
    expect(entries.first.nutrients[Nutrient.energy], 273);
    expect(find.bySemanticsLabel('Energy: 513 kcal, Estimated'), findsOneWidget);
  });

  testWidgets('no key, a bad key, or not food: clear messages, nothing saved', (tester) async {
    await pumpApp(tester);
    tester.view.physicalSize = const Size(390, 3000);
    final c = ProviderScope.containerOf(tester.element(find.text('RUVA')));
    app.mealPhoto!.reply = const MealEstimate(isFood: false, items: []);
    await _openPhoto(tester);
    expect(find.textContaining('No food was recognised'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    app.mealPhoto!.error = const MealPhotoKeyException('API key not valid');
    await tester.tap(find.byTooltip('Add to Lunch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Snap a meal photo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('didn’t accept the API key'), findsOneWidget);
    expect(await c.read(foodRepositoryProvider).forDay(DateTime(2026, 10, 4)), isEmpty);
  });
}
