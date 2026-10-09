// Smart Recipe Planner (PRD v1.2 §5): TheMealDB recipes matched against the
// kitchen with simple, explainable rules. No invented times, servings or
// nutrition — TheMealDB doesn't provide them, so RUVA says so.

import 'kitchen.dart';
import 'profile.dart';

class RecipeIngredient {
  const RecipeIngredient(this.name, this.measure);
  final String name;
  final String measure; // free text from the catalogue, e.g. "1 1/2 cups"
}

class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    this.category = '',
    this.area = '',
    this.thumb,
    this.steps = const [],
    this.ingredients = const [],
    this.source,
    this.minutes,
    this.servings,
  });

  final String id;
  final String name;
  final String category;
  final String area;
  final String? thumb;
  final List<String> steps;
  final List<RecipeIngredient> ingredients;
  final String? source;
  final int? minutes; // only your own recipes have these
  final int? servings;

  /// Created by you (stored on this phone), not from TheMealDB.
  bool get isMine => id.startsWith('mine:');

  /// Parses a full TheMealDB meal (lookup.php / search.php).
  static Recipe fromMealDb(Map<String, dynamic> m) {
    String s(String k) => ((m[k] as String?) ?? '').trim();
    return Recipe(
      id: s('idMeal'),
      name: s('strMeal'),
      category: s('strCategory'),
      area: s('strArea').isNotEmpty ? s('strArea') : s('strCountry'),
      thumb: s('strMealThumb').isEmpty ? null : s('strMealThumb'),
      steps: [
        for (final line in s('strInstructions').split(RegExp(r'\r?\n')))
          if (line.trim().replaceFirst(RegExp(r'^(step\s*)?\d+[.):]?\s*$', caseSensitive: false), '').isNotEmpty)
            line.trim().replaceFirst(RegExp(r'^(step\s*)?\d+[.):]\s*', caseSensitive: false), ''),
      ],
      ingredients: [
        for (var i = 1; i <= 20; i++)
          if (s('strIngredient$i').isNotEmpty) RecipeIngredient(s('strIngredient$i'), s('strMeasure$i')),
      ],
      source: s('strSource').isEmpty ? null : s('strSource'),
    );
  }
}

String _singular(String w) {
  if (w.length <= 3 || !w.endsWith('s') || w.endsWith('ss')) return w;
  if (RegExp(r'(o|x|z|ch|sh)es$').hasMatch(w)) return w.substring(0, w.length - 2);
  return w.substring(0, w.length - 1);
}

String _norm(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z ]'), ' ').split(' ').where((w) => w.isNotEmpty).map(_singular).join(' ');

/// True when [kitchenName] and a recipe ingredient name refer to the same
/// thing: equal after plural folding, or the shorter is the head noun (last
/// words) of the longer — "Baby spinach" ↔ "Spinach", "Eggs" ↔ "Egg", but not
/// "Rice" ↔ "Rice vinegar".
// ponytail: head-noun heuristic; "Milk" still matches "Coconut milk" and
// "Chicken" doesn't match "Chicken breast". Upgrade: a synonym table.
bool sameIngredient(String kitchenName, String recipeName) {
  final a = _norm(kitchenName), b = _norm(recipeName);
  if (a.isEmpty || b.isEmpty) return false;
  return a == b || a.endsWith(' $b') || b.endsWith(' $a');
}

class RecipeMatch {
  RecipeMatch(this.recipe, Iterable<Ingredient> kitchen, DateTime today) {
    final usable = kitchen.where((i) => i.isActive && !i.isExpired(today)).toList();
    for (final ing in recipe.ingredients) {
      final have = usable.where((k) => sameIngredient(k.name, ing.name)).toList();
      (have.isEmpty ? missing : available).add(ing);
      if (have.any((k) => k.expiringSoon(today))) usesExpiring++;
    }
  }

  final Recipe recipe;
  final List<RecipeIngredient> available = [];
  final List<RecipeIngredient> missing = [];
  int usesExpiring = 0;

  bool get complete => missing.isEmpty;
}

/// Best first: fewest missing, then most expiring items used, then most available.
List<RecipeMatch> rankMatches(Iterable<RecipeMatch> matches) => matches.toList()
  ..sort((a, b) {
    for (final c in [
      a.missing.length.compareTo(b.missing.length),
      b.usesExpiring.compareTo(a.usesExpiring),
      b.available.length.compareTo(a.available.length),
    ]) {
      if (c != 0) return c;
    }
    return a.recipe.name.compareTo(b.recipe.name);
  });

// --- Allergies and diets: keyword rules on ingredient names (PRD §5.4) -------
// They can miss hidden ingredients, so the UI always shows a warning.

const _allergenWords = {
  Allergen.eggs: ['egg', 'mayonnaise', 'meringue'],
  Allergen.dairy: [
    'milk',
    'butter',
    'cheese',
    'cream',
    'yogurt',
    'yoghurt',
    'ghee',
    'parmesan',
    'mozzarella',
    'cheddar',
    'feta',
    'ricotta',
    'mascarpone',
    'creme fraiche',
    'buttermilk',
    'custard',
    'paneer',
  ],
  Allergen.peanuts: ['peanut'],
  Allergen.treeNuts: [
    'almond',
    'cashew',
    'walnut',
    'pecan',
    'hazelnut',
    'pistachio',
    'macadamia',
    'brazil nut',
    'pine nut',
    'praline',
    'marzipan',
    'nut',
  ],
  Allergen.gluten: [
    'flour',
    'bread',
    'pasta',
    'spaghetti',
    'noodle',
    'wheat',
    'barley',
    'rye',
    'couscous',
    'breadcrumb',
    'pastry',
    'tortilla',
    'semolina',
    'bulgur',
    'biscuit',
    'lasagne',
    'macaroni',
    'penne',
    'fettuccine',
    'linguine',
    'tagliatelle',
    'rigatoni',
    'farfalle',
    'soy sauce',
    'beer',
  ],
  Allergen.soy: ['soy', 'soya', 'tofu', 'edamame', 'miso', 'tempeh'],
  Allergen.fish: [
    'fish',
    'salmon',
    'tuna',
    'cod',
    'haddock',
    'anchov',
    'sardine',
    'mackerel',
    'trout',
    'tilapia',
    'herring',
    'monkfish',
    'sea bass',
    'kipper',
    'fish sauce',
    'worcestershire',
  ],
  Allergen.shellfish: [
    'prawn',
    'shrimp',
    'crab',
    'lobster',
    'mussel',
    'clam',
    'oyster',
    'scallop',
    'squid',
    'calamari',
    'langoustine',
    'crayfish',
  ],
  Allergen.sesame: ['sesame', 'tahini'],
};

const _meat = [
  'chicken',
  'beef',
  'pork',
  'lamb',
  'mutton',
  'goat',
  'bacon',
  'ham',
  'sausage',
  'chorizo',
  'salami',
  'pepperoni',
  'prosciutto',
  'pancetta',
  'turkey',
  'duck',
  'veal',
  'venison',
  'mince',
  'steak',
  'lard',
  'suet',
  'gelatine',
  'gelatin',
  'stock cube',
  'chicken stock',
  'beef stock',
  'kidney',
  'liver',
  'oxtail',
  'brisket',
];
const _pork = [
  'pork',
  'bacon',
  'ham',
  'lard',
  'chorizo',
  'salami',
  'pepperoni',
  'prosciutto',
  'pancetta',
  'gelatine',
  'gelatin',
  'sausage',
];
const _alcohol = [
  'wine',
  'beer',
  'brandy',
  'rum',
  'vodka',
  'whisky',
  'whiskey',
  'sherry',
  'cider',
  'liqueur',
  'gin',
  'port',
  'marsala',
  'mirin',
  'sake',
  'cognac',
  'bourbon',
  'stout',
  'ale',
];
const _animalOther = ['honey'];

bool _hasWord(String ingredient, String word) =>
    RegExp('\\b${RegExp.escape(word)}', caseSensitive: false).hasMatch(ingredient);

bool _any(Recipe r, Iterable<String> words) => r.ingredients.any((i) => words.any((w) => _hasWord(i.name, w)));

/// Allergens a recipe appears to contain, judged from ingredient names.
Set<Allergen> allergensIn(Recipe r) => {
  for (final e in _allergenWords.entries)
    if (_any(r, e.value) && !(e.key == Allergen.treeNuts && _onlyNutmegOrCoconut(r))) e.key,
};

// "nut" also matches nutmeg/coconut, which aren't tree nuts for most people.
bool _onlyNutmegOrCoconut(Recipe r) => !r.ingredients.any(
  (i) => _allergenWords[Allergen.treeNuts]!.any(
    (w) => _hasWord(i.name, w) && !RegExp(r'nutmeg|coconut', caseSensitive: false).hasMatch(i.name),
  ),
);

bool fitsDiet(Recipe r, DietPreference d) => switch (d) {
  DietPreference.none => true,
  DietPreference.vegetarian =>
    !_any(r, _meat) && !_any(r, _allergenWords[Allergen.fish]!) && !_any(r, _allergenWords[Allergen.shellfish]!),
  DietPreference.vegan =>
    fitsDiet(r, DietPreference.vegetarian) &&
        !_any(r, [..._allergenWords[Allergen.eggs]!, ..._allergenWords[Allergen.dairy]!, ..._animalOther]),
  DietPreference.pescatarian => !_any(r, _meat),
  DietPreference.halal => !_any(r, [..._pork, ..._alcohol]),
};

/// Recipes safe to suggest: none of [allergies], and fits [diet].
bool suitable(Recipe r, {required Set<Allergen> allergies, required DietPreference diet}) =>
    allergensIn(r).intersection(allergies).isEmpty && fitsDiet(r, diet);

// --- Substitutions (PRD §5.2) ---------------------------------------------------

const _substitutes = {
  'butter': ['olive oil', 'vegetable oil', 'margarine', 'coconut oil'],
  'milk': ['oat milk', 'almond milk', 'soy milk', 'rice milk'],
  'double cream': ['single cream', 'cream', 'coconut milk'],
  'heavy cream': ['single cream', 'cream', 'coconut milk'],
  'sour cream': ['greek yogurt', 'yogurt', 'creme fraiche'],
  'creme fraiche': ['sour cream', 'greek yogurt'],
  'yogurt': ['greek yogurt', 'sour cream'],
  'buttermilk': ['milk', 'yogurt'],
  'lemon': ['lime'],
  'lime': ['lemon'],
  'onion': ['red onion', 'shallot', 'spring onion', 'leek'],
  'shallot': ['onion', 'red onion'],
  'chicken stock': ['vegetable stock', 'stock'],
  'beef stock': ['vegetable stock', 'stock'],
  'vegetable stock': ['chicken stock', 'stock'],
  'brown sugar': ['sugar', 'honey'],
  'honey': ['maple syrup', 'sugar'],
  'spinach': ['kale', 'chard', 'cabbage'],
  'parsley': ['coriander', 'cilantro'],
  'coriander': ['parsley'],
  'rice': ['brown rice', 'basmati rice', 'jasmine rice'],
  'chicken breast': ['chicken', 'chicken thigh'],
  'chicken thigh': ['chicken', 'chicken breast'],
  'cheddar cheese': ['cheese', 'mozzarella', 'gouda'],
  'parmesan cheese': ['cheese', 'pecorino'],
};

/// A kitchen item that can stand in for a missing [ingredient], if any.
Ingredient? substituteFor(RecipeIngredient ingredient, Iterable<Ingredient> kitchen, DateTime today) {
  final key = _substitutes.keys.firstWhere((k) => _norm(k) == _norm(ingredient.name), orElse: () => '');
  if (key.isEmpty) return null;
  for (final alt in _substitutes[key]!) {
    for (final k in kitchen) {
      if (k.isActive && !k.isExpired(today) && sameIngredient(k.name, alt)) return k;
    }
  }
  return null;
}

// --- Batch scaling ---------------------------------------------------------------

const _fractions = {'½': 0.5, '⅓': 1 / 3, '⅔': 2 / 3, '¼': 0.25, '¾': 0.75, '⅛': 0.125};

/// Scales the leading amount of a free-text measure ("1 1/2 cups", "½ tsp",
/// "200g"). Measures without a number ("to taste", "pinch") are unchanged.
String scaleMeasure(String measure, double factor) {
  if (factor == 1) return measure;
  final m = RegExp(r'^\s*(?:(\d+)\s+(\d+)/(\d+)|(\d+)/(\d+)|(\d+(?:\.\d+)?)(?:\s*([½⅓⅔¼¾⅛]))?|([½⅓⅔¼¾⅛]))')
      .firstMatch(measure);
  if (m == null) return measure;
  int g(int i) => int.parse(m.group(i)!);
  final v = m.group(1) != null
      ? g(1) + g(2) / g(3)
      : m.group(4) != null
      ? g(4) / g(5)
      : m.group(6) != null
      ? double.parse(m.group(6)!) + (_fractions[m.group(7)] ?? 0)
      : _fractions[m.group(8)]!;
  if (v == 0) return measure;
  final scaled = v * factor;
  final text = scaled == scaled.roundToDouble()
      ? scaled.round().toString()
      : scaled.toStringAsFixed(scaled < 1 ? 2 : 1).replaceFirst(RegExp(r'0$'), '');
  return '$text${measure.substring(m.end)}';
}
