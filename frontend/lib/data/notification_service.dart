import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show basicLocaleListResolution;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/hydration.dart';
import '../l10n/app_localizations.dart';

/// Opt-in local notifications (FR-10). Copy is neutral: it never urges the
/// user to extend a session, reach a milestone or ignore how they feel.
class NotificationService {
  static const targetReachedId = 1;
  static const dailyReminderId = 2;

  /// Water reminders use ids 100.. (one per slot in [waterReminderHours]).
  static const waterReminderBaseId = 100;
  static const monthlyReviewId = 200;

  final _plugin = FlutterLocalNotificationsPlugin();

  /// Strings in the device language (falls back to English); no BuildContext here.
  AppLocalizations get _l => lookupAppLocalizations(
    basicLocaleListResolution(PlatformDispatcher.instance.locales, AppLocalizations.supportedLocales),
  );
  bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Optional reminders you turn on in Settings',
      importance: Importance.defaultImportance,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Ask only when the user switches a notification on.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// Returns whether the OS allows notifications.
  Future<bool> requestPermission() async {
    await _init();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, sound: true) ??
        false;
  }

  Future<void> scheduleTargetReached(DateTime at) async {
    await _init();
    await _plugin.cancel(id: targetReachedId);
    if (!at.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: targetReachedId,
      scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: _l.notifTargetTitle,
      body: _l.notifTargetBody,
    );
  }

  /// Daily at a local time of day.
  // ponytail: scheduled as the equivalent UTC time and repeated daily, so it can
  // shift by an hour across a DST change until the app is next opened (sync
  // re-schedules on launch). Add flutter_timezone for a true local zone if needed.
  Future<void> scheduleDailyReminder(int hour, int minute) async {
    await _init();
    await _plugin.cancel(id: dailyReminderId);
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: dailyReminderId,
      scheduledDate: tz.TZDateTime.from(next.toUtc(), tz.UTC),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      title: _l.appName,
      body: _l.notifDailyBody,
    );
  }

  /// Daily repeating water reminders at [waterReminderHours] (local time).
  Future<void> scheduleWaterReminders() async {
    await _init();
    final now = DateTime.now();
    for (final (i, hour) in waterReminderHours.indexed) {
      var next = DateTime(now.year, now.month, now.day, hour);
      if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        id: waterReminderBaseId + i,
        scheduledDate: tz.TZDateTime.from(next.toUtc(), tz.UTC),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        title: _l.appName,
        body: _l.notifWaterBody,
      );
    }
  }

  /// Monthly kitchen review: the 1st of each month at 10:00 local time.
  // ponytail: scheduled as the equivalent UTC time (like the daily reminder),
  // so it can drift an hour across DST until the app next opens and re-syncs.
  Future<void> scheduleMonthlyReview() async {
    await _init();
    await _plugin.cancel(id: monthlyReviewId);
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, 1, 10);
    if (!next.isAfter(now)) next = DateTime(now.year, now.month + 1, 1, 10);
    await _plugin.zonedSchedule(
      id: monthlyReviewId,
      scheduledDate: tz.TZDateTime.from(next.toUtc(), tz.UTC),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      title: _l.appName,
      body: _l.notifReviewBody,
    );
  }

  Future<void> cancelWaterReminders() async {
    for (var i = 0; i < waterReminderHours.length; i++) {
      await cancel(waterReminderBaseId + i);
    }
  }

  Future<void> cancel(int id) async {
    await _init();
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await _init();
    await _plugin.cancelAll();
  }
}
