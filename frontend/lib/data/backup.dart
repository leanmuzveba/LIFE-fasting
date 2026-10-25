import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

/// A backup is a copy of the whole database, minus API keys: you keep the
/// file (Drive, email, Files) and restore it on a new phone.
abstract final class Backup {
  static Future<T> _inTemp<T>(Future<T> Function(String path) run) async {
    final dir = await Directory.systemTemp.createTemp('magnavita');
    try {
      return await run(p.join(dir.path, 'backup.db'));
    } finally {
      await dir.delete(recursive: true);
    }
  }

  /// The backup file's bytes.
  // ponytail: VACUUM INTO needs SQLite 3.27 (Android 11+); copy the file if older phones matter.
  static Future<Uint8List> create(Database db, {DatabaseFactory? factory}) => _inTemp((path) async {
    await db.execute('VACUUM INTO ?', [path]);
    final copy = await (factory ?? databaseFactory).openDatabase(path);
    await copy.delete('settings', where: "key LIKE 'apiKey.%'"); // the file may end up in the cloud
    await copy.execute('VACUUM'); // and leave no trace of them
    await copy.close();
    return File(path).readAsBytes();
  });

  /// Replaces everything in [db] with the backup; false when [bytes] isn't a
  /// MagnaVita backup (or is from a newer version). API keys on this phone stay.
  static Future<bool> restore(Database db, Uint8List bytes, {DatabaseFactory? factory}) => _inTemp((path) async {
    final f = factory ?? databaseFactory;
    await File(path).writeAsBytes(bytes);
    try {
      final check = await f.openDatabase(path, options: OpenDatabaseOptions(readOnly: true));
      try {
        final version = Sqflite.firstIntValue(await check.rawQuery('PRAGMA user_version')) ?? 0;
        final ours = (await check.query('sqlite_master', where: "name = 'sessions'")).isNotEmpty;
        if (!ours || version < 1 || version > AppDatabase.latestVersion) return false;
      } finally {
        await check.close();
      }
    } on Exception {
      return false; // not a database at all
    }
    await (await AppDatabase.open(factory: f, path: path)).close(); // an older backup gets this version's tables

    final tables = [
      for (final r in await db.query(
        'sqlite_master',
        columns: ['name'],
        where: "type = 'table' AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'",
      ))
        r['name']! as String,
    ];
    await db.execute('ATTACH DATABASE ? AS backup', [path]);
    try {
      // All or nothing: a failure leaves this phone's data as it was.
      await db.transaction((txn) async {
        await txn.execute('PRAGMA defer_foreign_keys = ON');
        for (final t in tables) {
          final where = t == 'settings' ? " WHERE key NOT LIKE 'apiKey.%'" : '';
          await txn.execute('DELETE FROM main.$t$where');
          await txn.execute('INSERT INTO main.$t SELECT * FROM backup.$t$where');
        }
      });
    } finally {
      await db.execute('DETACH DATABASE backup');
    }
    return true;
  });
}
