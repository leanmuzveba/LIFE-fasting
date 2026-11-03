import 'activity.dart';

/// An exercise from the bundled library (free-exercise-db, public domain).
class LibraryExercise {
  const LibraryExercise({
    required this.id,
    required this.name,
    this.equipment,
    this.level = 'beginner',
    this.category = 'strength',
    this.primary = const [],
    this.secondary = const [],
    this.instructions = const [],
    this.images = const [],
  });

  final String id;
  final String name;
  final String? equipment; // barbell, dumbbell, machine, cable, body only, …
  final String level;
  final String category;
  final List<String> primary; // muscles worked most
  final List<String> secondary;
  final List<String> instructions;
  final List<String> images; // start and end position photos

  EquipmentGroup get group => groupOf(equipment);

  /// Demonstration photo [i], from the dataset's own repository.
  String imageUrl(int i) => 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/${images[i]}';

  factory LibraryExercise.fromJson(Map<String, dynamic> j) {
    List<String> list(String k) => [for (final v in (j[k] as List?) ?? const []) v as String];
    return LibraryExercise(
      id: j['id'] as String,
      name: j['name'] as String,
      equipment: j['equipment'] as String?,
      level: (j['level'] as String?) ?? 'beginner',
      category: (j['category'] as String?) ?? 'strength',
      primary: list('primaryMuscles'),
      secondary: list('secondaryMuscles'),
      instructions: list('instructions'),
      images: list('images'),
    );
  }
}

enum EquipmentGroup { freeWeights, machines, bodyweight, other }

EquipmentGroup groupOf(String? equipment) => switch (equipment) {
  'barbell' || 'dumbbell' || 'kettlebells' || 'e-z curl bar' => EquipmentGroup.freeWeights,
  'machine' || 'cable' => EquipmentGroup.machines,
  'body only' => EquipmentGroup.bodyweight,
  _ => EquipmentGroup.other,
};

/// A strength session in progress: kept in the database as you go, so
/// closing the app never loses it.
class Workout {
  const Workout({required this.startedAt, this.exercises = const [], this.restUntil, this.planDay});

  final DateTime startedAt; // UTC
  final List<Exercise> exercises; // planned and ticked-off sets
  final DateTime? restUntil; // UTC; the rest timer's end
  final int? planDay; // the plan day this came from; finishing it moves the plan on

  int get doneSets => exercises.fold(0, (n, x) => n + x.log.where((s) => s.done).length);

  /// Only what you did: ticked sets, and exercises with at least one.
  List<Exercise> get completed => [
    for (final x in exercises)
      if (x.log.any((s) => s.done))
        x.withLog([
          for (final s in x.log)
            if (s.done) s,
        ]),
  ];

  Workout copyWith({List<Exercise>? exercises, DateTime? Function()? restUntil}) => Workout(
    startedAt: startedAt,
    exercises: exercises ?? this.exercises,
    restUntil: restUntil != null ? restUntil() : this.restUntil,
    planDay: planDay,
  );

  Map<String, Object?> toJson() => {
    'startedAt': startedAt.toIso8601String(),
    'exercises': [for (final x in exercises) x.toJson()],
    'restUntil': restUntil?.toIso8601String(),
    'planDay': ?planDay,
  };

  factory Workout.fromJson(Map<String, dynamic> j) => Workout(
    startedAt: DateTime.parse(j['startedAt'] as String).toUtc(),
    exercises: [for (final x in j['exercises'] as List) Exercise.fromJson(x as Map<String, dynamic>)],
    restUntil: j['restUntil'] == null ? null : DateTime.parse(j['restUntil'] as String).toUtc(),
    planDay: j['planDay'] as int?,
  );
}

/// Key that links an exercise across sessions: its library id, else its name.
String exerciseKey(Exercise x) => x.libraryId ?? x.name.trim().toLowerCase();

/// Estimated one-rep max (Epley): a fair way to compare sets of different reps.
double oneRepMax(double kg, int reps) => reps <= 1 ? kg : kg * (1 + reps / 30);

const defaultRestSeconds = 90;
const minRestSeconds = 15;
const maxRestSeconds = 600;

/// Your bests over past sessions of one exercise: the heaviest set, and the
/// set with the highest estimated one-rep max (often a lighter set of more reps).
({SetLog? heaviest, SetLog? strongest}) personalBests(Iterable<Exercise> sessions) {
  SetLog? heaviest, strongest;
  for (final s in sessions.expand((x) => x.log)) {
    if (s.kg == null || !s.done) continue;
    if (heaviest == null || s.kg! > heaviest.kg! || (s.kg == heaviest.kg && s.reps > heaviest.reps)) heaviest = s;
    if (strongest == null || oneRepMax(s.kg!, s.reps) > oneRepMax(strongest.kg!, strongest.reps)) strongest = s;
  }
  return (heaviest: heaviest, strongest: strongest);
}
