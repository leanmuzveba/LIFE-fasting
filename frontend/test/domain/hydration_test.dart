import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/domain/hydration.dart';

void main() {
  test('ml <-> fl oz conversions round-trip', () {
    expect(VolumeUnit.flOz.toMl(8), closeTo(236.588, 0.001));
    expect(VolumeUnit.flOz.fromMl(VolumeUnit.flOz.toMl(12.5)), closeTo(12.5, 1e-9));
    expect(VolumeUnit.ml.toMl(250), 250);
    expect(VolumeUnit.ml.maxEntry, 3000);
  });

  test('volumes are formatted in the chosen unit, litres from 1000 ml', () {
    expect(formatVolume(250, VolumeUnit.ml), '250 ml');
    expect(formatVolume(1250, VolumeUnit.ml), '1.25 L');
    expect(formatVolume(1500, VolumeUnit.ml), '1.5 L');
    expect(formatVolume(2000, VolumeUnit.ml), '2 L');
    expect(formatVolume(VolumeUnit.flOz.toMl(8), VolumeUnit.flOz), '8 fl oz');
    expect(formatVolume(500, VolumeUnit.flOz), '16.9 fl oz');
  });

  test('daily total adds every entry', () {
    final t = DateTime.utc(2026, 10, 4, 8);
    HydrationEntry e(double ml) => HydrationEntry(amountMl: ml, loggedAt: t, createdAt: t, updatedAt: t);
    expect(totalMl([e(250), e(500), e(330)]), 1080);
    expect(totalMl(const []), 0);
  });
}
