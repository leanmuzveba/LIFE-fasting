import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/domain/settings.dart';

import '../widget_test.dart' show pumpApp;

void main() {
  testWidgets('first launch shows the safety notice, then the age question', (tester) async {
    await pumpApp(tester, eligibility: AgeEligibility.unknown);
    expect(find.textContaining('not a medical device'), findsOneWidget);
    expect(find.textContaining('history of disordered eating'), findsOneWidget);
    expect(find.text('Start fast'), findsNothing);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Are you 18 or older?'), findsOneWidget);
    await tester.tap(find.text('I’m 18 or older'));
    await tester.pumpAndSettle();
    expect(find.text('Start fast'), findsOneWidget);
  });

  testWidgets('under-18 never sees fasting controls or encouraging copy', (tester) async {
    await pumpApp(tester, eligibility: AgeEligibility.unknown);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I’m under 18'));
    await tester.pumpAndSettle();
    expect(find.text('This app is designed for adults'), findsOneWidget);
    expect(find.textContaining('parent or guardian'), findsOneWidget);
    for (final forbidden in ['Start fast', 'Change target', 'TARGET', 'hours', 'Timer', 'ketosis', 'Ketosis']) {
      expect(find.textContaining(forbidden), findsNothing, reason: '"$forbidden" must not appear for under-18s');
    }
  });

  testWidgets('under-18 status persists across restarts', (tester) async {
    await pumpApp(tester, eligibility: AgeEligibility.under18);
    expect(find.text('This app is designed for adults'), findsOneWidget);
    expect(find.text('Start fast'), findsNothing);
  });

  testWidgets('a mistaken answer can be reset to onboarding', (tester) async {
    await pumpApp(tester, eligibility: AgeEligibility.under18);
    await tester.tap(find.text('I answered by mistake — start again'));
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsOneWidget);
  });
}
