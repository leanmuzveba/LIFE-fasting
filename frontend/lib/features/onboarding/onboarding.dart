import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/ruva_logo.dart';
import '../../domain/settings.dart';
import '../../state/providers.dart';

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
                  Row(
                    children: [
                      const RuvaLogo(size: 44, semanticLabel: null),
                      const SizedBox(width: 10),
                      Text(context.l10n.appName, style: AppText.brand),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Semantics(
                    header: true,
                    child: Text(title, style: AppText.title.copyWith(fontSize: 21, height: 1.25)),
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
      borderRadius: BorderRadius.circular(18),
      boxShadow: AppShadows.card,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIconView(icon, size: 20, color: AppColors.primary),
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
    final l = context.l10n;
    if (!_askAge) {
      return _Page(
        title: l.onboardingTitle,
        actions: [PillButton(label: l.continueLabel, large: true, onPressed: () => setState(() => _askAge = true))],
        children: [
          _Note(l.onboardingNotMedical),
          _Note(l.onboardingEstimates, icon: AppIcon.clock),
          _Note(l.onboardingPrivacy, icon: AppIcon.check),
          _Note(l.onboardingSafety),
        ],
      );
    }
    return _Page(
      title: l.ageTitle,
      actions: [
        PillButton(label: l.ageAdult, large: true, onPressed: () => _answer(AgeEligibility.adult)),
        PillButton(label: l.ageUnder18, outlined: true, onPressed: () => _answer(AgeEligibility.under18)),
      ],
      children: [Text(l.ageBody, style: AppText.body.copyWith(color: AppColors.textSecondary))],
    );
  }
}

/// Neutral education only: no timer, no schedules, no encouragement (FR-12).
class UnderageScreen extends ConsumerWidget {
  const UnderageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _Page(
    title: context.l10n.underageTitle,
    actions: [
      TextButton(
        onPressed: () async {
          await ref.read(settingsRepositoryProvider).clear();
          ref.invalidate(settingsProvider);
        },
        child: Text(context.l10n.underageReset),
      ),
    ],
    children: [
      _Note(context.l10n.underageMeals),
      _Note(context.l10n.underageTalk),
      _Note(context.l10n.underageSupport, icon: AppIcon.check),
    ],
  );
}
