import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/core/theme/tokens.dart';
import 'package:life_fasting/domain/settings.dart';

import '../widget_test.dart' show pumpApp, tick;

/// Pixel-sampled textContrastGuideline misfires on nodes mixing icons, text and
/// shadows, so colour pairs are checked exactly in the contrast test below.
Future<void> _guidelines(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
}

void main() {
  testWidgets('home (idle and running) meets contrast and tap-target guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    final clock = await pumpApp(tester);
    await _guidelines(tester);
    await tester.tap(find.text('Start fast'));
    await tester.pumpAndSettle();
    await tick(tester, clock, const Duration(hours: 15));
    await _guidelines(tester);
    handle.dispose();
  });

  testWidgets('history, settings and onboarding meet guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    final clock = await pumpApp(tester);
    await tester.tap(find.text('Start fast'));
    await tester.pumpAndSettle();
    await tick(tester, clock, const Duration(hours: 3));
    await tester.tap(find.bySemanticsLabel('History'));
    await tester.pumpAndSettle();
    await _guidelines(tester);
    await tester.tap(find.bySemanticsLabel('Settings').last);
    await tester.pumpAndSettle();
    await _guidelines(tester);
    handle.dispose();
  });

  testWidgets('onboarding meets guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, eligibility: AgeEligibility.unknown);
    await _guidelines(tester);
    handle.dispose();
  });

  for (final scale in [1.5, 2.0]) {
    testWidgets('no overflow at ${scale}x text on every tab', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(tester);
      expect(tester.takeException(), isNull);
      for (final tab in ['History', 'Settings', 'Timer']) {
        await tester.tap(find.bySemanticsLabel(tab).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: tab);
      }
      expect(find.byType(Scaffold), findsWidgets);
    });
  }

  test('colour pairs meet WCAG AA (4.5:1 text, 3:1 icons)', () {
    double ratio(Color a, Color b) {
      final (x, y) = (a.computeLuminance(), b.computeLuminance());
      return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
    }

    const text = [
      (AppColors.text, AppColors.white),
      (AppColors.text, AppColors.background),
      (AppColors.textSecondary, AppColors.white),
      (AppColors.textSecondary, AppColors.background),
      (AppColors.primary, AppColors.white),
      (AppColors.primary, AppColors.soft),
      (AppColors.white, AppColors.primary),
      (AppColors.errorText, AppColors.white),
      (AppColors.primaryDark, AppColors.accent),
    ];
    for (final (fg, bg) in text) {
      expect(ratio(fg, bg), greaterThanOrEqualTo(4.5), reason: '$fg on $bg');
    }
    const icons = [
      (AppColors.muted, AppColors.background),
      (AppColors.fatBurningIcon, AppColors.background),
      (AppColors.fatBurningIcon, AppColors.white),
      (AppColors.ketosis, AppColors.background),
      (AppColors.onFatBurning, AppColors.fatBurning),
      (AppColors.onKetosis, AppColors.ketosis),
      (AppColors.onAccent, AppColors.accent),
      (AppColors.accent, AppColors.primary), // lime knob/glyphs on forest
      (AppColors.primary, AppColors.background), // ring arc on mint
    ];
    for (final (fg, bg) in icons) {
      expect(ratio(fg, bg), greaterThanOrEqualTo(3), reason: '$fg on $bg');
    }
  });
}
