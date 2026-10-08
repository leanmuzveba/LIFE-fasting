import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ruva_kit.dart';
import '../../core/widgets/ruva_logo.dart';
import '../../core/widgets/sheet.dart';
import '../../domain/kitchen.dart';
import '../../domain/kitchen_review.dart';
import '../../state/providers.dart';
import 'ingredient_form_screen.dart';
import 'kitchen_labels.dart';
import 'shopping_list_sheet.dart';

enum _Choice { keep, usedUp, spoiled }

/// Monthly kitchen review (RUVA design, PRD §6): one item at a time — still
/// have it (update quantity), used it up, or spoiled — plus new purchases and
/// the shopping list. Each decision is saved immediately and recorded.
class KitchenReviewScreen extends ConsumerStatefulWidget {
  const KitchenReviewScreen({super.key});

  @override
  ConsumerState<KitchenReviewScreen> createState() => _KitchenReviewScreenState();
}

class _KitchenReviewScreenState extends ConsumerState<KitchenReviewScreen> {
  List<Ingredient>? _queue;
  int? _reviewId;
  int _index = 0;
  _Choice? _choice;
  double? _keptQuantity;
  bool _addToList = true;
  final List<String> _purchases = [];

  DateTime get _today {
    final t = ref.read(clockProvider)().toLocal();
    return DateTime(t.year, t.month, t.day);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final items = await ref.read(kitchenProvider.future);
      final queue = reviewQueue(items, _today);
      final id = queue.isEmpty ? null : await ref.read(reviewActionsProvider).start();
      if (mounted) {
        setState(() {
          _queue = queue;
          _reviewId = id;
        });
      }
    });
  }

  Future<void> _askQuantity(Ingredient item) async {
    final value = await showAppSheet<double>(context, (_) => _QuantitySheet(item: item));
    if (value != null && mounted) {
      setState(() {
        _choice = _Choice.keep;
        _keptQuantity = value;
      });
    }
  }

  Future<void> _continue() async {
    final item = _queue![_index];
    final actions = ref.read(reviewActionsProvider);
    final id = _reviewId!;
    switch (_choice!) {
      case _Choice.keep:
        await actions.keep(id, item, _keptQuantity ?? item.quantity);
      case _Choice.usedUp:
        await actions.usedUp(id, item, addToList: _addToList);
      case _Choice.spoiled:
        await actions.spoiled(id, item, addToList: _addToList);
    }
    if (_index >= _queue!.length - 1) {
      await actions.complete(id);
      if (mounted) await _showDone();
      return;
    }
    setState(() {
      _index++;
      _choice = null;
      _keptQuantity = null;
      _addToList = true;
    });
  }

  Future<void> _showDone() async {
    final l = context.l10n;
    await showAppSheet<void>(
      context,
      (ctx) => Gap16Column(
        children: [
          const Center(child: IconBubble(icon: Icons.check, size: 48)),
          Semantics(
            header: true,
            child: Text(l.reviewDoneTitle, textAlign: TextAlign.center, style: AppText.title),
          ),
          Text(l.reviewDoneBody, textAlign: TextAlign.center, style: AppText.body),
          PrimaryButton(label: l.done, onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _addPurchase() async {
    final before = (await ref.read(kitchenProvider.future)).map((i) => i.id).toSet();
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const IngredientFormScreen()));
    final after = await ref.read(kitchenProvider.future);
    setState(() => _purchases.addAll(after.where((i) => !before.contains(i.id)).map((i) => i.name)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final queue = _queue;
    final shopping = ref.watch(shoppingListProvider).value?.where((i) => !i.checked).length ?? 0;
    final header = Row(
      children: [
        IconButton(
          tooltip: l.back,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.chevron_left_rounded, size: 30, color: AppColors.primary),
        ),
        const Spacer(),
        const RuvaLogo(size: 40, semanticLabel: null),
      ],
    );

    if (queue == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (queue.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Semantics(
                    header: true,
                    child: Text(l.reviewTitle, style: AppText.title.copyWith(fontSize: 24)),
                  ),
                ),
                const Spacer(),
                Text(l.reviewEmpty, textAlign: TextAlign.center, style: AppText.body),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }

    final item = queue[_index];
    final purchased = item.purchasedOn == null
        ? null
        : l.reviewPurchased(DateFormat('d MMM').format(item.purchasedOn!));
    final last = _index >= queue.length - 1;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 20, 32),
          children: [
            header,
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 14),
                  MonoLabel(l.reviewEyebrow),
                  const SizedBox(height: 6),
                  Semantics(header: true, child: Text(l.reviewTitle, style: AppText.title.copyWith(fontSize: 24))),
                  const SizedBox(height: 6),
                  Text(
                    l.reviewProgress(_index + 1, queue.length, item.name),
                    style: AppText.dateLine.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  ForestCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          label: l.reviewProgress(_index + 1, queue.length, item.name),
                          excludeSemantics: true,
                          child: Row(
                            children: [
                              for (var i = 0; i < queue.length; i++) ...[
                                if (i > 0) const SizedBox(width: 6),
                                Expanded(
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: i <= _index ? AppColors.accent : const Color(0x33FFFFFF),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(l.reviewCardText, style: AppText.body.copyWith(fontSize: 15, color: AppColors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  RuvaCard(
                    bordered: true,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconBubble(
                              icon: categoryIcon(
                                item.categories.isEmpty ? IngredientCategory.pantry : item.categories.first,
                              ),
                              size: 54,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.name} — ${formatQuantity(_keptQuantity ?? item.quantity, item.unit)}',
                                    style: AppText.cardValue.copyWith(fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      stateLabel(l, item.state),
                                      ?purchased,
                                      ?expiryTextFor(l, item.expiresOn, _today),
                                    ].join(' · '),
                                    style: AppText.small.copyWith(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(
                          l.reviewQuestion,
                          style: AppText.title.copyWith(fontSize: 17, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 14),
                        _ChoiceButton(
                          icon: Icons.edit_outlined,
                          label: l.reviewKeep,
                          background: AppColors.lime200,
                          foreground: AppColors.primary,
                          selected: _choice == _Choice.keep,
                          onTap: () => _askQuantity(item),
                        ),
                        const SizedBox(height: 10),
                        _ChoiceButton(
                          icon: Icons.check_circle_outline,
                          label: l.reviewUsedUp,
                          background: const Color(0xFFDDF4E6),
                          foreground: const Color(0xFF1E7A4A), // success, darkened for text contrast
                          selected: _choice == _Choice.usedUp,
                          onTap: () => setState(() => _choice = _Choice.usedUp),
                        ),
                        const SizedBox(height: 10),
                        _ChoiceButton(
                          icon: Icons.delete_outline,
                          label: l.reviewSpoiled,
                          background: const Color(0xFFFCE3DE),
                          foreground: AppColors.errorText,
                          selected: _choice == _Choice.spoiled,
                          onTap: () => setState(() => _choice = _Choice.spoiled),
                        ),
                        if (_choice == _Choice.usedUp || _choice == _Choice.spoiled)
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: AppColors.primary,
                            value: _addToList,
                            onChanged: (v) => setState(() => _addToList = v ?? false),
                            title: Text(l.reviewAddToList, style: AppText.body),
                          ),
                        const SizedBox(height: 14),
                        Text(l.reviewNoWrongAnswers, style: AppText.small),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  MonoLabel(l.reviewAddPurchases),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in _purchases) RuvaChip(label: p, icon: Icons.check, selected: true),
                      RuvaChip(label: l.reviewAddPurchase, icon: Icons.add, selected: false, onTap: _addPurchase),
                    ],
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: last ? l.reviewFinish : l.reviewContinue,
                    onPressed: _choice == null ? null : _continue,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => showShoppingList(context),
                      child: Text(l.reviewPreviewList(shopping)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Owns its controller so it outlives the sheet's closing animation.
class _QuantitySheet extends StatefulWidget {
  const _QuantitySheet({required this.item});
  final Ingredient item;

  @override
  State<_QuantitySheet> createState() => _QuantitySheetState();
}

class _QuantitySheetState extends State<_QuantitySheet> {
  late final _controller = TextEditingController(text: formatQuantity(widget.item.quantity, '').trim());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Gap16Column(
      children: [
        Semantics(header: true, child: Text(l.reviewUpdateQuantity(widget.item.name), style: AppText.title)),
        RuvaTextField(
          controller: _controller,
          label: '${l.ingredientQuantity} (${widget.item.unit})',
          bold: true,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        PrimaryButton(
          label: l.save,
          onPressed: () {
            final v = double.tryParse(_controller.text.trim().replaceAll(',', '.'));
            if (v != null && v >= 0) Navigator.pop(context, v);
          },
        ),
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    inMutuallyExclusiveGroup: true,
    label: label,
    excludeSemantics: true,
    child: Material(
      color: background,
      shape: StadiumBorder(side: BorderSide(color: selected ? foreground : Colors.transparent, width: 2)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(selected ? Icons.radio_button_checked : icon, color: foreground, size: 20),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(label, style: AppText.link.copyWith(color: foreground, fontSize: 15)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
