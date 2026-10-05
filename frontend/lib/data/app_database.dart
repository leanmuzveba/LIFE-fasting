import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

typedef Migration = Future<void> Function(DatabaseExecutor db);

/// On-device SQLite database. Nothing leaves the phone.
///
/// Schema changes are append-only [migrations]: entry `i` upgrades version
/// `i` to `i + 1`. A fresh install runs them all; an existing install runs
/// only the ones it has not seen. Never edit or reorder a shipped migration —
/// add a new one (and extend `test/data/migration_test.dart`).
abstract final class AppDatabase {
  /// The file name stays from the original app so existing data is kept.
  static const fileName = 'life_fasting.db';

  static final List<Migration> migrations = [_v1Initial, _v2Hydration, _v3Activity, _v4Kitchen, _v5Review];

  static int get latestVersion => migrations.length;

  /// Opens (and creates/migrates) the database. Tests pass an FFI [factory],
  /// a [path], and optionally an older [version] to build a legacy database.
  static Future<Database> open({DatabaseFactory? factory, String? path, int? version}) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), fileName);
    final target = version ?? latestVersion;
    // sqflite runs onCreate/onUpgrade inside one transaction: all or nothing.
    Future<void> run(Database db, int from) async {
      for (var v = from; v < target; v++) {
        await migrations[v](db);
      }
    }

    return f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: target,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, _) => run(db, 0),
        onUpgrade: (db, from, _) => run(db, from),
      ),
    );
  }

  /// Version 5 — monthly kitchen reviews and the shopping list (PRD v1.2 §6).
  static Future<void> _v5Review(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE kitchen_reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        started_at INTEGER NOT NULL,          -- UTC epoch ms
        completed_at INTEGER
      )''');
    await db.execute('''
      CREATE TABLE kitchen_review_changes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        review_id INTEGER NOT NULL REFERENCES kitchen_reviews (id) ON DELETE CASCADE,
        ingredient_id INTEGER NOT NULL,       -- no FK: the ingredient may later be removed
        name TEXT NOT NULL,
        action TEXT NOT NULL,                 -- kept / usedUp / spoiled
        old_quantity REAL NOT NULL,
        new_quantity REAL,
        unit TEXT NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE shopping_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL CHECK (length(trim(name)) > 0),
        note TEXT NOT NULL DEFAULT '',
        checked INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )''');
  }

  /// Version 4 — My Kitchen ingredient inventory (PRD v1.2 §4).
  static Future<void> _v4Kitchen(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL CHECK (length(trim(name)) > 0),
        categories TEXT NOT NULL DEFAULT '',  -- comma-separated IngredientCategory names
        quantity REAL NOT NULL CHECK (quantity >= 0),
        unit TEXT NOT NULL,
        state TEXT NOT NULL,                  -- fresh / frozen / canned / dried
        purchased_on TEXT,                    -- YYYY-MM-DD
        expires_on TEXT,                      -- YYYY-MM-DD
        low_stock_at REAL CHECK (low_stock_at IS NULL OR low_stock_at >= 0),
        brand TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'active',-- active / finished / discarded (kept as history)
        status_at INTEGER,                    -- UTC epoch ms
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )''');
    await db.execute('CREATE INDEX ingredients_status ON ingredients (status, name)');
  }

  /// Version 3 — exercise and activity (PRD v1.2 §8).
  static Future<void> _v3Activity(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE activity_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        started_at INTEGER NOT NULL,          -- UTC epoch ms
        minutes INTEGER NOT NULL CHECK (minutes BETWEEN 1 AND 600),
        intensity TEXT,                       -- optional: light / moderate / heavy
        notes TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )''');
    await db.execute('CREATE INDEX activity_started ON activity_entries (started_at)');
  }

  /// Version 2 — water intake (PRD v1.2 §9).
  static Future<void> _v2Hydration(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE hydration_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount_ml REAL NOT NULL CHECK (amount_ml > 0),
        logged_at INTEGER NOT NULL,           -- UTC epoch ms
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )''');
    await db.execute('CREATE INDEX hydration_logged ON hydration_entries (logged_at)');
  }

  /// Version 1 — the original fasting tracker (sessions, settings, reminders).
  static Future<void> _v1Initial(DatabaseExecutor db) async {
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
