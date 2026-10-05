import 'hydration.dart';

enum AgeEligibility { unknown, adult, under18 }

class AppSettings {
  const AppSettings({
    this.use24HourTime = false,
    this.notificationsEnabled = false,
    this.targetMinutes = 16 * 60,
    this.onboardingComplete = false,
    this.eligibility = AgeEligibility.unknown,
    this.waterUnit = VolumeUnit.ml,
    this.waterGoalMl = defaultWaterGoalMl,
  });

  final bool use24HourTime;
  final bool notificationsEnabled;
  final int targetMinutes;
  final bool onboardingComplete;
  final AgeEligibility eligibility;
  final VolumeUnit waterUnit;

  /// Personal daily water goal (user-set; not a medical recommendation).
  final int waterGoalMl;

  /// Under-18s (and anyone not yet confirmed adult) never get fasting controls.
  bool get canFast => eligibility == AgeEligibility.adult;

  AppSettings copyWith({
    bool? use24HourTime,
    bool? notificationsEnabled,
    int? targetMinutes,
    bool? onboardingComplete,
    AgeEligibility? eligibility,
    VolumeUnit? waterUnit,
    int? waterGoalMl,
  }) => AppSettings(
    use24HourTime: use24HourTime ?? this.use24HourTime,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    targetMinutes: targetMinutes ?? this.targetMinutes,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    eligibility: eligibility ?? this.eligibility,
    waterUnit: waterUnit ?? this.waterUnit,
    waterGoalMl: waterGoalMl ?? this.waterGoalMl,
  );
}

enum NotificationType { targetReached, dailyReminder, waterReminder }

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

const defaultWaterGoalMl = 2000;
const minWaterGoalMl = 500;
const maxWaterGoalMl = 5000;
