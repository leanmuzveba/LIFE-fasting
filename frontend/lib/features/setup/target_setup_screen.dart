import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/pill_button.dart';
import '../../domain/settings.dart';
import '../../state/providers.dart';

/// Choose a tracking target: presets or a custom duration (FR-04).
class TargetSetupScreen extends ConsumerStatefulWidget {
  const TargetSetupScreen({super.key});

  @override
  ConsumerState<TargetSetupScreen> createState() => _TargetSetupScreenState();
}

class _TargetSetupScreenState extends ConsumerState<TargetSetupScreen> {
  static const _step = 30;
  int? _minutes;

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(settingsProvider).value?.targetMinutes ?? 16 * 60;
    final minutes = _minutes ?? saved;
    final isPreset = targetPresetsHours.any((h) => h * 60 == minutes);
    final l = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(l.targetTitle),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  Text(l.targetIntro, style: AppText.body.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final h in targetPresetsHours)
                        _Choice(
                          label: l.targetHours(h),
                          selected: minutes == h * 60,
                          onTap: () => setState(() => _minutes = h * 60),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(l.targetCustom, style: AppText.overline),
                  const SizedBox(height: 8),
                  _CustomStepper(
                    minutes: minutes,
                    selected: !isPreset,
                    onChanged: (m) => setState(() => _minutes = m.clamp(minTargetMinutes, maxTargetMinutes)),
                    step: _step,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: PillButton(
                label: l.saveTarget,
                large: true,
                onPressed: () async {
                  await ref.read(settingsProvider.notifier).change((s) => s.copyWith(targetMinutes: minutes));
                  if (context.mounted) Navigator.of(context).maybePop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    inMutuallyExclusiveGroup: true,
    child: Material(
      color: selected ? AppColors.pale : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? AppColors.deep : AppColors.track, width: selected ? 2 : 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppText.cardValue.copyWith(fontSize: 18))),
              if (selected) const AppIconView(AppIcon.check, size: 20, color: AppColors.deep, strokeWidth: 2.5),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CustomStepper extends StatelessWidget {
  const _CustomStepper({required this.minutes, required this.selected, required this.onChanged, required this.step});
  final int minutes;
  final bool selected;
  final ValueChanged<int> onChanged;
  final int step;

  @override
  Widget build(BuildContext context) {
    Widget btn(String symbol, String label, int delta, bool enabled) => IconButton.filledTonal(
      tooltip: label,
      onPressed: enabled ? () => onChanged(minutes + delta) : null,
      style: IconButton.styleFrom(backgroundColor: AppColors.pale, foregroundColor: AppColors.deep),
      icon: Text(symbol, style: AppText.cardValue.copyWith(color: AppColors.deep)),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? AppColors.deep : AppColors.track, width: selected ? 2 : 1.5),
      ),
      child: Row(
        children: [
          btn('−', context.l10n.targetDecrease, -step, minutes > minTargetMinutes),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                formatTarget(Duration(minutes: minutes)),
                textAlign: TextAlign.center,
                style: AppText.cardValue,
              ),
            ),
          ),
          btn('+', context.l10n.targetIncrease, step, minutes < maxTargetMinutes),
        ],
      ),
    );
  }
}
