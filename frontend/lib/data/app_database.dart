import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// On-device SQLite database. Nothing leaves the phone.
abstract final class AppDatabase {
  static const _version = 1;

  /// Opens (and creates/migrates) the database. Tests pass an FFI [factory]
  /// and [inMemoryDatabasePath].
  static Future<Database> open({DatabaseFactory? factory, String? path}) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), 'life_fasting.db');
    return f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(version: _version, onCreate: _create),
    );
  }

  static Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        started_at INTEGER NOT NULL,          -- UTC epoch ms
        ended_at INTEGER,                     -- UTC epoch ms, NULL while active
        target_minutes INTEGER NOT NULL CHECK (target_minutes > 0),
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        CHECK (ended_at IS NULL OR ended_at > started_at)
      )''');
    // At most one active session, enforced by the database itself.
    await db.execute('CREATE UNIQUE INDEX one_active_session ON sessions ((ended_at IS NULL)) WHERE ended_at IS NULL');
    await db.execute('CREATE INDEX sessions_started ON sessions (started_at)');
    await db.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    await db.execute('''
      CREATE TABLE notification_prefs (
        type TEXT PRIMARY KEY,
        enabled INTEGER NOT NULL,
        hour INTEGER CHECK (hour BETWEEN 0 AND 23),
        minute INTEGER CHECK (minute BETWEEN 0 AND 59)
      )''');
  }
}
