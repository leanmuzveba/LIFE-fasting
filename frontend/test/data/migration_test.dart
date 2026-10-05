import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/data/app_database.dart';
import 'package:life_fasting/data/session_repository.dart';
import 'package:life_fasting/data/settings_repository.dart';
import 'package:life_fasting/domain/fasting_session.dart';
import 'package:life_fasting/domain/settings.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Every schema upgrade must keep data from older installs (PRD v1.2 §13).
void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;
  late Directory dir;
  late String path;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('ruva_migration');
    path = p.join(dir.path, AppDatabase.fileName);
  });
  tearDown(() => dir.delete(recursive: true));

  test('a v1 install (original fasting app) upgrades to the latest schema with its data intact', () async {
    final t0 = DateTime.utc(2026, 10, 1, 18);
    var db = await AppDatabase.open(factory: factory, path: path, version: 1);
    final sessions = SessionRepository(db);
    await sessions.insert(
      FastingSession(
        startedAt: t0,
        endedAt: t0.add(const Duration(hours: 16)),
        targetMinutes: 960,
        createdAt: t0,
        updatedAt: t0,
      ),
    );
    await sessions.insert(
      FastingSession(startedAt: t0.add(const Duration(days: 2)), targetMinutes: 840, createdAt: t0, updatedAt: t0),
    );
    await SettingsRepository(db)
        .save(const AppSettings(eligibility: AgeEligibility.adult, onboardingComplete: true, targetMinutes: 840));
    await SettingsRepository(db).saveNotificationPref(
      const NotificationPreference(type: NotificationType.dailyReminder, enabled: true, hour: 7, minute: 30),
    );
    await db.close();

    db = await AppDatabase.open(factory: factory, path: path);
    expect(await db.getVersion(), AppDatabase.latestVersion);
    final all = await SessionRepository(db).all();
    expect(all, hasLength(2));
    expect(all.last.endedAt, t0.add(const Duration(hours: 16)));
    expect((await SessionRepository(db).active())!.targetMinutes, 840);
    final settings = await SettingsRepository(db).load();
    expect(settings.canFast, isTrue);
    expect(settings.targetMinutes, 840);
    final daily = (await SettingsRepository(
      db,
    ).notificationPrefs()).firstWhere((x) => x.type == NotificationType.dailyReminder);
    expect([daily.enabled, daily.hour, daily.minute], [true, 7, 30]);
    await db.close();
  });

  test('a fresh install and an upgraded install end with the same tables', () async {
    Future<List<String>> tables(Database db) async => [
      for (final r in await db.rawQuery("SELECT name FROM sqlite_master WHERE type IN ('table','index') ORDER BY name"))
        r['name']! as String,
    ];

    final fresh = await AppDatabase.open(factory: factory, path: p.join(dir.path, 'fresh.db'));
    final freshTables = await tables(fresh);
    await fresh.close();

    await (await AppDatabase.open(factory: factory, path: path, version: 1)).close();
    final upgraded = await AppDatabase.open(factory: factory, path: path);
    expect(await tables(upgraded), freshTables);
    await upgraded.close();
  });
}
