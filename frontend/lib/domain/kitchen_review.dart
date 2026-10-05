// Monthly kitchen review (PRD v1.2 §6) and the shopping list it can feed.

import 'kitchen.dart';

enum ReviewAction { kept, usedUp, spoiled }

/// One decision made during a review (PRD §13 MonthlyInventoryReview changes).
class ReviewChange {
  const ReviewChange({
    required this.ingredientId,
    required this.name,
    required this.action,
    required this.oldQuantity,
    this.newQuantity,
    required this.unit,
  });

  final int ingredientId;
  final String name;
  final ReviewAction action;
  final double oldQuantity;
  final double? newQuantity; // only for kept items
  final String unit;
}

class KitchenReview {
  const KitchenReview({this.id, required this.startedAt, this.completedAt, this.changes = const []});

  final int? id;
  final DateTime startedAt; // UTC
  final DateTime? completedAt;
  final List<ReviewChange> changes;
}

/// Order for reviewing: soonest expiry first (expired at the top), then the
/// rest alphabetically — so food at risk of waste is checked first.
List<Ingredient> reviewQueue(Iterable<Ingredient> items, DateTime today) {
  final list = items.where((i) => i.isActive).toList();
  list.sort((a, b) {
    final da = a.daysToExpiry(today), db = b.daysToExpiry(today);
    if (da != null && db != null && da != db) return da.compareTo(db);
    if (da != null && db == null) return -1;
    if (da == null && db != null) return 1;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return list;
}

class ShoppingItem {
  const ShoppingItem({this.id, required this.name, this.note = '', this.checked = false, required this.createdAt});

  final int? id;
  final String name;
  final String note;
  final bool checked;
  final DateTime createdAt;

  ShoppingItem copyWith({int? id, bool? checked}) =>
      ShoppingItem(id: id ?? this.id, name: name, note: note, checked: checked ?? this.checked, createdAt: createdAt);
}
