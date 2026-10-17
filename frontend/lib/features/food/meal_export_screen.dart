import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ruva_kit.dart';
import '../../domain/food.dart';
import '../../state/providers.dart';
import '../today/stats_export_screen.dart' show ExportStyle, sharePng;
import 'food_labels.dart';

/// One meal's calories, macros and foods in white on a transparent PNG.
class MealExportScreen extends ConsumerStatefulWidget {
  const MealExportScreen({super.key, required this.day});
  final DateTime day; // local midnight

  @override
  ConsumerState<MealExportScreen> createState() => _MealExportScreenState();
}

class _MealExportScreenState extends ConsumerState<MealExportScreen> {
  Meal? _meal; // null until entries load: the first meal with food
  ExportStyle _style = ExportStyle.white;
  final _card = GlobalKey();
  bool _busy = false;

  Future<void> _export(Meal meal) async {
    setState(() => _busy = true);
    try {
      await sharePng(_card, 'ruva-${DateFormat('yyyy-MM-dd').format(widget.day)}-${meal.name}.png');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final entries = ref.watch(diaryDayProvider(widget.day)).value ?? const <FoodEntry>[];
    final meal = _meal ?? Meal.values.firstWhere((m) => entries.any((e) => e.meal == m), orElse: () => Meal.breakfast);
    final foods = [
      for (final e in entries)
        if (e.meal == meal) e,
    ];
    Widget chips<T>(List<T> values, T selected, String Function(T) label, ValueChanged<T> onTap) => Row(
      children: [
        for (final (i, v) in values.indexed) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: RuvaChip(
              label: label(v),
              selected: v == selected,
              dense: true,
              outlined: true,
              onTap: () => setState(() => onTap(v)),
            ),
          ),
        ],
      ],
    );
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
          children: [
            ScreenHeader(title: l.mealExportTitle, subtitle: DateFormat('EEE d MMM y').format(widget.day)),
            chips(Meal.values, meal, (m) => mealLabel(l, m), (m) => _meal = m),
            const SizedBox(height: 6),
            chips(ExportStyle.values, _style, (s) => s.label(l), (s) => _style = s),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(color: const Color(0xFF5C6660), borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: foods.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        l.mealExportEmpty(mealLabel(l, meal)),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    )
                  : RepaintBoundary(
                      key: _card,
                      child: MealCard(day: widget.day, meal: meal, entries: foods, style: _style),
                    ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: l.shareDayButton, onPressed: foods.isEmpty || _busy ? null : () => _export(meal)),
          ],
        ),
      ),
    );
  }
}

/// The exported meal image on a transparent background.
class MealCard extends StatelessWidget {
  const MealCard({super.key, required this.day, required this.meal, required this.entries, required this.style});
  final DateTime day;
  final Meal meal;
  final List<FoodEntry> entries;
  final ExportStyle style;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final n = NumberFormat.decimalPattern();
    final sum = DayTotals(entries).sum;
    const white = Colors.white;
    const label = TextStyle(fontFamily: AppFonts.body, fontSize: 14, color: white);
    TextStyle big(double size) => TextStyle(
      fontFamily: AppFonts.display,
      fontWeight: FontWeight.w700,
      fontSize: size,
      height: 1.15,
      color: white,
    );
    String grams(double v) => v < 10 ? '${v.toStringAsFixed(1)} g' : '${v.round()} g';
    const shown = 6;

    return SizedBox(
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('EEEE · d MMM y').format(day).toUpperCase(),
            style: const TextStyle(fontFamily: AppFonts.mono, fontSize: 14, letterSpacing: 1.2, color: white),
          ),
          const SizedBox(height: 6),
          Text(mealLabel(l, meal), style: big(28)),
          const SizedBox(height: 18),
          Text(l.nutrientEnergy, style: label),
          Text(sum[Nutrient.energy] == null ? '—' : '${n.format(sum[Nutrient.energy]!.round())} kcal', style: big(40)),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final m in [Nutrient.protein, Nutrient.carbs, Nutrient.fat, Nutrient.fibre])
                Expanded(
                  child: Column(
                    children: [
                      Text(nutrientLabel(l, m), style: label.copyWith(fontSize: 13)),
                      Text(sum[m] == null ? '—' : grams(sum[m]!), style: big(22)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Container(width: 120, height: 3, color: style.line),
          const SizedBox(height: 14),
          for (final e in entries.take(shown))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                [e.name, if (e.nutrients[Nutrient.energy] case final k?) '${k.round()} kcal'].join(' · '),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: label,
              ),
            ),
          if (entries.length > shown) Text(l.mealExportMore(entries.length - shown), style: label),
          const SizedBox(height: 22),
          style.mark(wordmark: 130, logo: 64),
        ],
      ),
    );
  }
}
