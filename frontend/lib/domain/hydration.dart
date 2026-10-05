/// One water entry (PRD v1.2 §9). Amounts are stored in millilitres; the
/// chosen [VolumeUnit] is only for display and input.
class HydrationEntry {
  const HydrationEntry({
    this.id,
    required this.amountMl,
    required this.loggedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final double amountMl;
  final DateTime loggedAt; // UTC
  final DateTime createdAt;
  final DateTime updatedAt;

  HydrationEntry copyWith({int? id, double? amountMl, DateTime? loggedAt, DateTime? updatedAt}) => HydrationEntry(
    id: id ?? this.id,
    amountMl: amountMl ?? this.amountMl,
    loggedAt: loggedAt ?? this.loggedAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

enum VolumeUnit {
  ml,
  flOz;

  static const mlPerFlOz = 29.5735; // US fluid ounce

  double toMl(double value) => this == ml ? value : value * mlPerFlOz;
  double fromMl(double millilitres) => this == ml ? millilitres : millilitres / mlPerFlOz;

  /// Quick-add buttons, in this unit.
  List<double> get quickAdds => this == ml ? const [250, 500] : const [8, 16];

  /// Largest single entry accepted (about 3 L), in this unit.
  double get maxEntry => fromMl(3000);
}

/// "250 ml", "1.25 L", "8.5 fl oz" — totals of 1 L or more switch to litres.
String formatVolume(double millilitres, VolumeUnit unit) {
  // Fixed decimals, then drop trailing zeros: 1.50 -> 1.5, 2.00 -> 2.
  String trim(String s) => s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
  if (unit == VolumeUnit.flOz) return '${trim(unit.fromMl(millilitres).toStringAsFixed(1))} fl oz';
  if (millilitres >= 1000) return '${trim((millilitres / 1000).toStringAsFixed(2))} L';
  return '${millilitres.round()} ml';
}

double totalMl(Iterable<HydrationEntry> entries) => entries.fold(0, (sum, e) => sum + e.amountMl);

/// Water reminder slots (local hour): every 2 hours, 8 AM to 8 PM.
// ponytail: fixed schedule; add a custom window/interval if it's ever wanted.
const waterReminderHours = [8, 10, 12, 14, 16, 18, 20];
