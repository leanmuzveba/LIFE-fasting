enum AgeEligibility { unknown, adult, under18 }

class AppSettings {
  const AppSettings({
    this.use24HourTime = false,
    this.notificationsEnabled = false,
    this.targetMinutes = 16 * 60,
    this.onboardingComplete = false,
    this.eligibility = AgeEligibility.unknown,
  });

  final bool use24HourTime;
  final bool notificationsEnabled;
  final int targetMinutes;
  final bool onboardingComplete;
  final AgeEligibility eligibility;

  /// Under-18s (and anyone not yet confirmed adult) never get fasting controls.
  bool get canFast => eligibility == AgeEligibility.adult;

  AppSettings copyWith({
    bool? use24HourTime,
    bool? notificationsEnabled,
    int? targetMinutes,
    bool? onboardingComplete,
    AgeEligibility? eligibility,
  }) => AppSettings(
    use24HourTime: use24HourTime ?? this.use24HourTime,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    targetMinutes: targetMinutes ?? this.targetMinutes,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    eligibility: eligibility ?? this.eligibility,
  );
}

enum NotificationType { targetReached, dailyReminder }

class NotificationPreference {
  const NotificationPreference({required this.type, this.enabled = false, this.hour, this.minute});

  final NotificationType type;
  final bool enabled;

  /// Local time of day, for reminders that have one.
  final int? hour;
  final int? minute;

  NotificationPreference copyWith({bool? enabled, int? hour, int? minute}) => NotificationPreference(
    type: type,
    enabled: enabled ?? this.enabled,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
  );
}

/// Target presets offered to eligible adults. No preset is a recommendation.
const targetPresetsHours = [12, 14, 16, 18];
const minTargetMinutes = 60;
const maxTargetMinutes = 24 * 60; // The app does not promote extended fasting.
