import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n.dart';
import 'core/theme/app_theme.dart';
import 'data/app_database.dart';
import 'domain/settings.dart';
import 'features/onboarding/onboarding.dart';
import 'features/shell/app_shell.dart';
import 'features/splash/splash_screen.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Light app: transparent status bar with dark icons, white nav bar to match the tab bar.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  final db = await AppDatabase.open();
  runApp(ProviderScope(overrides: [databaseProvider.overrideWithValue(db)], child: const LifeFastingApp()));
}

class LifeFastingApp extends StatelessWidget {
  const LifeFastingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _Gate(),
    );
  }
}

/// Splash (until data has loaded and the splash has shown briefly), then
/// onboarding → (adult) app, or (under 18) education-only screen.
class _Gate extends ConsumerStatefulWidget {
  const _Gate();

  @override
  ConsumerState<_Gate> createState() => _GateState();
}

class _GateState extends ConsumerState<_Gate> {
  static const _minSplash = Duration(milliseconds: 1600);
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(_minSplash, () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value;
    final Widget page = settings == null || !_splashDone
        ? const SplashScreen()
        : !settings.onboardingComplete
        ? const OnboardingScreen()
        : settings.eligibility != AgeEligibility.adult
        ? const UnderageScreen()
        : const AppShell();
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 500),
      child: KeyedSubtree(key: ValueKey(page.runtimeType), child: page),
    );
  }
}
