import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/core/icons.dart';
import 'package:life_fasting/core/theme/app_theme.dart';
import 'package:life_fasting/core/theme/tokens.dart';
import 'package:life_fasting/core/widgets/pill_button.dart';

void main() {
  testWidgets('theme, every icon and both button styles render', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Column(
            children: [
              Wrap(children: [for (final i in AppIcon.values) AppIconView(i)]),
              PillButton(label: 'Start fast', large: true, onPressed: () => taps++),
              PillButton(label: 'Cancel', outlined: true, onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Start fast'));
    expect(taps, 1);
    final ctx = tester.element(find.text('Cancel'));
    expect(Theme.of(ctx).scaffoldBackgroundColor, AppColors.background);
    expect(Theme.of(ctx).textTheme.bodyMedium!.fontFamily, 'DM Sans');
  });
}
