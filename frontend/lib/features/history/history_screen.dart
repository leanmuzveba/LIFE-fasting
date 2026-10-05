import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/page_header.dart';
import '../../domain/fasting_session.dart';
import '../../state/providers.dart';
import 'calendar_view.dart';
import 'session_sheet.dart';

/// Recorded sessions as a list or a month calendar (FR-09).
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  bool _calendar = false;

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(historyProvider).value;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(l.navHistory),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: false, label: Text(l.historyList)),
              ButtonSegment(value: true, label: Text(l.historyCalendar)),
            ],
            selected: {_calendar},
            onSelectionChanged: (v) => setState(() => _calendar = v.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.pale,
              selectedForegroundColor: AppColors.deep,
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.track),
              textStyle: AppText.link.copyWith(fontSize: 14),
            ),
          ),
        ),
        Expanded(
          child: switch (sessions) {
            null => const Center(child: CircularProgressIndicator()),
            [] => const _EmptyState(),
            final list when _calendar => CalendarView(sessions: list),
            final list => ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => SessionTile(session: list[i]),
            ),
          },
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.pale, shape: BoxShape.circle),
            child: const AppIconView(AppIcon.calendar, size: 30, color: AppColors.deep),
          ),
          const SizedBox(height: 16),
          Text(context.l10n.historyEmptyTitle, style: AppText.title),
          const SizedBox(height: 6),
          Text(context.l10n.historyEmptyBody, textAlign: TextAlign.center, style: AppText.small),
        ],
      ),
    ),
  );
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
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showSessionSheet(context, s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.card),
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
                    color: strong ? AppColors.pale : AppColors.background,
                    shape: StadiumBorder(side: BorderSide(color: strong ? AppColors.sky : AppColors.track)),
                  ),
                  child: Text(
                    status,
                    style: AppText.cardSub.copyWith(
                      fontWeight: FontWeight.w700,
                      color: strong ? AppColors.deep : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
