import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../domain/food.dart';

/// A food you logged or saved before, with the amount you used.
typedef FoodShortcut = ({String key, String name, double grams, String portion, DateTime at});

class FoodRepository {
  FoodRepository(this._db);
  final Database _db;

  static int _ms(DateTime t) => t.toUtc().millisecondsSinceEpoch;
  static DateTime _dt(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _encode(Nutrients n) => jsonEncode({for (final e in n.entries) e.key.name: e.value});
  static Nutrients _decode(Object? s) => {
    for (final e in (jsonDecode((s as String?) ?? '{}') as Map<String, dynamic>).entries)
      ?Nutrient.values.asNameMap()[e.key]: (e.value as num).toDouble(),
  };

  static Map<String, Object?> _toRow(FoodEntry e) => {
    'day': _day(e.day),
    'meal': e.meal.name,
    'logged_at': _ms(e.loggedAt),
    'name': e.name.trim(),
    'food_key': e.foodKey,
    'grams': e.grams,
    'portion': e.portion,
    'nutrients': _encode(e.nutrients),
  };

  static FoodEntry _fromRow(Map<String, Object?> r) {
    final d = DateTime.parse(r['day']! as String);
    return FoodEntry(
      id: r['id']! as int,
      day: DateTime(d.year, d.month, d.day),
      meal: Meal.values.asNameMap()[r['meal']] ?? Meal.snacks,
      loggedAt: _dt(r['logged_at']! as int),
      name: r['name']! as String,
      foodKey: r['food_key'] as String?,
      grams: (r['grams'] as num?)?.toDouble(),
      portion: (r['portion'] as String?) ?? '',
      nutrients: _decode(r['nutrients']),
    );
  }

  // --- Diary ------------------------------------------------------------------

  Future<FoodEntry> insert(FoodEntry e) async => e.copyWith(id: await _db.insert('food_entries', _toRow(e)));

  Future<void> update(FoodEntry e) => _db.update('food_entries', _toRow(e), where: 'id = ?', whereArgs: [e.id]);

  Future<void> delete(int id) => _db.delete('food_entries', where: 'id = ?', whereArgs: [id]);

  Future<List<FoodEntry>> forDay(DateTime day) async => (await _db.query(
    'food_entries',
    where: 'day = ?',
    whereArgs: [_day(day)],
    orderBy: 'logged_at',
  )).map(_fromRow).toList();

  /// Whether [foodKey] is already logged for [meal] on [day].
  Future<bool> isLogged(String foodKey, DateTime day, Meal meal) async => (await _db.query(
    'food_entries',
    where: 'food_key = ? AND day = ? AND meal = ?',
    whereArgs: [foodKey, _day(day), meal.name],
    limit: 1,
  )).isNotEmpty;

  /// Entries for local dates from [from] to [to] inclusive (for History).
  Future<List<FoodEntry>> between(DateTime from, DateTime to) async => (await _db.query(
    'food_entries',
    where: 'day BETWEEN ? AND ?',
    whereArgs: [_day(from), _day(to)],
    orderBy: 'logged_at',
  )).map(_fromRow).toList();

  /// Most recently logged distinct foods.
  Future<List<FoodShortcut>> recent({int limit = 6}) async {
    final rows = await _db.rawQuery(
      '''
      SELECT food_key, name, grams, portion, logged_at FROM food_entries e
      WHERE food_key IS NOT NULL AND grams IS NOT NULL AND logged_at = (
        SELECT MAX(logged_at) FROM food_entries WHERE food_key = e.food_key)
      GROUP BY food_key ORDER BY logged_at DESC LIMIT ?''',
      [limit],
    );
    return [for (final r in rows) _shortcut(r, 'logged_at')];
  }

  static FoodShortcut _shortcut(Map<String, Object?> r, String at) => (
    key: r['food_key']! as String,
    name: r['name']! as String,
    grams: (r['grams']! as num).toDouble(),
    portion: (r['portion'] as String?) ?? '',
    at: _dt(r[at]! as int),
  );

  // --- Saved foods -------------------------------------------------------------

  Future<List<FoodShortcut>> saved() async => [
    for (final r in await _db.query('saved_foods', orderBy: 'name COLLATE NOCASE')) _shortcut(r, 'created_at'),
  ];

  Future<void> save(FoodShortcut s) => _db.insert('saved_foods', {
    'food_key': s.key,
    'name': s.name,
    'grams': s.grams,
    'portion': s.portion,
    'created_at': _ms(s.at),
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> unsave(String key) => _db.delete('saved_foods', where: 'food_key = ?', whereArgs: [key]);

  // --- Custom foods -------------------------------------------------------------

  Future<List<Food>> customFoods() async => [
    for (final r in await _db.query('custom_foods', orderBy: 'name COLLATE NOCASE'))
      Food(
        key: 'custom:${r['id']}',
        name: r['name']! as String,
        per100g: _decode(r['nutrients']),
        portions: [
          if (r['serving_grams'] case final num g) Portion((r['serving_label'] as String?) ?? '', g.toDouble()),
        ],
      ),
  ];

  /// Stores a food you created. [per100g] may be empty (nutrition unavailable).
  Future<Food> addCustomFood(String name, Nutrients per100g, Portion? serving, DateTime at) async {
    final id = await _db.insert('custom_foods', {
      'name': name.trim(),
      'nutrients': _encode(per100g),
      'serving_grams': serving?.grams,
      'serving_label': serving?.label,
      'created_at': _ms(at),
    });
    return Food(key: 'custom:$id', name: name.trim(), per100g: per100g, portions: [?serving]);
  }

  Future<void> deleteAll() async {
    await _db.delete('food_entries');
    await _db.delete('saved_foods');
    await _db.delete('custom_foods');
  }
}
