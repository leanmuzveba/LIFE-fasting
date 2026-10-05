import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/icons.dart';
import '../../core/theme/tokens.dart';
import '../../domain/milestone.dart';
import '../../state/providers.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../milestones/milestone_detail_screen.dart';
import '../settings/settings_screen.dart';
import '../setup/target_setup_screen.dart';

/// Root layout: Timer / History / Settings tabs with the mockup's bottom nav.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    // Re-apply scheduled reminders on launch (also corrects DST drift).
    ref.read(launchSyncProvider);
  }

  void _go(int i) => setState(() => _tab = i);

  void _push(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: [
            HomeScreen(
              onOpenSettings: () => _go(2),
              onChangeTarget: () => _push(const TargetSetupScreen()),
              onReadMore: (Milestone m) => _push(MilestoneDetailScreen(milestone: m)),
            ),
            const HistoryScreen(),
            SettingsScreen(onChangeTarget: () => _push(const TargetSetupScreen())),
          ],
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
    final items = [(l.navTimer, AppIcon.timer), (l.navHistory, AppIcon.calendar), (l.navSettings, AppIcon.sliders)];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
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
                            width: 56,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: ShapeDecoration(
                              color: i == index ? AppColors.pale : null,
                              shape: const StadiumBorder(),
                            ),
                            child: AppIconView(
                              items[i].$2,
                              color: i == index ? AppColors.deep : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            items[i].$1,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12,
                              fontWeight: i == index ? FontWeight.w800 : FontWeight.w700,
                              color: i == index ? AppColors.deep : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
