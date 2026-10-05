import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ruva_kit.dart';
import '../../core/widgets/ruva_logo.dart';
import '../../core/widgets/sheet.dart';
import '../../domain/fasting_session.dart';
import '../../domain/history.dart';
import '../../domain/hydration.dart';
import '../../state/providers.dart';
import '../activity_water/activity_water_screen.dart';
import 'session_sheet.dart';

enum HistoryFilter { all, fasting, water, activity }

/// History (RUVA design): filters, a month calendar with markers, a 14-day
/// fasting trend, recent days and a summary sheet for any day — all built
/// from what was actually recorded.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  HistoryFilter _filter = HistoryFilter.all;
  late DateTime _month = () {
    final t = ref.read(clockProvider)().toLocal();
    return DateTime(t.year, t.month);
  }();
  DateTime? _selected;

  bool _shows(HistoryFilter f) => _filter == HistoryFilter.all || _filter == f;

  void _openDay(DateTime day) {
    setState(() => _selected = day);
    showAppSheet<void>(context, (_) => _DaySheet(day: day));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final now = ref.watch(nowProvider).value ?? ref.read(clockProvider)();
    final today = localDay(now);
    final monthEnd = DateTime(_month.year, _month.month + 1);
    final monthDays = ref.watch(daySummariesProvider((_month, monthEnd))).value ?? const {};
    final windowStart = DateTime(today.year, today.month, today.day - 13);
    final windowEnd = DateTime(today.year, today.month, today.day + 1);
    final window = ref.watch(daySummariesProvider((windowStart, windowEnd))).value;
    final sessions = ref.watch(historyProvider).value ?? const <FastingSession>[];
    final trend = FastingTrend.of(sessions, today: now);
    final recent = (window?.values.where((d) => !d.isEmpty).toList() ?? <DaySummary>[])
      ..sort((a, b) => b.day.compareTo(a.day));
    final filters = [
      (HistoryFilter.all, l.historyAll, Icons.grid_view_rounded),
      (HistoryFilter.fasting, l.historyFasting, Icons.timer_outlined),
      (HistoryFilter.water, l.awWaterTab, Icons.water_drop_outlined),
      (HistoryFilter.activity, l.awActivityTab, Icons.directions_walk),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const RuvaLogo(size: 36, semanticLabel: null),
                  const SizedBox(width: 10),
                  Semantics(header: true, child: Text(l.navHistory, style: AppText.title.copyWith(fontSize: 32))),
                ],
              ),
              const SizedBox(height: 6),
              Text(formatLongDay(now), style: AppText.dateLine.copyWith(fontSize: 15)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        ChipRow(
          children: [
            for (final (f, label, icon) in filters)
              RuvaChip(label: label, icon: icon, selected: _filter == f, onTap: () => setState(() => _filter = f)),
          ],
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RuvaCard(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(DateFormat('MMMM y').format(_month), style: AppText.title.copyWith(fontSize: 19)),
                        ),
                        IconButton(
                          tooltip: l.previousMonth,
                          onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                          icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                        ),
                        IconButton(
                          tooltip: l.nextMonth,
                          onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                          icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _Calendar(
                      month: _month,
                      today: today,
                      selected: _selected,
                      days: monthDays,
                      shows: _shows,
                      onTap: _openDay,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        if (_shows(HistoryFilter.fasting)) _Legend(kind: _Mark.fast, label: l.historyFasting),
                        if (_shows(HistoryFilter.water)) _Legend(kind: _Mark.water, label: l.awWaterTab),
                        if (_shows(HistoryFilter.activity)) _Legend(kind: _Mark.activity, label: l.awActivityTab),
                      ],
                    ),
                  ],
                ),
              ),
              if (_shows(HistoryFilter.fasting)) ...[const SizedBox(height: 20), _TrendCard(trend: trend)],
              const SizedBox(height: 26),
              MonoLabel(l.historyRecentDays),
              const SizedBox(height: 12),
              if (recent.isEmpty)
                RuvaCard(
                  child: Column(
                    children: [
                      const IconBubble(icon: Icons.calendar_month_outlined, size: 56),
                      const SizedBox(height: 12),
                      Text(l.historyEmptyTitle, style: AppText.title),
                      const SizedBox(height: 6),
                      Text(l.historyNothingRecent, textAlign: TextAlign.center, style: AppText.small),
                    ],
                  ),
                ),
              for (final d in recent.take(7)) ...[
                _RecentDayCard(summary: d, shows: _shows, onTap: () => _openDay(d.day)),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              Text(
                l.historyQuote,
                textAlign: TextAlign.center,
                style: AppText.small.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _Mark { fast, water, activity }

/// Marker shapes differ as well as colours (never colour alone): fasting is a
/// lime dot with a forest ring, water a hollow ring, activity a solid dot.
class _Dot extends StatelessWidget {
  const _Dot(this.kind);
  final _Mark kind;

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: switch (kind) {
      _Mark.fast => BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 1),
      ),
      _Mark.water => BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryMid, width: 1.6),
      ),
      _Mark.activity => const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
    },
  );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.kind, required this.label});
  final _Mark kind;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _Dot(kind),
      const SizedBox(width: 6),
      Text(label, style: AppText.small.copyWith(fontSize: 12)),
    ],
  );
}

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.month,
    required this.today,
    required this.selected,
    required this.days,
    required this.shows,
    required this.onTap,
  });

  final DateTime month;
  final DateTime today;
  final DateTime? selected;
  final Map<DateTime, DaySummary> days;
  final bool Function(HistoryFilter) shows;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final first = DateTime(month.year, month.month);
    final leading = first.weekday % 7; // Sunday-first, as in the design
    final count = DateTime(month.year, month.month + 1, 0).day;
    final cells = [
      for (var i = leading; i > 0; i--) DateTime(month.year, month.month, 1 - i),
      for (var d = 1; d <= count; d++) DateTime(month.year, month.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(DateTime(cells.last.year, cells.last.month, cells.last.day + 1));
    }
    return Column(
      children: [
        Row(
          children: [
            for (final letter in l.weekdayInitialsSundayFirst.split(','))
              Expanded(
                child: ExcludeSemantics(child: Center(child: MonoLabel(letter, size: 11))),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var r = 0; r < cells.length ~/ 7; r++)
          Row(
            children: [
              for (final day in cells.sublist(r * 7, r * 7 + 7))
                Expanded(
                  child: day.month != month.month
                      ? SizedBox(
                          height: 54,
                          child: Center(
                            child: ExcludeSemantics(
                              child: Text('${day.day}', style: AppText.body.copyWith(color: AppColors.track)),
                            ),
                          ),
                        )
                      : _DayCell(
                          day: day,
                          isToday: day == today,
                          selected: day == selected,
                          summary: days[day],
                          shows: shows,
                          onTap: () => onTap(day),
                        ),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.selected,
    required this.summary,
    required this.shows,
    required this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final bool selected;
  final DaySummary? summary;
  final bool Function(HistoryFilter) shows;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = summary;
    final marks = [
      if (s != null && s.hasFast && shows(HistoryFilter.fasting)) _Mark.fast,
      if (s != null && s.hasWater && shows(HistoryFilter.water)) _Mark.water,
      if (s != null && s.hasActivity && shows(HistoryFilter.activity)) _Mark.activity,
    ];
    final what = [
      if (marks.contains(_Mark.fast)) l.historyFasting,
      if (marks.contains(_Mark.water)) l.awWaterTab,
      if (marks.contains(_Mark.activity)) l.awActivityTab,
    ];
    final highlighted = selected || isToday;
    final date = DateFormat('EEEE d MMMM').format(day);
    return Semantics(
      button: true,
      selected: selected,
      label: what.isEmpty ? '$date, ${l.historyNothingLogged}' : '$date: ${what.join(', ')}',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: SizedBox(
          height: 54,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: highlighted ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${day.day}',
                  style: highlighted
                      ? AppText.cardValue.copyWith(fontSize: 15, color: AppColors.white)
                      : AppText.body.copyWith(fontSize: 15),
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 7,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final (i, m) in marks.indexed) ...[if (i > 0) const SizedBox(width: 3), _Dot(m)],
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

/// Forest card: completed fasts in the last 14 days as a line (gaps where
/// nothing was recorded), average and longest fast, and the count.
class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.trend});
  final FastingTrend trend;

  String _h(double v) => '${v.toStringAsFixed(1)} h';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = trend;
    final first = DateFormat('MMM d').format(t.days.first).toUpperCase();
    final last = DateFormat('MMM d').format(t.days.last).toUpperCase();
    return ForestCard(
      child: Semantics(
        container: true,
        label: t.isEmpty
            ? l.trendEmpty
            : l.trendSemantics(_h(t.average!), _h(t.longest!), t.fastCount, '$first – $last'),
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MonoLabel(l.trendEyebrow, color: AppColors.accent, size: 10),
            const SizedBox(height: 8),
            if (t.isEmpty)
              Text(l.trendEmpty, style: AppText.body.copyWith(color: AppColors.white))
            else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_h(t.average!), style: AppText.cardValue.copyWith(fontSize: 34, color: AppColors.white)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(l.trendAverageFast, style: AppText.body.copyWith(color: onForestMuted)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 170,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _ChartPainter(trend: t, firstLabel: first, lastLabel: last),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0x1FFFFFFF)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Stat(label: l.trendLongest, value: _h(t.longest!)),
                  const SizedBox(width: 28),
                  _Stat(label: l.trendTotal, value: l.trendFastCount(t.fastCount)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      MonoLabel(label, color: onForestMuted, size: 10),
      const SizedBox(height: 4),
      Text(value, style: AppText.cardValue.copyWith(fontSize: 18, color: AppColors.white)),
    ],
  );
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.trend, required this.firstLabel, required this.lastLabel});
  final FastingTrend trend;
  final String firstLabel;
  final String lastLabel;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 36.0, bottom = 22.0;
    final w = size.width - left, h = size.height - bottom;
    final label = AppText.overline.copyWith(fontSize: 10, color: const Color(0x80FFFFFF), letterSpacing: 0.6);
    final values = trend.points.values;
    final maxH = math.max(24.0, values.reduce(math.max).ceilToDouble());
    final minH = math.min(8.0, values.reduce(math.min).floorToDouble());
    double y(double v) => h - (v - minH) / (maxH - minH) * h;
    double x(int i) => left + w * i / (trend.days.length - 1);

    final grid = Paint()
      ..color = const Color(0x1FFFFFFF)
      ..strokeWidth = 1;
    for (final g in [12.0, 16.0, 20.0]) {
      if (g < minH || g > maxH) continue;
      final gy = y(g);
      for (var gx = left; gx < size.width; gx += 8) {
        canvas.drawLine(Offset(gx, gy), Offset(math.min(gx + 4, size.width), gy), grid);
      }
      _text(canvas, '${g.toInt()}H', Offset(0, gy - 7), label);
    }
    canvas.drawLine(const Offset(left, 0), Offset(left, h), grid);
    _text(canvas, firstLabel, Offset(left, h + 6), label);
    final end = TextPainter(
      text: TextSpan(text: lastLabel, style: label),
      textDirection: TextDirection.ltr,
    )..layout();
    end.paint(canvas, Offset(size.width - end.width, h + 6));

    // Consecutive recorded days are joined; a day with nothing recorded breaks the line.
    final line = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()..color = AppColors.accent;
    final idx = trend.points.keys.toList()..sort();
    Path? path;
    int? prev;
    for (final i in idx) {
      final p = Offset(x(i), y(trend.points[i]!));
      if (path != null && prev != null && i == prev + 1) {
        path.lineTo(p.dx, p.dy);
      } else {
        if (path != null) canvas.drawPath(path, line);
        path = Path()..moveTo(p.dx, p.dy);
      }
      canvas.drawCircle(p, 4.5, dot);
      prev = i;
    }
    if (path != null) canvas.drawPath(path, line);
  }

  void _text(Canvas canvas, String s, Offset at, TextStyle style) => (TextPainter(
    text: TextSpan(text: s, style: style),
    textDirection: TextDirection.ltr,
  )..layout()).paint(canvas, at);

  @override
  bool shouldRepaint(_ChartPainter old) => old.trend != trend;
}

/// Short descriptions of a day's records, for tags.
List<(IconData, String)> dayTags(
  AppLocalizations l,
  DaySummary d,
  VolumeUnit unit,
  bool Function(HistoryFilter) shows,
) => [
  if (shows(HistoryFilter.fasting))
    for (final f in d.fasts)
      (
        Icons.timer_outlined,
        f.isActive
            ? l.historyFastInProgress
            : l.historyFastDone(
                formatHoursMinutes(f.endedAt!.difference(f.startedAt)),
                f.targetReachedAt(f.endedAt!) ? l.statusTargetReached.toLowerCase() : l.statusEnded.toLowerCase(),
              ),
      ),
  if (d.hasWater && shows(HistoryFilter.water))
    (Icons.water_drop_outlined, l.historyWater(formatVolume(d.waterMl, unit))),
  if (d.hasActivity && shows(HistoryFilter.activity))
    (Icons.directions_walk, l.historyActivity(l.activityMinutes(d.activityMinutes))),
];

/// "Recent days" card: tags for what was recorded that day.
class _RecentDayCard extends ConsumerWidget {
  const _RecentDayCard({required this.summary, required this.shows, required this.onTap});
  final DaySummary summary;
  final bool Function(HistoryFilter) shows;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final unit = ref.watch(settingsProvider).value?.waterUnit ?? VolumeUnit.ml;
    final tags = dayTags(l, summary, unit, shows);
    return RuvaCard(
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: Semantics(
        button: true,
        label:
            '${formatLongDay(summary.day)}: ${tags.isEmpty ? l.historyNothingLogged : tags.map((t) => t.$2).join(', ')}',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formatShortDay(summary.day), style: AppText.cardValue.copyWith(fontSize: 16)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (tags.isEmpty) _Tag(Icons.remove, l.historyNothingLogged),
                for (final (icon, text) in tags) _Tag(icon, text),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: AppColors.lime200, borderRadius: BorderRadius.circular(14)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text, style: AppText.cardSub.copyWith(color: AppColors.primary)),
        ),
      ],
    ),
  );
}

/// Everything recorded on [day]: fasts (tap to edit), water and activities.
class _DaySheet extends ConsumerWidget {
  const _DaySheet({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final settings = ref.watch(settingsProvider).value;
    final unit = settings?.waterUnit ?? VolumeUnit.ml;
    final use24h = settings?.use24HourTime ?? false;
    final next = DateTime(day.year, day.month, day.day + 1);
    final s = ref.watch(daySummariesProvider((day, next))).value?[day] ?? DaySummary(day);
    return Gap16Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MonoLabel(formatShortDay(day)),
            const SizedBox(height: 6),
            Semantics(
              header: true,
              child: Text(
                s.isEmpty ? l.historyNothingLogged : l.historyDaySummary,
                style: AppText.title.copyWith(fontSize: 22),
              ),
            ),
          ],
        ),
        if (s.isEmpty) Text(l.historySkipFine, style: AppText.body),
        for (final f in s.fasts) SessionTile(session: f),
        if (s.hasWater)
          Row(
            children: [
              const IconBubble(icon: Icons.water_drop_outlined, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(l.historyWaterEntries(formatVolume(s.waterMl, unit), s.water.length), style: AppText.body),
              ),
            ],
          ),
        for (final a in s.activities) ActivityCard(entry: a, use24h: use24h),
      ],
    );
  }
}

/// One session row: date, times, duration and a neutral status label.
class SessionTile extends ConsumerWidget {
  const SessionTile({super.key, required this.session});
  final FastingSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final use24h = ref.watch(settingsProvider).value?.use24HourTime ?? false;
    final now = ref.watch(nowProvider).value ?? DateTime.now();
    final s = session;
    final l = context.l10n;
    final (status, strong) = s.isActive
        ? (l.statusInProgress, true)
        : s.targetReachedAt(now)
        ? (l.statusTargetReached, true)
        : (l.statusEnded, false);
    final start = formatClock(s.startedAt, use24h: use24h);
    final times = s.endedAt == null
        ? l.sessionTimesOngoing(start)
        : l.sessionTimes(start, formatClock(s.endedAt!, use24h: use24h));

    return Semantics(
      button: true,
      label: l.sessionTileSemantics(
        formatShortDay(s.startedAt),
        times,
        formatHoursMinutes(s.elapsedAt(now)),
        formatTarget(s.target),
        status,
      ),
      excludeSemantics: true,
      // White card + shadow underneath; transparent Material on top so ripples show.
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppShadows.card,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => showSessionSheet(context, s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formatShortDay(s.startedAt).toUpperCase(), style: AppText.overline),
                        const SizedBox(height: 4),
                        Text(formatHoursMinutes(s.elapsedAt(now)), style: AppText.cardValue),
                        Text(l.sessionTileDetail(times, formatTarget(s.target)), style: AppText.cardSub),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: ShapeDecoration(
                      color: strong ? AppColors.soft : AppColors.background,
                      shape: StadiumBorder(side: BorderSide(color: strong ? AppColors.primary : AppColors.track)),
                    ),
                    child: Text(
                      status,
                      style: AppText.cardSub.copyWith(
                        fontWeight: FontWeight.w700,
                        color: strong ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
