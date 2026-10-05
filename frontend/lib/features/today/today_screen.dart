import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/brand_header.dart';
import '../../domain/fasting_timer.dart';
import '../../state/providers.dart';
import '../home/home_sheets.dart';
import '../hydration/hydration_screen.dart';
import '../ring/fasting_ring.dart';

/// First tab: greeting and the forest "hero" card holding today's fast
/// (brand guide: one hero card per screen). Tapping the ring opens the full
/// timer. Water, activity and food tiles join below as those features land.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key, required this.onOpenTimer, required this.onOpenWater});
  final VoidCallback onOpenTimer;
  final VoidCallback onOpenWater;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(timerSnapshotProvider(FastingRing.gapFor(300)));
    final settings = ref.watch(settingsProvider).value;
    final now = ref.watch(nowProvider).value;
    if (snap == null || settings == null || now == null) return const Center(child: CircularProgressIndicator());
    final l = context.l10n;
    final hour = now.toLocal().hour;
    final greeting = hour < 12
        ? l.greetingMorning
        : hour < 18
        ? l.greetingAfternoon
        : l.greetingEvening;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const BrandHeader(),
        const SizedBox(height: 12),
        Semantics(header: true, child: Text(greeting, style: AppText.title.copyWith(fontSize: 24, height: 1.2))),
        const SizedBox(height: 2),
        Text(formatLongDay(now), style: AppText.dateLine),
        const SizedBox(height: 16),
        _FastingHeroCard(snapshot: snap, use24h: settings.use24HourTime, now: now, onOpenTimer: onOpenTimer),
        const SizedBox(height: 10),
        Text(l.milestoneEstimateNote, style: AppText.small, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        WaterTile(onOpen: onOpenWater),
      ],
    );
  }
}

class _FastingHeroCard extends ConsumerWidget {
  const _FastingHeroCard({required this.snapshot, required this.use24h, required this.now, required this.onOpenTimer});

  final TimerSnapshot snapshot;
  final bool use24h;
  final DateTime now;
  final VoidCallback onOpenTimer;

  static const _onCard = Color(0xB3FFFFFF); // white 70%: secondary text on forest

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = snapshot;
    final session = ref.watch(activeSessionProvider).value;
    final target = formatTarget(s.target);
    final (status, detail) = !s.running || session == null
        ? (l.heroReady, l.heroIfStartedNow(target, formatClock(now.add(s.target), use24h: use24h)))
        : (
            s.targetReached ? l.ringTargetReached : l.heroFastingFor(formatHoursMinutes(s.elapsed)),
            l.heroEndsAt(target, formatClock(session.plannedEnd, use24h: use24h)),
          );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: l.ringSemantics(status, formatHoursMinutes(s.elapsed), target),
            hint: l.openTimer,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onOpenTimer,
              child: _CompactRing(snapshot: s),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.heroEyebrow, style: AppText.overline.copyWith(color: _onCard)),
                const SizedBox(height: 4),
                Text(status, style: AppText.title.copyWith(color: AppColors.white, fontSize: 18)),
                const SizedBox(height: 2),
                Text(detail, style: AppText.cardSub.copyWith(color: _onCard)),
                const SizedBox(height: 12),
                _LimeButton(
                  label: s.running ? l.endFast : l.startFast,
                  onPressed: s.running
                      ? () => showEndSheet(context)
                      : () => ref.read(activeSessionProvider.notifier).start(),
                ),
                TextButton(
                  onPressed: onOpenTimer,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.zero,
                    textStyle: AppText.link.copyWith(fontSize: 14),
                  ),
                  child: Text(l.openTimer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lime pill with forest label — the brand's accent button on dark cards.
class _LimeButton extends StatelessWidget {
  const _LimeButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.primaryDark,
        minimumSize: const Size(48, 48),
        textStyle: AppText.link.copyWith(fontSize: 15),
        padding: const EdgeInsets.symmetric(horizontal: 22),
      ),
      child: Text(label),
    ),
  );
}

/// Small ring for the hero card: lime progress on forest with the same
/// fat-burning/ketosis phase colours as the full timer.
class _CompactRing extends StatelessWidget {
  const _CompactRing({required this.snapshot});
  final TimerSnapshot snapshot;

  static const _size = 128.0;

  @override
  Widget build(BuildContext context) {
    final s = snapshot;
    return SizedBox.square(
      dimension: _size,
      child: CustomPaint(
        painter: RingArcPainter(
          progress: s.progress,
          radius: _size / 2 - 7,
          stroke: 10,
          phases: phaseStops(s),
          trackColor: const Color(0x2EFFFFFF),
          baseColor: AppColors.accent,
          knobColor: AppColors.primary,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                formatHms(s.elapsed),
                style: AppText.cardValue.copyWith(color: AppColors.white, fontSize: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
