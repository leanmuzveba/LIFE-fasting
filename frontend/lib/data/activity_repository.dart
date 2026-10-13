import 'dart:convert';

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
    'external_id': e.externalId,
    'kcal': e.kcal,
    'exercises': jsonEncode([for (final x in e.exercises) x.toJson()]),
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
    externalId: r['external_id'] as String?,
    kcal: (r['kcal'] as num?)?.toDouble(),
    exercises: [
      for (final j in jsonDecode((r['exercises'] as String?) ?? '[]') as List)
        Exercise.fromJson(j as Map<String, dynamic>),
    ],
  );

  Future<ActivityEntry> insert(ActivityEntry e) async =>
      e.copyWith(id: await _db.insert('activity_entries', _toRow(e)));

  Future<void> update(ActivityEntry e) => _db.update('activity_entries', _toRow(e), where: 'id = ?', whereArgs: [e.id]);

  /// Deletes your own entry; a watch workout is hidden instead so the next
  /// sync doesn't bring it back.
  Future<void> delete(ActivityEntry e) => e.fromWatch
      ? _db.update('activity_entries', {'hidden': 1}, where: 'id = ?', whereArgs: [e.id])
      : _db.delete('activity_entries', where: 'id = ?', whereArgs: [e.id]);

  /// Adds watch workouts not seen before; returns how many were new.
  Future<int> importWatch(Iterable<ActivityEntry> entries) async {
    var added = 0;
    for (final e in entries) {
      final id = await _db.insert('activity_entries', _toRow(e), conflictAlgorithm: ConflictAlgorithm.ignore);
      if (id > 0) added++;
    }
    return added;
  }

  /// Entries with `from <= startedAt < to`, newest first.
  Future<List<ActivityEntry>> between(DateTime from, DateTime to) async => (await _db.query(
    'activity_entries',
    where: 'hidden = 0 AND started_at >= ? AND started_at < ?',
    whereArgs: [_ms(from), _ms(to)],
    orderBy: 'started_at DESC',
  )).map(_fromRow).toList();

  Future<List<ActivityEntry>> recent({int limit = 20}) async => (await _db.query(
    'activity_entries',
    where: 'hidden = 0',
    orderBy: 'started_at DESC',
    limit: limit,
  )).map(_fromRow).toList();

  Future<List<ActivityEntry>> all() async =>
      (await _db.query('activity_entries', where: 'hidden = 0', orderBy: 'started_at')).map(_fromRow).toList();

  Future<void> deleteAll() => _db.delete('activity_entries');
}
