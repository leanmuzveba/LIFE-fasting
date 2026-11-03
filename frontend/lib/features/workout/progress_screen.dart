import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ruva_kit.dart';
import '../../domain/activity.dart';
import '../../domain/profile.dart';
import '../../domain/workout.dart';
import '../../state/providers.dart';
import 'exercise_detail.dart';

Future<void> showProgress(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ProgressScreen()));

/// A personal best: what it is, and when you set it.
typedef _Record = ({String name, String? libraryId, String best, DateTime at});

/// Strength progress from what you've logged: how often you train, and your bests.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final sessions = ref.watch(strengthSessionsProvider).value;
    final history = ref.watch(exerciseHistoryProvider).value ?? const {};
    final library = ref.watch(exerciseLibraryProvider).value ?? const <LibraryExercise>[];
    final plan = ref.watch(planProvider).value;
    final imperial = ref.watch(settingsProvider).value?.units == UnitSystem.imperial;
    final now = ref.read(clockProvider)();
    if (sessions == null) return const Scaffold(body: SizedBox.shrink());

    final counts = weeklyCounts(sessions.map((s) => s.startedAt), now);
    final month = sessions.where((s) => now.difference(s.startedAt).inDays < 30).length;
    final byId = {for (final x in library) x.id: x};
    final records = <_Record>[for (final sessions in history.values) ?_record(l, sessions, imperial)]
      ..sort((a, b) => b.at.compareTo(a.at));

    Widget stat(String label, String value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonoLabel(label, size: 10),
          const SizedBox(height: 4),
          Text(value, style: AppText.cardValue.copyWith(fontSize: 20)),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          children: [
            ScreenHeader(title: l.progressTitle, subtitle: l.progressSub),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (sessions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(l.progressEmpty, textAlign: TextAlign.center, style: AppText.body),
                    )
                  else ...[
                    RuvaCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              stat(
                                l.progressThisWeek,
                                plan == null ? '${counts.last}' : l.progressOfPlan(counts.last, plan.days.length),
                              ),
                              stat(l.progressStreak, l.progressWeeks(weekStreak(counts))),
                              stat(l.progressMonth, '$month'),
                            ],
                          ),
                          const SizedBox(height: 18),
                          MonoLabel(l.progressPerWeek, size: 10),
                          const SizedBox(height: 10),
                          _WeekBars(counts: counts, now: now, target: plan?.days.length),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    MonoLabel(l.progressBests),
                    const SizedBox(height: 4),
                    if (records.isEmpty) Text(l.progressNoBests, style: AppText.small),
                    for (final r in records)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(r.name, style: AppText.body.copyWith(fontSize: 15, fontWeight: FontWeight.w500)),
                        subtitle: Text('${r.best} · ${formatShortDay(r.at)}', style: AppText.small),
                        trailing: byId[r.libraryId] == null
                            ? null
                            : const Icon(Icons.chevron_right, color: AppColors.muted),
                        onTap: byId[r.libraryId] == null ? null : () => showExerciseDetail(context, byId[r.libraryId]!),
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

/// The record for one exercise's sessions (newest first): best estimated
/// 1-rep max with weights, else most reps in a set; dated to when you first hit it.
_Record? _record(AppLocalizations l, List<(DateTime, Exercise)> sessions, bool imperial) {
  if (sessions.isEmpty) return null;
  final x = sessions.first.$2;
  final series = oneRepMaxSeries(sessions);
  if (series.isNotEmpty) {
    final top = series.reduce((a, b) => b.$2 > a.$2 ? b : a); // the first time it was this high
    return (
      name: x.name,
      libraryId: x.libraryId,
      best: l.progressBest1rm(formatLoad(top.$2, imperial: imperial)),
      at: top.$1,
    );
  }
  (DateTime, int)? most;
  for (final (at, e) in sessions.reversed) {
    for (final s in e.log.where((s) => s.done)) {
      if (most == null || s.reps > most.$2) most = (at, s.reps);
    }
  }
  return most == null ? null : (name: x.name, libraryId: x.libraryId, best: l.progressMostReps(most.$2), at: most.$1);
}

/// Workouts per week as bars, with your plan's days a week as a line.
class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.counts, required this.now, this.target});
  final List<int> counts;
  final DateTime now;
  final int? target;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final top = [...counts, target ?? 0, 1].reduce((a, b) => a > b ? a : b);
    const height = 90.0;
    final first = weekStart(now);
    return Semantics(
      label: l.progressPerWeekLabel(counts.join(', ')),
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (i, n) in counts.indexed)
            Expanded(
              child: Column(
                children: [
                  Text(n == 0 ? '' : '$n', style: AppText.small.copyWith(fontSize: 11)),
                  const SizedBox(height: 2),
                  Container(
                    height: height * n / top + 2,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: target != null && n >= target! ? AppColors.primary : AppColors.lime200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d/M')
                        .format(DateTime(first.year, first.month, first.day - 7 * (counts.length - 1 - i))),
                    style: AppText.small.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Estimated 1-rep max over time, for an exercise's page.
class OneRepMaxChart extends StatelessWidget {
  const OneRepMaxChart({super.key, required this.series, required this.imperial});
  final List<(DateTime, double)> series;
  final bool imperial;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final first = formatLoad(series.first.$2, imperial: imperial);
    final last = formatLoad(series.last.$2, imperial: imperial);
    return Semantics(
      label: l.progressChartLabel(first, last),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonoLabel(l.progressChart, size: 10),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            width: double.infinity,
            child: CustomPaint(painter: _LinePainter(series)),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('${formatShortDay(series.first.$1)} · $first', style: AppText.small.copyWith(fontSize: 11)),
              const Spacer(),
              Text('${formatShortDay(series.last.$1)} · $last', style: AppText.small.copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.series);
  final List<(DateTime, double)> series;

  @override
  void paint(Canvas canvas, Size size) {
    final values = series.map((p) => p.$2);
    final lo = values.reduce((a, b) => a < b ? a : b), hi = values.reduce((a, b) => a > b ? a : b);
    final t0 = series.first.$1.millisecondsSinceEpoch, span = series.last.$1.millisecondsSinceEpoch - t0;
    Offset at((DateTime, double) p) => Offset(
      span == 0 ? size.width / 2 : (p.$1.millisecondsSinceEpoch - t0) / span * (size.width - 8) + 4,
      hi == lo ? size.height / 2 : size.height - 6 - (p.$2 - lo) / (hi - lo) * (size.height - 12),
    );
    final line = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(Path()..addPolygon([for (final p in series) at(p)], false), line);
    final dot = Paint()..color = AppColors.primary;
    for (final p in series) {
      canvas.drawCircle(at(p), 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.series != series;
}
