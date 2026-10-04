import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_fasting/data/app_database.dart';
import 'package:life_fasting/data/session_repository.dart';
import 'package:life_fasting/data/settings_repository.dart';
import 'package:life_fasting/domain/fasting_session.dart';
import 'package:life_fasting/domain/settings.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;
  late Directory dir;
  late String path;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('life_fasting_test');
    path = p.join(dir.path, 'test.db');
  });
  tearDown(() => dir.delete(recursive: true));

  final start = DateTime.utc(2026, 10, 3, 17);
  FastingSession newSession({DateTime? end}) =>
      FastingSession(startedAt: start, endedAt: end, targetMinutes: 960, createdAt: start, updatedAt: start);

  test('active session survives closing and reopening the database', () async {
    var db = await AppDatabase.open(factory: factory, path: path);
    await SessionRepository(db).insert(newSession());
    await db.close();

    db = await AppDatabase.open(factory: factory, path: path);
    final active = await SessionRepository(db).active();
    expect(active, isNotNull);
    expect(active!.startedAt, start);
    expect(active.startedAt.isUtc, isTrue);
    expect(active.targetMinutes, 960);
    await db.close();
  });

  test('end, edit, list and delete sessions', () async {
    final db = await AppDatabase.open(factory: factory, path: path);
    final repo = SessionRepository(db);
    final s = await repo.insert(newSession());
    await repo.update(s.copyWith(endedAt: () => start.add(const Duration(hours: 16))));
    expect(await repo.active(), isNull);

    final later = await repo.insert(
      FastingSession(
        startedAt: start.add(const Duration(days: 1)),
        targetMinutes: 720,
        createdAt: start,
        updatedAt: start,
      ),
    );
    final all = await repo.all();
    expect(all.map((x) => x.id), [later.id, s.id]); // newest first
    expect(all.last.endedAt, start.add(const Duration(hours: 16)));

    await repo.delete(s.id!);
    expect((await repo.all()).length, 1);
    await repo.deleteAll();
    expect(await repo.all(), isEmpty);
    await db.close();
  });

  test('database refuses a second active session and inverted times', () async {
    final db = await AppDatabase.open(factory: factory, path: path);
    final repo = SessionRepository(db);
    await repo.insert(newSession());
    expect(() => repo.insert(newSession()), throwsA(isA<DatabaseException>()));
    expect(
      () => repo.insert(newSession(end: start.subtract(const Duration(hours: 1)))),
      throwsA(isA<DatabaseException>()),
    );
    await db.close();
  });

  test('settings and notification preferences round-trip', () async {
    var db = await AppDatabase.open(factory: factory, path: path);
    var repo = SettingsRepository(db);
    expect((await repo.load()).eligibility, AgeEligibility.unknown);

    await repo.save(
      const AppSettings(
        use24HourTime: true,
        targetMinutes: 14 * 60,
        onboardingComplete: true,
        eligibility: AgeEligibility.adult,
      ),
    );
    await repo.saveNotificationPref(
      const NotificationPreference(type: NotificationType.dailyReminder, enabled: true, hour: 20, minute: 30),
    );
    await db.close();

    db = await AppDatabase.open(factory: factory, path: path);
    repo = SettingsRepository(db);
    final s = await repo.load();
    expect(s.use24HourTime, isTrue);
    expect(s.targetMinutes, 840);
    expect(s.onboardingComplete, isTrue);
    expect(s.canFast, isTrue);
    final prefs = await repo.notificationPrefs();
    final daily = prefs.firstWhere((x) => x.type == NotificationType.dailyReminder);
    expect([daily.enabled, daily.hour, daily.minute], [true, 20, 30]);
    expect(prefs.firstWhere((x) => x.type == NotificationType.targetReached).enabled, isFalse);

    await repo.clear();
    expect((await repo.load()).onboardingComplete, isFalse);
    await db.close();
  });
}
