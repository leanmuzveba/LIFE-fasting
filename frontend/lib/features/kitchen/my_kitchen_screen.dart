import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ruva_kit.dart';
import '../../core/widgets/ruva_logo.dart';
import '../../domain/kitchen.dart';
import '../../state/providers.dart';
import 'ingredient_form_screen.dart';
import 'kitchen_labels.dart';
import 'kitchen_review_screen.dart';
import 'shopping_list_sheet.dart';

enum _Flag { none, expiring, lowStock }

/// My Kitchen (RUVA design, PRD §4.3): search, category filters, an overview
/// of expiring and low-stock items, and the inventory list.
class MyKitchenScreen extends ConsumerStatefulWidget {
  const MyKitchenScreen({super.key});

  @override
  ConsumerState<MyKitchenScreen> createState() => _MyKitchenScreenState();
}

class _MyKitchenScreenState extends ConsumerState<MyKitchenScreen> {
  String _query = '';
  IngredientCategory? _category;
  _Flag _flag = _Flag.none;

  void _openForm([Ingredient? item]) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => IngredientFormScreen(existing: item)));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final now = ref.watch(nowProvider).value ?? ref.read(clockProvider)();
    final today = DateTime(now.toLocal().year, now.toLocal().month, now.toLocal().day);
    final all = ref.watch(kitchenProvider).value;
    final items = all ?? const <Ingredient>[];
    final expiring = items.where((i) => i.expiringSoon(today)).toList();
    final low = items.where((i) => i.isLowStock).toList();
    final shown = filterKitchen(
      switch (_flag) {
        _Flag.none => items,
        _Flag.expiring => expiring,
        _Flag.lowStock => low,
      },
      query: _query,
      category: _category,
    ).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'kitchen-fab',
        onPressed: _openForm,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add, color: AppColors.accent),
        label: Text(l.kitchenAddIngredient, style: AppText.link.copyWith(color: AppColors.white)),
        shape: const StadiumBorder(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 110),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Navigator.of(context).canPop()
                        ? IconButton(
                            tooltip: l.back,
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.chevron_left_rounded, size: 30, color: AppColors.primary),
                          )
                        : null,
                  ),
                  const Expanded(child: Center(child: RuvaLogo(size: 40, semanticLabel: null))),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MonoLabel(l.kitchenEyebrow),
                  const SizedBox(height: 4),
                  Semantics(
                    header: true,
                    child: Text(l.kitchenTitle, style: AppText.title.copyWith(fontSize: 27, height: 1.1)),
                  ),
                  const SizedBox(height: 18),
                  SearchField(hint: l.kitchenSearch, onChanged: (v) => setState(() => _query = v)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ChipRow(
              children: [
                RuvaChip(
                  label: l.kitchenAll,
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                for (final c in IngredientCategory.values)
                  RuvaChip(
                    label: categoryLabel(l, c),
                    icon: categoryIcon(c),
                    selected: _category == c,
                    onTap: () => setState(() => _category = _category == c ? null : c),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ForestCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: MonoLabel(l.kitchenOverview, color: AppColors.accent, size: 10)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                l.kitchenItems(items.length),
                                style: AppText.link.copyWith(fontSize: 13, color: AppColors.primaryDark),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          items.isEmpty
                              ? l.kitchenEmptyOverview
                              : low.length > 3
                              ? l.kitchenShoppingTrip
                              : l.kitchenWellStocked,
                          style: AppText.title.copyWith(
                            fontSize: 19,
                            color: AppColors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _OverviewTile(
                                icon: Icons.schedule,
                                iconColor: AppColors.warning,
                                label: l.kitchenExpiringSoon,
                                value: l.kitchenItems(expiring.length),
                                selected: _flag == _Flag.expiring,
                                onTap: () =>
                                    setState(() => _flag = _flag == _Flag.expiring ? _Flag.none : _Flag.expiring),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _OverviewTile(
                                icon: Icons.warning_amber_rounded,
                                iconColor: const Color(0xFFFF9B85), // coral, lightened for 3:1 on forest
                                label: l.kitchenLowStock,
                                value: l.kitchenItems(low.length),
                                selected: _flag == _Flag.lowStock,
                                onTap: () =>
                                    setState(() => _flag = _flag == _Flag.lowStock ? _Flag.none : _Flag.lowStock),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 4,
                          children: [
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.accent,
                                minimumSize: const Size(48, 48),
                              ),
                              onPressed: () =>
                                  Navigator.of(context)
                                      .push(MaterialPageRoute<void>(builder: (_) => const KitchenReviewScreen())),
                              icon: const Icon(Icons.fact_check_outlined, size: 20),
                              label: Text(l.kitchenStartReview),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.accent,
                                minimumSize: const Size(48, 48),
                              ),
                              onPressed: () => showShoppingList(context),
                              icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                              label: Text(l.shoppingTitle),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  MonoLabel(l.kitchenInYourKitchen(shown.length)),
                  const SizedBox(height: 14),
                  if (all != null && shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        items.isEmpty ? l.kitchenNothingHere : l.kitchenNoMatches,
                        textAlign: TextAlign.center,
                        style: AppText.small,
                      ),
                    ),
                  for (final item in shown) ...[
                    _KitchenItemCard(item: item, today: today, onTap: () => _openForm(item)),
                    const SizedBox(height: 14),
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

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '$label: $value',
    excludeSemantics: true,
    child: Material(
      color: selected ? const Color(0x33FFFFFF) : const Color(0x14FFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: selected ? AppColors.accent : const Color(0x1FFFFFFF)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 16),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.link.copyWith(fontSize: 13, color: AppColors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: AppText.cardValue.copyWith(color: AppColors.white)),
            ],
          ),
        ),
      ),
    ),
  );
}

class _KitchenItemCard extends StatelessWidget {
  const _KitchenItemCard({required this.item, required this.today, required this.onTap});
  final Ingredient item;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final expiry = item.expiringSoon(today) ? expiryTextFor(l, item.expiresOn, today) : null;
    final quantity = formatQuantity(item.quantity, item.unit);
    final state = stateLabel(l, item.state);
    final cat = item.categories.isEmpty ? IngredientCategory.pantry : item.categories.first;
    return RuvaCard(
      bordered: true,
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Semantics(
        button: true,
        label: [
          l.kitchenItemSemantics(item.name, quantity, state),
          if (item.isLowStock) l.kitchenLowStock,
          ?expiry,
        ].join('. '),
        excludeSemantics: true,
        child: Column(
          children: [
            Row(
              children: [
                IconBubble(
                  icon: categoryIcon(cat),
                  size: 54,
                  background: AppColors.primary,
                  foreground: AppColors.accent,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: AppText.cardValue.copyWith(fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(quantity, style: AppText.body.copyWith(fontSize: 14, color: AppColors.textSecondary)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.lime200, borderRadius: BorderRadius.circular(6)),
                            child: Text(state.toUpperCase(), style: AppText.overline.copyWith(fontSize: 9)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (item.isLowStock) const Icon(Icons.warning_amber_rounded, color: AppColors.errorText, size: 22),
              ],
            ),
            if (expiry != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFDDF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF6E7A8)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, size: 18, color: AppColors.fatBurningIcon),
                    const SizedBox(width: 8),
                    Expanded(child: Text(expiry, style: AppText.body.copyWith(fontSize: 13))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
