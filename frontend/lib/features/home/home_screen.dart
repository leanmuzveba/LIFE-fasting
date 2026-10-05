import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/ruva_logo.dart';
import '../../core/widgets/sheet.dart';
import '../../domain/milestone.dart';
import '../../state/providers.dart';
import '../ring/fasting_ring.dart';
import 'home_sheets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.onOpenSettings, required this.onChangeTarget, required this.onReadMore});

  final VoidCallback onOpenSettings;
  final VoidCallback onChangeTarget;
  final ValueChanged<Milestone> onReadMore;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _ringSize = 300.0;

  @override
  Widget build(BuildContext context) {
    final snap = ref.watch(timerSnapshotProvider(FastingRing.gapFor(_ringSize)));
    final settings = ref.watch(settingsProvider).value;
    final session = ref.watch(activeSessionProvider).value;
    final now = ref.watch(nowProvider).value;
    if (snap == null || settings == null || now == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final running = snap.running && session != null;
    final l = context.l10n;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(onOpenSettings: widget.onOpenSettings),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            running ? l.homeSessionInProgress(formatLongDay(now)) : formatLongDay(now),
            style: AppText.dateLine,
          ),
        ),
        // The ring sits in the middle of the space between the date and the buttons.
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: FastingRing(
                snapshot: snap,
                size: _ringSize,
                onPick: (m) => showMilestoneSheet(context, milestone: m, onReadMore: () => widget.onReadMore(m)),
                onCenterTap: () => showSessionTimesSheet(context),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            children: running
                ? [
                    _MainButton(label: l.endFast, onPressed: _askEnd),
                    const SizedBox(height: 4),
                    _LinkRow(links: {l.editStartTime: () => showEditStartSheet(context, startedAt: session.startedAt)}),
                  ]
                : [
                    _MainButton(label: l.startFast, onPressed: _start),
                    const SizedBox(height: 4),
                    _LinkRow(links: {l.changeTarget: widget.onChangeTarget}),
                  ],
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: IntrinsicHeight(child: content),
        ),
      ),
    );
  }

  Future<void> _start() => ref.read(activeSessionProvider.notifier).start();

  Future<void> _askEnd() => showEndSheet(context);
}

class _Header extends StatelessWidget {
  const _Header({required this.onOpenSettings});
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
    child: SizedBox(
      height: 48,
      child: Row(
        children: [
          const RuvaLogo(size: 36, semanticLabel: null),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(header: true, child: Text(context.l10n.appName, style: AppText.brand)),
          ),
          IconButton(
            tooltip: context.l10n.navSettings,
            onPressed: onOpenSettings,
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            icon: const AppIconView(AppIcon.settings, color: AppColors.primary, strokeWidth: 1.8),
          ),
        ],
      ),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value, required this.sub});
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '$label: $value, $sub',
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.overline),
          const SizedBox(height: 4),
          Text(value, style: AppText.cardValue),
          Text(sub, style: AppText.cardSub),
        ],
      ),
    ),
  );
}

/// Compact primary action: 48px tall (minimum tap height), not full width.
class _MainButton extends StatelessWidget {
  const _MainButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 200, maxWidth: 240),
    child: PillButton(label: label, onPressed: onPressed),
  );
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.links});
  final Map<String, VoidCallback> links;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 8,
    children: [
      for (final e in links.entries)
        TextButton(
          onPressed: e.value,
          style: TextButton.styleFrom(textStyle: AppText.link.copyWith(fontSize: 14)),
          child: Text(e.key),
        ),
    ],
  );
}

/// FAST STARTED / PLANNED END (or TARGET / IF STARTED NOW) cards, shown as a
/// pop-up when the centre of the ring is tapped.
Future<void> showSessionTimesSheet(BuildContext context) => showAppSheet<void>(
  context,
  (ctx) => Consumer(
    builder: (ctx, ref, _) {
      final session = ref.watch(activeSessionProvider).value;
      final settings = ref.watch(settingsProvider).value;
      final now = ref.watch(nowProvider).value ?? DateTime.now();
      final use24h = settings?.use24HourTime ?? false;
      final target = Duration(minutes: session?.targetMinutes ?? settings?.targetMinutes ?? 16 * 60);
      final plannedEnd = (session?.startedAt ?? now).add(target);
      final l = ctx.l10n;
      return Gap16Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: session != null
                      ? _InfoCard(
                          label: l.cardFastStarted,
                          value: formatClock(session.startedAt, use24h: use24h),
                          sub: formatShortDay(session.startedAt),
                        )
                      : _InfoCard(label: l.cardTarget, value: _targetWords(l, target), sub: l.cardChangeAnyTime),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoCard(
                    label: session != null ? l.cardPlannedEnd : l.cardIfStartedNow,
                    value: formatClock(plannedEnd, use24h: use24h),
                    sub: formatShortDay(plannedEnd),
                  ),
                ),
              ],
            ),
          ),
          PillButton(label: l.close, onPressed: () => Navigator.pop(ctx)),
        ],
      );
    },
  ),
);

String _targetWords(AppLocalizations l, Duration d) =>
    d.inMinutes.remainder(60) == 0 ? l.targetHours(d.inHours) : formatTarget(d);
