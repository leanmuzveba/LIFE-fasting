import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/pill_button.dart';
import '../../domain/settings.dart';
import '../../state/providers.dart';

const _safetyNotice =
    'Speak with a qualified healthcare professional before changing how you eat — especially if you have a '
    'medical condition, take medication, are pregnant, or have a history of disordered eating.';

/// Scrollable page frame shared by onboarding and the under-18 screen.
class _Page extends StatelessWidget {
  const _Page({required this.title, required this.children, required this.actions});

  final String title;
  final List<Widget> children;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      AppLogo(size: 32),
                      SizedBox(width: 10),
                      Text('Fasting Companion', style: AppText.brand),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Semantics(
                    header: true,
                    child: Text(title, style: AppText.title.copyWith(fontSize: 26, height: 1.25)),
                  ),
                  const SizedBox(height: 16),
                  for (final c in children) ...[c, const SizedBox(height: 14)],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < actions.length; i++) ...[if (i > 0) const SizedBox(height: 10), actions[i]],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Note extends StatelessWidget {
  const _Note(this.text, {this.icon = AppIcon.info});
  final String text;
  final AppIcon icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: AppShadows.card,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIconView(icon, size: 20, color: AppColors.deep),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: AppText.body.copyWith(fontSize: 14, height: 21 / 14)),
        ),
      ],
    ),
  );
}

/// Welcome & safety, then a simple self-declared age check.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _askAge = false;

  Future<void> _answer(AgeEligibility e) =>
      ref.read(settingsProvider.notifier).change((s) => s.copyWith(eligibility: e, onboardingComplete: true));

  @override
  Widget build(BuildContext context) {
    if (!_askAge) {
      return _Page(
        title: 'A calm way to record your eating and fasting times',
        actions: [PillButton(label: 'Continue', large: true, onPressed: () => setState(() => _askAge = true))],
        children: const [
          _Note(
            'This app records time. It is a tracking and educational tool, not a medical device, and it cannot tell '
            'what is happening in your body.',
          ),
          _Note(
            'Milestones on the timer are general estimates that vary between people. They are never goals.',
            icon: AppIcon.clock,
          ),
          _Note(
            'Your sessions stay on this phone. Nothing is uploaded, and you can delete everything at any time.',
            icon: AppIcon.check,
          ),
          _Note(_safetyNotice),
        ],
      );
    }
    return _Page(
      title: 'Are you 18 or older?',
      actions: [
        PillButton(label: 'I’m 18 or older', large: true, onPressed: () => _answer(AgeEligibility.adult)),
        PillButton(label: 'I’m under 18', outlined: true, onPressed: () => _answer(AgeEligibility.under18)),
      ],
      children: [
        Text(
          'Fasting tools in this app are designed for adults only. If you’re under 18, we’ll show general '
          'information instead.',
          style: AppText.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Neutral education only: no timer, no schedules, no encouragement (FR-12).
class UnderageScreen extends ConsumerWidget {
  const UnderageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _Page(
    title: 'This app is designed for adults',
    actions: [
      TextButton(
        onPressed: () async {
          await ref.read(settingsRepositoryProvider).clear();
          ref.invalidate(settingsProvider);
        },
        child: const Text('I answered by mistake — start again'),
      ),
    ],
    children: const [
      _Note(
        'Growing bodies need regular, balanced meals. Fasting isn’t recommended for people under 18 unless a '
        'doctor advises it.',
      ),
      _Note(
        'If you have questions about eating, food or your body, talk with a parent or guardian and a qualified '
        'healthcare professional such as your doctor or a dietitian.',
      ),
      _Note(
        'If you’re worried about how you feel about food, you deserve support — a trusted adult or your doctor '
        'can help you find it.',
        icon: AppIcon.check,
      ),
    ],
  );
}
