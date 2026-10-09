import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/data/meal_photo_api.dart';
import 'package:life_fasting/domain/kitchen.dart';
import 'package:life_fasting/state/providers.dart';

import '../widget_test.dart' show foodFacts, mealPhoto, pumpApp, scannedBarcode;

final _now = DateTime(2026, 10, 4, 7, 24);

Future<ProviderContainer> _openAdd(WidgetTester tester, void Function() setUpFakes) async {
  await pumpApp(tester);
  setUpFakes();
  tester.view.physicalSize = const Size(390, 3000);
  await tester.tap(find.bySemanticsLabel('Nutrition').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('My Kitchen'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Add Ingredient'));
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
}

void main() {
  test('a product becomes a draft ingredient: size, unit, category and state', () {
    final beans = ingredientFromProduct({
      'product_name': 'Baked beans in tomato sauce',
      'brands': 'KOO, Tiger Brands',
      'quantity': '410 g',
      'product_quantity': 410,
      'categories_tags': ['en:plant-based-foods', 'en:legumes', 'en:canned-foods'],
    }, _now)!;
    expect(beans.name, 'Baked beans in tomato sauce');
    expect(beans.brand, 'KOO');
    expect((beans.quantity, beans.unit), (410.0, 'g'));
    expect(beans.categories, {IngredientCategory.protein});
    expect(beans.state, FoodState.canned);
    expect(beans.id, isNull);

    final milk = ingredientFromProduct({
      'product_name': 'Full cream milk',
      'quantity': '1 l',
      'product_quantity': '1000',
      'categories_tags': ['en:dairies', 'en:milks'],
    }, _now)!;
    expect((milk.quantity, milk.unit), (1000.0, 'ml'));
    expect(milk.categories, {IngredientCategory.dairy});

    final odd = ingredientFromProduct({'product_name': 'Mystery snack'}, _now)!;
    expect((odd.quantity, odd.unit), (1.0, 'pcs'));
    expect(odd.categories, {IngredientCategory.pantry});
    expect(ingredientFromProduct({'product_name': ''}, _now), isNull);
  });

  test('grocery reply: unknown units become pieces, unknown categories dropped', () {
    final items = parseGroceries({
      'items': [
        {
          'name': 'Eggs',
          'quantity': 6,
          'unit': 'pcs',
          'categories': ['protein'],
          'state': 'fresh',
        },
        {
          'name': 'Rice',
          'quantity': 2,
          'unit': 'kilos',
          'categories': ['carbs', 'grains'],
          'state': 'dried',
        },
        {'name': '', 'quantity': 1, 'unit': 'g', 'categories': [], 'state': 'fresh'},
        {'name': 'Nothing', 'quantity': 0, 'unit': 'g', 'categories': [], 'state': 'fresh'},
      ],
    });
    expect(items.map((i) => (i.name, i.unit, i.state)), [
      ('Eggs', 'pcs', FoodState.fresh),
      ('Rice', 'pcs', FoodState.dried),
    ]);
    expect(items[1].categories, {IngredientCategory.carbs});
  });

  testWidgets('Add Ingredient → scan: the form opens prefilled and saves', (tester) async {
    final c = await _openAdd(tester, () {
      foodFacts.products['6001059940006'] = {
        'product_name': 'Peanut butter smooth',
        'brands': 'Black Cat',
        'quantity': '400 g',
        'product_quantity': 400,
        'categories_tags': ['en:spreads', 'en:nuts'],
      };
      scannedBarcode = '6001059940006';
    });
    expect(find.text('Type it in'), findsOneWidget);
    await tester.tap(find.text('Scan a barcode'));
    await tester.pumpAndSettle();
    expect(find.text('New Stock Entry'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Peanut butter smooth'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Black Cat'), findsOneWidget);
    await tester.ensureVisible(find.text('Save ingredient'));
    await tester.tap(find.text('Save ingredient'));
    await tester.pumpAndSettle();
    final saved = (await c.read(kitchenRepositoryProvider).active()).single;
    expect((saved.name, saved.quantity, saved.unit), ('Peanut butter smooth', 400.0, 'g'));
    expect(saved.categories, {IngredientCategory.fatsNutsSeeds});
  });

  testWidgets('Add Ingredient → photo: review, untick, then add', (tester) async {
    final c = await _openAdd(tester, () {
      mealPhoto!.groceriesReply = const [
        SpottedItem(
          name: 'Tomatoes',
          quantity: 6,
          unit: 'pcs',
          categories: {IngredientCategory.vegetables},
          state: FoodState.fresh,
        ),
        SpottedItem(
          name: 'Pasta',
          quantity: 500,
          unit: 'g',
          categories: {IngredientCategory.carbs},
          state: FoodState.dried,
        ),
        SpottedItem(name: 'Soap', quantity: 1, unit: 'pcs', categories: {}, state: FoodState.fresh),
      ];
    });
    await tester.tap(find.text('Snap your groceries'));
    await tester.pumpAndSettle();
    expect(find.text('Add 3 items to My Kitchen'), findsOneWidget);
    await tester.tap(find.text('Soap'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add 2 items to My Kitchen'));
    await tester.pumpAndSettle();
    final items = await c.read(kitchenRepositoryProvider).active();
    expect(items.map((i) => (i.name, i.quantity, i.unit)), [('Pasta', 500.0, 'g'), ('Tomatoes', 6.0, 'pcs')]);
    expect(items.first.notes, 'Added from a photo');
  });
}
