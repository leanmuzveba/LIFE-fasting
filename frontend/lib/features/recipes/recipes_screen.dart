import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import 'recipe_form_screen.dart';

enum _Show { all, mine, ready, expiring, saved }

/// Smart Recipe Planner (MagnaVita design, PRD v1.2 §5): what you can make with
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
  int _page = 0;
  static const _perPage = 10;
  DietPreference? _diet; // null = follow Settings

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _showLabel(AppLocalizations l, _Show s) => switch (s) {
    _Show.all => l.recipesShowAll,
    _Show.mine => l.recipesShowMine,
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
    final source = _query.isEmpty ? ref.watch(recipeSuggestionsProvider) : ref.watch(recipeSearchProvider(_query));
    // Your own recipes always show (even offline), matched like the rest.
    final t = ref.watch(clockProvider)().toLocal();
    final q = _query.toLowerCase();
    final mine = [
      for (final r in ref.watch(myRecipesProvider).value ?? const <Recipe>[])
        if (r.name.toLowerCase().contains(q) && allergensIn(r).intersection(allergies).isEmpty)
          RecipeMatch(r, kitchen, DateTime(t.year, t.month, t.day)),
    ];
    final online = source.value ?? const <RecipeMatch>[];
    final all = rankMatches([...mine, ...online]);
    final shown = [
      for (final m in all)
        if (fitsDiet(m.recipe, diet) &&
            switch (_show) {
              _Show.all => true,
              _Show.mine => m.recipe.isMine,
              _Show.ready => m.complete,
              _Show.expiring => m.usesExpiring > 0,
              _Show.saved => saved.contains(m.recipe.id),
            })
          m,
    ];

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-recipe',
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RecipeFormScreen())),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.primaryDark,
        icon: const Icon(Icons.add),
        label: Text(l.myRecipeNew, style: AppText.link.copyWith(color: AppColors.primaryDark)),
        shape: const StadiumBorder(),
      ),
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
                                  style: AppText.title.copyWith(fontSize: 21, color: AppColors.white),
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
                      dense: true,
                      onChanged: (v) {
                        if (v.trim().isEmpty && _query.isNotEmpty) setState(() => _query = '');
                      },
                      onSubmitted: (v) => setState(() {
                        _query = v.trim();
                        _page = 0;
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _FilterRow(
                label: l.recipesShow,
                children: [
                  for (final s in _Show.values)
                    RuvaChip(
                      dense: true,
                      label: _showLabel(l, s),
                      selected: _show == s,
                      onTap: () => setState(() {
                        _show = s;
                        _page = 0;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _FilterRow(
                label: l.recipesDiet,
                children: [
                  for (final d in DietPreference.values)
                    RuvaChip(
                      dense: true,
                      label: d == DietPreference.none ? l.recipesDietAny : dietLabel(l, d),
                      selected: diet == d,
                      onTap: () => setState(() {
                        _diet = d;
                        _page = 0;
                      }),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (allergies.isNotEmpty) ...[
                      _Note(
                        icon: Icons.health_and_safety_outlined,
                        text: l.recipesHiding(allergies.map((a) => allergenLabel(l, a)).join(', ')),
                      ),
                      const SizedBox(height: 14),
                    ] else
                      const SizedBox(height: 4),
                    if (source.isLoading && online.isEmpty && _show != _Show.mine)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (source.hasError && online.isEmpty && _show != _Show.mine)
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
                    else if (_show == _Show.mine && shown.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l.recipesMineEmpty, textAlign: TextAlign.center, style: AppText.small),
                      )
                    else if (_query.isEmpty && kitchen.isEmpty && mine.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l.recipesEmptyKitchen, textAlign: TextAlign.center, style: AppText.small),
                      )
                    else if (shown.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l.recipesNone, textAlign: TextAlign.center, style: AppText.small),
                      ),
                    if (shown.isNotEmpty)
                      ...() {
                        final pages = (shown.length / _perPage).ceil();
                        final page = _page.clamp(0, pages - 1);
                        final visible = shown.skip(page * _perPage).take(_perPage).toList();
                        Widget card(RecipeMatch m) => _RecipeCard(
                          match: m,
                          saved: saved.contains(m.recipe.id),
                          onSave: () =>
                              ref.read(recipeActionsProvider).setSaved(m.recipe, !saved.contains(m.recipe.id)),
                          onTap: () =>
                              Navigator.of(context)
                                  .push(MaterialPageRoute<void>(builder: (_) => RecipeDetailScreen(recipe: m.recipe))),
                        );
                        return [
                          for (var r = 0; r < visible.length; r += 2) ...[
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: card(visible[r])),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: r + 1 < visible.length ? card(visible[r + 1]) : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (pages > 1)
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 6,
                              children: [
                                for (var p = 0; p < pages; p++)
                                  RuvaChip(
                                    dense: true,
                                    outlined: true,
                                    label: '${p + 1}',
                                    selected: p == page,
                                    onTap: () => setState(() => _page = p),
                                  ),
                              ],
                            ),
                        ];
                      }(),
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
        child: Text('$label:', style: AppText.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
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
  const RecipeImage({super.key, required this.url, required this.height, this.preview = true, this.bytes});
  final String? url;
  final Uint8List? bytes; // your own photo wins over the URL
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
    if (bytes != null) {
      return Image.memory(
        bytes!,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
      );
    }
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
  const _RecipeCard({required this.match, required this.saved, required this.onSave, required this.onTap});

  final RecipeMatch match;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = match.recipe;
    final have = l.recipesHaveShort(match.available.length, r.ingredients.length);
    return Semantics(
      container: true,
      button: true,
      label: '${r.name}. $have${r.isMine ? '. ${l.myRecipeBadge}' : ''}',
      child: RuvaCard(
        padding: EdgeInsets.zero,
        radius: 18,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                RecipeImage(url: r.thumb, bytes: r.image, height: 96),
                Positioned(
                  top: 0,
                  right: 0,
                  child: RoundIconButton(
                    icon: saved ? Icons.favorite : Icons.favorite_border,
                    onTap: onSave,
                    tooltip: saved ? l.recipesUnsave : l.recipesSave,
                    size: 32,
                    background: AppColors.white,
                    foreground: AppColors.primary,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Text(
                      r.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.cardValue.copyWith(fontSize: 14, height: 1.25),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ExcludeSemantics(
                    child: Row(
                      children: [
                        Icon(
                          match.complete ? Icons.check_circle : Icons.info_outline,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(have, style: AppText.small.copyWith(fontSize: 11.5, color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ),
                  if (r.isMine || match.usesExpiring > 0) ...[
                    const SizedBox(height: 4),
                    ExcludeSemantics(
                      child: Text(
                        r.isMine ? l.myRecipeBadge : l.recipesUsesExpiring(match.usesExpiring),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.small.copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
