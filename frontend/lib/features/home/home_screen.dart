import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/sheet.dart';
import '../../domain/milestone.dart';
import '../../state/providers.dart';
import '../ring/fasting_ring.dart';
import 'home_sheets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenSettings,
    required this.onOpenHistory,
    required this.onChangeTarget,
    required this.onReadMore,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onOpenHistory;
  final VoidCallback onChangeTarget;
  final ValueChanged<Milestone> onReadMore;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _ringSize = 300.0;

  /// "Saved to history · 12 h 24 m" after ending, until the next start.
  String? _saved;

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

    final (strong, tail) = running
        ? snap.targetReached
              ? ('Target reached', ' · end whenever you’re ready')
              : (formatHms(snap.remaining), ' remaining')
        : ('', _saved != null ? 'Saved to history · $_saved' : 'Your timer is ready');

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(onOpenSettings: widget.onOpenSettings),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('${formatLongDay(now)}${running ? ' · Session in progress' : ''}', style: AppText.dateLine),
        ),
        const SizedBox(height: 16),
        Center(
          child: FastingRing(
            snapshot: snap,
            size: _ringSize,
            onPick: (m) => showMilestoneSheet(context, milestone: m, onReadMore: () => widget.onReadMore(m)),
            onCenterTap: () => showSessionTimesSheet(context),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: strong,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: tail),
              ],
            ),
            textAlign: TextAlign.center,
            style: AppText.link.copyWith(fontWeight: FontWeight.w600, fontFeatures: AppText.tabular),
          ),
        ),
        const SizedBox(height: 20),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: running
                ? [
                    PillButton(label: 'End fast', large: true, onPressed: _askEnd),
                    const SizedBox(height: 4),
                    _LinkRow(
                      links: {
                        'Edit start time': () => showEditStartSheet(context, startedAt: session.startedAt),
                        'View history': widget.onOpenHistory,
                      },
                    ),
                  ]
                : [
                    PillButton(label: 'Start fast', large: true, onPressed: _start),
                    const SizedBox(height: 4),
                    _LinkRow(links: {'Change target': widget.onChangeTarget, 'View history': widget.onOpenHistory}),
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

  Future<void> _start() async {
    setState(() => _saved = null);
    await ref.read(activeSessionProvider.notifier).start();
  }

  Future<void> _askEnd() async {
    final ended = await showEndSheet(context);
    if (ended != null && mounted) {
      setState(() => _saved = formatHoursMinutes(ended.elapsedAt(ended.endedAt!)));
    }
  }
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
          const AppLogo(),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(header: true, child: const Text('Fasting Companion', style: AppText.brand)),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: onOpenSettings,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            icon: const AppIconView(AppIcon.settings, color: AppColors.deep, strokeWidth: 1.8),
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
        borderRadius: BorderRadius.circular(16),
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

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.links});
  final Map<String, VoidCallback> links;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 8,
    children: [for (final e in links.entries) TextButton(onPressed: e.value, child: Text(e.key))],
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
      return Gap16Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: session != null
                      ? _InfoCard(
                          label: 'FAST STARTED',
                          value: formatClock(session.startedAt, use24h: use24h),
                          sub: formatShortDay(session.startedAt),
                        )
                      : _InfoCard(label: 'TARGET', value: _targetWords(target), sub: 'Change any time'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoCard(
                    label: session != null ? 'PLANNED END' : 'IF STARTED NOW',
                    value: formatClock(plannedEnd, use24h: use24h),
                    sub: formatShortDay(plannedEnd),
                  ),
                ),
              ],
            ),
          ),
          PillButton(label: 'Close', onPressed: () => Navigator.pop(ctx)),
        ],
      );
    },
  ),
);

String _targetWords(Duration d) => d.inMinutes.remainder(60) == 0 ? '${d.inHours} hours' : formatTarget(d);
