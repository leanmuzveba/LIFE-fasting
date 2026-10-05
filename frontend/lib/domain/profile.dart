/// Optional profile preferences (PRD v1.2 §5.1, §7, §13 UserProfile).
/// Used to filter recipe suggestions; nothing here is required.
enum UnitSystem { metric, imperial }

enum DietPreference { none, vegetarian, vegan, pescatarian, halal }

/// Allergies the user has recorded. Recipes containing these are never
/// suggested (PRD §5.4).
enum Allergen { eggs, dairy, peanuts, treeNuts, gluten, soy, fish, shellfish, sesame }
