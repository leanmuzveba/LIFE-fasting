import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widget_test.dart' show pumpApp;

/// Tall screen so the whole form is laid out without scrolling.
Future<void> _openActivity(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 2600);
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Quick add'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Log activity'));
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('log an activity: type, duration, optional intensity and notes', (tester) async {
    await pumpApp(tester);
    await _openActivity(tester);
    expect(find.text('No activities logged yet.'), findsOneWidget);

    await _scrollTo(tester, find.bySemanticsLabel('Run'));
    await tester.tap(find.bySemanticsLabel('Run'));
    await _scrollTo(tester, find.byTooltip('1 minute more'));
    await tester.tap(find.byTooltip('1 minute more'));
    await tester.tap(find.byTooltip('1 minute more'));
    await tester.pump();
    expect(find.text('32 min'), findsOneWidget);
    await _scrollTo(tester, find.bySemanticsLabel('Moderate'));
    await tester.tap(find.bySemanticsLabel('Moderate'));
    await _scrollTo(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Easy pace');
    await _scrollTo(tester, find.text('Log activity'));
    await tester.tap(find.text('Log activity'));
    await tester.pumpAndSettle();
    expect(find.text('Run logged — 32 min'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Run, 32 min · moderate')), findsOneWidget);
  });

  testWidgets('edit and delete a logged activity', (tester) async {
    await pumpApp(tester);
    await _openActivity(tester);
    await _scrollTo(tester, find.text('Log activity'));
    await tester.tap(find.text('Log activity'));
    await tester.pumpAndSettle();
    final card = find.bySemanticsLabel(RegExp(r'^Walk, 30 min'));
    await _scrollTo(tester, card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.text('Edit activity'), findsOneWidget);
    final delete = find.widgetWithText(TextButton, 'Delete');
    await _scrollTo(tester, delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(find.text('No activities logged yet.'), findsOneWidget);
  });
}
