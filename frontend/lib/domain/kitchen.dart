// My Kitchen inventory (PRD v1.2 §4).

/// PRD §4.1 categories — for browsing; an ingredient may have several.
enum IngredientCategory { protein, carbs, vegetables, fruits, fatsNutsSeeds, dairy, herbsSpices, pantry }

/// PRD §4.2 food state.
enum FoodState { fresh, frozen, canned, dried }

/// Active items are in the kitchen. Finished (used up) and discarded
/// (spoiled/removed in a review) items are kept as history, never deleted
/// automatically (PRD §4.3, §6).
enum IngredientStatus { active, finished, discarded }

const kitchenUnits = ['g', 'kg', 'ml', 'l', 'pcs', 'bunch', 'can', 'pack'];

/// Expiry within this many days counts as "expiring soon".
const expiringSoonDays = 3;

class Ingredient {
  const Ingredient({
    this.id,
    required this.name,
    required this.categories,
    required this.quantity,
    required this.unit,
    required this.state,
    this.purchasedOn,
    this.expiresOn,
    this.lowStockAt,
    this.brand = '',
    this.notes = '',
    this.status = IngredientStatus.active,
    this.statusAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final Set<IngredientCategory> categories;
  final double quantity;
  final String unit;
  final FoodState state;

  /// Calendar dates (local midnight), optional.
  final DateTime? purchasedOn;
  final DateTime? expiresOn;

  /// Optional: flag as low stock at or below this quantity (same unit).
  final double? lowStockAt;
  final String brand;
  final String notes;
  final IngredientStatus status;
  final DateTime? statusAt; // UTC, when finished/discarded
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status == IngredientStatus.active;

  /// Days until expiry from [today] (negative = expired), or null if no date.
  int? daysToExpiry(DateTime today) {
    final e = expiresOn;
    if (e == null) return null;
    final t = DateTime(today.year, today.month, today.day);
    return DateTime(e.year, e.month, e.day).difference(t).inDays;
  }

  bool isExpired(DateTime today) => (daysToExpiry(today) ?? 1) < 0;
  bool expiringSoon(DateTime today) {
    final d = daysToExpiry(today);
    return d != null && d <= expiringSoonDays;
  }

  bool get isLowStock => lowStockAt != null && quantity <= lowStockAt!;

  Ingredient copyWith({
    int? id,
    String? name,
    Set<IngredientCategory>? categories,
    double? quantity,
    String? unit,
    FoodState? state,
    DateTime? Function()? purchasedOn,
    DateTime? Function()? expiresOn,
    double? Function()? lowStockAt,
    String? brand,
    String? notes,
    IngredientStatus? status,
    DateTime? Function()? statusAt,
    DateTime? updatedAt,
  }) => Ingredient(
    id: id ?? this.id,
    name: name ?? this.name,
    categories: categories ?? this.categories,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    state: state ?? this.state,
    purchasedOn: purchasedOn != null ? purchasedOn() : this.purchasedOn,
    expiresOn: expiresOn != null ? expiresOn() : this.expiresOn,
    lowStockAt: lowStockAt != null ? lowStockAt() : this.lowStockAt,
    brand: brand ?? this.brand,
    notes: notes ?? this.notes,
    status: status ?? this.status,
    statusAt: statusAt != null ? statusAt() : this.statusAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

/// Problems with an ingredient form, or none.
enum IngredientError { nameRequired, quantityInvalid, lowStockInvalid, expiryBeforePurchase }

IngredientError? validateIngredient(Ingredient i) {
  if (i.name.trim().isEmpty) return IngredientError.nameRequired;
  if (i.quantity.isNaN || i.quantity < 0 || i.quantity > 100000) return IngredientError.quantityInvalid;
  if (i.lowStockAt != null && (i.lowStockAt! < 0 || i.lowStockAt!.isNaN)) return IngredientError.lowStockInvalid;
  if (i.purchasedOn != null && i.expiresOn != null && i.expiresOn!.isBefore(i.purchasedOn!)) {
    return IngredientError.expiryBeforePurchase;
  }
  return null;
}

/// Case-insensitive search on name and brand; [category] null = all.
Iterable<Ingredient> filterKitchen(Iterable<Ingredient> items, {String query = '', IngredientCategory? category}) {
  final q = query.trim().toLowerCase();
  return items.where(
    (i) =>
        (q.isEmpty || i.name.toLowerCase().contains(q) || i.brand.toLowerCase().contains(q)) &&
        (category == null || i.categories.contains(category)),
  );
}
