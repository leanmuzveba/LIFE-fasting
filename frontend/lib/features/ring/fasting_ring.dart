import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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

/// Arc / icon colour a milestone starts. Kinds without one keep the previous
/// phase colour (the later stage stays red).
/// (arc colour, icon colour on the filled marker, icon colour on light surfaces)
(Color, Color, Color)? phaseColors(MilestoneKind k) => switch (k) {
  MilestoneKind.bolt => (AppColors.fatBurning, AppColors.onFatBurning, AppColors.fatBurningIcon),
  MilestoneKind.drop => (AppColors.ketosis, AppColors.onKetosis, AppColors.ketosis),
  _ => null,
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

  /// Minimum spacing between markers so 48px tap targets never overlap.
  static double gapFor(double size) => 46 / (2 * math.pi * radiusFor(size));

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
                  painter: _RingPainter(
                    progress: s.progress,
                    radius: r,
                    stroke: _stroke,
                    phases: [
                      for (final m in s.markers)
                        if (phaseColors(m.milestone.kind) case (final c, _, _)) (m.fraction, c),
                    ],
                  ),
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
                  left: pt(m.fraction).dx - 24,
                  top: pt(m.fraction).dy - 24,
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
    final phase = phaseColors(m.kind);
    final accent = phase?.$1 ?? AppColors.sky;
    final (bg, border, fg, shadows, word) = switch (placement.state) {
      MarkerState.current => (
        accent,
        BorderSide(color: accent, width: 2),
        phase?.$2 ?? AppColors.onSky,
        [BoxShadow(color: accent.withValues(alpha: 0.28), spreadRadius: 6)],
        'current estimate',
      ),
      MarkerState.passed => (
        AppColors.white,
        BorderSide(color: accent, width: 2),
        phase?.$3 ?? AppColors.deep,
        const [BoxShadow(color: Color(0x24203443), offset: Offset(0, 1), blurRadius: 3)],
        'passed',
      ),
      MarkerState.upcoming => (
        AppColors.background,
        const BorderSide(color: AppColors.inputBorder, width: 1.5),
        phase?.$3 ?? AppColors.muted,
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
          dimension: 48,
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
  _RingPainter({required this.progress, required this.radius, required this.stroke, required this.phases});

  final double progress;
  final double radius;
  final double stroke;

  /// (start fraction, colour) for each phase after the initial sky blue.
  final List<(double, Color)> phases;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, paint..color = AppColors.track);
    if (progress <= 0) return;

    final end = math.min(progress, 1.0);
    Offset at(double f) {
      final a = f * 2 * math.pi - math.pi / 2;
      return center + Offset(radius * math.cos(a), radius * math.sin(a));
    }

    // Segments: sky until the first phase, then each phase colour until the next.
    final stops = [(0.0, AppColors.sky), ...phases];
    var endColor = AppColors.sky;
    for (var i = 0; i < stops.length; i++) {
      final from = stops[i].$1;
      if (from >= end) break;
      final to = math.min(i + 1 < stops.length ? stops[i + 1].$1 : 1.0, end);
      endColor = stops[i].$2;
      canvas.drawArc(rect, from * 2 * math.pi - math.pi / 2, (to - from) * 2 * math.pi, false, paint..color = endColor);
    }
    if (end >= 1) return;

    // Round caps at both ends, then the white knob at the tip.
    final dot = Paint()..color = AppColors.sky;
    canvas.drawCircle(at(0), stroke / 2, dot);
    canvas.drawCircle(at(end), stroke / 2, dot..color = endColor);
    canvas.drawCircle(at(end), 3.5, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.radius != radius || !listEquals(old.phases, phases);
}
