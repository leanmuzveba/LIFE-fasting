import 'package:sqflite/sqflite.dart';

import '../domain/fasting_session.dart';

class SessionRepository {
  SessionRepository(this._db);
  final Database _db;

  static int _ms(DateTime t) => t.toUtc().millisecondsSinceEpoch;
  static DateTime _dt(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

  static Map<String, Object?> _toRow(FastingSession s) => {
    'started_at': _ms(s.startedAt),
    'ended_at': s.endedAt == null ? null : _ms(s.endedAt!),
    'target_minutes': s.targetMinutes,
    'created_at': _ms(s.createdAt),
    'updated_at': _ms(s.updatedAt),
  };

  static FastingSession _fromRow(Map<String, Object?> r) => FastingSession(
    id: r['id'] as int,
    startedAt: _dt(r['started_at'] as int),
    endedAt: r['ended_at'] == null ? null : _dt(r['ended_at'] as int),
    targetMinutes: r['target_minutes'] as int,
    createdAt: _dt(r['created_at'] as int),
    updatedAt: _dt(r['updated_at'] as int),
  );

  Future<FastingSession?> active() async {
    final rows = await _db.query('sessions', where: 'ended_at IS NULL', limit: 1);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  /// All sessions, newest first.
  Future<List<FastingSession>> all() async =>
      (await _db.query('sessions', orderBy: 'started_at DESC')).map(_fromRow).toList();

  Future<FastingSession> insert(FastingSession s) async {
    final id = await _db.insert('sessions', _toRow(s));
    return s.copyWith(id: id);
  }

  Future<void> update(FastingSession s) => _db.update('sessions', _toRow(s), where: 'id = ?', whereArgs: [s.id]);

  Future<void> delete(int id) => _db.delete('sessions', where: 'id = ?', whereArgs: [id]);

  Future<void> deleteAll() => _db.delete('sessions');
}
