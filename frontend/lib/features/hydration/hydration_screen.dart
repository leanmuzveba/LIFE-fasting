import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/sheet.dart';
import '../../domain/hydration.dart';
import '../../state/providers.dart';

/// Today tile: total so far plus quick-add buttons. Tap to open the Water page.
class WaterTile extends ConsumerWidget {
  const WaterTile({super.key, required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final unit = ref.watch(settingsProvider).value?.waterUnit ?? VolumeUnit.ml;
    final now = ref.watch(nowProvider).value ?? DateTime.now();
    final entries = ref.watch(hydrationDayProvider(localDay(now))).value ?? const [];
    final total = totalMl(entries);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              label: '${l.waterTitle}: ${formatVolume(total, unit)}. ${l.waterEntries(entries.length)}',
              excludeSemantics: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onOpen,
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const AppIconView(AppIcon.water, size: 22, color: AppColors.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.waterToday, style: AppText.overline),
                          Text(formatVolume(total, unit), style: AppText.cardValue),
                        ],
                      ),
                    ),
                    const AppIconView(AppIcon.chevronRight, color: AppColors.muted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final (i, q) in unit.quickAdds.indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _QuickAdd(
                      label: '+${formatVolume(unit.toMl(q), unit)}',
                      semantics: l.waterAdd(formatVolume(unit.toMl(q), unit)),
                      onTap: () => ref.read(hydrationActionsProvider).add(unit.toMl(q)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAdd extends StatelessWidget {
  const _QuickAdd({required this.label, required this.semantics, required this.onTap});
  final String label;
  final String semantics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semantics,
    excludeSemantics: true,
    child: Material(
      color: AppColors.soft,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: AppText.link.copyWith(fontSize: 14)),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Add a custom amount for [day] or edit/delete [entry].
Future<void> showWaterEntrySheet(BuildContext context, {HydrationEntry? entry, required DateTime day}) =>
    showAppSheet<void>(context, (_) => _EntrySheet(entry: entry, day: day));

/// Add a custom amount (optionally at an earlier time) or edit/delete an entry.
class _EntrySheet extends ConsumerStatefulWidget {
  const _EntrySheet({this.entry, required this.day});
  final HydrationEntry? entry;
  final DateTime day;

  @override
  ConsumerState<_EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends ConsumerState<_EntrySheet> {
  late final VolumeUnit _unit = ref.read(settingsProvider).value?.waterUnit ?? VolumeUnit.ml;
  late final _amount = TextEditingController(
    text: widget.entry == null ? '' : _trim(_unit.fromMl(widget.entry!.amountMl)),
  );
  late TimeOfDay _time = TimeOfDay.fromDateTime((widget.entry?.loggedAt ?? ref.read(clockProvider)()).toLocal());
  bool _invalid = false;

  static String _trim(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (value == null || value <= 0 || value > _unit.maxEntry) {
      setState(() => _invalid = true);
      return;
    }
    final d = widget.day;
    var at = DateTime(d.year, d.month, d.day, _time.hour, _time.minute);
    final now = ref.read(clockProvider)();
    if (at.isAfter(now)) at = now; // never in the future
    final actions = ref.read(hydrationActionsProvider);
    final e = widget.entry;
    if (e == null) {
      await actions.add(_unit.toMl(value), at: at);
    } else {
      await actions.update(e.copyWith(amountMl: _unit.toMl(value), loggedAt: at.toUtc()));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final use24h = ref.watch(settingsProvider).value?.use24HourTime ?? false;
    final unitLabel = _unit == VolumeUnit.ml ? l.unitMl : l.unitFlOz;
    return Gap16Column(
      children: [
        Semantics(
          header: true,
          child: Text(widget.entry == null ? l.waterAddTitle : l.waterEditTitle, style: AppText.title),
        ),
        TextField(
          controller: _amount,
          autofocus: widget.entry == null,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          style: AppText.cardValue,
          decoration: InputDecoration(
            labelText: l.waterAmountLabel(unitLabel),
            errorText: _invalid ? l.waterInvalidAmount('${_trim(_unit.maxEntry)} $unitLabel') : null,
            filled: true,
            fillColor: AppColors.accentSoft,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (_) => setState(() => _invalid = false),
          onSubmitted: (_) => _save(),
        ),
        Semantics(
          button: true,
          label:
              '${l.waterTimeLabel}: ${MaterialLocalizations.of(context).formatTimeOfDay(_time, alwaysUse24HourFormat: use24h)}',
          excludeSemantics: true,
          child: OutlinedButton.icon(
            onPressed: () async {
              final t = await showTimePicker(context: context, initialTime: _time);
              if (t != null) setState(() => _time = t);
            },
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: const AppIconView(AppIcon.clock, color: AppColors.primary),
            label: Text(MaterialLocalizations.of(context).formatTimeOfDay(_time, alwaysUse24HourFormat: use24h)),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: widget.entry == null
                  ? PillButton(label: l.cancel, outlined: true, onPressed: () => Navigator.pop(context))
                  : PillButton(
                      label: l.delete,
                      outlined: true,
                      onPressed: () async {
                        await ref.read(hydrationActionsProvider).delete(widget.entry!);
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PillButton(label: l.save, onPressed: _save),
            ),
          ],
        ),
      ],
    );
  }
}
