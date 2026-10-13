/// A recorded physical activity (PRD v1.2 §8): type, date/time, duration,
/// optional intensity and notes.
enum ActivityType { walk, run, cycle, strength, yoga, other }

enum Intensity { light, moderate, heavy }

class ActivityEntry {
  const ActivityEntry({
    this.id,
    required this.type,
    required this.startedAt,
    required this.minutes,
    this.intensity,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
    this.externalId,
    this.kcal,
  });

  final int? id;
  final ActivityType type;
  final DateTime startedAt; // UTC
  final int minutes;
  final Intensity? intensity;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? externalId; // set when imported from your watch
  final double? kcal; // calories burned, when the watch reports them

  bool get fromWatch => externalId != null;

  ActivityEntry copyWith({
    int? id,
    ActivityType? type,
    DateTime? startedAt,
    int? minutes,
    Intensity? Function()? intensity,
    String? notes,
    DateTime? updatedAt,
  }) => ActivityEntry(
    id: id ?? this.id,
    type: type ?? this.type,
    startedAt: startedAt ?? this.startedAt,
    minutes: minutes ?? this.minutes,
    intensity: intensity != null ? intensity() : this.intensity,
    notes: notes ?? this.notes,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    externalId: externalId,
    kcal: kcal,
  );
}

const minActivityMinutes = 1;
const maxActivityMinutes = 600;

int totalMinutes(Iterable<ActivityEntry> entries) => entries.fold(0, (sum, e) => sum + e.minutes);

/// MET values (Compendium of Physical Activities) per type for light,
/// moderate and heavy effort; moderate when no intensity is chosen.
const _met = {
  ActivityType.walk: (2.8, 3.5, 5.0), // slow · ~5 km/h · brisk/uphill
  ActivityType.run: (7.0, 9.8, 11.5), // jog · ~10 km/h · fast
  ActivityType.cycle: (4.0, 6.8, 10.0), // leisure · 16–19 km/h · hard
  ActivityType.strength: (3.5, 5.0, 6.0),
  ActivityType.yoga: (2.5, 3.0, 4.0),
  ActivityType.other: (3.0, 4.5, 6.0),
};

double activityMet(ActivityType type, Intensity? intensity) {
  final (light, moderate, heavy) = _met[type]!;
  return switch (intensity) {
    Intensity.light => light,
    Intensity.heavy => heavy,
    _ => moderate,
  };
}

/// Estimated active calories: (MET − 1) × weight × hours. Resting energy is
/// left out so it adds up with watch calories (which exclude it too).
double activityKcal(ActivityType type, Intensity? intensity, int minutes, double weightKg) =>
    (activityMet(type, intensity) - 1) * weightKg * minutes / 60;
