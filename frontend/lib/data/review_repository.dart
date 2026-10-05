import 'package:sqflite/sqflite.dart';

import '../domain/kitchen_review.dart';

/// Monthly reviews with their changes, and the shopping list.
class ReviewRepository {
  ReviewRepository(this._db);
  final Database _db;

  static int _ms(DateTime t) => t.toUtc().millisecondsSinceEpoch;
  static DateTime _dt(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

  Future<int> startReview(DateTime at) => _db.insert('kitchen_reviews', {'started_at': _ms(at)});

  Future<void> addChange(int reviewId, ReviewChange c) => _db.insert('kitchen_review_changes', {
    'review_id': reviewId,
    'ingredient_id': c.ingredientId,
    'name': c.name,
    'action': c.action.name,
    'old_quantity': c.oldQuantity,
    'new_quantity': c.newQuantity,
    'unit': c.unit,
  });

  Future<void> completeReview(int reviewId, DateTime at) =>
      _db.update('kitchen_reviews', {'completed_at': _ms(at)}, where: 'id = ?', whereArgs: [reviewId]);

  /// All reviews, newest first, with their changes.
  Future<List<KitchenReview>> reviews() async {
    final rows = await _db.query('kitchen_reviews', orderBy: 'started_at DESC');
    final changes = await _db.query('kitchen_review_changes', orderBy: 'id');
    return [
      for (final r in rows)
        KitchenReview(
          id: r['id']! as int,
          startedAt: _dt(r['started_at']! as int),
          completedAt: r['completed_at'] == null ? null : _dt(r['completed_at']! as int),
          changes: [
            for (final c in changes.where((c) => c['review_id'] == r['id']))
              ReviewChange(
                ingredientId: c['ingredient_id']! as int,
                name: c['name']! as String,
                action: ReviewAction.values.byName(c['action']! as String),
                oldQuantity: (c['old_quantity']! as num).toDouble(),
                newQuantity: (c['new_quantity'] as num?)?.toDouble(),
                unit: c['unit']! as String,
              ),
          ],
        ),
    ];
  }

  // --- Shopping list ---------------------------------------------------------

  Future<List<ShoppingItem>> shoppingList() async => [
    for (final r in await _db.query('shopping_items', orderBy: 'checked, created_at'))
      ShoppingItem(
        id: r['id']! as int,
        name: r['name']! as String,
        note: (r['note'] as String?) ?? '',
        checked: r['checked'] == 1,
        createdAt: _dt(r['created_at']! as int),
      ),
  ];

  /// Adds unless an unchecked item with the same name is already on the list.
  Future<bool> addToShoppingList(String name, DateTime at, {String note = ''}) async {
    final n = name.trim();
    if (n.isEmpty) return false;
    final existing = await _db.query(
      'shopping_items',
      where: 'checked = 0 AND name = ? COLLATE NOCASE',
      whereArgs: [n],
      limit: 1,
    );
    if (existing.isNotEmpty) return false;
    await _db.insert('shopping_items', {'name': n, 'note': note, 'checked': 0, 'created_at': _ms(at)});
    return true;
  }

  Future<void> setChecked(int id, bool checked) =>
      _db.update('shopping_items', {'checked': checked ? 1 : 0}, where: 'id = ?', whereArgs: [id]);

  Future<void> removeShoppingItem(int id) => _db.delete('shopping_items', where: 'id = ?', whereArgs: [id]);

  Future<void> clearChecked() => _db.delete('shopping_items', where: 'checked = 1');

  Future<void> deleteAll() async {
    await _db.delete('kitchen_review_changes');
    await _db.delete('kitchen_reviews');
    await _db.delete('shopping_items');
  }
}
