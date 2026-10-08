import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:permission_handler/permission_handler.dart' show openAppSettings;

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ruva_kit.dart';
import '../../domain/food.dart';
import '../../domain/hydration.dart';
import '../../domain/steps.dart';
import '../../state/providers.dart';
import '../ring/fasting_ring.dart' show FastingRing;

/// Home dashboard (RUVA design): steps, then today's calories, hours fasted
/// and water. Logging happens from the centre + button.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onOpenTimer, required this.onOpenWater, required this.onOpenNutrition});
  final VoidCallback onOpenTimer;
  final VoidCallback onOpenWater;
  final VoidCallback onOpenNutrition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final now = ref.watch(nowProvider).value?.toLocal();
    final settings = ref.watch(settingsProvider).value;
    final snap = ref.watch(timerSnapshotProvider(FastingRing.gapFor(300)));
    if (now == null || settings == null || snap == null) return const Center(child: CircularProgressIndicator());
    final today = DateTime(now.year, now.month, now.day);
    final hour = now.hour;
    final greeting = hour < 12
        ? l.greetingMorning
        : hour < 18
        ? l.greetingAfternoon
        : l.greetingEvening;
    final name = settings.userName.trim().split(RegExp(r'\s+')).first;

    final food = ref.watch(diaryDayProvider(today)).value ?? const <FoodEntry>[];
    final kcal = DayTotals(food).sum[Nutrient.energy] ?? 0;
    final water = (ref.watch(hydrationDayProvider(today)).value ?? const <HydrationEntry>[]).fold(
      0.0,
      (a, e) => a + e.amountMl,
    );
    final unit = settings.waterUnit;
    final n = NumberFormat.decimalPattern();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        MonoLabel(DateFormat('EEEE · d MMM').format(now)),
        const SizedBox(height: 6),
        Semantics(
          header: true,
          child: Text(
            name.isEmpty ? greeting : l.homeGreeting(greeting, name),
            style: AppText.title.copyWith(fontSize: 22, height: 1.2),
          ),
        ),
        const SizedBox(height: 22),
        const _StepsCard(),
        const SizedBox(height: 28),
        MonoLabel(l.homeToday),
        const SizedBox(height: 12),
        _MetricRow(
          icon: Icons.local_fire_department_outlined,
          label: l.homeCalories,
          value: n.format(kcal.round()),
          unit: 'kcal',
          sub: l.homeCaloriesSub,
          onTap: onOpenNutrition,
        ),
        const SizedBox(height: 12),
        _MetricRow(
          icon: Icons.timer_outlined,
          label: l.homeFasted,
          value: snap.running ? formatHoursMinutes(snap.elapsed) : '—',
          sub: snap.running
              ? l.homeFastGoal(formatTarget(snap.target), (snap.progress * 100).round())
              : l.homeNotFasting,
          progress: snap.running ? snap.progress : null,
          onTap: onOpenTimer,
        ),
        const SizedBox(height: 12),
        _MetricRow(
          icon: Icons.water_drop_outlined,
          label: l.homeWater,
          value: formatVolume(water, unit),
          sub: l.homeWaterGoal(formatVolume(settings.waterGoalMl.toDouble(), unit)),
          progress: (water / settings.waterGoalMl).clamp(0.0, 1.0),
          onTap: onOpenWater,
        ),
      ],
    );
  }
}

class _StepsCard extends ConsumerWidget {
  const _StepsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final state = ref.watch(todayStepsProvider).value ?? const StepsState();
    final height = ref.watch(bodyProfileProvider).value?.heightCm;
    final n = NumberFormat.decimalPattern();
    final muted = AppText.small.copyWith(color: onForestMuted, fontSize: 13);
    final progress = (state.steps / dailyStepGoal).clamp(0.0, 1.0);

    return ForestCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.homeSteps, style: AppText.title.copyWith(color: AppColors.white, fontSize: 18)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.route_outlined, size: 15, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(l.homeKm(stepsToKm(state.steps, heightCm: height).toStringAsFixed(1)), style: muted),
              const SizedBox(width: 16),
              const Icon(Icons.flag_outlined, size: 15, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(l.homeStepGoal(n.format(dailyStepGoal)), style: muted),
            ],
          ),
          const SizedBox(height: 18),
          if (state.unavailable)
            Text(l.homeStepsUnavailable, style: muted)
          else if (state.needsPermission)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.homeStepsWhy, style: muted),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.primaryDark,
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: () async {
                        final ok = await ref.read(stepCounterProvider).request();
                        if (ok) {
                          ref.invalidate(todayStepsProvider);
                        } else if (context.mounted) {
                          showRuvaSnack(context, l.homeStepsDenied);
                        }
                      },
                      child: Text(l.homeStepsAllow),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: AppColors.white, minimumSize: const Size(48, 48)),
                      onPressed: openAppSettings,
                      child: Text(l.homeStepsOpenSettings),
                    ),
                  ],
                ),
              ],
            )
          else
            Center(
              child: Semantics(
                container: true,
                label: '${l.homeSteps}: ${n.format(state.steps)}, ${l.homeOfGoal((progress * 100).round())}',
                excludeSemantics: true,
                child: _Gauge(
                  progress: progress,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(n.format(state.steps), style: AppText.title.copyWith(fontSize: 30, color: AppColors.white)),
                      Text(
                        l.homeOfGoal((progress * 100).round()),
                        style: AppText.small.copyWith(color: AppColors.accent, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Segmented semicircle: lime ticks done, faint ticks to go.
class _Gauge extends StatelessWidget {
  const _Gauge({required this.progress, required this.child});
  final double progress;
  final Widget child;

  static const _width = 200.0;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: progress),
    duration: const Duration(milliseconds: 900),
    curve: Curves.easeOutCubic,
    builder: (context, v, _) => SizedBox(
      width: _width,
      height: _width * 0.56,
      child: CustomPaint(
        painter: _GaugePainter(v),
        child: Align(
          alignment: const Alignment(0, 0.95),
          child: FittedBox(fit: BoxFit.scaleDown, child: child),
        ),
      ),
    ),
  );
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.progress);
  final double progress;
  static const _segments = 26;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.98);
    final outer = size.width / 2 - 4, inner = outer * 0.72;
    final done = (progress * _segments).round();
    for (var i = 0; i < _segments; i++) {
      final angle = math.pi + i / (_segments - 1) * math.pi;
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + dir * inner,
        center + dir * outer,
        Paint()
          ..color = i < done ? AppColors.accent : const Color(0x40FFFFFF)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.progress != progress;
}

/// Daily row: icon disc, label and value, optional progress bar, subtitle.
class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.onTap,
    this.unit,
    this.progress,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? unit;
  final String sub;
  final double? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    label: '$label: $value${unit == null ? '' : ' $unit'}. $sub',
    excludeSemantics: true,
    child: Material(
      color: AppColors.lime200.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(label, style: AppText.body.copyWith(color: AppColors.textSecondary)),
                        ),
                        Text(value, style: AppText.cardValue.copyWith(fontSize: 17)),
                        if (unit != null) ...[
                          const SizedBox(width: 3),
                          Text(unit!, style: AppText.small.copyWith(fontSize: 12)),
                        ],
                      ],
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppColors.track,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primaryMid),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(sub, style: AppText.small.copyWith(fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
