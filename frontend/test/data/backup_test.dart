import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/data/app_database.dart';
import 'package:life_fasting/data/backup.dart';
import 'package:life_fasting/data/session_repository.dart';
import 'package:life_fasting/data/settings_repository.dart';
import 'package:life_fasting/domain/fasting_session.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;
  final start = DateTime.utc(2026, 10, 3, 17);
  FastingSession session(int hours) => FastingSession(
    startedAt: start,
    endedAt: start.add(Duration(hours: hours)),
    targetMinutes: 960,
    createdAt: start,
    updatedAt: start,
  );

  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('backup_test'));
  tearDown(() => dir.delete(recursive: true));
  Future<Database> phone(String name, {int? version}) =>
      AppDatabase.open(factory: factory, path: p.join(dir.path, name), version: version);

  test('backup → new phone: data comes back, API keys stay out of the file', () async {
    final old = await phone('old.db');
    await SessionRepository(old).insert(session(16));
    await SettingsRepository(old).setApiKey('gemini', 'old-phone-key');
    await old.insert('settings', {'key': 'targetMinutes', 'value': '960'});
    final file = await Backup.create(old, factory: factory);
    expect(latin1.decode(file).contains('old-phone-key'), isFalse);

    final fresh = await phone('new.db');
    await SessionRepository(fresh).insert(session(12)); // replaced by the backup
    await SettingsRepository(fresh).setApiKey('gemini', 'new-phone-key');
    expect(await Backup.restore(fresh, file, factory: factory), isTrue);

    final sessions = await SessionRepository(fresh).all();
    expect(sessions.map((s) => s.endedAt), [start.add(const Duration(hours: 16))]);
    expect((await fresh.query('settings', where: "key = 'targetMinutes'")).single['value'], '960');
    expect(await SettingsRepository(fresh).apiKey('gemini'), 'new-phone-key');
    await old.close();
    await fresh.close();
  });

  test('an older backup is upgraded; other files and newer backups are refused', () async {
    final legacyPath = p.join(dir.path, 'v1.db');
    final legacy = await phone('v1.db', version: 1);
    await SessionRepository(legacy).insert(session(18));
    await legacy.close();

    final db = await phone('new.db');
    expect(await Backup.restore(db, await File(legacyPath).readAsBytes(), factory: factory), isTrue);
    expect(await SessionRepository(db).all(), hasLength(1));

    expect(await Backup.restore(db, utf8.encode('not a database'), factory: factory), isFalse);
    final newer = await Backup.create(db, factory: factory);
    final newerPath = p.join(dir.path, 'newer.db');
    await File(newerPath).writeAsBytes(newer);
    final n = await factory.openDatabase(newerPath);
    await n.setVersion(AppDatabase.latestVersion + 1);
    await n.close();
    expect(await Backup.restore(db, await File(newerPath).readAsBytes(), factory: factory), isFalse);
    expect(await SessionRepository(db).all(), hasLength(1), reason: 'a refused file changes nothing');
    await db.close();
  });
}
