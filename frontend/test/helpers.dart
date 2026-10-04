import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_fasting/data/app_database.dart';
import 'package:life_fasting/data/notification_service.dart';
import 'package:life_fasting/state/providers.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Mutable fake clock for tests.
class FakeClock {
  FakeClock(this.now);
  DateTime now;
  DateTime call() => now;
  void advance(Duration d) => now = now.add(d);
}

Future<Database> openTestDb() {
  sqfliteFfiInit();
  return AppDatabase.open(factory: databaseFactoryFfiNoIsolate, path: inMemoryDatabasePath);
}

Future<ProviderContainer> testContainer(Database db, FakeClock clock) async {
  final c = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(clock.call),
      notificationServiceProvider.overrideWithValue(FakeNotifications()),
    ],
  );
  await c.read(settingsProvider.future);
  await c.read(activeSessionProvider.future);
  return c;
}

bool _fontsLoaded = false;

/// Loads the bundled Manrope so widget tests lay out like the real app
/// (the default test font renders every glyph as a wide box).
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  final loader = FontLoader('Manrope');
  for (final w in [500, 600, 700, 800]) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Manrope-$w.ttf').readAsBytesSync())));
  }
  await loader.load();
  _fontsLoaded = true;
}

/// Records what would be scheduled instead of calling the OS.
class FakeNotifications extends NotificationService {
  FakeNotifications({this.permission = true});
  bool permission;
  final scheduled = <int, DateTime>{};

  @override
  Future<bool> requestPermission() async => permission;

  @override
  Future<void> scheduleTargetReached(DateTime at) async => scheduled[NotificationService.targetReachedId] = at;

  @override
  Future<void> scheduleDailyReminder(int hour, int minute) async =>
      scheduled[NotificationService.dailyReminderId] = DateTime(2000, 1, 1, hour, minute);

  @override
  Future<void> cancel(int id) async => scheduled.remove(id);

  @override
  Future<void> cancelAll() async => scheduled.clear();
}
