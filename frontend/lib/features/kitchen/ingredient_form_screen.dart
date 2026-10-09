import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/ruva_kit.dart';
import '../../core/widgets/ruva_logo.dart';
import '../../core/widgets/sheet.dart';
import '../../domain/kitchen.dart';
import '../../state/providers.dart';
import 'kitchen_labels.dart';

/// Add / Edit Ingredient (RUVA design, PRD §4.2): name, one or more
/// categories, quantity + unit, state, optional dates, low-stock level,
/// brand and notes. Editing also offers Mark as finished and Remove.
class IngredientFormScreen extends ConsumerStatefulWidget {
  const IngredientFormScreen({super.key, this.existing});
  final Ingredient? existing;

  @override
  ConsumerState<IngredientFormScreen> createState() => _IngredientFormScreenState();
}

class _IngredientFormScreenState extends ConsumerState<IngredientFormScreen> {
  late final Ingredient? _e = widget.existing;
  late final _name = TextEditingController(text: _e?.name ?? '');
  late final _qty = TextEditingController(text: _e == null ? '' : _num(_e.quantity));
  late final _low = TextEditingController(text: _e?.lowStockAt == null ? '' : _num(_e!.lowStockAt!));
  late final _brand = TextEditingController(text: _e?.brand ?? '');
  late final _notes = TextEditingController(text: _e?.notes ?? '');
  late Set<IngredientCategory> _categories = {...?_e?.categories};
  late FoodState _state = _e?.state ?? FoodState.fresh;
  late String _unit = _e?.unit ?? 'g';
  late DateTime? _purchased = _e?.purchasedOn ?? _today();
  late DateTime? _expires = _e?.expiresOn;
  String? _error;

  bool get _editing => _e?.id != null; // a draft from a scan has no id yet

  static String _num(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  DateTime _today() {
    final t = ref.read(clockProvider)().toLocal();
    return DateTime(t.year, t.month, t.day);
  }

  @override
  void dispose() {
    for (final c in [_name, _qty, _low, _brand, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({required bool purchased}) async {
    final today = _today();
    final initial = (purchased ? _purchased : _expires) ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(today.year - 5),
      lastDate: purchased ? today : DateTime(today.year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (purchased) {
        _purchased = picked;
      } else {
        _expires = picked;
      }
      _error = null;
    });
  }

  double? _parse(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    final l = context.l10n;
    final now = ref.read(clockProvider)().toUtc();
    final qty = _parse(_qty.text);
    final low = _low.text.trim().isEmpty ? null : _parse(_low.text) ?? double.nan;
    final item = Ingredient(
      id: _e?.id,
      name: _name.text.trim(),
      categories: _categories,
      quantity: qty ?? double.nan,
      unit: _unit,
      state: _state,
      purchasedOn: _purchased,
      expiresOn: _expires,
      lowStockAt: low,
      brand: _brand.text,
      notes: _notes.text,
      status: _e?.status ?? IngredientStatus.active,
      statusAt: _e?.statusAt,
      createdAt: _e?.createdAt ?? now,
      updatedAt: now,
    );
    final error = await ref.read(kitchenActionsProvider).save(item);
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = errorLabel(l, error));
      return;
    }
    showRuvaSnack(context, l.ingredientSaved(item.name));
    Navigator.of(context).pop();
  }

  Future<void> _finish() async {
    final l = context.l10n;
    await ref.read(kitchenActionsProvider).markFinished(_e!);
    if (!mounted) return;
    showRuvaSnack(context, l.ingredientFinished(_e.name));
    Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    final l = context.l10n;
    final ok = await showAppSheet<bool>(
      context,
      (ctx) => Gap16Column(
        children: [
          Semantics(header: true, child: Text(l.ingredientRemoveConfirm(_e!.name), style: AppText.title)),
          Text(l.ingredientRemoveBody, style: AppText.body.copyWith(color: AppColors.textSecondary)),
          Row(
            children: [
              Expanded(
                child: PillButton(label: l.cancel, outlined: true, onPressed: () => Navigator.pop(ctx, false)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PillButton(label: l.delete, onPressed: () => Navigator.pop(ctx, true)),
              ),
            ],
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(kitchenActionsProvider).delete(_e!);
    if (!mounted) return;
    showRuvaSnack(context, l.ingredientRemoved(_e.name));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final today = _today();
    final expiry = expiryTextFor(l, _expires, today);
    final dateFmt = DateFormat('d MMM y');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 24),
                children: [
                  ScreenHeader(
                    eyebrow: l.kitchenTitle,
                    title: _editing ? l.ingredientEditTitle : l.ingredientAddTitle,
                    trailing: const RuvaLogo(size: 36, semanticLabel: null),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ForestCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MonoLabel(l.ingredientStatusEyebrow, color: onForestMuted, size: 10),
                                const SizedBox(height: 8),
                                Text(
                                  _editing ? l.ingredientUpdate : l.ingredientNewEntry,
                                  style: AppText.title.copyWith(fontSize: 17, color: AppColors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _editing ? l.ingredientUpdateSub : l.ingredientNewEntrySub,
                                  style: AppText.body.copyWith(fontSize: 14, color: onForestMuted),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(18)),
                            child: Icon(_editing ? Icons.edit_outlined : Icons.add, color: AppColors.primaryDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: RuvaCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          RuvaTextField(
                            controller: _name,
                            label: l.ingredientName,
                            hint: l.ingredientNameHint,
                            autofocus: !_editing,
                            onChanged: (_) => setState(() => _error = null),
                          ),
                          const SizedBox(height: 22),
                          MonoLabel(l.ingredientCategory),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final c in IngredientCategory.values)
                                RuvaChip(
                                  label: categoryLabel(l, c),
                                  selected: _categories.contains(c),
                                  trailingCheck: true,
                                  onTap: () => setState(
                                    () => _categories = _categories.contains(c)
                                        ? ({..._categories}..remove(c))
                                        : {..._categories, c},
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          RuvaTextField(
                            controller: _qty,
                            label: l.ingredientQuantity,
                            hint: '0',
                            bold: true,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() => _error = null),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final u in kitchenUnits)
                                RuvaChip(label: u, selected: _unit == u, onTap: () => setState(() => _unit = u)),
                            ],
                          ),
                          const SizedBox(height: 22),
                          MonoLabel(l.ingredientState),
                          const SizedBox(height: 10),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 2.8,
                            children: [
                              for (final s in FoodState.values)
                                _StateTile(
                                  label: stateLabel(l, s),
                                  icon: stateIcon(s),
                                  selected: _state == s,
                                  onTap: () => setState(() => _state = s),
                                ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          MonoLabel(l.ingredientDates),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _DateTile(
                                  label: l.ingredientPurchased,
                                  value: _purchased == null ? l.ingredientNotSet : dateFmt.format(_purchased!),
                                  onTap: () => _pickDate(purchased: true),
                                  onClear: _purchased == null ? null : () => setState(() => _purchased = null),
                                  clearLabel: l.ingredientClearDate(l.ingredientPurchased.toLowerCase()),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _DateTile(
                                  label: l.ingredientExpires,
                                  value: _expires == null ? l.ingredientNotSet : dateFmt.format(_expires!),
                                  onTap: () => _pickDate(purchased: false),
                                  onClear: _expires == null ? null : () => setState(() => _expires = null),
                                  clearLabel: l.ingredientClearDate(l.ingredientExpires.toLowerCase()),
                                ),
                              ),
                            ],
                          ),
                          if (expiry != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.schedule, size: 16, color: AppColors.fatBurningIcon),
                                const SizedBox(width: 6),
                                Text(expiry, style: AppText.small),
                              ],
                            ),
                          ],
                          const SizedBox(height: 22),
                          RuvaTextField(
                            controller: _low,
                            label: l.ingredientLowStockAt,
                            hint: l.ingredientLowStockHint,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          const SizedBox(height: 22),
                          RuvaTextField(controller: _brand, label: l.ingredientBrand, hint: l.ingredientBrandHint),
                          const SizedBox(height: 22),
                          RuvaTextField(
                            controller: _notes,
                            label: l.ingredientNotes,
                            hint: l.ingredientNotesHint,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              color: AppColors.background,
              child: Column(
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(_error!, style: AppText.small.copyWith(color: AppColors.errorText)),
                      ),
                    ),
                  PrimaryButton(label: l.ingredientSave, onPressed: _save),
                  if (_editing)
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: _finish,
                          icon: const Icon(Icons.check_circle_outline, color: AppColors.textSecondary),
                          label: Text(
                            l.ingredientMarkFinished,
                            style: AppText.body.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        TextButton(
                          onPressed: _remove,
                          style: TextButton.styleFrom(foregroundColor: AppColors.errorText),
                          child: Text(l.ingredientRemove),
                        ),
                      ],
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

class _StateTile extends StatelessWidget {
  const _StateTile({required this.label, required this.icon, required this.selected, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.white : AppColors.primary;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.primary : AppColors.lime200,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: AppText.body.copyWith(color: fg, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
    required this.clearLabel,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String clearLabel;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.lime200,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: '$label: $value',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MonoLabel(label, size: 9),
                    const SizedBox(height: 6),
                    Text(value, style: AppText.cardValue.copyWith(fontSize: 14)),
                  ],
                ),
              ),
            ),
            if (onClear != null)
              IconButton(
                tooltip: clearLabel,
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    ),
  );
}
