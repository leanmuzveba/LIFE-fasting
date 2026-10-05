import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../domain/kitchen.dart';

String categoryLabel(AppLocalizations l, IngredientCategory c) => switch (c) {
  IngredientCategory.protein => l.catProtein,
  IngredientCategory.carbs => l.catCarbs,
  IngredientCategory.vegetables => l.catVegetables,
  IngredientCategory.fruits => l.catFruits,
  IngredientCategory.fatsNutsSeeds => l.catFatsNutsSeeds,
  IngredientCategory.dairy => l.catDairy,
  IngredientCategory.herbsSpices => l.catHerbsSpices,
  IngredientCategory.pantry => l.catPantry,
};

IconData categoryIcon(IngredientCategory c) => switch (c) {
  IngredientCategory.protein => Icons.egg_outlined,
  IngredientCategory.carbs => Icons.grass,
  IngredientCategory.vegetables => Icons.eco_outlined,
  IngredientCategory.fruits => Icons.apple,
  IngredientCategory.fatsNutsSeeds => Icons.spa_outlined,
  IngredientCategory.dairy => Icons.local_drink_outlined,
  IngredientCategory.herbsSpices => Icons.local_florist_outlined,
  IngredientCategory.pantry => Icons.kitchen_outlined,
};

String stateLabel(AppLocalizations l, FoodState s) => switch (s) {
  FoodState.fresh => l.stateFresh,
  FoodState.frozen => l.stateFrozen,
  FoodState.canned => l.stateCanned,
  FoodState.dried => l.stateDried,
};

IconData stateIcon(FoodState s) => switch (s) {
  FoodState.fresh => Icons.eco_outlined,
  FoodState.frozen => Icons.ac_unit,
  FoodState.canned => Icons.inventory_2_outlined,
  FoodState.dried => Icons.grain,
};

String errorLabel(AppLocalizations l, IngredientError e) => switch (e) {
  IngredientError.nameRequired => l.errNameRequired,
  IngredientError.quantityInvalid => l.errQuantityInvalid,
  IngredientError.lowStockInvalid => l.errLowStockInvalid,
  IngredientError.expiryBeforePurchase => l.errExpiryBeforePurchase,
};

/// "12 pcs", "1.5 kg".
String formatQuantity(double q, String unit) {
  final n = q == q.roundToDouble()
      ? q.toInt().toString()
      : q.toStringAsFixed(q < 10 ? 2 : 1).replaceFirst(RegExp(r'0+$'), '');
  return '$n $unit';
}

/// "Expires in 3 days" / "Expires today" / "Expired 2 days ago", or null.
String? expiryTextFor(AppLocalizations l, DateTime? expires, DateTime today) {
  if (expires == null) return null;
  final d = DateTime(
    expires.year,
    expires.month,
    expires.day,
  ).difference(DateTime(today.year, today.month, today.day)).inDays;
  if (d == 0) return l.kitchenExpiresToday;
  return d > 0 ? l.kitchenExpiresIn(d) : l.kitchenExpired(-d);
}
