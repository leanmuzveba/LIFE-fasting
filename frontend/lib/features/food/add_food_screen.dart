import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ruva_kit.dart';
import '../../core/widgets/sheet.dart';
import '../../data/food_repository.dart' show FoodShortcut;
import '../../domain/food.dart';
import '../../state/providers.dart';
import 'food_labels.dart';

/// Search the bundled food database, pick an amount and log it (RUVA design,
/// PRD v1.2 §3). Recent and saved foods are one tap away.
class AddFoodScreen extends ConsumerStatefulWidget {
  const AddFoodScreen({super.key, required this.day, required this.meal});

  final DateTime day; // local date
  final Meal meal;

  @override
  ConsumerState<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends ConsumerState<AddFoodScreen> {
  final _search = TextEditingController();
  final _selectedKey = GlobalKey();
  String _query = '';
  late Meal _meal = widget.meal;
  late TimeOfDay _time = _defaultTime();
  Food? _selected;
  double _grams = 100;
  String _portion = '';

  TimeOfDay _defaultTime() {
    final now = ref.read(clockProvider)().toLocal();
    final isToday = now.year == widget.day.year && now.month == widget.day.month && now.day == widget.day.day;
    return isToday ? TimeOfDay.fromDateTime(now) : TimeOfDay(hour: mealDefaultHour(widget.meal), minute: 0);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _select(Food f, {double? grams, String portion = ''}) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selected = f;
      _grams = grams ?? (f.portions.isNotEmpty && f.isCustom ? f.portions.first.grams : 100);
      _portion = grams != null ? portion : (f.isCustom && f.portions.isNotEmpty ? f.portions.first.label : '');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _selectedKey.currentContext;
      if (c != null && c.mounted) Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 300));
    });
  }

  void _selectShortcut(FoodShortcut s, Map<String, Food> byKey) {
    final f = byKey[s.key];
    if (f != null) _select(f, grams: s.grams, portion: s.portion);
  }

  Future<void> _add() async {
    final l = context.l10n;
    final f = _selected!;
    final d = widget.day;
    final at = DateTime(d.year, d.month, d.day, _time.hour, _time.minute);
    final now = ref.read(clockProvider)().toLocal();
    await ref.read(foodActionsProvider).log(f, _grams, meal: _meal, at: at.isAfter(now) ? now : at, portion: _portion);
    if (!mounted) return;
    showRuvaSnack(context, l.addFoodAdded(f.name, mealLabel(l, _meal)));
    Navigator.of(context).pop();
  }

  Future<void> _createCustom() async {
    final f = await showAppSheet<Food>(context, (_) => _CustomFoodSheet(initialName: _query.trim()));
    if (f != null && mounted) _select(f);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final catalogue = ref.watch(foodCatalogueProvider).value;
    final byKey = {for (final f in catalogue ?? const <Food>[]) f.key: f};
    final recent = ref.watch(recentFoodsProvider).value ?? const [];
    final saved = ref.watch(savedFoodsProvider).value ?? const [];
    final results = catalogue == null ? const <Food>[] : searchFoods(catalogue, _query);
    final count = ref.watch(usdaFoodsProvider).value?.length;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            ScreenHeader(
              title: l.addFoodTitle,
              large: true,
              subtitle: l.addFoodTo(mealLabel(l, _meal), DateFormat('EEE, d MMM').format(widget.day)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MonoLabel(l.addFoodDatabase),
                  const SizedBox(height: 10),
                  ForestCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        SearchField(
                          hint: count == null ? l.addFoodLoading : l.addFoodSearch,
                          controller: _search,
                          onChanged: (v) => setState(() => _query = v),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l.addFoodSource,
                          textAlign: TextAlign.center,
                          style: AppText.small.copyWith(color: onForestMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (_query.trim().isEmpty) ...[
                    if (recent.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      MonoLabel(l.addFoodRecent),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final r in recent)
                            RuvaChip(label: r.name, selected: false, onTap: () => _selectShortcut(r, byKey)),
                        ],
                      ),
                    ],
                    if (saved.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      MonoLabel(l.addFoodSaved),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in saved)
                            RuvaChip(
                              label: s.name,
                              icon: Icons.star_rounded,
                              selected: false,
                              onTap: () => _selectShortcut(s, byKey),
                            ),
                        ],
                      ),
                    ],
                  ] else ...[
                    const SizedBox(height: 20),
                    MonoLabel(l.addFoodResults),
                    const SizedBox(height: 10),
                    RuvaCard(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          if (results.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(l.addFoodNoMatch(_query.trim()), style: AppText.small),
                            ),
                          for (final (i, f) in results.indexed) ...[
                            if (i > 0) const Divider(height: 1, color: AppColors.divider, indent: 20, endIndent: 20),
                            ListTile(
                              onTap: () => _select(f),
                              title: Text(f.name, style: AppText.cardValue.copyWith(fontSize: 15)),
                              subtitle: Text(
                                [
                                  if (f.isCustom) l.addFoodYours,
                                  if (f.per100g[Nutrient.energy] case final kcal?)
                                    l.addFoodPer100(
                                      formatNutrient(kcal),
                                      formatNutrient(f.per100g[Nutrient.protein] ?? 0),
                                    )
                                  else
                                    l.addFoodNoData,
                                ].join(' · '),
                                style: AppText.small.copyWith(fontSize: 12),
                              ),
                              trailing: Icon(
                                f == _selected ? Icons.check_circle : Icons.add_circle_outline,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (_selected case final f?) _selectedCard(f, saved.any((s) => s.key == f.key)),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                      onPressed: _createCustom,
                      icon: const Icon(Icons.edit_note_rounded),
                      label: Text(l.addFoodCreate),
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

  Widget _selectedCard(Food f, bool isSaved) {
    final l = context.l10n;
    final kcal = f.per100g[Nutrient.energy];
    final portions = [const Portion('', 100), ...f.portions.take(3)];
    void step(double by) => setState(() {
      _grams = (_grams + by).clamp(5, 2000);
      _portion = '';
    });
    return RuvaCard(
      key: _selectedKey,
      bordered: true,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: MonoLabel(l.addFoodSelected)),
              IconButton(
                tooltip: isSaved ? l.addFoodUnsave : l.addFoodSave,
                onPressed: () => ref.read(foodActionsProvider).setSaved(f, !isSaved, grams: _grams, portion: _portion),
                icon: Icon(isSaved ? Icons.star_rounded : Icons.star_outline_rounded, color: AppColors.primary),
              ),
              IconButton(
                tooltip: l.addFoodClear,
                onPressed: () => setState(() => _selected = null),
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
              ),
            ],
          ),
          Text(f.name, style: AppText.title.copyWith(fontSize: 20)),
          const SizedBox(height: 16),
          ValueStepper(
            large: true,
            label: formatPortion(_portion, _grams),
            minusTooltip: l.addFoodLess,
            plusTooltip: l.addFoodMore,
            onMinus: _grams > 5 ? () => step(-10) : null,
            onPlus: _grams < 2000 ? () => step(10) : null,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in portions)
                RuvaChip(
                  label: p.label.isEmpty ? '100 g' : p.label,
                  outlined: true,
                  selected: _portion == p.label && _grams == p.grams,
                  onTap: () => setState(() {
                    _grams = p.grams;
                    _portion = p.label;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            kcal == null ? l.addFoodNoData : l.addFoodAbout(formatNutrient(kcal * _grams / 100)),
            style: AppText.small,
          ),
          const SizedBox(height: 16),
          MonoLabel(l.addFoodMeal),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in Meal.values)
                RuvaChip(label: mealLabel(l, m), selected: _meal == m, onTap: () => setState(() => _meal = m)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: MonoLabel(l.addFoodTime)),
              TextButton.icon(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () async {
                  final t = await showTimePicker(context: context, initialTime: _time);
                  if (t != null) setState(() => _time = t);
                },
                icon: const Icon(Icons.schedule),
                label: Text(
                  MaterialLocalizations.of(context).formatTimeOfDay(
                    _time,
                    alwaysUse24HourFormat: ref.watch(settingsProvider).value?.use24HourTime ?? false,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryButton(label: l.addFoodAddTo(mealLabel(l, _meal)), onPressed: _add),
        ],
      ),
    );
  }
}

/// Create a food that isn't in the database. Nutrition is optional; blanks
/// stay "unavailable", never zero.
class _CustomFoodSheet extends ConsumerStatefulWidget {
  const _CustomFoodSheet({required this.initialName});
  final String initialName;

  @override
  ConsumerState<_CustomFoodSheet> createState() => _CustomFoodSheetState();
}

class _CustomFoodSheetState extends ConsumerState<_CustomFoodSheet> {
  late final _name = TextEditingController(text: widget.initialName);
  final _serving = TextEditingController(text: '100');
  final _values = {for (final n in Nutrient.macros) n: TextEditingController()};
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _serving.dispose();
    for (final c in _values.values) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    final l = context.l10n;
    final grams = _num(_serving);
    if (_name.text.trim().isEmpty) return setState(() => _error = l.customNameRequired);
    if (grams == null || grams <= 0) return setState(() => _error = l.customServingRequired);
    final per100 = <Nutrient, double>{
      for (final e in _values.entries)
        if (_num(e.value) case final v? when v >= 0) e.key: v * 100 / grams,
    };
    final f = await ref
        .read(foodActionsProvider)
        .createCustom(_name.text, per100, Portion(l.customServingLabel, grams));
    if (mounted) Navigator.pop(context, f);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    const numeric = TextInputType.numberWithOptions(decimal: true);
    return Gap16Column(
      children: [
        Semantics(header: true, child: Text(l.customTitle, style: AppText.title)),
        RuvaTextField(controller: _name, label: l.customName, bold: true),
        RuvaTextField(controller: _serving, label: l.customServing, keyboardType: numeric),
        MonoLabel(l.customPerServing),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final e in _values.entries)
              SizedBox(
                width: 150,
                child: RuvaTextField(
                  controller: e.value,
                  label: '${nutrientLabel(l, e.key)} (${e.key.unit})',
                  keyboardType: numeric,
                ),
              ),
          ],
        ),
        Text(l.customHint, style: AppText.small),
        if (_error != null) Text(_error!, style: AppText.small.copyWith(color: AppColors.errorText)),
        PrimaryButton(label: l.customSave, onPressed: _save),
      ],
    );
  }
}
