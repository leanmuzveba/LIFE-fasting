import 'package:sqflite/sqflite.dart';

import '../domain/hydration.dart';
import '../domain/settings.dart';

class SettingsRepository {
  SettingsRepository(this._db);
  final Database _db;

  Future<AppSettings> load() async {
    final kv = {for (final r in await _db.query('settings')) r['key'] as String: r['value'] as String};
    const d = AppSettings();
    return AppSettings(
      use24HourTime: kv['use24HourTime'] == null ? d.use24HourTime : kv['use24HourTime'] == '1',
      notificationsEnabled: kv['notificationsEnabled'] == null
          ? d.notificationsEnabled
          : kv['notificationsEnabled'] == '1',
      targetMinutes: (int.tryParse(kv['targetMinutes'] ?? '') ?? d.targetMinutes).clamp(
        minTargetMinutes,
        maxTargetMinutes,
      ),
      onboardingComplete: kv['onboardingComplete'] == '1',
      eligibility: AgeEligibility.values.asNameMap()[kv['eligibility']] ?? d.eligibility,
      waterUnit: VolumeUnit.values.asNameMap()[kv['waterUnit']] ?? d.waterUnit,
      waterGoalMl: (int.tryParse(kv['waterGoalMl'] ?? '') ?? d.waterGoalMl).clamp(minWaterGoalMl, maxWaterGoalMl),
    );
  }

  Future<void> save(AppSettings s) async {
    final batch = _db.batch();
    void put(String k, String v) =>
        batch.insert('settings', {'key': k, 'value': v}, conflictAlgorithm: ConflictAlgorithm.replace);
    put('use24HourTime', s.use24HourTime ? '1' : '0');
    put('notificationsEnabled', s.notificationsEnabled ? '1' : '0');
    put('targetMinutes', '${s.targetMinutes.clamp(minTargetMinutes, maxTargetMinutes)}');
    put('onboardingComplete', s.onboardingComplete ? '1' : '0');
    put('eligibility', s.eligibility.name);
    put('waterUnit', s.waterUnit.name);
    put('waterGoalMl', '${s.waterGoalMl.clamp(minWaterGoalMl, maxWaterGoalMl)}');
    await batch.commit(noResult: true);
  }

  Future<List<NotificationPreference>> notificationPrefs() async {
    final rows = {for (final r in await _db.query('notification_prefs')) r['type'] as String: r};
    return [
      for (final t in NotificationType.values)
        if (rows[t.name] case final r?)
          NotificationPreference(
            type: t,
            enabled: r['enabled'] == 1,
            hour: r['hour'] as int?,
            minute: r['minute'] as int?,
          )
        else
          NotificationPreference(type: t),
    ];
  }

  Future<void> saveNotificationPref(NotificationPreference p) => _db.insert('notification_prefs', {
    'type': p.type.name,
    'enabled': p.enabled ? 1 : 0,
    'hour': p.hour,
    'minute': p.minute,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  /// "Delete my data": wipes settings and preferences (sessions handled separately).
  Future<void> clear() async {
    await _db.delete('settings');
    await _db.delete('notification_prefs');
  }
}
