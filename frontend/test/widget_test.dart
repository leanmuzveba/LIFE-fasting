import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/main.dart';

void main() {
  testWidgets('app boots', (tester) async {
    await tester.pumpWidget(const LifeFastingApp());
    expect(find.text('Fasting Companion'), findsOneWidget);
  });
}
