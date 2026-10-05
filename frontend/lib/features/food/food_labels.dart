import 'package:flutter/material.dart';

import '../../domain/food.dart';
import '../../l10n/app_localizations.dart';

String mealLabel(AppLocalizations l, Meal m) => switch (m) {
  Meal.breakfast => l.mealBreakfast,
  Meal.lunch => l.mealLunch,
  Meal.dinner => l.mealDinner,
  Meal.snacks => l.mealSnacks,
};

IconData mealIcon(Meal m) => switch (m) {
  Meal.breakfast => Icons.free_breakfast_outlined,
  Meal.lunch => Icons.rice_bowl_outlined,
  Meal.dinner => Icons.dinner_dining_outlined,
  Meal.snacks => Icons.apple_outlined,
};

/// Default clock time for a meal logged on a past day.
int mealDefaultHour(Meal m) => switch (m) {
  Meal.breakfast => 8,
  Meal.lunch => 13,
  Meal.snacks => 16,
  Meal.dinner => 19,
};

String nutrientLabel(AppLocalizations l, Nutrient n) => switch (n) {
  Nutrient.energy => l.nutrientEnergy,
  Nutrient.protein => l.nutrientProtein,
  Nutrient.carbs => l.nutrientCarbs,
  Nutrient.fat => l.nutrientFat,
  Nutrient.fibre => l.nutrientFibre,
  Nutrient.calcium => l.nutrientCalcium,
  Nutrient.iron => l.nutrientIron,
  Nutrient.potassium => l.nutrientPotassium,
  Nutrient.sodium => l.nutrientSodium,
  Nutrient.vitaminC => l.nutrientVitaminC,
};

/// Whole numbers from 10 up, one decimal below (iron, small portions).
String formatNutrient(double v) {
  if (v >= 10) {
    final s = v.round().toString();
    return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ',');
  }
  final s = v.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

/// "1 cup (245 g)", "150 g", or just the portion when the weight is unknown.
String formatPortion(String portion, double? grams) {
  if (grams == null) return portion;
  final g = '${formatNutrient(grams)} g';
  return portion.isEmpty ? g : '$portion ($g)';
}
