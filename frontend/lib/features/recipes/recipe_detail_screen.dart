import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ruva_kit.dart';
import '../../core/widgets/sheet.dart';
import '../../domain/food.dart';
import '../../domain/kitchen.dart';
import '../../domain/profile.dart';
import '../../domain/recipe.dart';
import '../food/food_labels.dart';
import '../settings/settings_screen.dart' show dietLabel;
import '../../state/providers.dart';
import 'recipes_screen.dart' show RecipeImage;

/// One recipe (RUVA design, PRD v1.2 §5.2): what you have and what's missing,
/// substitutions, batch scaling, steps, mark as cooked and log to the diary.
class RecipeDetailScreen extends ConsumerStatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipe});
  final Recipe recipe;

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  static const _batches = [0.5, 1.0, 2.0, 3.0];
  double _batch = 1;

  DateTime get _today {
    final t = ref.read(clockProvider)().toLocal();
    return DateTime(t.year, t.month, t.day);
  }

  Future<void> _markCooked() async {
    await ref.read(recipeActionsProvider).markCooked(widget.recipe, _batch);
    if (mounted) showRuvaSnack(context, context.l10n.recipeCooked);
  }

  Future<void> _log() async {
    final l = context.l10n;
    final meal = await showAppSheet<Meal>(
      context,
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MonoLabel(l.recipeLog),
          const SizedBox(height: 6),
          Semantics(header: true, child: Text(l.recipeLogWhich, style: AppText.title)),
          const SizedBox(height: 8),
          for (final m in Meal.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: IconBubble(icon: mealIcon(m), size: 40),
              title: Text(mealLabel(l, m), style: AppText.cardValue.copyWith(fontSize: 15)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              onTap: () => Navigator.pop(ctx, m),
            ),
        ],
      ),
    );
    if (meal == null || !mounted) return;
    final ok = await ref
        .read(recipeActionsProvider)
        .logToDiary(widget.recipe, meal, ref.read(clockProvider)(), servingLabel: l.recipeServing);
    if (!mounted) return;
    final name = mealLabel(l, meal);
    showRuvaSnack(context, ok ? l.recipeLogged(name) : l.recipeAlreadyLogged(name));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = widget.recipe;
    final today = _today;
    final kitchen = ref.watch(kitchenProvider).value ?? const <Ingredient>[];
    final match = RecipeMatch(r, kitchen, today);
    final saved = ref.watch(savedRecipesProvider).value?.contains(r.id) ?? false;
    final labels = [
      for (final d in [DietPreference.vegan, DietPreference.vegetarian])
        if (fitsDiet(r, d)) dietLabel(l, d),
    ].take(1);
    final tags = [r.category, r.area, ...labels].where((t) => t.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Stack(
                  children: [
                    RecipeImage(url: r.thumb, height: 300 + MediaQuery.paddingOf(context).top, preview: false),
                    Positioned(
                      left: 16,
                      top: MediaQuery.paddingOf(context).top + 12,
                      child: RoundIconButton(
                        icon: Icons.chevron_left,
                        onTap: () => Navigator.of(context).maybePop(),
                        tooltip: l.back,
                        size: 44,
                        background: AppColors.white,
                        foreground: AppColors.text,
                      ),
                    ),
                    Positioned(
                      right: 16,
                      top: MediaQuery.paddingOf(context).top + 12,
                      child: RoundIconButton(
                        icon: saved ? Icons.favorite : Icons.favorite_border,
                        onTap: () => ref.read(recipeActionsProvider).setSaved(r, !saved),
                        tooltip: saved ? l.recipesUnsave : l.recipesSave,
                        size: 44,
                        background: AppColors.white,
                        foreground: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(header: true, child: Text(r.name, style: AppText.title.copyWith(fontSize: 21))),
                        if (tags.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [for (final t in tags) RuvaChip(label: t, selected: false)],
                          ),
                        ],
                        const SizedBox(height: 22),
                        MonoLabel(l.recipeBatch),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final b in _batches)
                              RuvaChip(
                                label: '${b == 0.5 ? '½' : b.round()}×',
                                outlined: true,
                                selected: _batch == b,
                                onTap: () => setState(() => _batch = b),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(l.recipeBatchHint, style: AppText.small.copyWith(fontSize: 12.5)),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: MonoLabel(l.recipeIngredients)),
                            MonoLabel(l.recipeTotal(r.ingredients.length)),
                          ],
                        ),
                        if (match.available.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _GroupLabel(label: l.recipeAvailable, count: match.available.length),
                          const SizedBox(height: 8),
                          _IngredientList(items: match.available, batch: _batch, missing: false),
                        ],
                        if (match.missing.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _GroupLabel(label: l.recipeMissing, count: match.missing.length, missing: true),
                          const SizedBox(height: 8),
                          _IngredientList(items: match.missing, batch: _batch, missing: true),
                          for (final m in match.missing)
                            if (substituteFor(m, kitchen, today) case final sub?)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.lime200,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.swap_horiz, color: AppColors.primary),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          l.recipeSubstitute(m.name.toLowerCase(), sub.name.toLowerCase()),
                                          style: AppText.body.copyWith(fontSize: 13.5, color: AppColors.primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                              onPressed: () async {
                                final n = await ref.read(recipeActionsProvider).addToShoppingList(match.missing);
                                if (context.mounted) showRuvaSnack(context, l.recipeAddedMissing(n));
                              },
                              icon: const Icon(Icons.add_shopping_cart),
                              label: Text(l.recipeAddMissing),
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        MonoLabel(l.recipeSteps),
                        const SizedBox(height: 12),
                        for (final (i, step) in r.steps.indexed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                  child: Text(
                                    '${i + 1}',
                                    style: AppText.cardValue.copyWith(fontSize: 13, color: AppColors.accent),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(child: Text(step, style: AppText.body.copyWith(fontSize: 15))),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        ForestCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.recipeNutrition,
                                style: AppText.title.copyWith(fontSize: 15, color: AppColors.white),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l.recipeNutritionNone,
                                style: AppText.body.copyWith(fontSize: 13.5, color: onForestMuted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(l.recipesAllergyGeneric, style: AppText.small.copyWith(fontSize: 12.5)),
                        const SizedBox(height: 6),
                        Text(l.recipeSource, style: AppText.small.copyWith(fontSize: 12.5)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Column(
                  children: [
                    PrimaryButton(label: l.recipeMarkCooked, onPressed: _markCooked),
                    const SizedBox(height: 10),
                    PrimaryButton(label: l.recipeLog, light: true, onPressed: _log),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.label, required this.count, this.missing = false});
  final String label;
  final int count;
  final bool missing;

  @override
  Widget build(BuildContext context) {
    final color = missing ? AppColors.errorText : AppColors.primary;
    return Row(
      children: [
        Text(label, style: AppText.cardValue.copyWith(fontSize: 15, color: color)),
        const SizedBox(width: 8),
        Icon(Icons.circle, size: 7, color: color),
        const SizedBox(width: 8),
        Text('$count', style: AppText.cardValue.copyWith(fontSize: 15, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _IngredientList extends StatelessWidget {
  const _IngredientList({required this.items, required this.batch, required this.missing});
  final List<RecipeIngredient> items;
  final double batch;
  final bool missing;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: missing ? const Color(0xFFFDF1EE) : AppColors.background,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: missing ? const Color(0xFFF6D5CC) : AppColors.track),
    ),
    child: Column(
      children: [
        for (final (i, ing) in items.indexed) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.divider, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  missing ? Icons.close : Icons.check,
                  size: 18,
                  color: missing ? AppColors.errorText : AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(ing.name, style: AppText.body.copyWith(fontSize: 15))),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    scaleMeasure(ing.measure, batch),
                    textAlign: TextAlign.end,
                    style: AppText.small.copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
