import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ruva_kit.dart';
import '../../core/widgets/ruva_logo.dart';
import '../../domain/profile.dart';
import '../../domain/recipe.dart';
import '../../state/providers.dart';
import '../settings/settings_screen.dart' show allergenLabel, dietLabel;
import 'recipe_detail_screen.dart';

enum _Show { all, ready, expiring, saved }

/// Smart Recipe Planner (RUVA design, PRD v1.2 §5): what you can make with
/// your kitchen, from TheMealDB, filtered by diet and never showing recipes
/// with a recorded allergen.
class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  final _search = TextEditingController();
  String _query = '';
  _Show _show = _Show.all;
  DietPreference? _diet; // null = follow Settings

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _showLabel(AppLocalizations l, _Show s) => switch (s) {
    _Show.all => l.recipesShowAll,
    _Show.ready => l.recipesShowReady,
    _Show.expiring => l.recipesShowExpiring,
    _Show.saved => l.recipesShowSaved,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = ref.watch(settingsProvider).value;
    final diet = _diet ?? settings?.diet ?? DietPreference.none;
    final allergies = settings?.allergies ?? const <Allergen>{};
    final kitchen = ref.watch(kitchenProvider).value ?? const [];
    final saved = ref.watch(savedRecipesProvider).value ?? const <String>{};
    final cooked = ref.watch(lastCookedProvider).value ?? const <String, DateTime>{};
    final source = _query.isEmpty ? ref.watch(recipeSuggestionsProvider) : ref.watch(recipeSearchProvider(_query));
    final all = source.value ?? const <RecipeMatch>[];
    final shown = [
      for (final m in all)
        if (fitsDiet(m.recipe, diet) &&
            switch (_show) {
              _Show.all => true,
              _Show.ready => m.complete,
              _Show.expiring => m.usesExpiring > 0,
              _Show.saved => saved.contains(m.recipe.id),
            })
          m,
    ];

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(recipeSuggestionsProvider);
            if (_query.isNotEmpty) ref.invalidate(recipeSearchProvider(_query));
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              ScreenHeader(
                eyebrow: l.navNutrition,
                title: l.recipesTitle,
                centered: true,
                trailing: const RuvaLogo(size: 34, semanticLabel: null),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ForestCard(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Positioned(
                            right: -26,
                            bottom: -34,
                            child: Icon(Icons.soup_kitchen_outlined, size: 120, color: Color(0x1AFFFFFF)),
                          ),
                          const Positioned(
                            right: 0,
                            top: 0,
                            child: Icon(Icons.auto_awesome, color: AppColors.accent, size: 24),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MonoLabel(l.recipesEyebrow, color: AppColors.accent, size: 10),
                              const SizedBox(height: 8),
                              Semantics(
                                header: true,
                                child: Text(
                                  l.recipesHero,
                                  style: AppText.title.copyWith(fontSize: 26, color: AppColors.white),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l.recipesHeroSub(l.kitchenItems(kitchen.length), l.recipesFound(shown.length)),
                                style: AppText.body.copyWith(color: onForestMuted, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.recipesTagline,
                      textAlign: TextAlign.center,
                      style: AppText.small.copyWith(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 16),
                    SearchField(
                      hint: l.recipesSearch,
                      controller: _search,
                      onChanged: (v) {
                        if (v.trim().isEmpty && _query.isNotEmpty) setState(() => _query = '');
                      },
                      onSubmitted: (v) => setState(() => _query = v.trim()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _FilterRow(
                label: l.recipesShow,
                children: [
                  for (final s in _Show.values)
                    RuvaChip(label: _showLabel(l, s), selected: _show == s, onTap: () => setState(() => _show = s)),
                ],
              ),
              const SizedBox(height: 8),
              _FilterRow(
                label: l.recipesDiet,
                children: [
                  for (final d in DietPreference.values)
                    RuvaChip(
                      label: d == DietPreference.none ? l.recipesDietAny : dietLabel(l, d),
                      selected: diet == d,
                      onTap: () => setState(() => _diet = d),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Note(
                      icon: Icons.health_and_safety_outlined,
                      text: allergies.isEmpty
                          ? l.recipesAllergyGeneric
                          : l.recipesAllergyNote(allergies.map((a) => allergenLabel(l, a)).join(', ')),
                    ),
                    const SizedBox(height: 18),
                    if (source.isLoading && all.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (source.hasError && all.isEmpty)
                      Column(
                        children: [
                          Text(l.recipesOffline, textAlign: TextAlign.center, style: AppText.small),
                          TextButton(
                            onPressed: () => _query.isEmpty
                                ? ref.invalidate(recipeSuggestionsProvider)
                                : ref.invalidate(recipeSearchProvider(_query)),
                            child: Text(l.recipesRetry),
                          ),
                        ],
                      )
                    else if (_query.isEmpty && kitchen.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l.recipesEmptyKitchen, textAlign: TextAlign.center, style: AppText.small),
                      )
                    else if (shown.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l.recipesNone, textAlign: TextAlign.center, style: AppText.small),
                      ),
                    for (final m in shown) ...[
                      _RecipeCard(
                        match: m,
                        saved: saved.contains(m.recipe.id),
                        cooked: cooked[m.recipe.id],
                        onSave: () => ref.read(recipeActionsProvider).setSaved(m.recipe, !saved.contains(m.recipe.id)),
                        onTap: () =>
                            Navigator.of(context)
                                .push(MaterialPageRoute<void>(builder: (_) => RecipeDetailScreen(recipe: m.recipe))),
                      ),
                      const SizedBox(height: 18),
                    ],
                    const SizedBox(height: 4),
                    Text(l.recipesPrivacy, textAlign: TextAlign.center, style: AppText.small.copyWith(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.label, required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 20, right: 4),
        child: Text('$label:', style: AppText.body.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
      ),
      Expanded(
        child: ChipRow(padding: const EdgeInsets.only(left: 8, right: 20), children: children),
      ),
    ],
  );
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: AppText.small.copyWith(fontSize: 12.5))),
    ],
  );
}

/// Recipe photo with a calm fallback (offline or no image).
class RecipeImage extends StatelessWidget {
  const RecipeImage({super.key, required this.url, required this.height, this.preview = true});
  final String? url;
  final double height;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.lime200, AppColors.cream],
        ),
      ),
      child: const Center(child: Icon(Icons.soup_kitchen_outlined, size: 52, color: Color(0x40135D44))),
    );
    if (url == null) return fallback;
    return Image.network(
      preview ? '$url/preview' : url!,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (_, child, progress) => progress == null ? child : fallback,
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.match,
    required this.saved,
    required this.cooked,
    required this.onSave,
    required this.onTap,
  });

  final RecipeMatch match;
  final bool saved;
  final DateTime? cooked;
  final VoidCallback onSave;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = match.recipe;
    final total = r.ingredients.length;
    final have = match.available.length;
    final tags = [r.category, r.area].where((t) => t.isNotEmpty).join(' · ');
    return RuvaCard(
      padding: EdgeInsets.zero,
      radius: 28,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              RecipeImage(url: r.thumb, height: 160),
              Positioned(
                top: 10,
                right: 10,
                child: RoundIconButton(
                  icon: saved ? Icons.favorite : Icons.favorite_border,
                  onTap: onSave,
                  tooltip: saved ? l.recipesUnsave : l.recipesSave,
                  background: AppColors.white,
                  foreground: AppColors.primary,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name, style: AppText.cardValue.copyWith(fontSize: 18)),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(tags, style: AppText.small.copyWith(fontSize: 13)),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: match.complete ? AppColors.lime200 : AppColors.cream,
                    borderRadius: BorderRadius.circular(20),
                    border: match.complete ? null : Border.all(color: AppColors.track),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        match.complete ? Icons.check_circle : Icons.info_outline,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l.recipesAvailable(have, total),
                          style: AppText.body.copyWith(fontSize: 13, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                if (match.missing.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l.recipesMissing(match.missing.map((i) => i.name.toLowerCase()).join(', ')),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.small.copyWith(fontSize: 12.5),
                  ),
                ],
                if (match.usesExpiring > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 15, color: AppColors.fatBurningIcon),
                      const SizedBox(width: 6),
                      Text(l.recipesUsesExpiring(match.usesExpiring), style: AppText.small.copyWith(fontSize: 12.5)),
                    ],
                  ),
                ],
                if (cooked != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    l.recipesCookedOn(DateFormat('d MMM').format(cooked!.toLocal())),
                    style: AppText.small.copyWith(fontSize: 12.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
