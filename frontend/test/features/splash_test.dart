import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/core/l10n.dart';
import 'package:life_fasting/core/theme/app_theme.dart';
import 'package:life_fasting/features/splash/splash_screen.dart';

import '../helpers.dart';
import '../widget_test.dart' show pumpApp;

Widget _app({bool reduceMotion = false}) => MaterialApp(
  theme: buildAppTheme(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: const SplashScreen(),
  ),
);

void main() {
  testWidgets('splash shows the wordmark, tagline and loading text', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();
    expect(find.textContaining('LIFE', findRichText: true), findsOneWidget);
    expect(find.text('INTERMITTENT FASTING & HEALTH'), findsOneWidget);
    expect(find.text('INITIALIZING TRACKER'), findsOneWidget);
    expect(find.byType(RingLogo), findsOneWidget);
  });

  testWidgets('the ring beats while loading', (tester) async {
    await tester.pumpWidget(_app());
    double scale() => tester
        .widget<Transform>(find.ancestor(of: find.byType(RingLogo), matching: find.byType(Transform)).first)
        .transform
        .getMaxScaleOnAxis();
    final sizes = <double>[];
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      sizes.add(scale());
    }
    expect(sizes.reduce((a, b) => a > b ? a : b), greaterThan(1.05));
  });

  testWidgets('reduced motion keeps the ring still', (tester) async {
    await tester.pumpWidget(_app(reduceMotion: true));
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('app opens on the splash, then the timer', (tester) async {
    await loadAppFonts();
    await pumpApp(tester); // pumpAndSettle runs past the minimum splash time
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('Start fast'), findsOneWidget);
  });
}
