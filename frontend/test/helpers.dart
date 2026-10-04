import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_fasting/data/app_database.dart';
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
    overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(clock.call)],
  );
  await c.read(settingsProvider.future);
  await c.read(activeSessionProvider.future);
  return c;
}
