import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:share_plus/share_plus.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ruva_kit.dart';
import '../../core/widgets/ruva_logo.dart';
import '../../state/providers.dart';

/// Strava-style overlay: a day's stats in white on a transparent PNG, with a
/// route line and the RUVA logo. Any day can be picked.
class StatsExportScreen extends ConsumerStatefulWidget {
  const StatsExportScreen({super.key, required this.day});
  final DateTime day; // local midnight

  @override
  ConsumerState<StatsExportScreen> createState() => _StatsExportScreenState();
}

class _StatsExportScreenState extends ConsumerState<StatsExportScreen> {
  late DateTime _day = widget.day;
  ExportStyle _style = ExportStyle.white;
  final _card = GlobalKey();
  bool _busy = false;

  DateTime get _today {
    final n = ref.read(clockProvider)().toLocal();
    return DateTime(n.year, n.month, n.day);
  }

  void _shift(int days) => setState(() => _day = DateTime(_day.year, _day.month, _day.day + days));

  Future<void> _pick() async {
    final d = await showDatePicker(context: context, initialDate: _day, firstDate: DateTime(2020), lastDate: _today);
    if (d != null) setState(() => _day = d);
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final boundary = _card.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3); // ~1080 px wide
      final png = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      final name = 'ruva-${DateFormat('yyyy-MM-dd').format(_day)}.png';
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(png, mimeType: 'image/png', name: name)],
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final stats = ref.watch(dayStatsProvider(_day)).value;
    final isToday = !_day.isBefore(_today);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: l.back,
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.chevron_left_rounded, size: 30, color: AppColors.primary),
                ),
                Semantics(header: true, child: Text(l.shareDayTitle, style: AppText.title.copyWith(fontSize: 20))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: l.previousDay,
                  onPressed: () => _shift(-1),
                  icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
                ),
                TextButton.icon(
                  onPressed: _pick,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(DateFormat('EEE d MMM y').format(_day), semanticsLabel: l.pickDay),
                ),
                IconButton(
                  tooltip: l.nextDay,
                  onPressed: isToday ? null : () => _shift(1),
                  icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final (i, st) in ExportStyle.values.indexed) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: RuvaChip(
                      label: st.label(l),
                      selected: st == _style,
                      dense: true,
                      outlined: true,
                      onTap: () => setState(() => _style = st),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            // Grey backdrop only in the preview, so white, lime and forest all
            // show; the exported PNG is just the card (transparent).
            Container(
              decoration: BoxDecoration(color: const Color(0xFF5C6660), borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: stats == null
                  ? const Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator())
                  : RepaintBoundary(
                      key: _card,
                      child: StatsCard(day: _day, stats: stats, style: _style),
                    ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: l.shareDayButton, onPressed: stats == null || _busy ? null : _export),
          ],
        ),
      ),
    );
  }
}

/// Looks for the exported image (after your reference PNGs). Stats are
/// always white; the route line and brand mark change.
enum ExportStyle {
  white(Colors.white, Colors.white),
  lime(AppColors.accent, AppColors.primary), // lime route, forest wordmark
  forest(AppColors.primary, AppColors.accent), // forest route, lime wordmark
  badge(AppColors.primary, null); // forest route, round RUVA logo

  const ExportStyle(this.line, this.wordmark);
  final Color line;
  final Color? wordmark; // null: the round logo instead

  String label(AppLocalizations l) => switch (this) {
    white => l.styleWhite,
    lime => l.styleLime,
    forest => l.styleForest,
    badge => l.styleBadge,
  };
}

/// The exported image on a transparent background.
class StatsCard extends StatelessWidget {
  const StatsCard({super.key, required this.day, required this.stats, this.style = ExportStyle.white});
  final DateTime day;
  final DayStats stats;
  final ExportStyle style;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final n = NumberFormat.decimalPattern();
    const white = Colors.white;
    Widget stat(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontFamily: AppFonts.body, fontSize: 14, color: white),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 34,
              height: 1.15,
              color: white,
            ),
          ),
        ],
      ),
    );
    final h = stats.activeMinutes ~/ 60, m = stats.activeMinutes % 60;

    return SizedBox(
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('EEEE · d MMM y').format(day).toUpperCase(),
            style: const TextStyle(fontFamily: AppFonts.mono, fontSize: 12, letterSpacing: 1.2, color: white),
          ),
          const SizedBox(height: 18),
          if (stats.steps != null) stat(l.statSteps, n.format(stats.steps)),
          if (stats.km != null) stat(l.statDistance, '${stats.km!.toStringAsFixed(2)} km'),
          stat(l.statBurned, '${n.format(stats.kcal.round())} kcal'),
          stat(l.statActive, h > 0 ? '${h}h ${m}m' : '$m min'),
          SizedBox(
            width: 150,
            height: 110,
            child: CustomPaint(
              painter: _RoutePainter(seed: day.year * 400 + day.month * 32 + day.day, color: style.line),
            ),
          ),
          const SizedBox(height: 22),
          if (style.wordmark case final c?)
            Image.asset('assets/brand/wordmark.png', width: 130, color: c, semanticLabel: 'RUVA')
          else
            const RuvaLogo(size: 64, semanticLabel: 'RUVA'),
        ],
      ),
    );
  }
}

/// A smooth hand-drawn-looking route line (different every day).
// ponytail: decorative, not your real route — RUVA doesn't record GPS. Read
// Health Connect exercise routes if a real map line is wanted.
class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.seed, required this.color});
  final int seed;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(seed);
    const count = 9;
    final c = size.center(Offset.zero);
    // Points around an open loop (like a walk that nearly returns home).
    final pts = [
      for (var i = 0; i < count; i++)
        () {
          final a = -math.pi / 2 + i / count * 2 * math.pi * 0.9;
          final k = 0.65 + r.nextDouble() * 0.35;
          return c + Offset(math.cos(a) * size.width / 2 * k, math.sin(a) * size.height / 2 * k);
        }(),
    ];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      // Catmull-Rom → cubic Bézier for a smooth line through every point.
      final p0 = pts[math.max(i - 1, 0)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[math.min(i + 2, pts.length - 1)];
      final c1 = p1 + (p2 - p0) / 6, c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.seed != seed || old.color != color;
}
