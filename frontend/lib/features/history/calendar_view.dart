import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/l10n.dart';
import '../../core/icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../domain/fasting_session.dart';
import 'history_screen.dart';

/// Month grid; days with a session (by local start date) get a dot.
class CalendarView extends StatefulWidget {
  const CalendarView({super.key, required this.sessions});
  final List<FastingSession> sessions;

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late DateTime _month = _monthOf(widget.sessions.first.startedAt.toLocal());
  DateTime? _day;

  static DateTime _monthOf(DateTime d) => DateTime(d.year, d.month);
  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final byDay = <DateTime, List<FastingSession>>{};
    for (final s in widget.sessions) {
      byDay.putIfAbsent(_dayOf(s.startedAt.toLocal()), () => []).add(s);
    }
    final first = _month;
    final leading = first.weekday - 1; // Monday-first
    final daysInMonth = DateTime(first.year, first.month + 1, 0).day;
    final selected = _day == null ? const <FastingSession>[] : byDay[_day] ?? const [];
    final l = context.l10n;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l.previousMonth,
              onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
              icon: const AppIconView(AppIcon.back, color: AppColors.primary),
            ),
            Expanded(
              child: Text(
                DateFormat('MMMM y').format(_month),
                textAlign: TextAlign.center,
                style: AppText.cardValue.copyWith(fontSize: 17),
              ),
            ),
            IconButton(
              tooltip: l.nextMonth,
              onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
              icon: const AppIconView(AppIcon.chevronRight, color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final d in l.weekdayInitials.split(','))
              Expanded(
                child: ExcludeSemantics(
                  child: Text(d, textAlign: TextAlign.center, style: AppText.overline),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < leading; i++) const SizedBox(),
            for (var d = 1; d <= daysInMonth; d++)
              _DayCell(
                date: DateTime(first.year, first.month, d),
                count: byDay[DateTime(first.year, first.month, d)]?.length ?? 0,
                selected: _day == DateTime(first.year, first.month, d),
                onTap: () => setState(() => _day = DateTime(first.year, first.month, d)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_day != null && selected.isEmpty)
          Text(
            l.noSessionsOn(DateFormat('EEEE d MMMM').format(_day!)),
            textAlign: TextAlign.center,
            style: AppText.small,
          ),
        for (final s in selected) ...[SessionTile(session: s), const SizedBox(height: 10)],
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.date, required this.count, required this.selected, required this.onTap});
  final DateTime date;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: context.l10n.daySessions(DateFormat('EEEE d MMMM').format(date), count),
    excludeSemantics: true,
    child: InkResponse(
      onTap: onTap,
      radius: 22,
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppColors.primary : (count > 0 ? AppColors.soft : null),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: AppText.link.copyWith(
                fontSize: 14,
                color: selected ? AppColors.white : (count > 0 ? AppColors.primary : AppColors.text),
              ),
            ),
            // Dot as well as colour, so state isn't shown by colour alone.
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: count == 0 ? Colors.transparent : (selected ? AppColors.accent : AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
