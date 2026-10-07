import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/domain/food.dart';
import 'package:life_fasting/state/providers.dart';

import '../widget_test.dart' show pumpApp;

FoodEntry _e(String name, Nutrients n) => FoodEntry(
  day: DateTime(2026, 10, 4),
  meal: Meal.lunch,
  loggedAt: DateTime.utc(2026, 10, 4, 12),
  name: name,
  grams: 100,
  nutrients: n,
);

Future<void> _openDiary(WidgetTester tester) async {
  await pumpApp(tester);
  tester.view.physicalSize = const Size(390, 3000);
  await tester.tap(find.bySemanticsLabel('Nutrition').last);
  await tester.pumpAndSettle();
}

void main() {
  test('parses a USDA line; blank nutrients stay unavailable', () {
    final f = Food.fromUsdaLine(
      '170903\tYogurt, Greek, plain, lowfat\t73\t9.95\t3.94\t1.92\t\t115\t\t\t\t\t1 cup=245|bad|1 tbsp=15',
    );
    expect(f.key, 'usda:170903');
    expect(f.per100g[Nutrient.energy], 73);
    expect(f.per100g.containsKey(Nutrient.fibre), isFalse);
    expect(f.portions.map((p) => (p.label, p.grams)), [('1 cup', 245.0), ('1 tbsp', 15.0)]);
  });

  test('search needs every word; prefix matches and shorter names first', () {
    const foods = [
      Food(key: 'usda:1', name: 'Rice, white, long-grain, cooked', per100g: {}),
      Food(key: 'usda:2', name: 'Rice, white, cooked', per100g: {}),
      Food(key: 'usda:3', name: 'Beans, with rice', per100g: {}),
      Food(key: 'usda:4', name: 'Bread, white', per100g: {}),
    ];
    expect(searchFoods(foods, 'rice white').map((f) => f.key), ['usda:2', 'usda:1']);
    expect(searchFoods(foods, 'rice').map((f) => f.key), ['usda:2', 'usda:1', 'usda:3']);
    expect(searchFoods(foods, '  '), isEmpty);
  });

  test('day totals mark partial and unavailable nutrients', () {
    final t = DayTotals([
      _e('a', {Nutrient.energy: 100, Nutrient.protein: 5}),
      _e('b', {Nutrient.energy: 50}),
    ]);
    expect(t.sum[Nutrient.energy], 150);
    expect(t.incomplete, {Nutrient.protein});
    expect(t.sum.containsKey(Nutrient.fibre), isFalse);
    expect(_e('c', {Nutrient.energy: 100}).copyWith(grams: 250).nutrients[Nutrient.energy], 250);
  });

  testWidgets('search, log with a portion, add your own food, change and remove', (tester) async {
    await _openDiary(tester);
    expect(find.text('Food Diary'), findsOneWidget);
    expect(find.text('Nothing logged yet — that’s perfectly fine.'), findsNWidgets(4));

    // USDA food with a household portion.
    await tester.tap(find.byTooltip('Add to Breakfast'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search foods'));
    await tester.pumpAndSettle();
    expect(find.text('Search foods…'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'greek yogurt plain');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yogurt, Greek, plain, lowfat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 container (7 oz)'));
    await tester.pumpAndSettle();
    expect(find.text('1 container (7 oz) (200 g)'), findsOneWidget);
    expect(find.text('≈ 146 kcal (est.)'), findsOneWidget);
    await tester.tap(find.text('Add to Breakfast'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp(r'^Yogurt, Greek, plain, lowfat, .*146 kcal')), findsOneWidget);
    expect(find.bySemanticsLabel('Energy: 146 kcal, Estimated'), findsOneWidget);

    // Your own food, energy only.
    await tester.tap(find.byTooltip('Add to Lunch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search foods'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create custom food'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), 'Mum’s stew');
    await tester.enterText(fields.at(2), '250');
    await tester.enterText(fields.at(3), '300');
    await tester.tap(find.text('Save and select'));
    await tester.pumpAndSettle();
    expect(find.text('1 serving (250 g)'), findsOneWidget);
    await tester.tap(find.text('Add to Lunch'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Energy: 446 kcal, Estimated'), findsOneWidget);
    expect(find.bySemanticsLabel('Protein: 20 g, Partial'), findsOneWidget);

    // Change the amount, then remove it.
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Mum’s stew, ')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Energy: 458 kcal, Estimated'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Mum’s stew, ')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Energy: 146 kcal, Estimated'), findsOneWidget);
  });

  testWidgets('recent and saved foods are one tap away; other days are separate', (tester) async {
    await _openDiary(tester);
    final c = ProviderScope.containerOf(tester.element(find.text('Food Diary')));
    final yogurt = (await c.read(usdaFoodsProvider.future)).firstWhere((f) => f.name == 'Yogurt, Greek, plain, lowfat');
    await c.read(foodActionsProvider).log(yogurt, 150, meal: Meal.breakfast, at: DateTime(2026, 10, 4, 7));
    await c.read(foodActionsProvider).setSaved(yogurt, true, grams: 150);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add food'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search foods'));
    await tester.pumpAndSettle();
    expect(find.text('RECENT'), findsOneWidget);
    expect(find.text('SAVED'), findsOneWidget);
    await tester.tap(find.text('Yogurt, Greek, plain, lowfat').first);
    await tester.pumpAndSettle();
    expect(find.text('150 g'), findsOneWidget);
    expect(find.byTooltip('Remove from favourites'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Previous day'));
    await tester.pumpAndSettle();
    expect(find.text('Sat, 3 Oct'), findsOneWidget);
    expect(find.text('Nothing logged yet — that’s perfectly fine.'), findsNWidgets(4));
    await tester.tap(find.byTooltip('Next day'));
    await tester.pumpAndSettle();
    expect(find.text('Sat, 3 Oct'), findsNothing);
  });
}
