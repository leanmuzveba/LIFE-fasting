import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../data/activity_repository.dart';
import '../data/body_repository.dart';
import '../data/food_facts_api.dart';
import '../data/food_repository.dart';
import '../data/hydration_repository.dart';
import '../data/meal_photo_api.dart';
import '../data/kitchen_repository.dart';
import '../data/notification_service.dart';
import '../data/recipe_repository.dart';
import '../data/review_repository.dart';
import '../data/session_repository.dart';
import '../data/settings_repository.dart';
import '../data/step_counter.dart';
import '../domain/activity.dart';
import '../domain/body.dart';
import '../domain/fasting_session.dart';
import '../domain/fasting_timer.dart';
import '../domain/food.dart';
import '../domain/history.dart';
import '../domain/hydration.dart';
import '../domain/kitchen.dart';
import '../domain/kitchen_review.dart';
import '../domain/meal_estimate.dart';
import '../domain/recipe.dart';
import '../domain/settings.dart';
import '../domain/steps.dart';

/// Opened in main() and injected with an override.
final databaseProvider = Provider<Database>((ref) => throw UnimplementedError('override databaseProvider'));

final sessionRepositoryProvider = Provider((ref) => SessionRepository(ref.watch(databaseProvider)));
final settingsRepositoryProvider = Provider((ref) => SettingsRepository(ref.watch(databaseProvider)));

/// Current instant. Overridden in tests for a fixed clock.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Ticks once a second. The displayed time is recomputed from stored
/// timestamps on every tick, so pausing (app in background) never drifts.
final nowProvider = StreamProvider<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  final controller = StreamController<DateTime>();
  controller.add(clock());
  final timer = Timer.periodic(const Duration(seconds: 1), (_) => controller.add(clock()));
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });
  return controller.stream;
});

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final repo = ref.watch(settingsRepositoryProvider);
    final s = await repo.load();
    if (s.memberSince != null) return s;
    // First run (or first run of a version that tracks it): remember the date.
    final stamped = s.copyWith(memberSince: ref.read(clockProvider)().toUtc());
    await repo.save(stamped);
    return stamped;
  }

  Future<void> save(AppSettings next) async {
    await ref.read(settingsRepositoryProvider).save(next);
    state = AsyncData(next);
  }

  Future<void> change(AppSettings Function(AppSettings) edit) async => save(edit(await future));
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// Thrown when an action is blocked by the safety rules (FR-12).
class NotEligibleError extends StateError {
  NotEligibleError() : super('Fasting sessions are only available to confirmed adults.');
}

class ActiveSessionNotifier extends AsyncNotifier<FastingSession?> {
  @override
  Future<FastingSession?> build() => ref.watch(sessionRepositoryProvider).active();

  SessionRepository get _repo => ref.read(sessionRepositoryProvider);
  DateTime _now() => ref.read(clockProvider)().toUtc();

  Future<void> start() async {
    final settings = await ref.read(settingsProvider.future);
    if (!settings.canFast) throw NotEligibleError();
    if (await future != null) return;
    final now = _now();
    final s = await _repo.insert(
      FastingSession(startedAt: now, targetMinutes: settings.targetMinutes, createdAt: now, updatedAt: now),
    );
    state = AsyncData(s);
    ref.invalidate(historyProvider);
    await syncNotifications(ref);
  }

  /// Ends the session and returns it as saved.
  Future<FastingSession?> end() async {
    final s = await future;
    if (s == null) return null;
    final now = _now();
    // Guard against a device clock that moved behind the start time.
    final endAt = now.isAfter(s.startedAt) ? now : s.startedAt.add(const Duration(seconds: 1));
    final ended = s.copyWith(endedAt: () => endAt, updatedAt: now);
    await _repo.update(ended);
    state = const AsyncData(null);
    ref.invalidate(historyProvider);
    await syncNotifications(ref);
    return ended;
  }

  /// Returns a validation error, or null when saved.
  Future<SessionTimeError?> editStart(DateTime startedAt) async {
    final s = await future;
    if (s == null) return null;
    final now = _now();
    final error = validateSessionTimes(start: startedAt, now: now);
    if (error != null) return error;
    final edited = s.copyWith(startedAt: startedAt.toUtc(), updatedAt: now);
    await _repo.update(edited);
    state = AsyncData(edited);
    ref.invalidate(historyProvider);
    await syncNotifications(ref);
    return null;
  }
}

final activeSessionProvider = AsyncNotifierProvider<ActiveSessionNotifier, FastingSession?>(ActiveSessionNotifier.new);

/// All sessions, newest first.
final historyProvider = FutureProvider<List<FastingSession>>((ref) => ref.watch(sessionRepositoryProvider).all());

/// Derived timer state for the Home screen; null until data has loaded.
final timerSnapshotProvider = Provider.family<TimerSnapshot?, double>((ref, gapFraction) {
  final session = ref.watch(activeSessionProvider).value;
  final settings = ref.watch(settingsProvider).value;
  final now = ref.watch(nowProvider).value;
  if (settings == null || now == null || ref.watch(activeSessionProvider).isLoading) return null;
  return TimerSnapshot.compute(
    session: session,
    idleTargetMinutes: settings.targetMinutes,
    now: now,
    gapFraction: gapFraction,
  );
});

/// Edit / delete any saved session from History (FR-08, FR-09).
class SessionActions {
  SessionActions(this._ref);
  final Ref _ref;

  /// Returns a validation error, or null when saved.
  Future<SessionTimeError?> save(FastingSession edited) async {
    final now = _ref.read(clockProvider)().toUtc();
    final error = validateSessionTimes(start: edited.startedAt, end: edited.endedAt, now: now);
    if (error != null) return error;
    await _ref.read(sessionRepositoryProvider).update(edited.copyWith(updatedAt: now));
    _refresh();
    return null;
  }

  Future<void> delete(FastingSession s) async {
    await _ref.read(sessionRepositoryProvider).delete(s.id!);
    _refresh();
  }

  void _refresh() {
    _ref.invalidate(historyProvider);
    _ref.invalidate(activeSessionProvider);
    syncNotifications(_ref);
  }

  /// "Delete all data": sessions, settings, preferences and scheduled reminders.
  Future<void> deleteEverything() async {
    await _ref.read(sessionRepositoryProvider).deleteAll();
    await _ref.read(hydrationRepositoryProvider).deleteAll();
    await _ref.read(activityRepositoryProvider).deleteAll();
    await _ref.read(kitchenRepositoryProvider).deleteAll();
    await _ref.read(reviewRepositoryProvider).deleteAll();
    await _ref.read(foodRepositoryProvider).deleteAll();
    await _ref.read(bodyRepositoryProvider).deleteAll();
    await _ref.read(recipeRepositoryProvider).deleteAll();
    await _ref.read(settingsRepositoryProvider).clear();
    await _ref.read(notificationServiceProvider).cancelAll();
    _ref.invalidate(historyProvider);
    _ref.invalidate(activeSessionProvider);
    _ref.invalidate(hydrationDayProvider);
    _ref.invalidate(activityDayProvider);
    _ref.invalidate(recentActivitiesProvider);
    _ref.invalidate(kitchenProvider);
    _ref.invalidate(shoppingListProvider);
    _ref.invalidate(diaryDayProvider);
    _ref.invalidate(customFoodsProvider);
    _ref.invalidate(recentFoodsProvider);
    _ref.invalidate(savedFoodsProvider);
    _ref.invalidate(bodyProfileProvider);
    _ref.invalidate(weighInsProvider);
    _ref.invalidate(savedRecipesProvider);
    _ref.invalidate(lastCookedProvider);
    _ref.invalidate(recipeSuggestionsProvider);
    _ref.invalidate(notificationPrefsProvider);
    _ref.invalidate(settingsProvider);
  }
}

final sessionActionsProvider = Provider(SessionActions.new);

final notificationServiceProvider = Provider((ref) => NotificationService());

class NotificationPrefsNotifier extends AsyncNotifier<List<NotificationPreference>> {
  @override
  Future<List<NotificationPreference>> build() => ref.watch(settingsRepositoryProvider).notificationPrefs();

  /// Saves a preference. Turning one on asks the OS for permission first;
  /// returns false (and keeps it off) if permission is refused.
  Future<bool> set(NotificationPreference p) async {
    if (p.enabled && !await ref.read(notificationServiceProvider).requestPermission()) return false;
    await ref.read(settingsRepositoryProvider).saveNotificationPref(p);
    final all = [for (final x in await future) x.type == p.type ? p : x];
    state = AsyncData(all);
    await ref
        .read(settingsProvider.notifier)
        .change((s) => s.copyWith(notificationsEnabled: all.any((x) => x.enabled)));
    await syncNotifications(ref);
    return true;
  }
}

final notificationPrefsProvider = AsyncNotifierProvider<NotificationPrefsNotifier, List<NotificationPreference>>(
  NotificationPrefsNotifier.new,
);

/// Idempotently (re)schedules exactly the notifications the user has enabled.
/// Called after every session change and on app launch.
Future<void> syncNotifications(Ref ref) async {
  final svc = ref.read(notificationServiceProvider);
  final settings = await ref.read(settingsProvider.future);
  final prefs = {for (final p in await ref.read(settingsRepositoryProvider).notificationPrefs()) p.type: p};
  final active = await ref.read(sessionRepositoryProvider).active();
  final allowed = settings.canFast; // Never notify under-18 or unconfirmed users.

  final target = prefs[NotificationType.targetReached];
  if (allowed && active != null && (target?.enabled ?? false)) {
    await svc.scheduleTargetReached(active.plannedEnd);
  } else {
    await svc.cancel(NotificationService.targetReachedId);
  }

  // Water reminders are general wellness, not fasting: allowed for everyone who opted in.
  if (prefs[NotificationType.waterReminder]?.enabled ?? false) {
    await svc.scheduleWaterReminders();
  } else {
    await svc.cancelWaterReminders();
  }

  if (prefs[NotificationType.monthlyReview]?.enabled ?? false) {
    await svc.scheduleMonthlyReview();
  } else {
    await svc.cancel(NotificationService.monthlyReviewId);
  }

  final daily = prefs[NotificationType.dailyReminder];
  if (allowed && daily != null && daily.enabled && daily.hour != null && daily.minute != null) {
    await svc.scheduleDailyReminder(daily.hour!, daily.minute!);
  } else {
    await svc.cancel(NotificationService.dailyReminderId);
  }
}

final launchSyncProvider = FutureProvider<void>((ref) async {
  try {
    await syncNotifications(ref);
  } catch (e) {
    debugPrint('Notification sync failed: $e'); // Never block the app on reminders.
  }
});

// --- Hydration (PRD v1.2 §9) ------------------------------------------------

final hydrationRepositoryProvider = Provider((ref) => HydrationRepository(ref.watch(databaseProvider)));

/// Local calendar day (midnight) containing [t].
DateTime localDay(DateTime t) {
  final l = t.toLocal();
  return DateTime(l.year, l.month, l.day);
}

/// Water entries for one local day, oldest first. Key: local midnight.
final hydrationDayProvider = FutureProvider.family<List<HydrationEntry>, DateTime>((ref, day) {
  final next = DateTime(day.year, day.month, day.day + 1);
  return ref.watch(hydrationRepositoryProvider).between(day, next);
});

class HydrationActions {
  HydrationActions(this._ref);
  final Ref _ref;

  HydrationRepository get _repo => _ref.read(hydrationRepositoryProvider);
  DateTime _now() => _ref.read(clockProvider)().toUtc();

  /// Logs [amountMl] at [at] (default: now). Rejects non-positive or future amounts.
  Future<void> add(double amountMl, {DateTime? at}) async {
    final now = _now();
    final when = (at ?? now).toUtc();
    if (amountMl <= 0 || when.isAfter(now)) return;
    await _repo.insert(HydrationEntry(amountMl: amountMl, loggedAt: when, createdAt: now, updatedAt: now));
    _ref.invalidate(hydrationDayProvider);
    _ref.invalidate(daySummariesProvider);
  }

  Future<void> update(HydrationEntry e) async {
    if (e.amountMl <= 0) return;
    await _repo.update(e.copyWith(updatedAt: _now()));
    _ref.invalidate(hydrationDayProvider);
    _ref.invalidate(daySummariesProvider);
  }

  Future<void> delete(HydrationEntry e) async {
    await _repo.delete(e.id!);
    _ref.invalidate(hydrationDayProvider);
    _ref.invalidate(daySummariesProvider);
  }
}

final hydrationActionsProvider = Provider(HydrationActions.new);

// --- Activity (PRD v1.2 §8) -------------------------------------------------

final activityRepositoryProvider = Provider((ref) => ActivityRepository(ref.watch(databaseProvider)));

/// Activities that started on one local day (key: local midnight), newest first.
final activityDayProvider = FutureProvider.family<List<ActivityEntry>, DateTime>((ref, day) {
  final next = DateTime(day.year, day.month, day.day + 1);
  return ref.watch(activityRepositoryProvider).between(day, next);
});

/// Latest activities, newest first.
final recentActivitiesProvider = FutureProvider((ref) => ref.watch(activityRepositoryProvider).recent());

class ActivityActions {
  ActivityActions(this._ref);
  final Ref _ref;

  ActivityRepository get _repo => _ref.read(activityRepositoryProvider);
  DateTime _now() => _ref.read(clockProvider)().toUtc();

  void _refresh() {
    _ref.invalidate(activityDayProvider);
    _ref.invalidate(recentActivitiesProvider);
    _ref.invalidate(daySummariesProvider);
  }

  /// Returns false (and saves nothing) for an out-of-range duration or a future start.
  Future<bool> save(ActivityEntry e) async {
    final now = _now();
    if (e.minutes < minActivityMinutes || e.minutes > maxActivityMinutes || e.startedAt.isAfter(now)) return false;
    final notes = e.notes.trim();
    if (e.id == null) {
      await _repo.insert(e.copyWith(notes: notes));
    } else {
      await _repo.update(e.copyWith(notes: notes, updatedAt: now));
    }
    _refresh();
    return true;
  }

  Future<void> delete(ActivityEntry e) async {
    await _repo.delete(e.id!);
    _refresh();
  }
}

final activityActionsProvider = Provider(ActivityActions.new);

// --- History (PRD v1.2 §10) -------------------------------------------------

/// Per-day summaries of everything recorded in [range] (local days, end exclusive).
final daySummariesProvider = FutureProvider.family<Map<DateTime, DaySummary>, (DateTime, DateTime)>((ref, range) async {
  final (from, to) = range;
  final sessions = await ref.watch(historyProvider.future);
  final water = await ref.watch(hydrationRepositoryProvider).between(from, to);
  final activities = await ref.watch(activityRepositoryProvider).between(from, to);
  final fromUtc = from.toUtc(), toUtc = to.toUtc();
  return summariseByDay(
    sessions: sessions.where((s) => !s.startedAt.isBefore(fromUtc) && s.startedAt.isBefore(toUtc)),
    water: water,
    activities: activities,
  );
});

// --- My Kitchen (PRD v1.2 §4) ----------------------------------------------

final kitchenRepositoryProvider = Provider((ref) => KitchenRepository(ref.watch(databaseProvider)));

/// Ingredients currently in the kitchen, A–Z.
final kitchenProvider = FutureProvider((ref) => ref.watch(kitchenRepositoryProvider).active());

class KitchenActions {
  KitchenActions(this._ref);
  final Ref _ref;

  KitchenRepository get _repo => _ref.read(kitchenRepositoryProvider);
  DateTime _now() => _ref.read(clockProvider)().toUtc();

  /// Adds or updates; returns the validation problem, or null when saved.
  Future<IngredientError?> save(Ingredient i) async {
    final error = validateIngredient(i);
    if (error != null) return error;
    if (i.id == null) {
      await _repo.insert(i);
    } else {
      await _repo.update(i.copyWith(updatedAt: _now()));
    }
    _ref.invalidate(kitchenProvider);
    return null;
  }

  /// Used up: leaves the kitchen but stays in history.
  Future<void> markFinished(Ingredient i) => _setStatus(i, IngredientStatus.finished);

  /// Spoiled/removed in a review: leaves the kitchen but stays in history.
  Future<void> discard(Ingredient i) => _setStatus(i, IngredientStatus.discarded);

  Future<void> _setStatus(Ingredient i, IngredientStatus status) async {
    final now = _now();
    await _repo.update(i.copyWith(status: status, statusAt: () => now, updatedAt: now));
    _ref.invalidate(kitchenProvider);
  }

  /// Removes the record entirely (user's explicit choice only).
  Future<void> delete(Ingredient i) async {
    await _repo.delete(i.id!);
    _ref.invalidate(kitchenProvider);
  }
}

final kitchenActionsProvider = Provider(KitchenActions.new);

// --- Monthly kitchen review + shopping list (PRD v1.2 §6) -------------------

final reviewRepositoryProvider = Provider((ref) => ReviewRepository(ref.watch(databaseProvider)));

final shoppingListProvider = FutureProvider((ref) => ref.watch(reviewRepositoryProvider).shoppingList());

/// Applies each review decision straight away (nothing is lost if the review
/// is interrupted) and records it against the review.
class ReviewActions {
  ReviewActions(this._ref);
  final Ref _ref;

  ReviewRepository get _repo => _ref.read(reviewRepositoryProvider);
  KitchenActions get _kitchen => _ref.read(kitchenActionsProvider);
  DateTime _now() => _ref.read(clockProvider)().toUtc();

  Future<int> start() => _repo.startReview(_now());

  /// Still have it: quantity updated (or unchanged).
  Future<void> keep(int reviewId, Ingredient i, double quantity) async {
    await _kitchen.save(i.copyWith(quantity: quantity));
    await _repo.addChange(reviewId, _change(i, ReviewAction.kept, quantity));
  }

  Future<void> usedUp(int reviewId, Ingredient i, {bool addToList = true}) async {
    await _kitchen.markFinished(i);
    await _repo.addChange(reviewId, _change(i, ReviewAction.usedUp, null));
    if (addToList) await addToShoppingList(i.name);
  }

  Future<void> spoiled(int reviewId, Ingredient i, {bool addToList = true}) async {
    await _kitchen.discard(i);
    await _repo.addChange(reviewId, _change(i, ReviewAction.spoiled, null));
    if (addToList) await addToShoppingList(i.name);
  }

  Future<void> complete(int reviewId) => _repo.completeReview(reviewId, _now());

  ReviewChange _change(Ingredient i, ReviewAction a, double? newQ) => ReviewChange(
    ingredientId: i.id!,
    name: i.name,
    action: a,
    oldQuantity: i.quantity,
    newQuantity: newQ,
    unit: i.unit,
  );

  Future<bool> addToShoppingList(String name, {String note = ''}) async {
    final added = await _repo.addToShoppingList(name, _now(), note: note);
    _ref.invalidate(shoppingListProvider);
    return added;
  }

  Future<void> setChecked(ShoppingItem s, bool checked) async {
    await _repo.setChecked(s.id!, checked);
    _ref.invalidate(shoppingListProvider);
  }

  Future<void> remove(ShoppingItem s) async {
    await _repo.removeShoppingItem(s.id!);
    _ref.invalidate(shoppingListProvider);
  }

  Future<void> clearChecked() async {
    await _repo.clearChecked();
    _ref.invalidate(shoppingListProvider);
  }
}

final reviewActionsProvider = Provider(ReviewActions.new);

// --- Food diary (PRD v1.2 §3) ---------------------------------------------------

final foodRepositoryProvider = Provider((ref) => FoodRepository(ref.watch(databaseProvider)));
final foodFactsApiProvider = Provider((ref) => FoodFactsApi());

/// USDA FoodData Central SR Legacy, bundled (public domain); loaded once.
final usdaFoodsProvider = FutureProvider<List<Food>>((ref) async {
  final data = await rootBundle.load('assets/foods/usda_sr_legacy.tsv');
  final text = utf8.decode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  return [
    for (final line in text.split('\n'))
      if (line.isNotEmpty) Food.fromUsdaLine(line),
  ];
});

final customFoodsProvider = FutureProvider((ref) => ref.watch(foodRepositoryProvider).customFoods());

/// Everything searchable: your own foods first, then USDA.
final foodCatalogueProvider = FutureProvider<List<Food>>(
  (ref) async => [...await ref.watch(customFoodsProvider.future), ...await ref.watch(usdaFoodsProvider.future)],
);

/// Diary entries for one local date (key: local midnight), in time order.
final diaryDayProvider = FutureProvider.family<List<FoodEntry>, DateTime>(
  (ref, day) => ref.watch(foodRepositoryProvider).forDay(day),
);

final recentFoodsProvider = FutureProvider((ref) => ref.watch(foodRepositoryProvider).recent());
final savedFoodsProvider = FutureProvider((ref) => ref.watch(foodRepositoryProvider).saved());

class FoodActions {
  FoodActions(this._ref);
  final Ref _ref;

  FoodRepository get _repo => _ref.read(foodRepositoryProvider);
  DateTime _now() => _ref.read(clockProvider)().toUtc();

  void _changed() {
    _ref.invalidate(diaryDayProvider);
    _ref.invalidate(recentFoodsProvider);
  }

  /// Logs [grams] of [food] to [meal] on local date [day] at local time [at].
  Future<FoodEntry?> log(
    Food food,
    double grams, {
    required Meal meal,
    required DateTime at,
    String portion = '',
  }) async {
    if (grams <= 0) return null;
    final local = at.toLocal();
    final e = await _repo.insert(
      FoodEntry(
        day: DateTime(local.year, local.month, local.day),
        meal: meal,
        loggedAt: at.toUtc(),
        name: food.name,
        foodKey: food.key,
        grams: grams,
        portion: portion,
        unit: food.unit,
        nutrients: scaleNutrients(food.per100g, grams),
      ),
    );
    _changed();
    return e;
  }

  Future<void> update(FoodEntry e) async {
    if ((e.grams ?? 1) <= 0) return;
    await _repo.update(e);
    _changed();
  }

  Future<void> delete(FoodEntry e) async {
    await _repo.delete(e.id!);
    _changed();
  }

  Future<void> setSaved(Food food, bool saved, {double grams = 100, String portion = ''}) async {
    if (saved) {
      await _repo.save((key: food.key, name: food.name, grams: grams, portion: portion, at: _now()));
    } else {
      await _repo.unsave(food.key);
    }
    _ref.invalidate(savedFoodsProvider);
  }

  Future<Food> createCustom(Food food) async {
    final f = await _repo.addCustomFood(food, _now());
    _ref.invalidate(customFoodsProvider);
    return f;
  }

  /// Logs the reviewed items from a meal photo as separate entries, marked
  /// with [label] so they read as estimates in the diary.
  Future<void> logEstimate(
    Iterable<EstimatedItem> items, {
    required Meal meal,
    required DateTime at,
    required String label,
  }) async {
    final local = at.toLocal();
    for (final i in items) {
      if (i.grams <= 0 || i.name.trim().isEmpty) continue;
      await _repo.insert(
        FoodEntry(
          day: DateTime(local.year, local.month, local.day),
          meal: meal,
          loggedAt: at.toUtc(),
          name: i.name.trim(),
          grams: i.grams,
          portion: label,
          nutrients: i.nutrients,
        ),
      );
    }
    _changed();
  }

  /// Finds a packaged food: first among foods you scanned or created, then
  /// Open Food Facts (saved locally so it works offline next time). Null when
  /// unknown; throws when offline and not saved.
  Future<Food?> lookupBarcode(String barcode, {required String servingLabel, required String packLabel}) async {
    final local = await _repo.byBarcode(barcode);
    if (local != null) return local;
    final product = await _ref.read(foodFactsApiProvider).product(barcode);
    final food = product == null
        ? null
        : foodFromOpenFoodFacts(barcode, product, servingLabel: servingLabel, packLabel: packLabel);
    return food == null ? null : createCustom(food);
  }
}

final foodActionsProvider = Provider(FoodActions.new);

// --- Smart Recipe Planner (PRD v1.2 §5) -------------------------------------------

final recipeApiProvider = Provider((ref) => RecipeApi());
final recipeRepositoryProvider = Provider(
  (ref) => RecipeRepository(ref.watch(databaseProvider), ref.watch(recipeApiProvider), ref.watch(clockProvider)),
);

final recipeProvider = FutureProvider.family<Recipe?, String>(
  (ref, id) => ref.watch(recipeRepositoryProvider).byId(id),
);
final savedRecipesProvider = FutureProvider((ref) => ref.watch(recipeRepositoryProvider).savedIds());
final lastCookedProvider = FutureProvider((ref) => ref.watch(recipeRepositoryProvider).lastCooked());

/// How many kitchen items are looked up, and how many recipes are opened.
const _maxQueries = 8, _maxCandidates = 16;

/// What you can make: recipes that use your kitchen items (expiring first),
/// minus anything with a recorded allergen; ranked by fewest missing.
/// Diet filtering is left to the screen so it can be switched.
final recipeSuggestionsProvider = FutureProvider<List<RecipeMatch>>((ref) async {
  final repo = ref.watch(recipeRepositoryProvider);
  final kitchen = await ref.watch(kitchenProvider.future);
  final allergies = (await ref.watch(settingsProvider.future)).allergies;
  final t = ref.read(clockProvider)().toLocal();
  final today = DateTime(t.year, t.month, t.day);

  final usable = kitchen.where((i) => !i.isExpired(today)).toList()
    ..sort((a, b) => (a.daysToExpiry(today) ?? 9999).compareTo(b.daysToExpiry(today) ?? 9999));
  final hits = <String, int>{};
  for (final item in usable.take(_maxQueries)) {
    var ids = await repo.idsWith(item.name);
    final words = item.name.trim().split(RegExp(r'\s+'));
    if (ids.isEmpty && words.length > 1) ids = await repo.idsWith(words.last);
    for (final id in ids) {
      hits[id] = (hits[id] ?? 0) + 1;
    }
  }
  final ids = (hits.keys.toList()..sort((a, b) => hits[b]!.compareTo(hits[a]!))).take(_maxCandidates);
  final recipes = await Future.wait(ids.map(repo.byId));
  return rankMatches([
    for (final r in recipes)
      if (r != null && allergensIn(r).intersection(allergies).isEmpty) RecipeMatch(r, kitchen, today),
  ]);
});

/// Recipes by name, matched against the kitchen; recorded allergens excluded.
final recipeSearchProvider = FutureProvider.family<List<RecipeMatch>, String>((ref, query) async {
  final recipes = await ref.watch(recipeRepositoryProvider).search(query);
  final kitchen = await ref.watch(kitchenProvider.future);
  final allergies = (await ref.watch(settingsProvider.future)).allergies;
  final t = ref.read(clockProvider)().toLocal();
  return rankMatches([
    for (final r in recipes)
      if (allergensIn(r).intersection(allergies).isEmpty) RecipeMatch(r, kitchen, DateTime(t.year, t.month, t.day)),
  ]);
});

class RecipeActions {
  RecipeActions(this._ref);
  final Ref _ref;

  RecipeRepository get _repo => _ref.read(recipeRepositoryProvider);

  Future<void> setSaved(Recipe r, bool saved) async {
    await _repo.setSaved(r, saved);
    _ref.invalidate(savedRecipesProvider);
  }

  Future<void> markCooked(Recipe r, double batch) async {
    await _repo.markCooked(r, batch);
    _ref.invalidate(lastCookedProvider);
  }

  /// Logs one serving to the diary. Returns false when this recipe is
  /// already logged for that meal and day (no duplicates).
  Future<bool> logToDiary(Recipe r, Meal meal, DateTime at, {required String servingLabel}) async {
    final food = _ref.read(foodRepositoryProvider);
    final local = at.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    if (await food.isLogged('recipe:${r.id}', day, meal)) return false;
    await food.insert(
      FoodEntry(
        day: day,
        meal: meal,
        loggedAt: at.toUtc(),
        name: r.name,
        foodKey: 'recipe:${r.id}',
        portion: servingLabel,
        nutrients: const {}, // TheMealDB has no nutrition: shown as unavailable
      ),
    );
    _ref.invalidate(diaryDayProvider);
    return true;
  }

  /// Adds missing ingredients to the shopping list; returns how many were new.
  Future<int> addToShoppingList(Iterable<RecipeIngredient> items) async {
    var added = 0;
    for (final i in items) {
      if (await _ref.read(reviewActionsProvider).addToShoppingList(i.name)) added++;
    }
    return added;
  }
}

final recipeActionsProvider = Provider(RecipeActions.new);

// --- Meal photo estimates (PRD v1.2 §3, optional; reviewed before saving) ------

/// Built into the app at build time (--dart-define-from-file=secrets.json);
/// never committed.
const _builtInGeminiKey = String.fromEnvironment('GEMINI_API_KEY');

/// Which Gemini key is used: yours from Settings, else the built-in one.
final geminiKeyProvider = FutureProvider<({String key, bool own})?>((ref) async {
  final own = await ref.watch(settingsRepositoryProvider).apiKey('gemini');
  if (own != null && own.isNotEmpty) return (key: own, own: true);
  return _builtInGeminiKey.isEmpty ? null : (key: _builtInGeminiKey, own: false);
});

/// Null when no key is available.
final mealPhotoApiProvider = FutureProvider<MealPhotoApi?>((ref) async {
  final k = await ref.watch(geminiKeyProvider.future);
  return k == null ? null : MealPhotoApi(k.key);
});

// --- Personal measurements (PRD v1.2 §7) -------------------------------------------

final bodyRepositoryProvider = Provider((ref) => BodyRepository(ref.watch(databaseProvider)));
final bodyProfileProvider = FutureProvider((ref) => ref.watch(bodyRepositoryProvider).profile());
final weighInsProvider = FutureProvider((ref) => ref.watch(bodyRepositoryProvider).weighIns());

class BodyActions {
  BodyActions(this._ref);
  final Ref _ref;

  BodyRepository get _repo => _ref.read(bodyRepositoryProvider);

  Future<void> saveProfile(BodyProfile p) async {
    await _repo.saveProfile(p);
    _ref.invalidate(bodyProfileProvider);
  }

  Future<void> addWeighIn(WeighIn w) async {
    if (w.weightKg <= 0) return;
    await _repo.addWeighIn(w);
    _ref.invalidate(weighInsProvider);
  }

  Future<void> updateWeighIn(WeighIn w) async {
    if (w.weightKg <= 0) return;
    await _repo.updateWeighIn(w);
    _ref.invalidate(weighInsProvider);
  }

  Future<void> deleteWeighIn(WeighIn w) async {
    await _repo.deleteWeighIn(w.id!);
    _ref.invalidate(weighInsProvider);
  }
}

final bodyActionsProvider = Provider(BodyActions.new);

// --- Steps (home page) ---------------------------------------------------------------

final stepCounterProvider = Provider((ref) => StepCounter());

/// Today's steps, or why they can't be shown.
class StepsState {
  const StepsState({this.steps = 0, this.needsPermission = false, this.unavailable = false});
  final int steps;
  final bool needsPermission;
  final bool unavailable;
}

final todayStepsProvider = StreamProvider<StepsState>((ref) async* {
  final counter = ref.watch(stepCounterProvider);
  final repo = ref.watch(settingsRepositoryProvider);
  DateTime now() => ref.read(clockProvider)().toLocal();
  if (!await counter.granted()) {
    yield const StepsState(needsPermission: true);
    return;
  }
  var book = StepBook.fromJson(await repo.stepBook());
  yield StepsState(steps: stepsToday(book, now()));
  var saved = book?.last ?? -1;
  try {
    await for (final reading in counter.readings()) {
      final day = book?.day;
      book = recordSteps(book, reading, now());
      // Save on a new day, after a reboot, or every 50 steps.
      if (book.day != day || reading < saved || reading - saved >= 50) {
        await repo.saveStepBook(book.toJson());
        saved = reading;
      }
      yield StepsState(steps: book.today);
    }
  } catch (_) {
    yield const StepsState(unavailable: true);
  }
});
