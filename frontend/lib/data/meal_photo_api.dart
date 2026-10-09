import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../domain/food.dart';
import '../domain/kitchen.dart';
import '../domain/meal_estimate.dart';

/// The key and model can't be used (wrong/expired key, quota, blocked).
class MealPhotoKeyException implements Exception {
  const MealPhotoKeyException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Estimates what's on a plate with Google Gemini (vision). The photo is sent
/// to Google; nothing else about you is.
class MealPhotoApi {
  MealPhotoApi(this.apiKey, {this.models = defaultModels});

  /// Tried in order: the second (lighter) model takes over when the first is
  /// overloaded, slow or retired.
  // ponytail: model names are pinned; update when Google retires them.
  static const defaultModels = ['gemini-3.5-flash', 'gemini-3.5-flash-lite'];

  final String apiKey;
  final List<String> models;

  static const _prompt =
      'You are helping someone log a meal in a food diary. Identify each distinct food or drink in the photo '
      'and estimate the amount shown in grams (cooked weight as served; millilitres count as grams for drinks), '
      'with energy (kcal), protein, carbohydrate, fat and fibre in grams for that amount. Use realistic portion '
      'sizes judged from the plate, cutlery and hands. Name foods plainly (e.g. "white rice", "grilled chicken '
      'thigh", "tomato and onion relish"); include visible sauces, oils and drinks. If the photo is not food, set '
      'is_food to false and return no items. Put any uncertainty in a short note.';

  static const _schema = {
    'type': 'OBJECT',
    'properties': {
      'is_food': {'type': 'BOOLEAN'},
      'note': {'type': 'STRING'},
      'items': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'name': {'type': 'STRING'},
            'grams': {'type': 'NUMBER'},
            'kcal': {'type': 'NUMBER'},
            'protein_g': {'type': 'NUMBER'},
            'carbs_g': {'type': 'NUMBER'},
            'fat_g': {'type': 'NUMBER'},
            'fibre_g': {'type': 'NUMBER'},
          },
          'required': ['name', 'grams', 'kcal', 'protein_g', 'carbs_g', 'fat_g', 'fibre_g'],
        },
      },
    },
    'required': ['is_food', 'items'],
  };

  Future<MealEstimate> estimate(Uint8List jpeg) async =>
      parseMealEstimate(await _withFallback((m) => _ask(m, jpeg, _prompt, _schema)));

  static final _groceryPrompt =
      'You are helping someone record the groceries they have at home. List each distinct food item visible '
      '(packets, tins, produce, bottles). For each give a plain name (no brand), a count or amount you can see, '
      'a unit from: $_units, the best categories from: $_cats, and its state from: fresh, frozen, canned, dried. '
      'Read pack sizes from labels when legible; otherwise count items with unit "pcs". Skip non-food items. '
      'If there is no food, return no items.';
  static final _units = kitchenUnits.join(', ');
  static final _cats = IngredientCategory.values.map((c) => c.name).join(', ');

  static const _grocerySchema = {
    'type': 'OBJECT',
    'properties': {
      'items': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'name': {'type': 'STRING'},
            'quantity': {'type': 'NUMBER'},
            'unit': {'type': 'STRING'},
            'categories': {
              'type': 'ARRAY',
              'items': {'type': 'STRING'},
            },
            'state': {'type': 'STRING'},
          },
          'required': ['name', 'quantity', 'unit', 'categories', 'state'],
        },
      },
    },
    'required': ['items'],
  };

  /// Food items spotted in a photo of groceries, for review before saving.
  Future<List<SpottedItem>> groceries(Uint8List jpeg) async =>
      parseGroceries(await _withFallback((m) => _ask(m, jpeg, _groceryPrompt, _grocerySchema)));

  Future<Map<String, dynamic>> _withFallback(Future<Map<String, dynamic>> Function(String model) call) async {
    Object? last;
    for (final model in models) {
      try {
        return await call(model);
      } on MealPhotoKeyException {
        rethrow; // the key itself is the problem; another model won't help
      } catch (e) {
        last = e;
      }
    }
    throw last ?? const HttpException('No model available');
  }

  Future<Map<String, dynamic>> _ask(String model, Uint8List jpeg, String prompt, Map<String, Object> schema) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.postUrl(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent'),
      );
      req.headers
        ..contentType = ContentType.json
        ..set('x-goog-api-key', apiKey);
      req.add(
        utf8.encode(
          jsonEncode({
            'contents': [
              {
                'parts': [
                  {
                    'inline_data': {'mime_type': 'image/jpeg', 'data': base64Encode(jpeg)},
                  },
                  {'text': prompt},
                ],
              },
            ],
            'generationConfig': {'responseMimeType': 'application/json', 'responseSchema': schema, 'temperature': 0.2},
          }),
        ),
      );
      final res = await req.close().timeout(const Duration(seconds: 45));
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode == 400 || res.statusCode == 401 || res.statusCode == 403) {
        final msg = ((jsonDecode(body) as Map)['error'] as Map?)?['message'] as String?;
        throw MealPhotoKeyException(msg ?? 'HTTP ${res.statusCode}');
      }
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      final text =
          (((jsonDecode(body) as Map)['candidates'] as List).first as Map)['content']['parts'][0]['text'] as String;
      return jsonDecode(text) as Map<String, dynamic>;
    } finally {
      client.close(force: true);
    }
  }
}

/// Parses the structured reply; drops items without a name or weight.
MealEstimate parseMealEstimate(Map<String, dynamic> j) {
  double? n(Object? v) => v is num && v >= 0 ? v.toDouble() : null;
  return MealEstimate(
    isFood: j['is_food'] != false,
    note: ((j['note'] as String?) ?? '').trim(),
    items: [
      for (final i in (j['items'] as List? ?? const []).cast<Map<String, dynamic>>())
        if ('${i['name'] ?? ''}'.trim().isNotEmpty && (n(i['grams']) ?? 0) > 0)
          EstimatedItem(
            name: '${i['name']}'.trim(),
            grams: n(i['grams'])!,
            nutrients: {
              Nutrient.energy: ?n(i['kcal']),
              Nutrient.protein: ?n(i['protein_g']),
              Nutrient.carbs: ?n(i['carbs_g']),
              Nutrient.fat: ?n(i['fat_g']),
              Nutrient.fibre: ?n(i['fibre_g']),
            },
          ),
    ],
  );
}

/// Parses spotted groceries; unknown units fall back to pieces, unknown
/// categories are dropped, nameless or zero items are skipped.
List<SpottedItem> parseGroceries(Map<String, dynamic> j) => [
  for (final i in (j['items'] as List? ?? const []).cast<Map<String, dynamic>>())
    if ('${i['name'] ?? ''}'.trim().isNotEmpty && i['quantity'] is num && (i['quantity'] as num) > 0)
      SpottedItem(
        name: '${i['name']}'.trim(),
        quantity: (i['quantity'] as num).toDouble(),
        unit: kitchenUnits.contains(i['unit']) ? i['unit'] as String : 'pcs',
        categories: {
          for (final c in (i['categories'] as List? ?? const [])) ?IngredientCategory.values.asNameMap()['$c'],
        },
        state: FoodState.values.asNameMap()['${i['state']}'] ?? FoodState.fresh,
      ),
];
