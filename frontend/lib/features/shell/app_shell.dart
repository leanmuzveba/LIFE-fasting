import 'package:flutter/material.dart';

import '../../core/icons.dart';
import '../../core/theme/tokens.dart';
import '../../domain/milestone.dart';
import '../home/home_screen.dart';
import '../milestones/milestone_detail_screen.dart';
import '../setup/target_setup_screen.dart';

/// Root layout: Timer / History / Settings tabs with the mockup's bottom nav.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

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
              onOpenHistory: () => _go(1),
              onChangeTarget: () => _push(const TargetSetupScreen()),
              onReadMore: (Milestone m) => _push(MilestoneDetailScreen(milestone: m)),
            ),
            const _Placeholder('History'),
            const _Placeholder('Settings'),
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

  static const _items = [('Timer', AppIcon.timer), ('History', AppIcon.calendar), ('Settings', AppIcon.sliders)];

  @override
  Widget build(BuildContext context) {
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
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == index,
                    label: _items[i].$1,
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
                              _items[i].$2,
                              color: i == index ? AppColors.deep : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _items[i].$1,
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

/// Temporary stand-in until the screen is built in a later step.
class _Placeholder extends StatelessWidget {
  const _Placeholder(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: const Center(child: Text('Coming in a later step')),
  );
}
