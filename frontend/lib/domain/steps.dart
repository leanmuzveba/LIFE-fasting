// Steps today from Android's hardware step counter, which only reports a
// running total since the phone last booted.

const dailyStepGoal = 10000;

/// What we remember between readings (stored on the phone).
class StepBook {
  const StepBook({
    required this.day,
    required this.base,
    required this.carried,
    required this.last,
    required this.lastAt,
  });

  final String day; // local date 'YYYY-MM-DD'
  final int base; // counter value that counts as 0 for [day] since the last boot
  final int carried; // steps today from before a reboot
  final int last; // last counter value seen
  final DateTime lastAt;

  int get today => carried + (last - base).clamp(0, 1 << 30);

  Map<String, Object> toJson() => {
    'day': day,
    'base': base,
    'carried': carried,
    'last': last,
    'lastAt': lastAt.toUtc().toIso8601String(),
  };

  static StepBook? fromJson(Map<String, dynamic>? j) => j == null
      ? null
      : StepBook(
          day: j['day'] as String,
          base: j['base'] as int,
          carried: j['carried'] as int,
          last: j['last'] as int,
          lastAt: DateTime.parse(j['lastAt'] as String),
        );
}

String _dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Folds a new counter [reading] taken at local time [now] into [book].
// ponytail: steps between the last reading before midnight and midnight are
// counted for the new day, and steps on days the app isn't opened are lost.
// Upgrade path: read daily totals from Health Connect.
StepBook recordSteps(StepBook? book, int reading, DateTime now) {
  final day = _dayKey(now);
  if (book == null) {
    // First reading ever: we can't know earlier steps, start from here.
    return StepBook(day: day, base: reading, carried: 0, last: reading, lastAt: now);
  }
  final rebooted = reading < book.last;
  if (book.day != day) {
    final yesterday = _dayKey(DateTime(now.year, now.month, now.day - 1));
    // Continue from yesterday's last reading if it was recent; otherwise
    // only count from now.
    final base = !rebooted && book.day == yesterday ? book.last : (rebooted ? 0 : reading);
    return StepBook(day: day, base: base, carried: 0, last: reading, lastAt: now);
  }
  if (rebooted) {
    return StepBook(day: day, base: 0, carried: book.today, last: reading, lastAt: now);
  }
  return StepBook(day: day, base: book.base, carried: book.carried, last: reading, lastAt: now);
}

/// Today's steps from a stored book, or 0 when it's from another day.
int stepsToday(StepBook? book, DateTime now) => book != null && book.day == _dayKey(now) ? book.today : 0;

/// Rough distance from steps; uses height when known (stride ≈ 41.5% of it).
double stepsToKm(int steps, {double? heightCm}) => steps * (heightCm == null ? 0.75 : heightCm * 0.00415) / 1000;
