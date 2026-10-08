import 'package:sqflite/sqflite.dart';

import '../domain/body.dart';

/// Profile details (in the settings table, so "delete my data" clears them)
/// and the weigh-in history.
class BodyRepository {
  BodyRepository(this._db);
  final Database _db;

  static int _ms(DateTime t) => t.toUtc().millisecondsSinceEpoch;

  Future<BodyProfile> profile() async {
    final kv = {
      for (final r in await _db.query('settings', where: "key LIKE 'body.%'")) r['key'] as String: r['value'] as String,
    };
    return BodyProfile(
      heightCm: double.tryParse(kv['body.heightCm'] ?? ''),
      birthYear: int.tryParse(kv['body.birthYear'] ?? ''),
      sex: Sex.values.asNameMap()[kv['body.sex']],
      trackWeight: kv['body.trackWeight'] != '0',
    );
  }

  Future<void> saveProfile(BodyProfile p) async {
    final batch = _db.batch();
    void put(String k, Object? v) => v == null
        ? batch.delete('settings', where: 'key = ?', whereArgs: ['body.$k'])
        : batch.insert('settings', {'key': 'body.$k', 'value': '$v'}, conflictAlgorithm: ConflictAlgorithm.replace);
    put('heightCm', p.heightCm);
    put('birthYear', p.birthYear);
    put('sex', p.sex?.name);
    put('trackWeight', p.trackWeight ? 1 : 0);
    await batch.commit(noResult: true);
  }

  static Map<String, Object?> _toRow(WeighIn w) => {
    'measured_at': _ms(w.at),
    'weight_kg': w.weightKg,
    'waist_cm': w.waistCm,
    'neck_cm': w.neckCm,
    'hip_cm': w.hipCm,
  };

  /// Oldest first.
  Future<List<WeighIn>> weighIns() async => [
    for (final r in await _db.query('weigh_ins', orderBy: 'measured_at'))
      WeighIn(
        id: r['id']! as int,
        at: DateTime.fromMillisecondsSinceEpoch(r['measured_at']! as int, isUtc: true),
        weightKg: (r['weight_kg']! as num).toDouble(),
        waistCm: (r['waist_cm'] as num?)?.toDouble(),
        neckCm: (r['neck_cm'] as num?)?.toDouble(),
        hipCm: (r['hip_cm'] as num?)?.toDouble(),
      ),
  ];

  Future<void> addWeighIn(WeighIn w) => _db.insert('weigh_ins', _toRow(w));
  Future<void> updateWeighIn(WeighIn w) => _db.update('weigh_ins', _toRow(w), where: 'id = ?', whereArgs: [w.id]);
  Future<void> deleteWeighIn(int id) => _db.delete('weigh_ins', where: 'id = ?', whereArgs: [id]);
  Future<void> deleteAll() => _db.delete('weigh_ins');
}
