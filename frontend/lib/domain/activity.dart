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
  });

  final int? id;
  final ActivityType type;
  final DateTime startedAt; // UTC
  final int minutes;
  final Intensity? intensity;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

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
  );
}

const minActivityMinutes = 1;
const maxActivityMinutes = 600;

int totalMinutes(Iterable<ActivityEntry> entries) => entries.fold(0, (sum, e) => sum + e.minutes);
