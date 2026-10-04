import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/core/theme/app_theme.dart';
import 'package:life_fasting/domain/fasting_session.dart';
import 'package:life_fasting/domain/fasting_timer.dart';
import 'package:life_fasting/domain/milestone.dart';
import 'package:life_fasting/features/ring/fasting_ring.dart';

final _t0 = DateTime.utc(2026, 10, 3, 17);

TimerSnapshot _snap(Duration? elapsed, {int targetMinutes = 960}) => TimerSnapshot.compute(
  session: elapsed == null
      ? null
      : FastingSession(startedAt: _t0, targetMinutes: targetMinutes, createdAt: _t0, updatedAt: _t0),
  idleTargetMinutes: targetMinutes,
  now: _t0.add(elapsed ?? Duration.zero),
  gapFraction: FastingRing.gapFor(300),
);

Future<List<Milestone>> _pump(WidgetTester tester, TimerSnapshot s, {double textScale = 1}) async {
  final picked = <Milestone>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: FastingRing(snapshot: s, onPick: picked.add),
            ),
          ),
        ),
      ),
    ),
  );
  return picked;
}

void main() {
  testWidgets('idle ring', (tester) async {
    await _pump(tester, _snap(null));
    expect(find.text('READY WHEN YOU ARE'), findsOneWidget);
    expect(find.text('00:00:00'), findsOneWidget);
    expect(find.text('16 h target'), findsOneWidget);
    expect(find.text('Later stage · after your target'), findsOneWidget);
  });

  testWidgets('half-way ring shows progress and marker states', (tester) async {
    await _pump(tester, _snap(const Duration(hours: 12, minutes: 24, seconds: 36)));
    expect(find.text('FASTING IN PROGRESS'), findsOneWidget);
    expect(find.text('12:24:36'), findsOneWidget);
    expect(find.text('of 16 h target'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Fuel use shifts, around 10 h, current estimate')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Fast begins, passed')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Ketosis may begin, around 14 h, upcoming')), findsOneWidget);
  });

  testWidgets('full ring when target reached; elapsed keeps counting', (tester) async {
    await _pump(tester, _snap(const Duration(hours: 16, minutes: 12, seconds: 5)));
    expect(find.text('TARGET REACHED'), findsOneWidget);
    expect(find.text('16:12:05'), findsOneWidget);
  });

  testWidgets('markers and chips open the milestone', (tester) async {
    final picked = await _pump(tester, _snap(const Duration(hours: 3)));
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Ketosis may begin')));
    await tester.tap(find.text('Later stage · after your target'));
    expect(picked.map((m) => m.id), ['ketosis', 'later']);
  });

  testWidgets('tap targets meet the 44/48px guidelines and are labelled', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _snap(const Duration(hours: 3)));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('large system text does not overflow the ring', (tester) async {
    await _pump(tester, _snap(const Duration(hours: 3)), textScale: 2);
    expect(tester.takeException(), isNull);
    expect(find.text('03:00:00'), findsOneWidget);
  });
}
