import 'package:sqflite/sqflite.dart';

import '../domain/kitchen.dart';

class KitchenRepository {
  KitchenRepository(this._db);
  final Database _db;

  static int _ms(DateTime t) => t.toUtc().millisecondsSinceEpoch;
  static DateTime _dt(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

  /// Calendar dates are stored as 'YYYY-MM-DD' (no time zone involved).
  static String? _date(DateTime? d) => d == null
      ? null
      : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static DateTime? _parseDate(Object? s) {
    final p = s is String ? DateTime.tryParse(s) : null;
    return p == null ? null : DateTime(p.year, p.month, p.day);
  }

  static Map<String, Object?> _toRow(Ingredient i) => {
    'name': i.name.trim(),
    'categories': i.categories.map((c) => c.name).join(','),
    'quantity': i.quantity,
    'unit': i.unit,
    'state': i.state.name,
    'purchased_on': _date(i.purchasedOn),
    'expires_on': _date(i.expiresOn),
    'low_stock_at': i.lowStockAt,
    'brand': i.brand.trim(),
    'notes': i.notes.trim(),
    'status': i.status.name,
    'status_at': i.statusAt == null ? null : _ms(i.statusAt!),
    'created_at': _ms(i.createdAt),
    'updated_at': _ms(i.updatedAt),
  };

  static Ingredient _fromRow(Map<String, Object?> r) => Ingredient(
    id: r['id']! as int,
    name: r['name']! as String,
    categories: {
      for (final c in ((r['categories'] as String?) ?? '').split(',')) ?IngredientCategory.values.asNameMap()[c],
    },
    quantity: (r['quantity']! as num).toDouble(),
    unit: r['unit']! as String,
    state: FoodState.values.asNameMap()[r['state']] ?? FoodState.fresh,
    purchasedOn: _parseDate(r['purchased_on']),
    expiresOn: _parseDate(r['expires_on']),
    lowStockAt: (r['low_stock_at'] as num?)?.toDouble(),
    brand: (r['brand'] as String?) ?? '',
    notes: (r['notes'] as String?) ?? '',
    status: IngredientStatus.values.asNameMap()[r['status']] ?? IngredientStatus.active,
    statusAt: r['status_at'] == null ? null : _dt(r['status_at']! as int),
    createdAt: _dt(r['created_at']! as int),
    updatedAt: _dt(r['updated_at']! as int),
  );

  Future<Ingredient> insert(Ingredient i) async => i.copyWith(id: await _db.insert('ingredients', _toRow(i)));

  Future<void> update(Ingredient i) => _db.update('ingredients', _toRow(i), where: 'id = ?', whereArgs: [i.id]);

  Future<void> delete(int id) => _db.delete('ingredients', where: 'id = ?', whereArgs: [id]);

  /// Items currently in the kitchen, A–Z.
  Future<List<Ingredient>> active() async => (await _db.query(
    'ingredients',
    where: 'status = ?',
    whereArgs: [IngredientStatus.active.name],
    orderBy: 'name COLLATE NOCASE',
  )).map(_fromRow).toList();

  /// Every record including finished/discarded history.
  Future<List<Ingredient>> all() async =>
      (await _db.query('ingredients', orderBy: 'created_at')).map(_fromRow).toList();

  Future<void> deleteAll() => _db.delete('ingredients');
}
