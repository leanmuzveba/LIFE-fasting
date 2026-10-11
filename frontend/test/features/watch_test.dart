import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widget_test.dart' show pumpApp, watch;

Future<void> _openWatchSheet(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Settings').last);
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text('Connect your watch'), 200, scrollable: find.byType(Scrollable).first);
  await tester.tap(find.text('Connect your watch'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('connect a watch: calories burned appear on Home', (tester) async {
    await pumpApp(tester);
    tester.view.physicalSize = const Size(390, 2400);
    watch.calories = 312.4;
    expect(find.text('Calories burned'), findsNothing, reason: 'nothing until you connect');

    await _openWatchSheet(tester);
    expect(find.textContaining('Mi Fitness'), findsOneWidget);
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    expect(find.text('Watch connected'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Home').last);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp(r'^Calories burned: 312 kcal')), findsOneWidget);
  });

  testWidgets('declined permission or no Health Connect: clear messages', (tester) async {
    await pumpApp(tester);
    tester.view.physicalSize = const Size(390, 2400);
    watch.grants = false;
    await _openWatchSheet(tester);
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    expect(find.textContaining('wasn’t given access'), findsOneWidget);

    watch.isAvailable = false;
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    expect(find.text('Install Health Connect'), findsOneWidget);
  });
}
