import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/data/notification_service.dart';
import 'package:life_fasting/domain/kitchen.dart';
import 'package:life_fasting/domain/kitchen_review.dart';
import 'package:life_fasting/domain/settings.dart';
import 'package:life_fasting/state/providers.dart';

import '../helpers.dart' show FakeNotifications;
import '../widget_test.dart' show pumpApp;

final _t = DateTime.utc(2026, 10, 4);
Ingredient _i(String name, {double q = 1, String unit = 'pcs', DateTime? expires}) => Ingredient(
  name: name,
  categories: const {IngredientCategory.pantry},
  quantity: q,
  unit: unit,
  state: FoodState.fresh,
  expiresOn: expires,
  createdAt: _t,
  updatedAt: _t,
);

void main() {
  test('review queue: soonest expiry first, then A–Z; finished items skipped', () {
    final today = DateTime(2026, 10, 4);
    final q = reviewQueue([
      _i('rice'),
      _i('Apples'),
      _i('Eggs', expires: DateTime(2026, 10, 6)),
      _i('Spinach', expires: DateTime(2026, 10, 3)),
      _i('Gone').copyWith(status: IngredientStatus.finished),
    ], today);
    expect(q.map((i) => i.name), ['Spinach', 'Eggs', 'Apples', 'rice']);
  });

  testWidgets('a review updates the kitchen, fills the shopping list and is recorded', (tester) async {
    await pumpApp(tester);
    tester.view.physicalSize = const Size(390, 2600);
    final c = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    for (final i in [
      _i('Rice', q: 1.5, unit: 'kg'),
      _i('Eggs', q: 12, expires: DateTime(2026, 10, 6)),
      _i('Baby spinach', q: 300, unit: 'g', expires: DateTime(2026, 10, 4)),
    ]) {
      await c.read(kitchenRepositoryProvider).insert(i);
    }
    c.invalidate(kitchenProvider);
    await tester.tap(find.bySemanticsLabel('Nutrition').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Kitchen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start monthly review'));
    await tester.pumpAndSettle();

    // 1 — spoiled, stays on the shopping list (default on).
    expect(find.text('Item 1 of 3 · Baby spinach'), findsOneWidget);
    await tester.tap(find.text('Spoiled — remove it'));
    await tester.pumpAndSettle();
    expect(find.text('Add to shopping list'), findsOneWidget);
    await tester.tap(find.text('Continue review'));
    await tester.pumpAndSettle();

    // 2 — still have it, quantity updated.
    expect(find.text('Item 2 of 3 · Eggs'), findsOneWidget);
    await tester.tap(find.text('Still have it — update quantity'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '6');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Eggs — 6 pcs'), findsOneWidget);
    await tester.tap(find.text('Continue review'));
    await tester.pumpAndSettle();

    // 3 — used up, not added to the list.
    expect(find.text('Item 3 of 3 · Rice'), findsOneWidget);
    await tester.tap(find.text('We ate it / used it up'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to shopping list'));
    await tester.tap(find.text('Finish review'));
    await tester.pumpAndSettle();
    expect(find.text('Review complete'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('My Kitchen'), findsOneWidget);

    final active = await c.read(kitchenRepositoryProvider).active();
    expect(active.map((i) => (i.name, i.quantity)), [('Eggs', 6.0)]);
    final list = await c.read(reviewRepositoryProvider).shoppingList();
    expect(list.map((s) => s.name), ['Baby spinach']);
    final reviews = await c.read(reviewRepositoryProvider).reviews();
    expect(reviews.single.completedAt, isNotNull);
    expect(reviews.single.changes.map((ch) => (ch.name, ch.action, ch.newQuantity)), [
      ('Baby spinach', ReviewAction.spoiled, null),
      ('Eggs', ReviewAction.kept, 6.0),
      ('Rice', ReviewAction.usedUp, null),
    ]);
  });

  testWidgets('shopping list: add, dedupe, tick and clear', (tester) async {
    await pumpApp(tester);
    tester.view.physicalSize = const Size(390, 2600);
    final c = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    await tester.tap(find.bySemanticsLabel('Nutrition').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Kitchen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shopping list'));
    await tester.pumpAndSettle();
    expect(find.text('Your shopping list is empty.'), findsOneWidget);

    for (final name in ['Oats', 'oats ', 'Milk']) {
      await tester.enterText(find.byType(TextField).last, name);
      await tester.tap(find.byTooltip('Add'));
      await tester.pumpAndSettle();
    }
    expect(find.text('2 items to buy'), findsOneWidget);
    await tester.tap(find.text('Oats'));
    await tester.pumpAndSettle();
    expect(find.text('1 item to buy'), findsOneWidget);
    await tester.tap(find.text('Clear ticked items'));
    await tester.pumpAndSettle();
    expect((await c.read(reviewRepositoryProvider).shoppingList()).map((s) => s.name), ['Milk']);
  });

  testWidgets('monthly review reminder is off by default and toggles from Settings', (tester) async {
    await pumpApp(tester);
    tester.view.physicalSize = const Size(390, 2600);
    final c = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    final fake = c.read(notificationServiceProvider) as FakeNotifications;
    await tester.tap(find.bySemanticsLabel('Settings').last);
    await tester.pumpAndSettle();
    expect(fake.scheduled.containsKey(NotificationService.monthlyReviewId), isFalse);

    await tester.tap(find.text('Monthly kitchen review'));
    await tester.pumpAndSettle();
    expect(fake.scheduled.containsKey(NotificationService.monthlyReviewId), isTrue);
    final prefs = await c.read(settingsRepositoryProvider).notificationPrefs();
    expect(prefs.firstWhere((p) => p.type == NotificationType.monthlyReview).enabled, isTrue);

    await tester.tap(find.text('Review my kitchen now'));
    await tester.pumpAndSettle();
    expect(find.text('Your kitchen is empty — add what you have and review it next month.'), findsOneWidget);
  });
}
