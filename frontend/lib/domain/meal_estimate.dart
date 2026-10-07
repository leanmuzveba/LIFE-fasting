// Photo-assisted meal logging (PRD v1.2 §3 optional): an AI estimate the
// user reviews and edits before anything is saved.

import 'food.dart';

class EstimatedItem {
  const EstimatedItem({required this.name, required this.grams, required this.nutrients});

  final String name;
  final double grams;
  final Nutrients nutrients; // totals for [grams]

  /// Same food, different amount: nutrients scale with the weight.
  EstimatedItem withGrams(double g) =>
      EstimatedItem(name: name, grams: g, nutrients: scaleNutrients(nutrients, g * 100 / grams));

  EstimatedItem withName(String n) => EstimatedItem(name: n, grams: grams, nutrients: nutrients);
}

class MealEstimate {
  const MealEstimate({required this.isFood, required this.items, this.note = ''});

  final bool isFood;
  final List<EstimatedItem> items;
  final String note;
}
