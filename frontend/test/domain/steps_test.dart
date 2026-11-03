import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/domain/steps.dart';

void main() {
  test('shown steps: the highest of watch, phone and yours (plus phone steps since you typed it)', () {
    expect(shownSteps(watch: 4000, phone: 3000), (4000, StepSource.watch));
    expect(shownSteps(phone: 3000), (3000, StepSource.phone));
    const mine = ManualSteps(9800, phoneAt: 3000);
    expect(shownSteps(watch: 4000, phone: 3000, manual: mine), (9800, StepSource.edited));
    expect(shownSteps(watch: 4000, phone: 3250, manual: mine), (10050, StepSource.edited));
    expect(shownSteps(watch: 12000, phone: 3250, manual: mine), (12000, StepSource.watch));
    expect(shownSteps(manual: const ManualSteps(500)), (500, StepSource.edited)); // no phone sensor
  });
}
