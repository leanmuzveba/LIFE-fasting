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
    this.exercises = const [],
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
  final List<Exercise> exercises; // gym moves done, e.g. crunches 3 × 15

  bool get fromWatch => externalId != null;

  ActivityEntry copyWith({
    int? id,
    ActivityType? type,
    DateTime? startedAt,
    int? minutes,
    Intensity? Function()? intensity,
    String? notes,
    DateTime? updatedAt,
    List<Exercise>? exercises,
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
    exercises: exercises ?? this.exercises,
  );
}

/// One exercise in a workout: sets × reps (or seconds, for holds like plank).
class Exercise {
  const Exercise(this.name, {this.sets = 3, this.reps = 10});
  final String name;
  final int sets;
  final int reps;

  Map<String, Object> toJson() => {'name': name, 'sets': sets, 'reps': reps};
  factory Exercise.fromJson(Map<String, dynamic> j) =>
      Exercise(j['name'] as String, sets: j['sets'] as int, reps: j['reps'] as int);

  @override
  String toString() => '$name $sets × $reps';
}

/// Suggestions when naming an exercise; ones you've used before come first.
const commonExercises = [
  'Crunches',
  'Leg raises',
  'Plank',
  'Sit-ups',
  'Bicycle crunches',
  'Russian twists',
  'Mountain climbers',
  'Push-ups',
  'Squats',
  'Lunges',
  'Burpees',
  'Jumping jacks',
  'Glute bridges',
  'Hip thrusts',
  'Deadlift',
  'Bench press',
  'Shoulder press',
  'Bicep curls',
  'Tricep dips',
  'Pull-ups',
  'Lat pulldown',
  'Seated row',
  'Leg press',
  'Leg curls',
  'Leg extensions',
  'Calf raises',
];

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
