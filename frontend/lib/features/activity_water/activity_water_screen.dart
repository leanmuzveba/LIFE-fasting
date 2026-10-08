import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ruva_kit.dart';
import '../../core/widgets/ruva_logo.dart';
import '../../core/widgets/sheet.dart';
import '../../domain/activity.dart';
import '../../domain/hydration.dart';
import '../../domain/settings.dart';
import '../../state/providers.dart';
import '../hydration/hydration_screen.dart';
import '../ring/fasting_ring.dart';

/// "Activity & Water" (RUVA design): today's water against a personal goal
/// with quick-adds, and an activity log. Opened from the Today tiles.
class ActivityWaterScreen extends StatefulWidget {
  const ActivityWaterScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<ActivityWaterScreen> createState() => _ActivityWaterScreenState();
}

class _ActivityWaterScreenState extends State<ActivityWaterScreen> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              children: [
                SizedBox(
                  width: 48,
                  child: IconButton(
                    tooltip: l.back,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.chevron_left_rounded, size: 30, color: AppColors.primary),
                  ),
                ),
                const Expanded(child: Center(child: RuvaLogo(size: 40, semanticLabel: null))),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 12),
            MonoLabel(l.today),
            const SizedBox(height: 4),
            Semantics(header: true, child: Text(l.awTitle, style: AppText.title.copyWith(fontSize: 26, height: 1.1))),
            const SizedBox(height: 18),
            _Segmented(
              labels: [l.awWaterTab, l.awActivityTab],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 22),
            if (_tab == 0) const _WaterTab() else const _ActivityTab(),
          ],
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.labels, required this.index, required this.onChanged});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(color: AppColors.track, borderRadius: BorderRadius.circular(40)),
    child: Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Semantics(
              button: true,
              selected: i == index,
              label: labels[i],
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    labels[i],
                    style: AppText.link.copyWith(
                      fontSize: 15,
                      color: i == index ? AppColors.white : AppColors.textSecondary,
                      fontWeight: i == index ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

// --- Water -------------------------------------------------------------------

class _WaterTab extends ConsumerWidget {
  const _WaterTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final unit = settings.waterUnit;
    final now = ref.watch(nowProvider).value ?? DateTime.now();
    final today = localDay(now);
    final entries = ref.watch(hydrationDayProvider(today)).value ?? const [];
    final total = totalMl(entries);
    final progress = (total / settings.waterGoalMl).clamp(0.0, 1.0);
    final quick = unit == VolumeUnit.ml ? const [200.0, 300.0, 500.0] : const [8.0, 12.0, 16.0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ForestCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label:
                          '${formatVolume(total, unit)} ${l.waterOfGoal(formatVolume(settings.waterGoalMl.toDouble(), unit))}',
                      hint: l.waterEditGoal,
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: () => _editGoal(context, ref, settings),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: LayoutBuilder(
                            builder: (_, box) => CustomPaint(
                              painter: RingArcPainter(
                                progress: progress,
                                radius: box.maxWidth / 2 - box.maxWidth * 0.035,
                                stroke: box.maxWidth * 0.07,
                                phases: const [],
                                trackColor: const Color(0x26000000),
                                baseColor: AppColors.accent,
                                knobColor: AppColors.accent,
                              ),
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(box.maxWidth * 0.14),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          formatVolume(total, unit),
                                          style: AppText.cardValue.copyWith(color: AppColors.white, fontSize: 22),
                                        ),
                                        const SizedBox(height: 4),
                                        MonoLabel(
                                          l.waterOfGoal(formatVolume(settings.waterGoalMl.toDouble(), unit)),
                                          color: AppColors.accent,
                                          size: 9,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      for (final q in quick) ...[
                        _LimeQuickAdd(
                          label: '+${formatVolume(unit.toMl(q), unit)}',
                          semantics: l.waterAdd(formatVolume(unit.toMl(q), unit)),
                          onTap: () => ref.read(hydrationActionsProvider).add(unit.toMl(q)),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => showWaterEntrySheet(context, day: today),
                  style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                  child: Text(l.waterCustomAmount),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        MonoLabel(l.waterTodaysEntries),
        const SizedBox(height: 12),
        RuvaCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l.waterNoneYet, style: AppText.small),
                ),
              for (final (i, e) in entries.reversed.indexed) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.divider),
                _WaterRow(entry: e, unit: unit, use24h: settings.use24HourTime, day: today),
              ],
            ],
          ),
        ),
        if (entries.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            progress >= 1 ? l.waterGoalReached : l.waterKeepGoing,
            textAlign: TextAlign.center,
            style: AppText.small,
          ),
        ],
      ],
    );
  }

  Future<void> _editGoal(BuildContext context, WidgetRef ref, AppSettings s) =>
      showAppSheet<void>(context, (_) => _GoalSheet(initialMl: s.waterGoalMl, unit: s.waterUnit));
}

class _WaterRow extends ConsumerWidget {
  const _WaterRow({required this.entry, required this.unit, required this.use24h, required this.day});
  final HydrationEntry entry;
  final VolumeUnit unit;
  final bool use24h;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final amount = formatVolume(entry.amountMl, unit);
    final time = formatClock(entry.loggedAt, use24h: use24h);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const IconBubble(icon: Icons.water_drop_outlined, size: 41),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(amount, style: AppText.cardValue.copyWith(fontSize: 16)),
                Text(time, style: AppText.small),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: l.entryOptions('$amount, $time'),
            icon: const Icon(Icons.more_horiz, color: AppColors.muted),
            color: AppColors.white,
            onSelected: (v) => v == 'edit'
                ? showWaterEntrySheet(context, entry: entry, day: day)
                : ref.read(hydrationActionsProvider).delete(entry),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(l.edit)),
              PopupMenuItem(value: 'delete', child: Text(l.delete)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LimeQuickAdd extends StatelessWidget {
  const _LimeQuickAdd({required this.label, required this.semantics, required this.onTap});
  final String label;
  final String semantics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semantics,
    excludeSemantics: true,
    child: Material(
      color: AppColors.accent,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 112),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.water_drop_outlined, size: 16, color: AppColors.primaryDark),
                const SizedBox(width: 8),
                Text(label, style: AppText.link.copyWith(fontSize: 14, color: AppColors.primaryDark)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _GoalSheet extends ConsumerStatefulWidget {
  const _GoalSheet({required this.initialMl, required this.unit});
  final int initialMl;
  final VolumeUnit unit;

  @override
  ConsumerState<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends ConsumerState<_GoalSheet> {
  late int _ml = widget.initialMl;
  static const _step = 250;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Gap16Column(
      children: [
        Semantics(header: true, child: Text(l.waterEditGoal, style: AppText.title)),
        Text(l.waterGoalHint, style: AppText.small),
        ValueStepper(
          large: true,
          label: formatVolume(_ml.toDouble(), widget.unit),
          minusTooltip: '−${formatVolume(_step.toDouble(), VolumeUnit.ml)}',
          plusTooltip: '+${formatVolume(_step.toDouble(), VolumeUnit.ml)}',
          onMinus: _ml > minWaterGoalMl ? () => setState(() => _ml -= _step) : null,
          onPlus: _ml < maxWaterGoalMl ? () => setState(() => _ml += _step) : null,
        ),
        PrimaryButton(
          label: l.save,
          onPressed: () async {
            await ref.read(settingsProvider.notifier).change((s) => s.copyWith(waterGoalMl: _ml));
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

// --- Activity ----------------------------------------------------------------

IconData activityIcon(ActivityType t) => switch (t) {
  ActivityType.walk => Icons.directions_walk,
  ActivityType.run => Icons.directions_run,
  ActivityType.cycle => Icons.directions_bike,
  ActivityType.strength => Icons.fitness_center,
  ActivityType.yoga => Icons.self_improvement,
  ActivityType.other => Icons.more_horiz,
};

String activityLabel(AppLocalizations l, ActivityType t) => switch (t) {
  ActivityType.walk => l.activityWalk,
  ActivityType.run => l.activityRun,
  ActivityType.cycle => l.activityCycle,
  ActivityType.strength => l.activityStrength,
  ActivityType.yoga => l.activityYoga,
  ActivityType.other => l.activityOther,
};

String intensityLabel(AppLocalizations l, Intensity i) => switch (i) {
  Intensity.light => l.intensityLight,
  Intensity.moderate => l.intensityModerate,
  Intensity.heavy => l.intensityHeavy,
};

class _ActivityTab extends ConsumerWidget {
  const _ActivityTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final recent = ref.watch(recentActivitiesProvider).value ?? const [];
    final use24h = ref.watch(settingsProvider).value?.use24HourTime ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonoLabel(l.activityRecent),
        const SizedBox(height: 12),
        if (recent.isEmpty) Text(l.activityNone, style: AppText.small),
        for (final a in recent.take(3)) ...[ActivityCard(entry: a, use24h: use24h), const SizedBox(height: 10)],
        const SizedBox(height: 16),
        const RuvaCard(padding: EdgeInsets.all(18), child: ActivityForm()),
      ],
    );
  }
}

/// One activity row; tap to edit or delete.
class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.entry, required this.use24h});
  final ActivityEntry entry;
  final bool use24h;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = entry;
    final detail = [
      l.activityMinutes(a.minutes),
      if (a.intensity != null) intensityLabel(l, a.intensity!).toLowerCase(),
      '${formatShortDay(a.startedAt)} ${formatClock(a.startedAt, use24h: use24h)}',
    ].join(' · ');
    return RuvaCard(
      padding: const EdgeInsets.all(16),
      onTap: () => showAppSheet<void>(context, (_) => ActivityForm(entry: a)),
      child: Semantics(
        label: '${activityLabel(l, a.type)}, $detail. ${l.edit}',
        excludeSemantics: true,
        child: Row(
          children: [
            IconBubble(
              icon: activityIcon(a.type),
              size: 48,
              background: AppColors.primary,
              foreground: AppColors.accent,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activityLabel(l, a.type), style: AppText.cardValue.copyWith(fontSize: 15)),
                  Text(detail, style: AppText.small),
                  if (a.notes.isNotEmpty)
                    Text(a.notes, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.small),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Log a new activity, or edit/delete [entry].
class ActivityForm extends ConsumerStatefulWidget {
  const ActivityForm({super.key, this.entry});
  final ActivityEntry? entry;

  @override
  ConsumerState<ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends ConsumerState<ActivityForm> {
  late ActivityType _type = widget.entry?.type ?? ActivityType.walk;
  late int _minutes = widget.entry?.minutes ?? 30;
  late Intensity? _intensity = widget.entry?.intensity;
  late final _notes = TextEditingController(text: widget.entry?.notes ?? '');
  late DateTime? _when = widget.entry?.startedAt.toLocal(); // null = now
  String? _error;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickWhen() async {
    final now = ref.read(clockProvider)();
    final initial = _when ?? now;
    final date = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2020), lastDate: now);
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return;
    setState(() {
      _when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _error = null;
    });
  }

  Future<void> _save() async {
    final l = context.l10n;
    final now = ref.read(clockProvider)().toUtc();
    final e = widget.entry;
    final entry = ActivityEntry(
      id: e?.id,
      type: _type,
      startedAt: (_when ?? now).toUtc(),
      minutes: _minutes,
      intensity: _intensity,
      notes: _notes.text,
      createdAt: e?.createdAt ?? now,
      updatedAt: now,
    );
    if (!await ref.read(activityActionsProvider).save(entry)) {
      setState(() => _error = l.activityFutureError);
      return;
    }
    if (!mounted) return;
    if (e != null) {
      Navigator.pop(context);
    } else {
      showRuvaSnack(context, l.activityLogged(activityLabel(l, _type), _minutes));
      setState(() {
        _notes.clear();
        _when = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final use24h = ref.watch(settingsProvider).value?.use24HourTime ?? false;
    final whenLabel = _when == null ? l.today : '${formatShortDay(_when!)}, ${formatClock(_when!, use24h: use24h)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            widget.entry == null ? l.activityLogTitle : l.activityEditTitle,
            style: AppText.title.copyWith(fontSize: 17),
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.25,
          children: [
            for (final t in ActivityType.values)
              Semantics(
                button: true,
                selected: t == _type,
                label: activityLabel(l, t),
                excludeSemantics: true,
                child: Material(
                  color: t == _type ? AppColors.primary : AppColors.lime200,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => setState(() => _type = t),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(activityIcon(t), color: t == _type ? AppColors.accent : AppColors.primary),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            activityLabel(l, t),
                            style: AppText.body.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: t == _type ? AppColors.white : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        MonoLabel(l.activityDuration),
        const SizedBox(height: 10),
        ValueStepper(
          large: true,
          label: l.activityMinutes(_minutes),
          minusTooltip: l.decreaseMinute,
          plusTooltip: l.increaseMinute,
          onMinus: _minutes > minActivityMinutes ? () => setState(() => _minutes--) : null,
          onPlus: _minutes < maxActivityMinutes ? () => setState(() => _minutes++) : null,
        ),
        const SizedBox(height: 18),
        MonoLabel(l.activityIntensity),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final (i, v) in Intensity.values.indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: RuvaChip(
                  label: intensityLabel(l, v),
                  selected: v == _intensity,
                  outlined: true,
                  // Tap again to clear: intensity is optional.
                  onTap: () => setState(() => _intensity = v == _intensity ? null : v),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        MonoLabel(l.activityWhen),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _pickWhen,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
            side: const BorderSide(color: AppColors.divider),
          ),
          icon: const Icon(Icons.schedule, color: AppColors.primary),
          label: Text(whenLabel),
        ),
        const SizedBox(height: 18),
        RuvaTextField(controller: _notes, label: l.activityNotes, maxLines: 2),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: AppText.small.copyWith(color: AppColors.errorText)),
        ],
        const SizedBox(height: 18),
        PrimaryButton(label: widget.entry == null ? l.activityLogButton : l.save, onPressed: _save),
        if (widget.entry != null)
          TextButton(
            onPressed: () async {
              await ref.read(activityActionsProvider).delete(widget.entry!);
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.errorText),
            child: Text(l.delete),
          ),
      ],
    );
  }
}
