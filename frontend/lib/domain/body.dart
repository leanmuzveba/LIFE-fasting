// Personal measurements (PRD v1.2 §7): optional, private, explained.
// BMI is a rough screening number, never the basis for a diet; adult
// categories and weight targets are not applied under 18.

import 'dart:math' as math;

enum Sex { female, male }

/// Optional profile details used for the calculations.
class BodyProfile {
  const BodyProfile({this.heightCm, this.birthYear, this.sex, this.trackWeight = true});

  final double? heightCm;
  final int? birthYear;
  final Sex? sex;
  final bool trackWeight; // PRD: users can opt out of weight tracking

  /// Age this calendar year (may be one year high before the birthday).
  int? ageOn(DateTime today) => birthYear == null ? null : today.year - birthYear!;
}

class WeighIn {
  const WeighIn({this.id, required this.at, required this.weightKg, this.waistCm, this.neckCm, this.hipCm});

  final int? id;
  final DateTime at; // UTC
  final double weightKg;
  final double? waistCm;
  final double? neckCm;
  final double? hipCm;

  WeighIn copyWith({DateTime? at, double? weightKg}) => WeighIn(
    id: id,
    at: at ?? this.at,
    weightKg: weightKg ?? this.weightKg,
    waistCm: waistCm,
    neckCm: neckCm,
    hipCm: hipCm,
  );
}

double bmi(double weightKg, double heightCm) => weightKg / math.pow(heightCm / 100, 2);

enum BmiBand { underweight, healthy, overweight, obese }

/// WHO adult bands; null under 18 (children need BMI-for-age charts).
BmiBand? bmiBand(double value, {required bool adult}) => !adult
    ? null
    : value < 18.5
    ? BmiBand.underweight
    : value < 25
    ? BmiBand.healthy
    : value < 30
    ? BmiBand.overweight
    : BmiBand.obese;

/// Weights for BMI 18.5–24.9 at [heightCm].
({double low, double high}) healthyRange(double heightCm) {
  final h2 = math.pow(heightCm / 100, 2);
  return (low: 18.5 * h2, high: 24.9 * h2);
}

/// Kilograms to the nearest edge of the healthy range: negative = lose,
/// positive = gain, 0 = already within it.
double toHealthyRange(double weightKg, double heightCm) {
  final r = healthyRange(heightCm);
  return weightKg < r.low
      ? r.low - weightKg
      : weightKg > r.high
      ? r.high - weightKg
      : 0;
}

enum BodyFatMethod { tape, bmi }

/// Estimated body fat %. Prefers the US Navy tape method (waist, neck and,
/// for women, hip); otherwise the Deurenberg BMI formula. Adults only.
({double percent, BodyFatMethod method})? bodyFat({
  required Sex? sex,
  required int? age,
  required double heightCm,
  required WeighIn latest,
}) {
  if (sex == null || age == null || age < 18) return null;
  final w = latest.waistCm, n = latest.neckCm, hip = latest.hipCm;
  double log10(num x) => math.log(x) / math.ln10;
  double? tape;
  if (w != null && n != null) {
    if (sex == Sex.male && w > n) {
      tape = 495 / (1.0324 - 0.19077 * log10(w - n) + 0.15456 * log10(heightCm)) - 450;
    } else if (sex == Sex.female && hip != null && w + hip > n) {
      tape = 495 / (1.29579 - 0.35004 * log10(w + hip - n) + 0.22100 * log10(heightCm)) - 450;
    }
  }
  if (tape != null && tape > 2 && tape < 70) return (percent: tape, method: BodyFatMethod.tape);
  final fromBmi = 1.20 * bmi(latest.weightKg, heightCm) + 0.23 * age - 10.8 * (sex == Sex.male ? 1 : 0) - 5.4;
  return (percent: fromBmi.clamp(2, 70).toDouble(), method: BodyFatMethod.bmi);
}

// --- Units -----------------------------------------------------------------------

const kgPerLb = 0.45359237;
const cmPerInch = 2.54;
