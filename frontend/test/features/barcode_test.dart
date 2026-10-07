import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/domain/food.dart';
import 'package:life_fasting/state/providers.dart';

import '../widget_test.dart' show foodFacts, pumpApp, scannedBarcode;

const _cola = '5449000000996';
final _colaProduct = <String, dynamic>{
  'product_name': 'Coca-Cola Original',
  'brands': 'Coca-Cola, The Coca-Cola Company',
  'quantity': '330 ml',
  'product_quantity': 330,
  'serving_size': '330 ml',
  'serving_quantity': '330',
  'nutriments': {'energy-kcal_100g': 42, 'carbohydrates_100g': 10.6, 'proteins_100g': 0, 'sodium_100g': 0.01},
};

Future<void> _scanToBreakfast(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Add to Breakfast'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Scan a barcode'));
  await tester.pumpAndSettle();
}

void main() {
  test('parses Open Food Facts: kJ fallback, minerals to mg, ml drinks, portions', () {
    final f = foodFromOpenFoodFacts(_cola, _colaProduct, servingLabel: '1 serving', packLabel: 'Whole pack')!;
    expect(f.name, 'Coca-Cola Original');
    expect(f.brand, 'Coca-Cola');
    expect(f.unit, 'ml');
    expect(f.per100g[Nutrient.energy], 42);
    expect(f.per100g[Nutrient.sodium], 10);
    expect(f.per100g.containsKey(Nutrient.fat), isFalse);
    expect(f.portions.map((p) => (p.label, p.grams)), [('1 serving', 330.0)]);

    final bar = foodFromOpenFoodFacts(
      '1',
      {
        'product_name': 'Oat bar',
        'quantity': '6 x 40 g',
        'product_quantity': 240,
        'serving_size': '1 bar (40 g)',
        'serving_quantity': 40,
        'nutriments': {'energy_100g': 1800},
      },
      servingLabel: '1 serving',
      packLabel: 'Whole pack',
    )!;
    expect(bar.unit, 'g');
    expect(bar.per100g[Nutrient.energy]!.round(), 430);
    expect(bar.portions.map((p) => (p.label, p.grams)), [('1 bar', 40.0), ('Whole pack', 240.0)]);
    expect(foodFromOpenFoodFacts('2', {'product_name': ''}, servingLabel: '', packLabel: ''), isNull);
  });

  testWidgets('+ offers search or scan; a scanned drink logs in ml and is saved for offline', (tester) async {
    await pumpApp(tester);
    tester.view.physicalSize = const Size(390, 3000);
    final c = ProviderScope.containerOf(tester.element(find.text('RUVA')));
    await tester.tap(find.bySemanticsLabel('Nutrition').last);
    await tester.pumpAndSettle();
    foodFacts.products[_cola] = _colaProduct;
    scannedBarcode = _cola;

    await tester.tap(find.byTooltip('Add food'));
    await tester.pumpAndSettle();
    expect(find.text('Search foods'), findsOneWidget);
    expect(find.text('Scan a barcode'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10)); // dismiss
    await tester.pumpAndSettle();

    await _scanToBreakfast(tester);
    expect(find.text('Coca-Cola Original'), findsOneWidget);
    expect(find.text('1 serving (330 ml)'), findsOneWidget);
    expect(find.text('≈ 139 kcal (est.)'), findsOneWidget);
    await tester.tap(find.text('Add to Breakfast'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp(r'^Coca-Cola Original, .*1 serving \(330 ml\), 139 kcal')), findsOneWidget);

    // Second scan works offline from the saved copy.
    foodFacts.offline = true;
    await _scanToBreakfast(tester);
    expect(find.text('1 serving (330 ml)'), findsOneWidget);
    expect(foodFacts.lookups, [_cola]);
    final entries = await c.read(foodRepositoryProvider).forDay(DateTime(2026, 10, 4));
    expect(entries.single.unit, 'ml');
  });

  testWidgets('unknown barcode: add it from the label, then the next scan finds it', (tester) async {
    await pumpApp(tester);
    tester.view.physicalSize = const Size(390, 3000);
    await tester.tap(find.bySemanticsLabel('Nutrition').last);
    await tester.pumpAndSettle();
    scannedBarcode = '6001234567890';

    await _scanToBreakfast(tester);
    expect(find.textContaining('Barcode 6001234567890'), findsOneWidget);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), 'Rusks, buttermilk');
    await tester.enterText(fields.at(2), '35');
    await tester.enterText(fields.at(3), '150');
    await tester.tap(find.text('Save and select'));
    await tester.pumpAndSettle();
    expect(find.text('1 serving (35 g)'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await _scanToBreakfast(tester);
    expect(find.text('Rusks, buttermilk'), findsOneWidget);
    expect(foodFacts.lookups, ['6001234567890']); // only the first scan went online
  });
}
