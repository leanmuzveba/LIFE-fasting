import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../domain/recipe.dart';

/// TheMealDB JSON API (free developer key "1"). Only ingredient names and
/// search words are sent — never anything about you.
class RecipeApi {
  static const _base = 'https://www.themealdb.com/api/json/v1/1/';

  /// GETs `<path>` and returns the decoded JSON. Throws on network errors.
  Future<Map<String, dynamic>> get(String path) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.getUrl(Uri.parse('$_base$path'));
      final res = await req.close().timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      return jsonDecode(await res.transform(utf8.decoder).join()) as Map<String, dynamic>;
    } finally {
      client.close(force: true);
    }
  }
}

/// Recipes with a local cache (works offline once fetched), favourites and
/// a log of what you cooked.
class RecipeRepository {
  RecipeRepository(this._db, this._api, this._now);
  final Database _db;
  final RecipeApi _api;
  final DateTime Function() _now;

  static const _listMaxAge = Duration(days: 7);

  int _nowMs() => _now().toUtc().millisecondsSinceEpoch;

  /// Cached GET: recipes never change, lists refresh weekly; a stale copy is
  /// used when offline.
  Future<Map<String, dynamic>> _cached(String path, {Duration? maxAge}) async {
    final row = (await _db.query('api_cache', where: 'key = ?', whereArgs: [path])).firstOrNull;
    final fresh = row != null && (maxAge == null || _nowMs() - (row['fetched_at']! as int) < maxAge.inMilliseconds);
    if (fresh) return jsonDecode(row['json']! as String) as Map<String, dynamic>;
    try {
      final json = await _api.get(path);
      await _db.insert('api_cache', {
        'key': path,
        'json': jsonEncode(json),
        'fetched_at': _nowMs(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return json;
    } catch (_) {
      if (row != null) return jsonDecode(row['json']! as String) as Map<String, dynamic>;
      rethrow;
    }
  }

  static List<Map<String, dynamic>> _meals(Map<String, dynamic> json) =>
      ((json['meals'] as List<dynamic>?) ?? const []).cast<Map<String, dynamic>>();

  /// Recipe ids whose main ingredients include [ingredient].
  Future<List<String>> idsWith(String ingredient) async {
    final q = Uri.encodeQueryComponent(ingredient.trim().toLowerCase().replaceAll(' ', '_'));
    return [for (final m in _meals(await _cached('filter.php?i=$q', maxAge: _listMaxAge))) m['idMeal'] as String];
  }

  Future<Recipe?> byId(String id) async {
    final meals = _meals(await _cached('lookup.php?i=${Uri.encodeQueryComponent(id)}'));
    return meals.isEmpty ? null : Recipe.fromMealDb(meals.first);
  }

  Future<List<Recipe>> search(String name) async {
    final q = Uri.encodeQueryComponent(name.trim().toLowerCase());
    return _meals(await _cached('search.php?s=$q', maxAge: _listMaxAge)).map(Recipe.fromMealDb).toList();
  }

  // --- Favourites and cooked log -------------------------------------------------

  Future<Set<String>> savedIds() async => {
    for (final r in await _db.query('saved_recipes', columns: ['recipe_id'])) r['recipe_id']! as String,
  };

  Future<void> setSaved(Recipe r, bool saved) => saved
      ? _db.insert('saved_recipes', {
          'recipe_id': r.id,
          'name': r.name,
          'saved_at': _nowMs(),
        }, conflictAlgorithm: ConflictAlgorithm.replace)
      : _db.delete('saved_recipes', where: 'recipe_id = ?', whereArgs: [r.id]);

  Future<void> markCooked(Recipe r, double batch) =>
      _db.insert('recipe_logs', {'recipe_id': r.id, 'name': r.name, 'batch': batch, 'cooked_at': _nowMs()});

  /// When each recipe was last cooked (UTC).
  Future<Map<String, DateTime>> lastCooked() async => {
    for (final r in await _db.rawQuery('SELECT recipe_id, MAX(cooked_at) AS at FROM recipe_logs GROUP BY recipe_id'))
      r['recipe_id']! as String: DateTime.fromMillisecondsSinceEpoch(r['at']! as int, isUtc: true),
  };

  Future<void> deleteAll() async {
    await _db.delete('saved_recipes');
    await _db.delete('recipe_logs');
    await _db.delete('api_cache');
  }
}
