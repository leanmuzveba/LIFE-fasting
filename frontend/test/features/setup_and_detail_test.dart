import 'package:flutter_test/flutter_test.dart';

import '../widget_test.dart' show openTimer, pumpApp;

void main() {
  testWidgets('choose a preset target; the timer reflects it', (tester) async {
    await pumpApp(tester);
    await openTimer(tester);
    await tester.tap(find.text('Change target'));
    await tester.pumpAndSettle();
    expect(find.text('Your target'), findsOneWidget);
    expect(find.textContaining('No option here is a recommendation'), findsOneWidget);
    await tester.tap(find.text('14 hours'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save target'));
    await tester.pumpAndSettle();
    expect(find.text('14 h target'), findsOneWidget);
  });

  testWidgets('custom target steps in 30 minutes and is capped at 24 h', (tester) async {
    await pumpApp(tester);
    await openTimer(tester);
    await tester.tap(find.text('Change target'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Decrease by 30 minutes'));
    await tester.pumpAndSettle();
    expect(find.text('15 h 30 m'), findsOneWidget);
    for (var i = 0; i < 20; i++) {
      await tester.tap(find.byTooltip('Increase by 30 minutes'), warnIfMissed: false);
      await tester.pump();
    }
    expect(find.text('24 h'), findsOneWidget);
    await tester.tap(find.text('Save target'));
    await tester.pumpAndSettle();
    expect(find.text('24 h target'), findsOneWidget);
    // Every milestone now fits on the ring; nothing listed as "after your target".
    expect(find.textContaining('after your target'), findsNothing);
  });

  testWidgets('Read more opens the milestone page with disclaimer', (tester) async {
    await pumpApp(tester);
    await openTimer(tester);
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Ketosis may begin')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Read more'));
    await tester.pumpAndSettle();
    expect(find.text('Milestone'), findsOneWidget);
    expect(find.text('Ketosis may begin'), findsOneWidget);
    expect(find.textContaining('cannot measure ketones'), findsOneWidget);
    expect(find.textContaining('awaiting review'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Start fast'), findsOneWidget);
  });
}
