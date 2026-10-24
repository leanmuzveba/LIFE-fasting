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
/// fitness icon and the RUVA logo. Any day can be picked.
class StatsExportScreen extends ConsumerStatefulWidget {
  const StatsExportScreen({super.key, required this.day});
  final DateTime day; // local midnight

  @override
  ConsumerState<StatsExportScreen> createState() => _StatsExportScreenState();
}

class _StatsExportScreenState extends ConsumerState<StatsExportScreen> {
  late DateTime _day = widget.day;
  ExportStyle _style = ExportStyle.white;
  ExportLayout _layout = ExportLayout.compact;
  final _card = GlobalKey();
  bool _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      await sharePng(_card, 'ruva-${DateFormat('yyyy-MM-dd').format(_day)}.png');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final stats = ref.watch(dayStatsProvider(_day)).value;
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
            DayNav(day: _day, onChanged: (d) => setState(() => _day = d)),
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
            const SizedBox(height: 6),
            Row(
              children: [
                for (final (i, lay) in ExportLayout.values.indexed) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: RuvaChip(
                      label: lay == ExportLayout.compact ? l.layoutCompact : l.layoutPoster,
                      selected: lay == _layout,
                      dense: true,
                      outlined: true,
                      onTap: () => setState(() => _layout = lay),
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
                      child: StatsCard(day: _day, stats: stats, style: _style, layout: _layout),
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

/// ‹ previous day · pick a date · next day › (never past today).
class DayNav extends ConsumerWidget {
  const DayNav({super.key, required this.day, required this.onChanged});
  final DateTime day; // local midnight
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final n = ref.read(clockProvider)().toLocal();
    final today = DateTime(n.year, n.month, n.day);
    void shift(int days) => onChanged(DateTime(day.year, day.month, day.day + days));
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: l.previousDay,
          onPressed: () => shift(-1),
          icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
        ),
        TextButton.icon(
          onPressed: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: day,
              firstDate: DateTime(2020),
              lastDate: today,
            );
            if (d != null) onChanged(d);
          },
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
          label: Text(DateFormat('EEE d MMM y').format(day), semanticsLabel: l.pickDay),
        ),
        IconButton(
          tooltip: l.nextDay,
          onPressed: day.isBefore(today) ? () => shift(1) : null,
          icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
        ),
      ],
    );
  }
}

/// Renders the [RepaintBoundary] under [key] to a transparent PNG and opens
/// the share sheet.
Future<void> sharePng(GlobalKey key, String name) async {
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 3); // ~1080 px wide
  final png = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(png, mimeType: 'image/png', name: name)],
    ),
  );
}

/// The day on an exported image, as large as its stats: weekday, then date.
class ExportDate extends StatelessWidget {
  const ExportDate(this.day, {super.key});
  final DateTime day;

  @override
  Widget build(BuildContext context) => Text(
    '${DateFormat('EEEE').format(day)}\n${DateFormat('d MMM y').format(day)}',
    textAlign: TextAlign.center,
    style: const TextStyle(
      fontFamily: AppFonts.display,
      fontWeight: FontWeight.w700,
      fontSize: 34,
      height: 1.15,
      color: Colors.white,
    ),
  );
}

/// Looks for the exported image (after your reference PNGs). Stats are
/// always white; the icon and brand mark change.
enum ExportStyle {
  white(Colors.white, Colors.white),
  lime(AppColors.accent, AppColors.primary), // lime icon, forest wordmark
  forest(AppColors.primary, AppColors.accent), // forest icon, lime wordmark
  badge(AppColors.primary, null); // forest icon, round RUVA logo

  const ExportStyle(this.line, this.wordmark);
  final Color line; // the icon
  final Color? wordmark; // null: the round logo instead

  /// The RUVA wordmark tinted for this style, or the round logo.
  Widget mark({required double wordmark, required double logo}) => switch (this.wordmark) {
    final c? => Image.asset('assets/brand/wordmark.png', width: wordmark, color: c, semanticLabel: 'RUVA'),
    null => RuvaLogo(size: logo, semanticLabel: 'RUVA'),
  };

  String label(AppLocalizations l) => switch (this) {
    white => l.styleWhite,
    lime => l.styleLime,
    forest => l.styleForest,
    badge => l.styleBadge,
  };
}

/// compact: stats, small icon, small mark. poster (your path1/path30): big
/// icon on top, stats, full-width wordmark at the bottom.
enum ExportLayout { compact, poster }

/// The exported image on a transparent background.
class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.day,
    required this.stats,
    this.style = ExportStyle.white,
    this.layout = ExportLayout.compact,
  });
  final DateTime day;
  final DayStats stats;
  final ExportStyle style;
  final ExportLayout layout;

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
    final poster = layout == ExportLayout.poster;
    final icon = Icon(fitnessIcon(day), size: poster ? 120 : 72, color: style.line);
    final brand = style.mark(wordmark: poster ? 300 : 130, logo: poster ? 96 : 64);

    return SizedBox(
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (poster) ...[icon, const SizedBox(height: 24)],
          ExportDate(day),
          const SizedBox(height: 18),
          if (stats.steps != null) stat(l.statSteps, n.format(stats.steps)),
          if (stats.km != null) stat(l.statDistance, '${stats.km!.toStringAsFixed(2)} km'),
          stat(l.statBurned, '${n.format(stats.kcal.round())} kcal'),
          stat(l.statActive, h > 0 ? '${h}h ${m}m' : '$m min'),
          if (!poster) ...[icon, const SizedBox(height: 18)] else const SizedBox(height: 10),
          brand,
        ],
      ),
    );
  }
}

/// A fitness icon for the exported image, different from day to day.
IconData fitnessIcon(DateTime day) => const [
  Icons.directions_run_rounded,
  Icons.fitness_center_rounded,
  Icons.directions_walk_rounded,
  Icons.self_improvement_rounded,
  Icons.directions_bike_rounded,
  Icons.hiking_rounded,
  Icons.sports_gymnastics_rounded,
  Icons.favorite_rounded,
][(day.year * 400 + day.month * 32 + day.day) % 8];
