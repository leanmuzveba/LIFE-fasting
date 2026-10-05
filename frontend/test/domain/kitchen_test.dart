import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/domain/kitchen.dart';

Ingredient item(
  String name, {
  Set<IngredientCategory> categories = const {},
  double quantity = 1,
  DateTime? purchased,
  DateTime? expires,
  double? lowAt,
  String brand = '',
}) => Ingredient(
  name: name,
  categories: categories,
  quantity: quantity,
  unit: 'pcs',
  state: FoodState.fresh,
  purchasedOn: purchased,
  expiresOn: expires,
  lowStockAt: lowAt,
  brand: brand,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  final today = DateTime(2026, 10, 4, 15);

  test('expiry: days left, today, expired, "expiring soon" within 3 days', () {
    expect(item('a', expires: DateTime(2026, 10, 7)).daysToExpiry(today), 3);
    expect(item('a', expires: DateTime(2026, 10, 7)).expiringSoon(today), isTrue);
    expect(item('a', expires: DateTime(2026, 10, 8)).expiringSoon(today), isFalse);
    expect(item('a', expires: DateTime(2026, 10, 4)).daysToExpiry(today), 0);
    expect(item('a', expires: DateTime(2026, 10, 2)).isExpired(today), isTrue);
    expect(item('a').daysToExpiry(today), isNull);
    expect(item('a').expiringSoon(today), isFalse);
  });

  test('low stock only when a level is set and quantity is at or below it', () {
    expect(item('a', quantity: 2, lowAt: 3).isLowStock, isTrue);
    expect(item('a', quantity: 3, lowAt: 3).isLowStock, isTrue);
    expect(item('a', quantity: 4, lowAt: 3).isLowStock, isFalse);
    expect(item('a', quantity: 0).isLowStock, isFalse, reason: 'no level set');
  });

  test('validation', () {
    expect(validateIngredient(item('  ')), IngredientError.nameRequired);
    expect(validateIngredient(item('Eggs', quantity: -1)), IngredientError.quantityInvalid);
    expect(validateIngredient(item('Eggs', quantity: double.nan)), IngredientError.quantityInvalid);
    expect(validateIngredient(item('Eggs', lowAt: -2)), IngredientError.lowStockInvalid);
    expect(
      validateIngredient(item('Eggs', purchased: DateTime(2026, 10, 4), expires: DateTime(2026, 10, 1))),
      IngredientError.expiryBeforePurchase,
    );
    expect(validateIngredient(item('Eggs', quantity: 0)), isNull, reason: 'zero is a valid count');
  });

  test('search by name or brand and filter by any of several categories', () {
    final items = [
      item('Eggs', categories: {IngredientCategory.protein}),
      item('Greek yogurt', categories: {IngredientCategory.dairy, IngredientCategory.protein}, brand: 'Clover'),
      item('Rice', categories: {IngredientCategory.carbs}),
    ];
    List<String> names(Iterable<Ingredient> r) => r.map((i) => i.name).toList();
    expect(names(filterKitchen(items, query: 'EG')), ['Eggs']);
    expect(names(filterKitchen(items, query: 'clover')), ['Greek yogurt']);
    expect(names(filterKitchen(items, category: IngredientCategory.protein)), ['Eggs', 'Greek yogurt']);
    expect(names(filterKitchen(items, query: 'rice', category: IngredientCategory.protein)), isEmpty);
    expect(filterKitchen(items), hasLength(3));
  });
}
