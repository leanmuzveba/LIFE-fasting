// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'RUVA';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get back => 'Back';

  @override
  String get navToday => 'Today';

  @override
  String get navTimer => 'Timer';

  @override
  String get navNutrition => 'Nutrition';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String homeSessionInProgress(String date) {
    return '$date · Session in progress';
  }

  @override
  String get startFast => 'Start fast';

  @override
  String get endFast => 'End fast';

  @override
  String get editStartTime => 'Edit start time';

  @override
  String get changeTarget => 'Change target';

  @override
  String get cardFastStarted => 'FAST STARTED';

  @override
  String get cardPlannedEnd => 'PLANNED END';

  @override
  String get cardTarget => 'TARGET';

  @override
  String get cardIfStartedNow => 'IF STARTED NOW';

  @override
  String get cardChangeAnyTime => 'Change any time';

  @override
  String targetHours(int hours) {
    return '$hours hours';
  }

  @override
  String get ringReady => 'Ready when you are';

  @override
  String get ringTargetReached => 'Target reached';

  @override
  String get ringInProgress => 'Fasting in progress';

  @override
  String get ringTimeElapsed => 'TIME ELAPSED';

  @override
  String ringTargetLine(String target) {
    return '$target target';
  }

  @override
  String ringOfTargetLine(String target) {
    return 'of $target target';
  }

  @override
  String get ringCenterHint => 'Shows start and planned end times';

  @override
  String ringSemantics(String status, String elapsed, String targetLine) {
    return '$status. $elapsed elapsed, $targetLine.';
  }

  @override
  String ringSemanticsRemaining(String status, String elapsed, String targetLine, String remaining) {
    return '$status. $elapsed elapsed, $targetLine, $remaining remaining.';
  }

  @override
  String get markerCurrent => 'current estimate';

  @override
  String get markerPassed => 'passed';

  @override
  String get markerUpcoming => 'upcoming';

  @override
  String markerSemantics(String title, String state) {
    return '$title, $state. Opens details.';
  }

  @override
  String markerSemanticsAround(String title, String time, String state) {
    return '$title, around $time, $state. Opens details.';
  }

  @override
  String get readMore => 'Read more';

  @override
  String get endSessionTitle => 'End this session?';

  @override
  String get endSessionRecorded => 'Recorded so far: ';

  @override
  String get endSessionBody => '. You can end a session whenever you choose. It will be saved to your history.';

  @override
  String get endSession => 'End session';

  @override
  String get editStartBody =>
      'Forgot to press Start? Set when you actually began. The ring and history update after you save.';

  @override
  String get startedAtLabel => 'STARTED AT';

  @override
  String startedAtSemantics(String time) {
    return 'Started at $time. Change time';
  }

  @override
  String willStart(String day, String time) {
    return 'Will start $day at $time.';
  }

  @override
  String get errorStartInFuture => 'Start time can’t be in the future.';

  @override
  String get errorEndInFuture => 'End time can’t be in the future.';

  @override
  String get errorEndBeforeStart => 'End time must be after the start time.';

  @override
  String get milestoneTitle => 'Milestone';

  @override
  String get milestoneMarkerNote =>
      'The position of this marker is a visual reference for elapsed time. It is not proof that anything has happened in your body, and reaching it is not a goal or a health achievement.';

  @override
  String get milestoneReviewed => 'Content reviewed';

  @override
  String milestoneReviewedSource(String source) {
    return 'Content reviewed · $source';
  }

  @override
  String get milestoneDraft => 'Draft educational copy — awaiting review by a qualified health professional.';

  @override
  String get targetTitle => 'Your target';

  @override
  String get targetIntro =>
      'Choose how long you’d like to track. No option here is a recommendation, and you can end any session whenever you choose.';

  @override
  String get targetCustom => 'CUSTOM';

  @override
  String get targetDecrease => 'Decrease by 30 minutes';

  @override
  String get targetIncrease => 'Increase by 30 minutes';

  @override
  String get saveTarget => 'Save target';

  @override
  String get historyList => 'List';

  @override
  String get historyCalendar => 'Calendar';

  @override
  String get historyEmptyTitle => 'No sessions yet';

  @override
  String get historyEmptyBody => 'When you end a session, it’s saved here. You can edit or delete it at any time.';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusTargetReached => 'Target reached';

  @override
  String get statusEnded => 'Session ended';

  @override
  String sessionTimesOngoing(String start) {
    return '$start → now';
  }

  @override
  String sessionTimes(String start, String end) {
    return '$start → $end';
  }

  @override
  String sessionTileDetail(String times, String target) {
    return '$times · $target target';
  }

  @override
  String sessionTileSemantics(String day, String times, String duration, String target, String status) {
    return '$day, $times, $duration of $target target, $status. Opens options.';
  }

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get weekdayInitials => 'M,T,W,T,F,S,S';

  @override
  String noSessionsOn(String day) {
    return 'No sessions on $day.';
  }

  @override
  String daySessions(String day, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
      zero: 'no sessions',
    );
    return '$day, $_temp0';
  }

  @override
  String get sessionTitle => 'Session';

  @override
  String get sessionStarted => 'STARTED';

  @override
  String get sessionEnded => 'ENDED';

  @override
  String timeFieldSemantics(String label, String value) {
    return '$label $value. Change';
  }

  @override
  String get deleteSessionTitle => 'Delete this session?';

  @override
  String get deleteSessionBody => 'It will be removed from your history on this phone. This can’t be undone.';

  @override
  String get settingsTimer => 'TIMER';

  @override
  String get settingsTarget => 'Target';

  @override
  String get settings24h => '24-hour clock';

  @override
  String get settingsNotifications => 'NOTIFICATIONS';

  @override
  String get settingsTargetReached => 'Target time reached';

  @override
  String get settingsTargetReachedSub => 'A quiet notice when your planned time passes';

  @override
  String get settingsDailyReminder => 'Daily reminder';

  @override
  String settingsEveryDayAt(String time) {
    return 'Every day at $time';
  }

  @override
  String get settingsOff => 'Off';

  @override
  String get settingsReminderTime => 'Reminder time';

  @override
  String get settingsNotificationsBlocked => 'Notifications are turned off for this app in your phone’s settings.';

  @override
  String get settingsPrivacy => 'PRIVACY';

  @override
  String get settingsDataStays => 'Your data stays on this phone';

  @override
  String get settingsDataStaysSub => 'Nothing is uploaded or shared. There are no accounts or ads.';

  @override
  String get settingsDeleteAll => 'Delete all data';

  @override
  String get settingsDeleteAllSub => 'Sessions, settings and reminders';

  @override
  String get settingsAbout => 'ABOUT';

  @override
  String get settingsNotMedical => 'Not a medical device';

  @override
  String get settingsNotMedicalSub =>
      'This app records time only. Milestones are general estimates and can’t tell what is happening in your body. Speak with a qualified healthcare professional before changing how you eat.';

  @override
  String get deleteAllTitle => 'Delete all data?';

  @override
  String get deleteAllBody =>
      'This removes every session, your settings and any reminders from this phone. It can’t be undone.';

  @override
  String get deleteAll => 'Delete all';

  @override
  String get onboardingTitle => 'Welcome to RUVA, your calm place for fasting, food and wellness';

  @override
  String get onboardingNotMedical =>
      'This app records time. It is a tracking and educational tool, not a medical device, and it cannot tell what is happening in your body.';

  @override
  String get onboardingEstimates =>
      'Milestones on the timer are general estimates that vary between people. They are never goals.';

  @override
  String get onboardingPrivacy =>
      'Your sessions stay on this phone. Nothing is uploaded, and you can delete everything at any time.';

  @override
  String get onboardingSafety =>
      'Speak with a qualified healthcare professional before changing how you eat — especially if you have a medical condition, take medication, are pregnant, or have a history of disordered eating.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get ageTitle => 'Are you 18 or older?';

  @override
  String get ageBody =>
      'Fasting tools in this app are designed for adults only. If you’re under 18, we’ll show general information instead.';

  @override
  String get ageAdult => 'I’m 18 or older';

  @override
  String get ageUnder18 => 'I’m under 18';

  @override
  String get underageTitle => 'This app is designed for adults';

  @override
  String get underageMeals =>
      'Growing bodies need regular, balanced meals. Fasting isn’t recommended for people under 18 unless a doctor advises it.';

  @override
  String get underageTalk =>
      'If you have questions about eating, food or your body, talk with a parent or guardian and a qualified healthcare professional such as your doctor or a dietitian.';

  @override
  String get underageSupport =>
      'If you’re worried about how you feel about food, you deserve support — a trusted adult or your doctor can help you find it.';

  @override
  String get underageReset => 'I answered by mistake — start again';

  @override
  String get notifTargetTitle => 'Target time reached';

  @override
  String get notifTargetBody => 'Your planned time has passed. End your session whenever you’re ready.';

  @override
  String get splashTagline => 'FASTING · NUTRITION · WELLNESS';

  @override
  String get splashInitializing => 'GETTING READY';

  @override
  String get splashLoading => 'RUVA, loading';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get heroEyebrow => 'FASTING';

  @override
  String get heroReady => 'Ready when you are';

  @override
  String heroFastingFor(String duration) {
    return 'Fasting for $duration';
  }

  @override
  String heroEndsAt(String target, String time) {
    return '$target target · ends $time';
  }

  @override
  String heroIfStartedNow(String target, String time) {
    return '$target target · ends $time if you start now';
  }

  @override
  String get openTimer => 'Open timer';

  @override
  String get milestoneEstimateNote => 'Milestones on the timer are estimates and vary between people.';

  @override
  String get nutritionEmptyTitle => 'Nutrition is on its way';

  @override
  String get nutritionEmptyBody => 'Your food diary, My Kitchen and recipe ideas will live here.';

  @override
  String get notifDailyBody => 'Your daily reminder. Open the app to start or review a session.';
}
