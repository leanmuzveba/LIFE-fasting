import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'data/app_database.dart';
import 'domain/settings.dart';
import 'features/onboarding/onboarding.dart';
import 'features/shell/app_shell.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.open();
  runApp(ProviderScope(overrides: [databaseProvider.overrideWithValue(db)], child: const LifeFastingApp()));
}

class LifeFastingApp extends StatelessWidget {
  const LifeFastingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fasting Companion',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _Gate(),
    );
  }
}

/// Onboarding → (adult) app, or (under 18) education-only screen.
class _Gate extends ConsumerWidget {
  const _Gate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    if (settings == null) return const Scaffold();
    if (!settings.onboardingComplete) return const OnboardingScreen();
    if (settings.eligibility != AgeEligibility.adult) return const UnderageScreen();
    return const AppShell();
  }
}
