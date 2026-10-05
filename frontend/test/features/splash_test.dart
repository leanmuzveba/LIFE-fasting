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

int _letters(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .where((i) => RegExp(r'/(u|v|a)\.png$').hasMatch((i.image as AssetImage).assetName))
    .length;

void main() {
  testWidgets('the logo builds up: U, V, A appear in order', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();
    expect(_letters(tester), 0);
    await tester.pump(const Duration(milliseconds: 320));
    expect(_letters(tester), 1);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_letters(tester), 2);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_letters(tester), 3);
    expect(find.bySemanticsLabel('RUVA, loading'), findsOneWidget);
  });

  test('head pulses during the build-up and lands full size', () {
    final scales = [for (var t = 0.0; t <= 1.2; t += 1 / 30) AnimatedLogo(t: t).headScale];
    expect(scales.first, closeTo(0.15, 0.01));
    expect(scales.reduce(_max), closeTo(1, 0.01));
    expect(scales.where((s) => s < 0.3).length, greaterThan(3), reason: 'several pulses');
    expect(const AnimatedLogo(t: 1.2).headScale, 1);
  });

  test('after the build-up the head keeps a heartbeat', () {
    final beats = [for (var p = 0.0; p < 1; p += 0.02) AnimatedLogo(t: 1.2, beat: p).headScale];
    expect(beats.reduce(_max), greaterThan(1.1));
    expect(beats.last, 1);
  });

  testWidgets('reduced motion shows the finished logo without animating', (tester) async {
    await tester.pumpWidget(_app(reduceMotion: true));
    await tester.pump();
    expect(_letters(tester), 3);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('app opens on the splash, then Today', (tester) async {
    await loadAppFonts();
    await pumpApp(tester); // pumpAndSettle runs past the minimum splash time
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('Start fast'), findsOneWidget);
  });
}

double _max(double a, double b) => a > b ? a : b;
