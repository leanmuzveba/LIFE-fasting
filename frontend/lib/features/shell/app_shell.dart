import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ruva_kit.dart';
import '../../core/widgets/sheet.dart';
import '../../domain/hydration.dart';
import '../../domain/milestone.dart';
import '../../state/providers.dart';
import '../activity_water/activity_water_screen.dart';
import '../food/food_diary_screen.dart';
import '../history/history_screen.dart';
import '../home/home_sheets.dart' show showEndSheet;
import '../home/timer_screen.dart';
import '../milestones/milestone_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../ring/fasting_ring.dart' show FastingRing;
import '../settings/settings_screen.dart';
import '../setup/target_setup_screen.dart';
import '../today/today_screen.dart';

enum _Quick { water, fast, food, activity, weighIn }

/// Root layout: Home · History · (+) · Nutrition · Settings.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _nutritionTab = 2;
  int _tab = 0;
  bool _menuOpen = false;

  @override
  void initState() {
    super.initState();
    // Re-apply scheduled reminders on launch (also corrects DST drift).
    ref.read(launchSyncProvider);
  }

  void _go(int i) => setState(() => _tab = i);

  Future<void> _push(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  void _openTimer() => _push(
    TimerScreen(
      onChangeTarget: () => _push(const TargetSetupScreen()),
      onReadMore: (Milestone m) => _push(MilestoneDetailScreen(milestone: m)),
    ),
  );

  /// The centre + menu (RUVA home design).
  Future<void> _quickAdd() async {
    final l = context.l10n;
    final settings = ref.read(settingsProvider).value;
    final snap = ref.read(timerSnapshotProvider(FastingRing.gapFor(300)));
    final unit = settings?.waterUnit ?? VolumeUnit.ml;
    final glassMl = unit == VolumeUnit.ml ? 250.0 : unit.toMl(8);
    final running = snap?.running ?? false;
    setState(() => _menuOpen = true);
    final choice = await showAppSheet<_Quick>(
      context,
      (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MonoLabel(l.quickEyebrow),
          const SizedBox(height: 4),
          Semantics(header: true, child: Text(l.quickTitle, style: AppText.title)),
          const SizedBox(height: 12),
          for (final (value, icon, title, sub) in [
            (_Quick.water, Icons.water_drop_outlined, l.quickWater, l.quickWaterSub(formatVolume(glassMl, unit))),
            running
                ? (_Quick.fast, Icons.timer_off_outlined, l.quickEnd, l.quickEndSub(formatHoursMinutes(snap!.elapsed)))
                : (
                    _Quick.fast,
                    Icons.timer_outlined,
                    l.quickStart,
                    l.quickStartSub(formatTarget(snap?.target ?? const Duration(hours: 16))),
                  ),
            (_Quick.food, Icons.restaurant_outlined, l.quickFood, l.quickFoodSub),
            (_Quick.activity, Icons.directions_run_rounded, l.quickActivity, l.quickActivitySub),
            (_Quick.weighIn, Icons.monitor_weight_outlined, l.quickWeigh, l.quickWeighSub),
          ])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: IconBubble(icon: icon, size: 40, background: AppColors.primary, foreground: AppColors.accent),
              title: Text(title, style: AppText.cardValue.copyWith(fontSize: 15)),
              subtitle: Text(sub, style: AppText.small.copyWith(fontSize: 12.5)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              onTap: () => Navigator.pop(ctx, value),
            ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _menuOpen = false);
    switch (choice) {
      case null:
        return;
      case _Quick.water:
        await ref.read(hydrationActionsProvider).add(glassMl);
        final t = ref.read(clockProvider)().toLocal();
        final entries = await ref.read(hydrationDayProvider(DateTime(t.year, t.month, t.day)).future);
        final total = entries.fold(0.0, (a, e) => a + e.amountMl);
        if (mounted) showRuvaSnack(context, l.quickWaterAdded(formatVolume(glassMl, unit), formatVolume(total, unit)));
      case _Quick.fast:
        if (running) {
          await showEndSheet(context);
        } else {
          await ref.read(activeSessionProvider.notifier).start();
          if (mounted) showRuvaSnack(context, l.quickStarted);
        }
      case _Quick.food:
        _go(_nutritionTab);
      case _Quick.activity:
        await _push(const ActivityWaterScreen(initialTab: 1));
      case _Quick.weighIn:
        await _push(const ProfileScreen(openWeighIn: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: [
            HomeScreen(
              onOpenTimer: _openTimer,
              onOpenWater: () => _push(const ActivityWaterScreen()),
              onOpenNutrition: () => _go(_nutritionTab),
            ),
            const HistoryScreen(),
            const FoodDiaryScreen(),
            SettingsScreen(onChangeTarget: () => _push(const TargetSetupScreen())),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        heroTag: 'quick-add',
        tooltip: l.quickEyebrow,
        onPressed: _quickAdd,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.accent,
        elevation: 2,
        shape: const CircleBorder(),
        child: AnimatedRotation(
          turns: _menuOpen ? 0.125 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.add_rounded, size: 32),
        ),
      ),
      bottomNavigationBar: _BottomNav(index: _tab, onTap: _go),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final items = [
      (l.navToday, AppIcon.home),
      (l.navHistory, AppIcon.calendar),
      (l.navNutrition, AppIcon.nutrition),
      (l.navSettings, AppIcon.sliders),
    ];
    // Labels may grow to 1.3x with system text size; the full label is always
    // read by screen readers, so the bar never overflows at larger sizes.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: BottomAppBar(
        color: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        elevation: 8,
        shadowColor: const Color(0x33135D44),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i == 2) const SizedBox(width: 72),
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == index,
                  label: items[i].$1,
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: ShapeDecoration(
                            color: i == index ? AppColors.soft : null,
                            shape: const StadiumBorder(),
                          ),
                          child: AppIconView(
                            items[i].$2,
                            color: i == index ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[i].$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 12,
                            fontWeight: i == index ? FontWeight.w600 : FontWeight.w500,
                            color: i == index ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
