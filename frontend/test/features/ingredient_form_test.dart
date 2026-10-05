import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/domain/kitchen.dart';
import 'package:life_fasting/features/kitchen/ingredient_form_screen.dart';
import 'package:life_fasting/state/providers.dart';

import '../widget_test.dart' show pumpApp;

/// Opens the form on top of the running app; returns its provider container.
Future<ProviderContainer> openForm(WidgetTester tester, {Ingredient? existing}) async {
  await pumpApp(tester);
  tester.view.physicalSize = const Size(390, 2200);
  final ctx = tester.element(find.text('RUVA'));
  Navigator.of(ctx).push(MaterialPageRoute<void>(builder: (_) => IngredientFormScreen(existing: existing)));
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(ctx);
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('add an ingredient with several categories, unit, state and dates', (tester) async {
    final c = await openForm(tester);
    expect(find.text('New Stock Entry'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Greek yogurt');
    await tapText(tester, 'Protein');
    await tapText(tester, 'Dairy & alternatives');
    await tester.enterText(find.byType(TextField).at(1), '500');
    await tapText(tester, 'g');
    await tapText(tester, 'Frozen');
    await tester.enterText(find.byType(TextField).at(2), '100');
    await tester.enterText(find.byType(TextField).at(3), 'Clover');
    await tapText(tester, 'Save ingredient');

    final items = await c.read(kitchenProvider.future);
    expect(items, hasLength(1));
    final i = items.single;
    expect(i.name, 'Greek yogurt');
    expect(i.categories, {IngredientCategory.protein, IngredientCategory.dairy});
    expect([i.quantity, i.unit, i.state, i.lowStockAt, i.brand], [500.0, 'g', FoodState.frozen, 100.0, 'Clover']);
    expect(i.purchasedOn, DateTime(2026, 10, 4), reason: 'purchase date defaults to today');
    expect(i.expiresOn, isNull);
  });

  testWidgets('a missing name or quantity shows a clear message', (tester) async {
    final c = await openForm(tester);
    await tapText(tester, 'Save ingredient');
    expect(find.text('Please enter a name.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Eggs');
    await tapText(tester, 'Save ingredient');
    expect(find.text('Enter a quantity of 0 or more.'), findsOneWidget);
    expect(await c.read(kitchenProvider.future), isEmpty);
  });

  testWidgets('edit: mark as finished keeps history; remove deletes after confirming', (tester) async {
    final now = DateTime.utc(2026, 10, 4);
    final existing = Ingredient(
      name: 'Eggs',
      categories: const {IngredientCategory.protein},
      quantity: 12,
      unit: 'pcs',
      state: FoodState.fresh,
      createdAt: now,
      updatedAt: now,
    );
    var c = await openForm(tester);
    final saved = await c.read(kitchenRepositoryProvider).insert(existing);
    Navigator.of(tester.element(find.text('New Stock Entry'))).pop();
    await tester.pumpAndSettle();

    Navigator.of(tester.element(find.text('RUVA')))
        .push(MaterialPageRoute<void>(builder: (_) => IngredientFormScreen(existing: saved)));
    await tester.pumpAndSettle();
    expect(find.text('Update Stock'), findsOneWidget);
    await tapText(tester, 'Mark as finished');
    expect(await c.read(kitchenProvider.future), isEmpty, reason: 'leaves the kitchen');
    final history = await c.read(kitchenRepositoryProvider).all();
    expect(history.single.status, IngredientStatus.finished, reason: 'but is kept as history');

    await tester.pump(const Duration(seconds: 3)); // let the snackbar clear
    await tester.pumpAndSettle();
    final again = await c.read(kitchenRepositoryProvider).insert(existing);
    Navigator.of(tester.element(find.text('RUVA')))
        .push(MaterialPageRoute<void>(builder: (_) => IngredientFormScreen(existing: again)));
    await tester.pumpAndSettle();
    await tapText(tester, 'Remove from kitchen');
    expect(find.text('Remove Eggs?'), findsOneWidget);
    await tapText(tester, 'Delete');
    c = ProviderScope.containerOf(tester.element(find.text('RUVA')));
    expect((await c.read(kitchenRepositoryProvider).all()).where((i) => i.id == again.id), isEmpty);
  });
}
