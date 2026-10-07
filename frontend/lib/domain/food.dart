// Food diary (PRD v1.2 §3): foods, portions, diary entries and day totals.
// All nutrition is an estimate; a missing nutrient means "unavailable", never 0.

enum Meal { breakfast, lunch, dinner, snacks }

/// Order matches the columns of assets/foods/usda_sr_legacy.tsv (tool/build_usda.py).
enum Nutrient {
  energy('kcal'),
  protein('g'),
  carbs('g'),
  fat('g'),
  fibre('g'),
  calcium('mg'),
  iron('mg'),
  potassium('mg'),
  sodium('mg'),
  vitaminC('mg');

  const Nutrient(this.unit);
  final String unit;

  static const macros = [energy, protein, carbs, fat, fibre];
  static const micros = [calcium, iron, potassium, sodium, vitaminC];
}

typedef Nutrients = Map<Nutrient, double>;

Nutrients scaleNutrients(Nutrients per100g, double grams) => {
  for (final e in per100g.entries) e.key: e.value * grams / 100,
};

class Portion {
  const Portion(this.label, this.grams);
  final String label;
  final double grams;
}

/// A food you can log: from the USDA database (`usda:<fdcId>`) or one you
/// created (`custom:<id>`).
class Food {
  const Food({
    required this.key,
    required this.name,
    required this.per100g,
    this.portions = const [],
    this.unit = 'g',
    this.brand = '',
    this.barcode,
  });

  final String key;
  final String name;
  final Nutrients per100g;
  final List<Portion> portions;
  final String unit; // 'g', or 'ml' for drinks (values are per 100 ml)
  final String brand;
  final String? barcode;

  bool get hasNutrition => per100g.isNotEmpty;
  bool get isCustom => key.startsWith('custom:');

  /// Parses one line of the bundled USDA table.
  static Food fromUsdaLine(String line) {
    final c = line.split('\t');
    return Food(
      key: 'usda:${c[0]}',
      name: c[1],
      per100g: {for (final (i, n) in Nutrient.values.indexed) n: ?double.tryParse(c[2 + i])},
      portions: [
        for (final p in c[2 + Nutrient.values.length].split('|'))
          if (p.lastIndexOf('=') case final i when i > 0)
            if (double.tryParse(p.substring(i + 1)) case final g? when g > 0) Portion(p.substring(0, i), g),
      ],
    );
  }
}

class FoodEntry {
  const FoodEntry({
    this.id,
    required this.day,
    required this.meal,
    required this.loggedAt,
    required this.name,
    this.foodKey,
    this.grams,
    this.portion = '',
    this.unit = 'g',
    required this.nutrients,
  });

  final int? id;
  final DateTime day; // local calendar date
  final Meal meal;
  final DateTime loggedAt; // UTC; the time shown for the meal
  final String name;
  final String? foodKey;
  final double? grams; // null for a recipe serving (weight unknown)
  final String portion; // e.g. "1 cup", empty when entered in grams
  final String unit; // 'g' or 'ml'
  final Nutrients nutrients; // totals for this entry

  FoodEntry copyWith({int? id, double? grams, DateTime? loggedAt, Meal? meal}) {
    final g = grams ?? this.grams;
    final old = this.grams;
    return FoodEntry(
      id: id ?? this.id,
      day: day,
      meal: meal ?? this.meal,
      loggedAt: loggedAt ?? this.loggedAt,
      name: name,
      foodKey: foodKey,
      grams: g,
      portion: grams == null ? portion : '',
      unit: unit,
      nutrients: g != null && old != null && old > 0 ? scaleNutrients(nutrients, g * 100 / old) : nutrients,
    );
  }
}

/// Sums of a day's entries. A nutrient is [incomplete] when some entries lack
/// it, and absent from [sum] when none have it (shown as "unavailable").
class DayTotals {
  DayTotals(Iterable<FoodEntry> entries) {
    final list = entries.toList();
    for (final n in Nutrient.values) {
      final have = list.where((e) => e.nutrients.containsKey(n));
      if (have.isNotEmpty) sum[n] = have.fold(0.0, (a, e) => a + e.nutrients[n]!);
      if (have.isNotEmpty && have.length < list.length) incomplete.add(n);
    }
  }

  final Nutrients sum = {};
  final Set<Nutrient> incomplete = {};
}

/// Suggested meal for a time of day.
Meal mealForHour(int hour) => hour < 11
    ? Meal.breakfast
    : hour < 15
    ? Meal.lunch
    : hour < 17
    ? Meal.snacks
    : hour < 21
    ? Meal.dinner
    : Meal.snacks;

/// Every word of [query] must appear; names starting with the first word come
/// first, then shorter (more general) names.
List<Food> searchFoods(Iterable<Food> foods, String query, {int limit = 40}) {
  final words = query.toLowerCase().split(RegExp(r'[\s,]+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return const [];
  final hits = [
    for (final f in foods)
      if (words.every(f.name.toLowerCase().contains)) f,
  ];
  int rank(Food f) => (f.isCustom ? 0 : 2) + (f.name.toLowerCase().startsWith(words.first) ? 0 : 1);
  hits.sort((a, b) {
    final r = rank(a).compareTo(rank(b));
    return r != 0 ? r : a.name.length.compareTo(b.name.length);
  });
  return hits.take(limit).toList();
}

/// Parses an Open Food Facts product. Null when it has no name. Minerals and
/// vitamins arrive in grams and are converted to mg; missing values stay
/// unavailable. [servingLabel]/[packLabel] name the portions ("1 serving").
Food? foodFromOpenFoodFacts(
  String barcode,
  Map<String, dynamic> p, {
  required String servingLabel,
  required String packLabel,
}) {
  String s(String k) => '${p[k] ?? ''}'.trim();
  final name = s('product_name').isNotEmpty ? s('product_name') : s('product_name_en');
  if (name.isEmpty) return null;
  final n = (p['nutriments'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
  double? v(String k) => switch (n['${k}_100g']) {
    final num x => x.toDouble(),
    final String x => double.tryParse(x),
    _ => null,
  };
  double? amount(String k) => switch (p[k]) {
    final num x when x > 0 => x.toDouble(),
    final String x => double.tryParse(x),
    _ => null,
  };
  final kj = v('energy');
  final per100 = <Nutrient, double>{
    Nutrient.energy: ?(v('energy-kcal') ?? (kj == null ? null : kj / 4.184)),
    Nutrient.protein: ?v('proteins'),
    Nutrient.carbs: ?v('carbohydrates'),
    Nutrient.fat: ?v('fat'),
    Nutrient.fibre: ?v('fiber'),
    for (final (key, nutrient) in [
      ('calcium', Nutrient.calcium),
      ('iron', Nutrient.iron),
      ('potassium', Nutrient.potassium),
      ('sodium', Nutrient.sodium),
      ('vitamin-c', Nutrient.vitaminC),
    ])
      if (v(key) case final g?) nutrient: g * 1000,
  };
  final ml = RegExp(r'\d\s*(ml|cl|l)\b', caseSensitive: false).hasMatch(s('quantity'));
  // "1 bar (40 g)" -> "1 bar"; a bare amount like "330 ml" -> "1 serving".
  var serving = s('serving_size').replaceAll(RegExp(r'\s*\(.*?\)'), '').trim();
  if (serving.isEmpty || RegExp(r'^[\d.,\s]+(g|kg|mg|ml|cl|l|oz|fl\.? ?oz)?$', caseSensitive: false).hasMatch(serving)) serving = servingLabel;
  final servingAmount = amount('serving_quantity');
  final packAmount = amount('product_quantity');
  return Food(
    key: 'barcode:$barcode',
    name: name,
    brand: s('brands').split(',').first.trim(),
    barcode: barcode,
    unit: ml ? 'ml' : 'g',
    per100g: per100,
    portions: [
      if (servingAmount != null) Portion(serving, servingAmount),
      if (packAmount != null && packAmount != servingAmount) Portion(packLabel, packAmount),
    ],
  );
}
