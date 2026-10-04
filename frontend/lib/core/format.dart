import 'package:intl/intl.dart';

String _pad(int n) => n.toString().padLeft(2, '0');

/// 12:24:36 — hours are not wrapped at 24.
String formatHms(Duration d) =>
    '${_pad(d.inHours)}:${_pad(d.inMinutes.remainder(60))}:${_pad(d.inSeconds.remainder(60))}';

/// "12 h 24 m"
String formatHoursMinutes(Duration d) => '${d.inHours} h ${d.inMinutes.remainder(60)} m';

/// "16 h", "16 h 30 m" — for targets.
String formatTarget(Duration d) {
  final m = d.inMinutes.remainder(60);
  return m == 0 ? '${d.inHours} h' : '${d.inHours} h $m m';
}

/// "7:00 PM" or "19:00", in the device's local time.
String formatClock(DateTime t, {bool use24h = false}) =>
    (use24h ? DateFormat('HH:mm') : DateFormat('h:mm a')).format(t.toLocal());

/// "Sat 3 Oct"
String formatShortDay(DateTime t) => DateFormat('EEE d MMM').format(t.toLocal());

/// "Sunday 4 October"
String formatLongDay(DateTime t) => DateFormat('EEEE d MMMM').format(t.toLocal());
