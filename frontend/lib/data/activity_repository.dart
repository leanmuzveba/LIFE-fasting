import 'package:sqflite/sqflite.dart';

import '../domain/activity.dart';

class ActivityRepository {
  ActivityRepository(this._db);
  final Database _db;

  static int _ms(DateTime t) => t.toUtc().millisecondsSinceEpoch;
  static DateTime _dt(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

  static Map<String, Object?> _toRow(ActivityEntry e) => {
    'type': e.type.name,
    'started_at': _ms(e.startedAt),
    'minutes': e.minutes,
    'intensity': e.intensity?.name,
    'notes': e.notes,
    'created_at': _ms(e.createdAt),
    'updated_at': _ms(e.updatedAt),
  };

  static ActivityEntry _fromRow(Map<String, Object?> r) => ActivityEntry(
    id: r['id']! as int,
    type: ActivityType.values.asNameMap()[r['type']] ?? ActivityType.other,
    startedAt: _dt(r['started_at']! as int),
    minutes: r['minutes']! as int,
    intensity: Intensity.values.asNameMap()[r['intensity']],
    notes: (r['notes'] as String?) ?? '',
    createdAt: _dt(r['created_at']! as int),
    updatedAt: _dt(r['updated_at']! as int),
  );

  Future<ActivityEntry> insert(ActivityEntry e) async =>
      e.copyWith(id: await _db.insert('activity_entries', _toRow(e)));

  Future<void> update(ActivityEntry e) => _db.update('activity_entries', _toRow(e), where: 'id = ?', whereArgs: [e.id]);

  Future<void> delete(int id) => _db.delete('activity_entries', where: 'id = ?', whereArgs: [id]);

  /// Entries with `from <= startedAt < to`, newest first.
  Future<List<ActivityEntry>> between(DateTime from, DateTime to) async => (await _db.query(
    'activity_entries',
    where: 'started_at >= ? AND started_at < ?',
    whereArgs: [_ms(from), _ms(to)],
    orderBy: 'started_at DESC',
  )).map(_fromRow).toList();

  Future<List<ActivityEntry>> recent({int limit = 20}) async =>
      (await _db.query('activity_entries', orderBy: 'started_at DESC', limit: limit)).map(_fromRow).toList();

  Future<List<ActivityEntry>> all() async =>
      (await _db.query('activity_entries', orderBy: 'started_at')).map(_fromRow).toList();

  Future<void> deleteAll() => _db.delete('activity_entries');
}
