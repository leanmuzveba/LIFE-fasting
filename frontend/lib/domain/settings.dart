import 'hydration.dart';
import 'profile.dart';

export 'profile.dart';

enum AgeEligibility { unknown, adult, under18 }

class AppSettings {
  const AppSettings({
    this.use24HourTime = false,
    this.notificationsEnabled = false,
    this.targetMinutes = 16 * 60,
    this.onboardingComplete = false,
    this.eligibility = AgeEligibility.unknown,
    this.units = UnitSystem.metric,
    this.waterGoalMl = defaultWaterGoalMl,
    this.userName = '',
    this.memberSince,
    this.diet = DietPreference.none,
    this.allergies = const {},
  });

  final bool use24HourTime;
  final bool notificationsEnabled;
  final int targetMinutes;
  final bool onboardingComplete;
  final AgeEligibility eligibility;
  final UnitSystem units;

  /// Personal daily water goal (user-set; not a medical recommendation).
  final int waterGoalMl;

  /// Optional display name ('' = not set).
  final String userName;

  /// When RUVA was first set up on this phone.
  final DateTime? memberSince;
  final DietPreference diet;
  final Set<Allergen> allergies;

  VolumeUnit get waterUnit => units == UnitSystem.metric ? VolumeUnit.ml : VolumeUnit.flOz;

  /// Under-18s (and anyone not yet confirmed adult) never get fasting controls.
  bool get canFast => eligibility == AgeEligibility.adult;

  AppSettings copyWith({
    bool? use24HourTime,
    bool? notificationsEnabled,
    int? targetMinutes,
    bool? onboardingComplete,
    AgeEligibility? eligibility,
    UnitSystem? units,
    int? waterGoalMl,
    String? userName,
    DateTime? memberSince,
    DietPreference? diet,
    Set<Allergen>? allergies,
  }) => AppSettings(
    use24HourTime: use24HourTime ?? this.use24HourTime,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    targetMinutes: targetMinutes ?? this.targetMinutes,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    eligibility: eligibility ?? this.eligibility,
    units: units ?? this.units,
    waterGoalMl: waterGoalMl ?? this.waterGoalMl,
    userName: userName ?? this.userName,
    memberSince: memberSince ?? this.memberSince,
    diet: diet ?? this.diet,
    allergies: allergies ?? this.allergies,
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
