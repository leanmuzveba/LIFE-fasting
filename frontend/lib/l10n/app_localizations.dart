import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'RUVA'**
  String get appName;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navTimer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get navTimer;

  /// No description provided for @navNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get navNutrition;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @homeSessionInProgress.
  ///
  /// In en, this message translates to:
  /// **'{date} · Session in progress'**
  String homeSessionInProgress(String date);

  /// No description provided for @startFast.
  ///
  /// In en, this message translates to:
  /// **'Start fast'**
  String get startFast;

  /// No description provided for @endFast.
  ///
  /// In en, this message translates to:
  /// **'End fast'**
  String get endFast;

  /// No description provided for @editStartTime.
  ///
  /// In en, this message translates to:
  /// **'Edit start time'**
  String get editStartTime;

  /// No description provided for @changeTarget.
  ///
  /// In en, this message translates to:
  /// **'Change target'**
  String get changeTarget;

  /// No description provided for @cardFastStarted.
  ///
  /// In en, this message translates to:
  /// **'FAST STARTED'**
  String get cardFastStarted;

  /// No description provided for @cardPlannedEnd.
  ///
  /// In en, this message translates to:
  /// **'PLANNED END'**
  String get cardPlannedEnd;

  /// No description provided for @cardTarget.
  ///
  /// In en, this message translates to:
  /// **'TARGET'**
  String get cardTarget;

  /// No description provided for @cardIfStartedNow.
  ///
  /// In en, this message translates to:
  /// **'IF STARTED NOW'**
  String get cardIfStartedNow;

  /// No description provided for @cardChangeAnyTime.
  ///
  /// In en, this message translates to:
  /// **'Change any time'**
  String get cardChangeAnyTime;

  /// No description provided for @targetHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours'**
  String targetHours(int hours);

  /// No description provided for @ringReady.
  ///
  /// In en, this message translates to:
  /// **'Ready when you are'**
  String get ringReady;

  /// No description provided for @ringTargetReached.
  ///
  /// In en, this message translates to:
  /// **'Target reached'**
  String get ringTargetReached;

  /// No description provided for @ringInProgress.
  ///
  /// In en, this message translates to:
  /// **'Fasting in progress'**
  String get ringInProgress;

  /// No description provided for @ringTimeElapsed.
  ///
  /// In en, this message translates to:
  /// **'TIME ELAPSED'**
  String get ringTimeElapsed;

  /// No description provided for @ringTargetLine.
  ///
  /// In en, this message translates to:
  /// **'{target} target'**
  String ringTargetLine(String target);

  /// No description provided for @ringOfTargetLine.
  ///
  /// In en, this message translates to:
  /// **'of {target} target'**
  String ringOfTargetLine(String target);

  /// No description provided for @ringCenterHint.
  ///
  /// In en, this message translates to:
  /// **'Shows start and planned end times'**
  String get ringCenterHint;

  /// No description provided for @ringSemantics.
  ///
  /// In en, this message translates to:
  /// **'{status}. {elapsed} elapsed, {targetLine}.'**
  String ringSemantics(String status, String elapsed, String targetLine);

  /// No description provided for @ringSemanticsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{status}. {elapsed} elapsed, {targetLine}, {remaining} remaining.'**
  String ringSemanticsRemaining(String status, String elapsed, String targetLine, String remaining);

  /// No description provided for @markerCurrent.
  ///
  /// In en, this message translates to:
  /// **'current estimate'**
  String get markerCurrent;

  /// No description provided for @markerPassed.
  ///
  /// In en, this message translates to:
  /// **'passed'**
  String get markerPassed;

  /// No description provided for @markerUpcoming.
  ///
  /// In en, this message translates to:
  /// **'upcoming'**
  String get markerUpcoming;

  /// No description provided for @markerSemantics.
  ///
  /// In en, this message translates to:
  /// **'{title}, {state}. Opens details.'**
  String markerSemantics(String title, String state);

  /// No description provided for @markerSemanticsAround.
  ///
  /// In en, this message translates to:
  /// **'{title}, around {time}, {state}. Opens details.'**
  String markerSemanticsAround(String title, String time, String state);

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @endSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'End this session?'**
  String get endSessionTitle;

  /// No description provided for @endSessionRecorded.
  ///
  /// In en, this message translates to:
  /// **'Recorded so far: '**
  String get endSessionRecorded;

  /// No description provided for @endSessionBody.
  ///
  /// In en, this message translates to:
  /// **'. You can end a session whenever you choose. It will be saved to your history.'**
  String get endSessionBody;

  /// No description provided for @endSession.
  ///
  /// In en, this message translates to:
  /// **'End session'**
  String get endSession;

  /// No description provided for @editStartBody.
  ///
  /// In en, this message translates to:
  /// **'Forgot to press Start? Set when you actually began. The ring and history update after you save.'**
  String get editStartBody;

  /// No description provided for @startedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'STARTED AT'**
  String get startedAtLabel;

  /// No description provided for @startedAtSemantics.
  ///
  /// In en, this message translates to:
  /// **'Started at {time}. Change time'**
  String startedAtSemantics(String time);

  /// No description provided for @willStart.
  ///
  /// In en, this message translates to:
  /// **'Will start {day} at {time}.'**
  String willStart(String day, String time);

  /// No description provided for @errorStartInFuture.
  ///
  /// In en, this message translates to:
  /// **'Start time can’t be in the future.'**
  String get errorStartInFuture;

  /// No description provided for @errorEndInFuture.
  ///
  /// In en, this message translates to:
  /// **'End time can’t be in the future.'**
  String get errorEndInFuture;

  /// No description provided for @errorEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'End time must be after the start time.'**
  String get errorEndBeforeStart;

  /// No description provided for @milestoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Milestone'**
  String get milestoneTitle;

  /// No description provided for @milestoneMarkerNote.
  ///
  /// In en, this message translates to:
  /// **'The position of this marker is a visual reference for elapsed time. It is not proof that anything has happened in your body, and reaching it is not a goal or a health achievement.'**
  String get milestoneMarkerNote;

  /// No description provided for @milestoneReviewed.
  ///
  /// In en, this message translates to:
  /// **'Content reviewed'**
  String get milestoneReviewed;

  /// No description provided for @milestoneReviewedSource.
  ///
  /// In en, this message translates to:
  /// **'Content reviewed · {source}'**
  String milestoneReviewedSource(String source);

  /// No description provided for @milestoneDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft educational copy — awaiting review by a qualified health professional.'**
  String get milestoneDraft;

  /// No description provided for @targetTitle.
  ///
  /// In en, this message translates to:
  /// **'Your target'**
  String get targetTitle;

  /// No description provided for @targetIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose how long you’d like to track. No option here is a recommendation, and you can end any session whenever you choose.'**
  String get targetIntro;

  /// No description provided for @targetCustom.
  ///
  /// In en, this message translates to:
  /// **'CUSTOM'**
  String get targetCustom;

  /// No description provided for @targetDecrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease by 30 minutes'**
  String get targetDecrease;

  /// No description provided for @targetIncrease.
  ///
  /// In en, this message translates to:
  /// **'Increase by 30 minutes'**
  String get targetIncrease;

  /// No description provided for @saveTarget.
  ///
  /// In en, this message translates to:
  /// **'Save target'**
  String get saveTarget;

  /// No description provided for @historyList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get historyList;

  /// No description provided for @historyCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get historyCalendar;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'When you end a session, it’s saved here. You can edit or delete it at any time.'**
  String get historyEmptyBody;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusTargetReached.
  ///
  /// In en, this message translates to:
  /// **'Target reached'**
  String get statusTargetReached;

  /// No description provided for @statusEnded.
  ///
  /// In en, this message translates to:
  /// **'Session ended'**
  String get statusEnded;

  /// No description provided for @sessionTimesOngoing.
  ///
  /// In en, this message translates to:
  /// **'{start} → now'**
  String sessionTimesOngoing(String start);

  /// No description provided for @sessionTimes.
  ///
  /// In en, this message translates to:
  /// **'{start} → {end}'**
  String sessionTimes(String start, String end);

  /// No description provided for @sessionTileDetail.
  ///
  /// In en, this message translates to:
  /// **'{times} · {target} target'**
  String sessionTileDetail(String times, String target);

  /// No description provided for @sessionTileSemantics.
  ///
  /// In en, this message translates to:
  /// **'{day}, {times}, {duration} of {target} target, {status}. Opens options.'**
  String sessionTileSemantics(String day, String times, String duration, String target, String status);

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @weekdayInitials.
  ///
  /// In en, this message translates to:
  /// **'M,T,W,T,F,S,S'**
  String get weekdayInitials;

  /// No description provided for @noSessionsOn.
  ///
  /// In en, this message translates to:
  /// **'No sessions on {day}.'**
  String noSessionsOn(String day);

  /// No description provided for @daySessions.
  ///
  /// In en, this message translates to:
  /// **'{day}, {count, plural, =0{no sessions} =1{1 session} other{{count} sessions}}'**
  String daySessions(String day, int count);

  /// No description provided for @sessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get sessionTitle;

  /// No description provided for @sessionStarted.
  ///
  /// In en, this message translates to:
  /// **'STARTED'**
  String get sessionStarted;

  /// No description provided for @sessionEnded.
  ///
  /// In en, this message translates to:
  /// **'ENDED'**
  String get sessionEnded;

  /// No description provided for @timeFieldSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label} {value}. Change'**
  String timeFieldSemantics(String label, String value);

  /// No description provided for @deleteSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this session?'**
  String get deleteSessionTitle;

  /// No description provided for @deleteSessionBody.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from your history on this phone. This can’t be undone.'**
  String get deleteSessionBody;

  /// No description provided for @settingsTimer.
  ///
  /// In en, this message translates to:
  /// **'TIMER'**
  String get settingsTimer;

  /// No description provided for @settingsTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get settingsTarget;

  /// No description provided for @settings24h.
  ///
  /// In en, this message translates to:
  /// **'24-hour clock'**
  String get settings24h;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get settingsNotifications;

  /// No description provided for @settingsTargetReached.
  ///
  /// In en, this message translates to:
  /// **'Target time reached'**
  String get settingsTargetReached;

  /// No description provided for @settingsTargetReachedSub.
  ///
  /// In en, this message translates to:
  /// **'A quiet notice when your planned time passes'**
  String get settingsTargetReachedSub;

  /// No description provided for @settingsDailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get settingsDailyReminder;

  /// No description provided for @settingsEveryDayAt.
  ///
  /// In en, this message translates to:
  /// **'Every day at {time}'**
  String settingsEveryDayAt(String time);

  /// No description provided for @settingsOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsOff;

  /// No description provided for @settingsReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get settingsReminderTime;

  /// No description provided for @settingsNotificationsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off for this app in your phone’s settings.'**
  String get settingsNotificationsBlocked;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY'**
  String get settingsPrivacy;

  /// No description provided for @settingsDataStays.
  ///
  /// In en, this message translates to:
  /// **'Your data stays on this phone'**
  String get settingsDataStays;

  /// No description provided for @settingsDataStaysSub.
  ///
  /// In en, this message translates to:
  /// **'Nothing is uploaded or shared. There are no accounts or ads.'**
  String get settingsDataStaysSub;

  /// No description provided for @settingsDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get settingsDeleteAll;

  /// No description provided for @settingsDeleteAllSub.
  ///
  /// In en, this message translates to:
  /// **'Sessions, settings and reminders'**
  String get settingsDeleteAllSub;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get settingsAbout;

  /// No description provided for @settingsNotMedical.
  ///
  /// In en, this message translates to:
  /// **'Not a medical device'**
  String get settingsNotMedical;

  /// No description provided for @settingsNotMedicalSub.
  ///
  /// In en, this message translates to:
  /// **'This app records time only. Milestones are general estimates and can’t tell what is happening in your body. Speak with a qualified healthcare professional before changing how you eat.'**
  String get settingsNotMedicalSub;

  /// No description provided for @deleteAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get deleteAllTitle;

  /// No description provided for @deleteAllBody.
  ///
  /// In en, this message translates to:
  /// **'This removes every session, your settings and any reminders from this phone. It can’t be undone.'**
  String get deleteAllBody;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAll;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to RUVA, your calm place for fasting, food and wellness'**
  String get onboardingTitle;

  /// No description provided for @onboardingNotMedical.
  ///
  /// In en, this message translates to:
  /// **'This app records time. It is a tracking and educational tool, not a medical device, and it cannot tell what is happening in your body.'**
  String get onboardingNotMedical;

  /// No description provided for @onboardingEstimates.
  ///
  /// In en, this message translates to:
  /// **'Milestones on the timer are general estimates that vary between people. They are never goals.'**
  String get onboardingEstimates;

  /// No description provided for @onboardingPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Your sessions stay on this phone. Nothing is uploaded, and you can delete everything at any time.'**
  String get onboardingPrivacy;

  /// No description provided for @onboardingSafety.
  ///
  /// In en, this message translates to:
  /// **'Speak with a qualified healthcare professional before changing how you eat — especially if you have a medical condition, take medication, are pregnant, or have a history of disordered eating.'**
  String get onboardingSafety;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @ageTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you 18 or older?'**
  String get ageTitle;

  /// No description provided for @ageBody.
  ///
  /// In en, this message translates to:
  /// **'Fasting tools in this app are designed for adults only. If you’re under 18, we’ll show general information instead.'**
  String get ageBody;

  /// No description provided for @ageAdult.
  ///
  /// In en, this message translates to:
  /// **'I’m 18 or older'**
  String get ageAdult;

  /// No description provided for @ageUnder18.
  ///
  /// In en, this message translates to:
  /// **'I’m under 18'**
  String get ageUnder18;

  /// No description provided for @underageTitle.
  ///
  /// In en, this message translates to:
  /// **'This app is designed for adults'**
  String get underageTitle;

  /// No description provided for @underageMeals.
  ///
  /// In en, this message translates to:
  /// **'Growing bodies need regular, balanced meals. Fasting isn’t recommended for people under 18 unless a doctor advises it.'**
  String get underageMeals;

  /// No description provided for @underageTalk.
  ///
  /// In en, this message translates to:
  /// **'If you have questions about eating, food or your body, talk with a parent or guardian and a qualified healthcare professional such as your doctor or a dietitian.'**
  String get underageTalk;

  /// No description provided for @underageSupport.
  ///
  /// In en, this message translates to:
  /// **'If you’re worried about how you feel about food, you deserve support — a trusted adult or your doctor can help you find it.'**
  String get underageSupport;

  /// No description provided for @underageReset.
  ///
  /// In en, this message translates to:
  /// **'I answered by mistake — start again'**
  String get underageReset;

  /// No description provided for @notifTargetTitle.
  ///
  /// In en, this message translates to:
  /// **'Target time reached'**
  String get notifTargetTitle;

  /// No description provided for @notifTargetBody.
  ///
  /// In en, this message translates to:
  /// **'Your planned time has passed. End your session whenever you’re ready.'**
  String get notifTargetBody;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'RUVA, loading'**
  String get splashLoading;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @heroEyebrow.
  ///
  /// In en, this message translates to:
  /// **'FASTING'**
  String get heroEyebrow;

  /// No description provided for @heroReady.
  ///
  /// In en, this message translates to:
  /// **'Ready when you are'**
  String get heroReady;

  /// No description provided for @heroFastingFor.
  ///
  /// In en, this message translates to:
  /// **'Fasting for {duration}'**
  String heroFastingFor(String duration);

  /// No description provided for @heroEndsAt.
  ///
  /// In en, this message translates to:
  /// **'{target} target · ends {time}'**
  String heroEndsAt(String target, String time);

  /// No description provided for @heroIfStartedNow.
  ///
  /// In en, this message translates to:
  /// **'{target} target · ends {time} if you start now'**
  String heroIfStartedNow(String target, String time);

  /// No description provided for @openTimer.
  ///
  /// In en, this message translates to:
  /// **'Open timer'**
  String get openTimer;

  /// No description provided for @milestoneEstimateNote.
  ///
  /// In en, this message translates to:
  /// **'Milestones on the timer are estimates and vary between people.'**
  String get milestoneEstimateNote;

  /// No description provided for @nutritionEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition is on its way'**
  String get nutritionEmptyTitle;

  /// No description provided for @nutritionEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Your food diary, My Kitchen and recipe ideas will live here.'**
  String get nutritionEmptyBody;

  /// No description provided for @notifWaterBody.
  ///
  /// In en, this message translates to:
  /// **'A gentle reminder to have some water, if you\'d like.'**
  String get notifWaterBody;

  /// No description provided for @waterTitle.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get waterTitle;

  /// No description provided for @waterToday.
  ///
  /// In en, this message translates to:
  /// **'WATER TODAY'**
  String get waterToday;

  /// No description provided for @waterAdd.
  ///
  /// In en, this message translates to:
  /// **'Add {amount}'**
  String waterAdd(String amount);

  /// No description provided for @waterAddCustom.
  ///
  /// In en, this message translates to:
  /// **'Add amount'**
  String get waterAddCustom;

  /// No description provided for @waterEntries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No entries} =1{1 entry} other{{count} entries}}'**
  String waterEntries(int count);

  /// No description provided for @waterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No water recorded for this day.'**
  String get waterEmpty;

  /// No description provided for @waterDayTotal.
  ///
  /// In en, this message translates to:
  /// **'Total for the day'**
  String get waterDayTotal;

  /// No description provided for @waterAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'AMOUNT ({unit})'**
  String waterAmountLabel(String unit);

  /// No description provided for @waterTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get waterTimeLabel;

  /// No description provided for @waterInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount between 1 and {max}.'**
  String waterInvalidAmount(String max);

  /// No description provided for @waterEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Water entry'**
  String get waterEditTitle;

  /// No description provided for @waterAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add water'**
  String get waterAddTitle;

  /// No description provided for @waterEntrySemantics.
  ///
  /// In en, this message translates to:
  /// **'{amount} at {time}. Edit'**
  String waterEntrySemantics(String amount, String time);

  /// No description provided for @previousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get previousDay;

  /// No description provided for @nextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get nextDay;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @settingsUnits.
  ///
  /// In en, this message translates to:
  /// **'UNITS'**
  String get settingsUnits;

  /// No description provided for @settingsWaterUnit.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get settingsWaterUnit;

  /// No description provided for @unitMl.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get unitMl;

  /// No description provided for @unitFlOz.
  ///
  /// In en, this message translates to:
  /// **'fl oz'**
  String get unitFlOz;

  /// No description provided for @settingsWaterReminders.
  ///
  /// In en, this message translates to:
  /// **'Water reminders'**
  String get settingsWaterReminders;

  /// No description provided for @settingsWaterRemindersSub.
  ///
  /// In en, this message translates to:
  /// **'Every 2 hours, 8 AM to 8 PM'**
  String get settingsWaterRemindersSub;

  /// No description provided for @notifDailyBody.
  ///
  /// In en, this message translates to:
  /// **'Your daily reminder. Open the app to start or review a session.'**
  String get notifDailyBody;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
