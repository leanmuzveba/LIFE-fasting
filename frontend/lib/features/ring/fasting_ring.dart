import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../domain/fasting_timer.dart';
import '../../domain/milestone.dart';

AppIcon milestoneIcon(MilestoneKind k, {bool detailed = false}) => switch (k) {
  MilestoneKind.clock => AppIcon.clock,
  MilestoneKind.bolt => AppIcon.bolt,
  MilestoneKind.drop => detailed ? AppIcon.dropDetail : AppIcon.drop,
  MilestoneKind.flame => AppIcon.flame,
};

/// The signature circular timer: track, progress arc, centre readout,
/// and tappable milestone markers. Milestones past the target are not shown.
class FastingRing extends StatelessWidget {
  const FastingRing({super.key, required this.snapshot, required this.onPick, this.onCenterTap, this.size = 300});

  final TimerSnapshot snapshot;
  final ValueChanged<Milestone> onPick;

  /// Tapping inside the ring (the time readout) — Home shows session times.
  final VoidCallback? onCenterTap;
  final double size;

  static const _stroke = 14.0;
  static double radiusFor(double size) => size / 2 - 26;

  /// Minimum spacing between markers so 44px tap targets never overlap.
  static double gapFor(double size) => 42 / (2 * math.pi * radiusFor(size));

  @override
  Widget build(BuildContext context) {
    final s = snapshot;
    final c = size / 2;
    final r = radiusFor(size);
    Offset pt(double f) {
      final a = f * 2 * math.pi - math.pi / 2;
      return Offset(c + r * math.cos(a), c + r * math.sin(a));
    }

    final status = !s.running
        ? 'Ready when you are'
        : s.targetReached
        ? 'Target reached'
        : 'Fasting in progress';
    final targetLine = '${s.running ? 'of ' : ''}${formatTarget(s.target)} target';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RingPainter(progress: s.progress, radius: r, stroke: _stroke),
                ),
              ),
              Positioned.fill(
                child: Semantics(
                  container: true,
                  button: onCenterTap != null,
                  hint: onCenterTap == null ? null : 'Shows start and planned end times',
                  onTap: onCenterTap,
                  label:
                      '$status. ${formatHoursMinutes(s.elapsed)} elapsed, $targetLine'
                      '${s.running && !s.targetReached ? ', ${formatHoursMinutes(s.remaining)} remaining' : ''}.',
                  child: ExcludeSemantics(
                    child: Center(
                      child: Material(
                        type: MaterialType.transparency,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: onCenterTap,
                          child: SizedBox.square(
                            dimension: 2 * (r - _stroke / 2 - 4),
                            child: Center(
                              child: SizedBox(
                                width: (r - _stroke) * 1.55,
                                height: (r - _stroke) * 1.3,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: _Readout(
                                    status: status,
                                    time: formatHms(s.elapsed),
                                    targetLine: targetLine,
                                    timerSize: (size * 0.135).roundToDouble(),
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
              ),
              for (final m in s.markers)
                Positioned(
                  left: pt(m.fraction).dx - 22,
                  top: pt(m.fraction).dy - 22,
                  child: _Marker(placement: m, onTap: () => onPick(m.milestone)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout({required this.status, required this.time, required this.targetLine, required this.timerSize});

  final String status;
  final String time;
  final String targetLine;
  final double timerSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Running-but-not-reached shows no label: the ring speaks for itself.
        if (status != 'Fasting in progress') ...[
          Text(status.toUpperCase(), style: AppText.overline.copyWith(letterSpacing: 1.32, color: AppColors.deep)),
          const SizedBox(height: 4),
        ],
        Text(
          time,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: timerSize,
            height: 1.1,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.01 * timerSize,
            color: AppColors.text,
            fontFeatures: AppText.tabular,
          ),
        ),
        const SizedBox(height: 4),
        Text('TIME ELAPSED', style: AppText.overline.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.32)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: const ShapeDecoration(color: AppColors.pale, shape: StadiumBorder()),
          child: Text(
            targetLine,
            style: AppText.cardSub.copyWith(fontWeight: FontWeight.w700, color: AppColors.deep),
          ),
        ),
      ],
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.placement, required this.onTap});

  final MarkerPlacement placement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = placement.milestone;
    final (bg, border, fg, shadows, word) = switch (placement.state) {
      MarkerState.current => (
        AppColors.sky,
        const BorderSide(color: AppColors.sky, width: 2),
        AppColors.onSky,
        const [BoxShadow(color: Color(0x4765BFE8), spreadRadius: 6)],
        'current estimate',
      ),
      MarkerState.passed => (
        AppColors.white,
        const BorderSide(color: AppColors.sky, width: 2),
        AppColors.deep,
        const [BoxShadow(color: Color(0x24203443), offset: Offset(0, 1), blurRadius: 3)],
        'passed',
      ),
      MarkerState.upcoming => (
        AppColors.background,
        const BorderSide(color: AppColors.inputBorder, width: 1.5),
        AppColors.muted,
        const <BoxShadow>[],
        'upcoming',
      ),
    };
    final hours = m.offsetMinutes == 0 ? '' : 'around ${formatTarget(m.offset)}, ';

    return Semantics(
      button: true,
      label: '${m.title}, $hours$word. Opens details.',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bg,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(border),
                    boxShadow: shadows,
                  ),
                  child: AppIconView(milestoneIcon(m.kind), size: 18, color: fg),
                ),
                if (placement.state == MarkerState.passed)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 15,
                      height: 15,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.deep,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: const AppIconView(AppIcon.check, size: 9, color: AppColors.white, strokeWidth: 3.5),
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

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.radius, required this.stroke});

  final double progress;
  final double radius;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, base..color = AppColors.track);
    if (progress <= 0) return;
    if (progress >= 1) {
      canvas.drawCircle(center, radius, base..color = AppColors.sky);
      return;
    }
    final sweep = progress * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      base
        ..color = AppColors.sky
        ..strokeCap = StrokeCap.round,
    );
    final a = sweep - math.pi / 2;
    canvas.drawCircle(
      center + Offset(radius * math.cos(a), radius * math.sin(a)),
      3.5,
      Paint()..color = AppColors.white,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.radius != radius;
}
