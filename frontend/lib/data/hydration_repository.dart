import 'package:sqflite/sqflite.dart';

import '../domain/hydration.dart';

class HydrationRepository {
  HydrationRepository(this._db);
  final Database _db;

  static int _ms(DateTime t) => t.toUtc().millisecondsSinceEpoch;
  static DateTime _dt(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

  static Map<String, Object?> _toRow(HydrationEntry e) => {
    'amount_ml': e.amountMl,
    'logged_at': _ms(e.loggedAt),
    'created_at': _ms(e.createdAt),
    'updated_at': _ms(e.updatedAt),
  };

  static HydrationEntry _fromRow(Map<String, Object?> r) => HydrationEntry(
    id: r['id']! as int,
    amountMl: (r['amount_ml']! as num).toDouble(),
    loggedAt: _dt(r['logged_at']! as int),
    createdAt: _dt(r['created_at']! as int),
    updatedAt: _dt(r['updated_at']! as int),
  );

  Future<HydrationEntry> insert(HydrationEntry e) async =>
      e.copyWith(id: await _db.insert('hydration_entries', _toRow(e)));

  Future<void> update(HydrationEntry e) =>
      _db.update('hydration_entries', _toRow(e), where: 'id = ?', whereArgs: [e.id]);

  Future<void> delete(int id) => _db.delete('hydration_entries', where: 'id = ?', whereArgs: [id]);

  /// Entries with `from <= loggedAt < to`, oldest first.
  Future<List<HydrationEntry>> between(DateTime from, DateTime to) async => (await _db.query(
    'hydration_entries',
    where: 'logged_at >= ? AND logged_at < ?',
    whereArgs: [_ms(from), _ms(to)],
    orderBy: 'logged_at',
  )).map(_fromRow).toList();

  Future<List<HydrationEntry>> all() async =>
      (await _db.query('hydration_entries', orderBy: 'logged_at')).map(_fromRow).toList();

  Future<void> deleteAll() => _db.delete('hydration_entries');
}
