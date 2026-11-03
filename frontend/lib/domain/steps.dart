// Steps today from Android's hardware step counter, which only reports a
// running total since the phone last booted.

const dailyStepGoal = 10000; // default; changeable on the home steps card
const minStepGoal = 1000, maxStepGoal = 50000;

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

/// Steps you typed in for a day (say, from your watch's own screen), and the
/// phone's count at that moment, so steps walked afterwards still add up.
class ManualSteps {
  const ManualSteps(this.steps, {this.phoneAt});
  final int steps;
  final int? phoneAt;

  Map<String, Object?> toJson() => {'steps': steps, 'phoneAt': phoneAt};
  factory ManualSteps.fromJson(Map<String, dynamic> j) => ManualSteps(j['steps'] as int, phoneAt: j['phoneAt'] as int?);
}

/// Where the shown count comes from.
enum StepSource { phone, watch, edited }

/// The day's steps: the highest of the watch, the phone and your own figure
/// (plus what the phone has counted since you entered it). So a late watch
/// sync never pulls the count down, and takes over once it catches up.
(int, StepSource) shownSteps({int? watch, int? phone, ManualSteps? manual}) {
  final since = phone != null && manual?.phoneAt != null ? (phone - manual!.phoneAt!).clamp(0, 1 << 30) : 0;
  final mine = manual == null ? null : manual.steps + since;
  var best = (phone ?? 0, StepSource.phone);
  if (watch != null && watch >= best.$1) best = (watch, StepSource.watch);
  if (mine != null && mine > best.$1) best = (mine, StepSource.edited);
  return best;
}

String stepDayKey(DateTime d) => _dayKey(d);
