import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/domain/kitchen.dart';
import 'package:life_fasting/state/providers.dart';

import '../widget_test.dart' show pumpApp;

/// Opens the Nutrition tab (My Kitchen) with [items] already stored.
Future<void> _openKitchen(WidgetTester tester, List<Ingredient> items) async {
  await pumpApp(tester);
  tester.view.physicalSize = const Size(390, 2600);
  final c = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
  for (final i in items) {
    await c.read(kitchenRepositoryProvider).insert(i);
  }
  c.invalidate(kitchenProvider);
  await tester.tap(find.bySemanticsLabel('Nutrition').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('My Kitchen'));
  await tester.pumpAndSettle();
}

final _t = DateTime.utc(2026, 10, 4);
Ingredient _i(
  String name,
  Set<IngredientCategory> cats, {
  double q = 1,
  String unit = 'pcs',
  DateTime? expires,
  double? lowAt,
}) => Ingredient(
  name: name,
  categories: cats,
  quantity: q,
  unit: unit,
  state: FoodState.fresh,
  expiresOn: expires,
  lowStockAt: lowAt,
  createdAt: _t,
  updatedAt: _t,
);

final _sample = [
  _i('Eggs', {IngredientCategory.protein}, q: 12, expires: DateTime(2026, 10, 6), lowAt: 3),
  _i('Baby spinach', {IngredientCategory.vegetables}, q: 300, unit: 'g', expires: DateTime(2026, 10, 4)),
  _i('Brown rice', {IngredientCategory.carbs}, q: 1.5, unit: 'kg'),
  _i('Red lentils', {IngredientCategory.protein}, q: 400, unit: 'g', lowAt: 400),
];

void main() {
  testWidgets('empty kitchen invites you to add what you have', (tester) async {
    await _openKitchen(tester, const []);
    expect(find.text('My Kitchen'), findsOneWidget);
    expect(find.text('Add what you have at home to get started.'), findsOneWidget);
    expect(find.text('Nothing here yet.'), findsOneWidget);
    await tester.tap(find.text('Add Ingredient'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Type it in'));
    await tester.pumpAndSettle();
    expect(find.text('New Stock Entry'), findsOneWidget);
  });

  testWidgets('overview counts expiring soon and low stock; items show quantity and expiry', (tester) async {
    await _openKitchen(tester, _sample);
    expect(find.text('4 items'), findsOneWidget);
    expect(find.bySemanticsLabel('Expiring soon: 2 items'), findsOneWidget);
    expect(find.bySemanticsLabel('Low stock: 1 item'), findsOneWidget);
    expect(find.text('12 pcs'), findsOneWidget);
    expect(find.text('1.5 kg'), findsOneWidget);
    expect(find.text('Expires in 2 days'), findsOneWidget);
    expect(find.text('Expires today'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Red lentils, 400 g, Fresh\. Low stock')), findsOneWidget);
  });

  testWidgets('search, category filter and overview tiles narrow the list', (tester) async {
    await _openKitchen(tester, _sample);
    await tester.enterText(find.byType(TextField), 'rice');
    await tester.pumpAndSettle();
    expect(find.text('In your kitchen · 1 item'.toUpperCase()), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Protein').first);
    await tester.pumpAndSettle();
    expect(find.text('Eggs'), findsOneWidget);
    expect(find.text('Red lentils'), findsOneWidget);
    expect(find.text('Brown rice'), findsNothing);
    await tester.tap(find.bySemanticsLabel('All').first);
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Low stock: 1 item'));
    await tester.pumpAndSettle();
    expect(find.text('Red lentils'), findsOneWidget);
    expect(find.text('Eggs'), findsNothing);
  });

  testWidgets('tap an item to edit; saved changes show in the list', (tester) async {
    await _openKitchen(tester, _sample);
    await tester.tap(find.text('Brown rice'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Ingredient'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), '2');
    await tester.ensureVisible(find.text('Save ingredient'));
    await tester.tap(find.text('Save ingredient'));
    await tester.pumpAndSettle();
    expect(find.text('2 kg'), findsOneWidget);
  });
}
