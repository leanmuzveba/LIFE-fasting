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
  /// **'Privacy & data'**
  String get settingsPrivacy;

  /// No description provided for @settingsDataStays.
  ///
  /// In en, this message translates to:
  /// **'Your data stays on this phone'**
  String get settingsDataStays;

  /// No description provided for @settingsDataStaysSub.
  ///
  /// In en, this message translates to:
  /// **'Nothing is uploaded or shared. There are no accounts or ads. Recipe search sends only ingredient names and search words to TheMealDB; barcode scans send only the barcode number to Open Food Facts; meal photos are sent to Google Gemini.'**
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
  /// **'Units'**
  String get settingsUnits;

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

  /// No description provided for @awTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity & Water'**
  String get awTitle;

  /// No description provided for @awWaterTab.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get awWaterTab;

  /// No description provided for @awActivityTab.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get awActivityTab;

  /// No description provided for @waterOfGoal.
  ///
  /// In en, this message translates to:
  /// **'of {goal} goal'**
  String waterOfGoal(String goal);

  /// No description provided for @waterCustomAmount.
  ///
  /// In en, this message translates to:
  /// **'Custom amount'**
  String get waterCustomAmount;

  /// No description provided for @waterTodaysEntries.
  ///
  /// In en, this message translates to:
  /// **'Today\'s entries'**
  String get waterTodaysEntries;

  /// No description provided for @waterNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No water logged yet today.'**
  String get waterNoneYet;

  /// No description provided for @waterGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached — lovely work.'**
  String get waterGoalReached;

  /// No description provided for @waterKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Nice pace — every glass counts.'**
  String get waterKeepGoing;

  /// No description provided for @waterEditGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily water goal'**
  String get waterEditGoal;

  /// No description provided for @waterGoalHint.
  ///
  /// In en, this message translates to:
  /// **'A personal goal you choose. Needs vary from person to person.'**
  String get waterGoalHint;

  /// No description provided for @entryOptions.
  ///
  /// In en, this message translates to:
  /// **'Options for {entry}'**
  String entryOptions(String entry);

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @activityRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get activityRecent;

  /// No description provided for @activityNone.
  ///
  /// In en, this message translates to:
  /// **'No activities logged yet.'**
  String get activityNone;

  /// No description provided for @activityLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Log an activity'**
  String get activityLogTitle;

  /// No description provided for @activityEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit activity'**
  String get activityEditTitle;

  /// No description provided for @activityType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get activityType;

  /// No description provided for @activityWalk.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get activityWalk;

  /// No description provided for @activityRun.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get activityRun;

  /// No description provided for @activityCycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get activityCycle;

  /// No description provided for @activityStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get activityStrength;

  /// No description provided for @activityYoga.
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get activityYoga;

  /// No description provided for @activityOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get activityOther;

  /// No description provided for @activityDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get activityDuration;

  /// No description provided for @activityMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String activityMinutes(int minutes);

  /// No description provided for @activityIntensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity (optional)'**
  String get activityIntensity;

  /// No description provided for @intensityLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get intensityLight;

  /// No description provided for @intensityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get intensityModerate;

  /// No description provided for @intensityHeavy.
  ///
  /// In en, this message translates to:
  /// **'Heavy'**
  String get intensityHeavy;

  /// No description provided for @activityNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get activityNotes;

  /// No description provided for @activityWhen.
  ///
  /// In en, this message translates to:
  /// **'Date & time'**
  String get activityWhen;

  /// No description provided for @activityLogButton.
  ///
  /// In en, this message translates to:
  /// **'Log activity'**
  String get activityLogButton;

  /// No description provided for @activityLogged.
  ///
  /// In en, this message translates to:
  /// **'{type} logged — {minutes} min'**
  String activityLogged(String type, int minutes);

  /// No description provided for @activityFutureError.
  ///
  /// In en, this message translates to:
  /// **'The start time can\'t be in the future.'**
  String get activityFutureError;

  /// No description provided for @decreaseMinute.
  ///
  /// In en, this message translates to:
  /// **'1 minute less'**
  String get decreaseMinute;

  /// No description provided for @increaseMinute.
  ///
  /// In en, this message translates to:
  /// **'1 minute more'**
  String get increaseMinute;

  /// No description provided for @activityToday.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY TODAY'**
  String get activityToday;

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// No description provided for @settingsRemindersOptional.
  ///
  /// In en, this message translates to:
  /// **'Reminders (all optional)'**
  String get settingsRemindersOptional;

  /// No description provided for @settingsAboutSafety.
  ///
  /// In en, this message translates to:
  /// **'About & safety'**
  String get settingsAboutSafety;

  /// No description provided for @settingsDiet.
  ///
  /// In en, this message translates to:
  /// **'Dietary preferences'**
  String get settingsDiet;

  /// No description provided for @settingsAllergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get settingsAllergies;

  /// No description provided for @settingsHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How RUVA works + safety notes'**
  String get settingsHowItWorks;

  /// No description provided for @settingsHowItWorksBody.
  ///
  /// In en, this message translates to:
  /// **'RUVA helps you record fasting times, water, activity, meals and your kitchen, all on this phone. Fasting milestones and nutrition values are estimates, not measurements. RUVA does not diagnose anything. Speak with a qualified healthcare professional before changing how you eat.'**
  String get settingsHowItWorksBody;

  /// No description provided for @settingsFooter.
  ///
  /// In en, this message translates to:
  /// **'Made with care. Not medical advice.'**
  String get settingsFooter;

  /// No description provided for @settingsCurrentState.
  ///
  /// In en, this message translates to:
  /// **'Current state: {state}'**
  String settingsCurrentState(String state);

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @unitsMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get unitsMetric;

  /// No description provided for @unitsImperial.
  ///
  /// In en, this message translates to:
  /// **'Imperial'**
  String get unitsImperial;

  /// No description provided for @dietNone.
  ///
  /// In en, this message translates to:
  /// **'No preference'**
  String get dietNone;

  /// No description provided for @dietVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get dietVegetarian;

  /// No description provided for @dietVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get dietVegan;

  /// No description provided for @dietPescatarian.
  ///
  /// In en, this message translates to:
  /// **'Pescatarian'**
  String get dietPescatarian;

  /// No description provided for @dietHalal.
  ///
  /// In en, this message translates to:
  /// **'Halal'**
  String get dietHalal;

  /// No description provided for @allergiesNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get allergiesNone;

  /// No description provided for @allergiesHint.
  ///
  /// In en, this message translates to:
  /// **'Recipes with these ingredients will never be suggested. Always check labels — a database can\'t guarantee a food is allergen-free.'**
  String get allergiesHint;

  /// No description provided for @allergenEggs.
  ///
  /// In en, this message translates to:
  /// **'Eggs'**
  String get allergenEggs;

  /// No description provided for @allergenDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy'**
  String get allergenDairy;

  /// No description provided for @allergenPeanuts.
  ///
  /// In en, this message translates to:
  /// **'Peanuts'**
  String get allergenPeanuts;

  /// No description provided for @allergenTreeNuts.
  ///
  /// In en, this message translates to:
  /// **'Tree nuts'**
  String get allergenTreeNuts;

  /// No description provided for @allergenGluten.
  ///
  /// In en, this message translates to:
  /// **'Gluten'**
  String get allergenGluten;

  /// No description provided for @allergenSoy.
  ///
  /// In en, this message translates to:
  /// **'Soy'**
  String get allergenSoy;

  /// No description provided for @allergenFish.
  ///
  /// In en, this message translates to:
  /// **'Fish'**
  String get allergenFish;

  /// No description provided for @allergenShellfish.
  ///
  /// In en, this message translates to:
  /// **'Shellfish'**
  String get allergenShellfish;

  /// No description provided for @allergenSesame.
  ///
  /// In en, this message translates to:
  /// **'Sesame'**
  String get allergenSesame;

  /// No description provided for @profileAddName.
  ///
  /// In en, this message translates to:
  /// **'Add your name'**
  String get profileAddName;

  /// No description provided for @profileEditHint.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditHint;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get profileTitle;

  /// No description provided for @profileOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional. Your name is only used to greet you and stays on this phone.'**
  String get profileOptional;

  /// No description provided for @profileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileNameLabel;

  /// No description provided for @profileMemberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String profileMemberSince(String date);

  /// No description provided for @historyAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get historyAll;

  /// No description provided for @historyFasting.
  ///
  /// In en, this message translates to:
  /// **'Fasting'**
  String get historyFasting;

  /// No description provided for @historyRecentDays.
  ///
  /// In en, this message translates to:
  /// **'Recent days'**
  String get historyRecentDays;

  /// No description provided for @historyNothingRecent.
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded in the last two weeks. That\'s completely fine.'**
  String get historyNothingRecent;

  /// No description provided for @historyNothingLogged.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged'**
  String get historyNothingLogged;

  /// No description provided for @historyDaySummary.
  ///
  /// In en, this message translates to:
  /// **'Day summary'**
  String get historyDaySummary;

  /// No description provided for @historySkipFine.
  ///
  /// In en, this message translates to:
  /// **'Skipping a day is completely fine.'**
  String get historySkipFine;

  /// No description provided for @historyQuote.
  ///
  /// In en, this message translates to:
  /// **'“Trends are guides, not grades. Skip a day anytime.”'**
  String get historyQuote;

  /// No description provided for @historyFastInProgress.
  ///
  /// In en, this message translates to:
  /// **'Fast in progress'**
  String get historyFastInProgress;

  /// No description provided for @historyFastDone.
  ///
  /// In en, this message translates to:
  /// **'{duration} fast · {status}'**
  String historyFastDone(String duration, String status);

  /// No description provided for @historyWater.
  ///
  /// In en, this message translates to:
  /// **'{amount} water'**
  String historyWater(String amount);

  /// No description provided for @historyActivity.
  ///
  /// In en, this message translates to:
  /// **'{duration} activity'**
  String historyActivity(String duration);

  /// No description provided for @historyWaterEntries.
  ///
  /// In en, this message translates to:
  /// **'{amount} of water · {count, plural, =1{1 entry} other{{count} entries}}'**
  String historyWaterEntries(String amount, int count);

  /// No description provided for @weekdayInitialsSundayFirst.
  ///
  /// In en, this message translates to:
  /// **'S,M,T,W,T,F,S'**
  String get weekdayInitialsSundayFirst;

  /// No description provided for @trendEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Fasting · last 14 days'**
  String get trendEyebrow;

  /// No description provided for @trendAverageFast.
  ///
  /// In en, this message translates to:
  /// **'average fast'**
  String get trendAverageFast;

  /// No description provided for @trendLongest.
  ///
  /// In en, this message translates to:
  /// **'Longest'**
  String get trendLongest;

  /// No description provided for @trendTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get trendTotal;

  /// No description provided for @trendFastCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 fast} other{{count} fasts}}'**
  String trendFastCount(int count);

  /// No description provided for @trendEmpty.
  ///
  /// In en, this message translates to:
  /// **'No completed fasts in the last 14 days.'**
  String get trendEmpty;

  /// No description provided for @trendSemantics.
  ///
  /// In en, this message translates to:
  /// **'Fasting, last 14 days ({range}): average fast {average}, longest {longest}, {count, plural, =1{1 fast} other{{count} fasts}}.'**
  String trendSemantics(String average, String longest, int count, String range);

  /// No description provided for @kitchenTitle.
  ///
  /// In en, this message translates to:
  /// **'My Kitchen'**
  String get kitchenTitle;

  /// No description provided for @kitchenEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get kitchenEyebrow;

  /// No description provided for @kitchenSearch.
  ///
  /// In en, this message translates to:
  /// **'Search your kitchen…'**
  String get kitchenSearch;

  /// No description provided for @kitchenAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get kitchenAll;

  /// No description provided for @catProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get catProtein;

  /// No description provided for @catCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get catCarbs;

  /// No description provided for @catVegetables.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get catVegetables;

  /// No description provided for @catFruits.
  ///
  /// In en, this message translates to:
  /// **'Fruits'**
  String get catFruits;

  /// No description provided for @catFatsNutsSeeds.
  ///
  /// In en, this message translates to:
  /// **'Fats, nuts & seeds'**
  String get catFatsNutsSeeds;

  /// No description provided for @catDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy & alternatives'**
  String get catDairy;

  /// No description provided for @catHerbsSpices.
  ///
  /// In en, this message translates to:
  /// **'Herbs & spices'**
  String get catHerbsSpices;

  /// No description provided for @catPantry.
  ///
  /// In en, this message translates to:
  /// **'Pantry essentials'**
  String get catPantry;

  /// No description provided for @stateFresh.
  ///
  /// In en, this message translates to:
  /// **'Fresh'**
  String get stateFresh;

  /// No description provided for @stateFrozen.
  ///
  /// In en, this message translates to:
  /// **'Frozen'**
  String get stateFrozen;

  /// No description provided for @stateCanned.
  ///
  /// In en, this message translates to:
  /// **'Canned'**
  String get stateCanned;

  /// No description provided for @stateDried.
  ///
  /// In en, this message translates to:
  /// **'Dried'**
  String get stateDried;

  /// No description provided for @kitchenOverview.
  ///
  /// In en, this message translates to:
  /// **'Kitchen overview'**
  String get kitchenOverview;

  /// No description provided for @kitchenItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String kitchenItems(int count);

  /// No description provided for @kitchenWellStocked.
  ///
  /// In en, this message translates to:
  /// **'Your pantry is well stocked.'**
  String get kitchenWellStocked;

  /// No description provided for @kitchenShoppingTrip.
  ///
  /// In en, this message translates to:
  /// **'Time for a shopping trip.'**
  String get kitchenShoppingTrip;

  /// No description provided for @kitchenEmptyOverview.
  ///
  /// In en, this message translates to:
  /// **'Add what you have at home to get started.'**
  String get kitchenEmptyOverview;

  /// No description provided for @kitchenExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get kitchenExpiringSoon;

  /// No description provided for @kitchenLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get kitchenLowStock;

  /// No description provided for @kitchenInYourKitchen.
  ///
  /// In en, this message translates to:
  /// **'In your kitchen · {count, plural, =1{1 item} other{{count} items}}'**
  String kitchenInYourKitchen(int count);

  /// No description provided for @kitchenNothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get kitchenNothingHere;

  /// No description provided for @kitchenNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No ingredients match your search.'**
  String get kitchenNoMatches;

  /// No description provided for @kitchenAddIngredient.
  ///
  /// In en, this message translates to:
  /// **'Add Ingredient'**
  String get kitchenAddIngredient;

  /// No description provided for @kitchenExpiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get kitchenExpiresToday;

  /// No description provided for @kitchenExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Expires in 1 day} other{Expires in {days} days}}'**
  String kitchenExpiresIn(int days);

  /// No description provided for @kitchenExpired.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Expired 1 day ago} other{Expired {days} days ago}}'**
  String kitchenExpired(int days);

  /// No description provided for @ingredientAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Ingredient'**
  String get ingredientAddTitle;

  /// No description provided for @ingredientEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Ingredient'**
  String get ingredientEditTitle;

  /// No description provided for @ingredientStatusEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get ingredientStatusEyebrow;

  /// No description provided for @ingredientNewEntry.
  ///
  /// In en, this message translates to:
  /// **'New Stock Entry'**
  String get ingredientNewEntry;

  /// No description provided for @ingredientNewEntrySub.
  ///
  /// In en, this message translates to:
  /// **'Adding to your main inventory'**
  String get ingredientNewEntrySub;

  /// No description provided for @ingredientUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update Stock'**
  String get ingredientUpdate;

  /// No description provided for @ingredientUpdateSub.
  ///
  /// In en, this message translates to:
  /// **'Editing an item in your inventory'**
  String get ingredientUpdateSub;

  /// No description provided for @ingredientName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get ingredientName;

  /// No description provided for @ingredientNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Baby spinach'**
  String get ingredientNameHint;

  /// No description provided for @ingredientCategory.
  ///
  /// In en, this message translates to:
  /// **'Category (one or more)'**
  String get ingredientCategory;

  /// No description provided for @ingredientQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity & unit'**
  String get ingredientQuantity;

  /// No description provided for @ingredientState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get ingredientState;

  /// No description provided for @ingredientDates.
  ///
  /// In en, this message translates to:
  /// **'Dates (optional)'**
  String get ingredientDates;

  /// No description provided for @ingredientPurchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get ingredientPurchased;

  /// No description provided for @ingredientExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get ingredientExpires;

  /// No description provided for @ingredientNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get ingredientNotSet;

  /// No description provided for @ingredientClearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear {label} date'**
  String ingredientClearDate(String label);

  /// No description provided for @ingredientLowStockAt.
  ///
  /// In en, this message translates to:
  /// **'Low-stock alert at (optional)'**
  String get ingredientLowStockAt;

  /// No description provided for @ingredientLowStockHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2'**
  String get ingredientLowStockHint;

  /// No description provided for @ingredientBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand (optional)'**
  String get ingredientBrand;

  /// No description provided for @ingredientBrandHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Woolworths'**
  String get ingredientBrandHint;

  /// No description provided for @ingredientNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get ingredientNotes;

  /// No description provided for @ingredientNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Anything to remember'**
  String get ingredientNotesHint;

  /// No description provided for @ingredientSave.
  ///
  /// In en, this message translates to:
  /// **'Save ingredient'**
  String get ingredientSave;

  /// No description provided for @ingredientSaved.
  ///
  /// In en, this message translates to:
  /// **'{name} saved to My Kitchen'**
  String ingredientSaved(String name);

  /// No description provided for @ingredientMarkFinished.
  ///
  /// In en, this message translates to:
  /// **'Mark as finished'**
  String get ingredientMarkFinished;

  /// No description provided for @ingredientFinished.
  ///
  /// In en, this message translates to:
  /// **'{name} marked as finished'**
  String ingredientFinished(String name);

  /// No description provided for @ingredientRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from kitchen'**
  String get ingredientRemove;

  /// No description provided for @ingredientRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String ingredientRemoveConfirm(String name);

  /// No description provided for @ingredientRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes the item and its history. To keep a record, mark it as finished instead.'**
  String get ingredientRemoveBody;

  /// No description provided for @ingredientRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed'**
  String ingredientRemoved(String name);

  /// No description provided for @errNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name.'**
  String get errNameRequired;

  /// No description provided for @errQuantityInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity of 0 or more.'**
  String get errQuantityInvalid;

  /// No description provided for @errLowStockInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a low-stock amount of 0 or more, or leave it empty.'**
  String get errLowStockInvalid;

  /// No description provided for @errExpiryBeforePurchase.
  ///
  /// In en, this message translates to:
  /// **'The expiry date can\'t be before the purchase date.'**
  String get errExpiryBeforePurchase;

  /// No description provided for @kitchenItemSemantics.
  ///
  /// In en, this message translates to:
  /// **'{name}, {quantity}, {state}'**
  String kitchenItemSemantics(String name, String quantity, String state);

  /// No description provided for @notifReviewBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s a new month — a quick kitchen review keeps your inventory and recipe ideas accurate. Optional, as always.'**
  String get notifReviewBody;

  /// No description provided for @reviewEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Monthly kitchen review'**
  String get reviewEyebrow;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review your kitchen'**
  String get reviewTitle;

  /// No description provided for @reviewProgress.
  ///
  /// In en, this message translates to:
  /// **'Item {current} of {total} · {name}'**
  String reviewProgress(int current, int total, String name);

  /// No description provided for @reviewCardText.
  ///
  /// In en, this message translates to:
  /// **'A few minutes now saves food and money all month.'**
  String get reviewCardText;

  /// No description provided for @reviewQuestion.
  ///
  /// In en, this message translates to:
  /// **'Is this still in your kitchen?'**
  String get reviewQuestion;

  /// No description provided for @reviewKeep.
  ///
  /// In en, this message translates to:
  /// **'Still have it — update quantity'**
  String get reviewKeep;

  /// No description provided for @reviewUsedUp.
  ///
  /// In en, this message translates to:
  /// **'We ate it / used it up'**
  String get reviewUsedUp;

  /// No description provided for @reviewSpoiled.
  ///
  /// In en, this message translates to:
  /// **'Spoiled — remove it'**
  String get reviewSpoiled;

  /// No description provided for @reviewNoWrongAnswers.
  ///
  /// In en, this message translates to:
  /// **'No wrong answers — this just keeps your inventory honest. Spoiled food happens to everyone.'**
  String get reviewNoWrongAnswers;

  /// No description provided for @reviewAddToList.
  ///
  /// In en, this message translates to:
  /// **'Add to shopping list'**
  String get reviewAddToList;

  /// No description provided for @reviewAddPurchases.
  ///
  /// In en, this message translates to:
  /// **'Add new purchases this month'**
  String get reviewAddPurchases;

  /// No description provided for @reviewAddPurchase.
  ///
  /// In en, this message translates to:
  /// **'Add a purchase'**
  String get reviewAddPurchase;

  /// No description provided for @reviewAdded.
  ///
  /// In en, this message translates to:
  /// **'Added: {names}'**
  String reviewAdded(String names);

  /// No description provided for @reviewContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue review'**
  String get reviewContinue;

  /// No description provided for @reviewFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish review'**
  String get reviewFinish;

  /// No description provided for @reviewPreviewList.
  ///
  /// In en, this message translates to:
  /// **'Preview shopping list ({count})'**
  String reviewPreviewList(int count);

  /// No description provided for @reviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your kitchen is empty — add what you have and review it next month.'**
  String get reviewEmpty;

  /// No description provided for @reviewDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Review complete'**
  String get reviewDoneTitle;

  /// No description provided for @reviewDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Your inventory is up to date. Thanks for keeping it honest.'**
  String get reviewDoneBody;

  /// No description provided for @reviewUpdateQuantity.
  ///
  /// In en, this message translates to:
  /// **'Update {name}'**
  String reviewUpdateQuantity(String name);

  /// No description provided for @reviewPurchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased {date}'**
  String reviewPurchased(String date);

  /// No description provided for @kitchenStartReview.
  ///
  /// In en, this message translates to:
  /// **'Start monthly review'**
  String get kitchenStartReview;

  /// No description provided for @shoppingTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping list'**
  String get shoppingTitle;

  /// No description provided for @shoppingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing to buy} =1{1 item to buy} other{{count} items to buy}}'**
  String shoppingCount(int count);

  /// No description provided for @shoppingAddHint.
  ///
  /// In en, this message translates to:
  /// **'Add an item…'**
  String get shoppingAddHint;

  /// No description provided for @shoppingAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get shoppingAdd;

  /// No description provided for @shoppingClearChecked.
  ///
  /// In en, this message translates to:
  /// **'Clear ticked items'**
  String get shoppingClearChecked;

  /// No description provided for @shoppingRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String shoppingRemove(String name);

  /// No description provided for @shoppingEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your shopping list is empty.'**
  String get shoppingEmpty;

  /// No description provided for @settingsMonthlyReview.
  ///
  /// In en, this message translates to:
  /// **'Monthly kitchen review'**
  String get settingsMonthlyReview;

  /// No description provided for @settingsMonthlyReviewSub.
  ///
  /// In en, this message translates to:
  /// **'1st of each month at 10:00'**
  String get settingsMonthlyReviewSub;

  /// No description provided for @settingsReviewNow.
  ///
  /// In en, this message translates to:
  /// **'Review my kitchen now'**
  String get settingsReviewNow;

  /// No description provided for @mealBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealBreakfast;

  /// No description provided for @mealLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealLunch;

  /// No description provided for @mealDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealDinner;

  /// No description provided for @mealSnacks.
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get mealSnacks;

  /// No description provided for @nutrientEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get nutrientEnergy;

  /// No description provided for @nutrientProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get nutrientProtein;

  /// No description provided for @nutrientCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get nutrientCarbs;

  /// No description provided for @nutrientFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get nutrientFat;

  /// No description provided for @nutrientFibre.
  ///
  /// In en, this message translates to:
  /// **'Fibre'**
  String get nutrientFibre;

  /// No description provided for @nutrientCalcium.
  ///
  /// In en, this message translates to:
  /// **'Calcium'**
  String get nutrientCalcium;

  /// No description provided for @nutrientIron.
  ///
  /// In en, this message translates to:
  /// **'Iron'**
  String get nutrientIron;

  /// No description provided for @nutrientPotassium.
  ///
  /// In en, this message translates to:
  /// **'Potassium'**
  String get nutrientPotassium;

  /// No description provided for @nutrientSodium.
  ///
  /// In en, this message translates to:
  /// **'Sodium'**
  String get nutrientSodium;

  /// No description provided for @nutrientVitaminC.
  ///
  /// In en, this message translates to:
  /// **'Vitamin C'**
  String get nutrientVitaminC;

  /// No description provided for @nutrientEstimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get nutrientEstimated;

  /// No description provided for @nutrientPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get nutrientPartial;

  /// No description provided for @nutrientUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get nutrientUnavailable;

  /// No description provided for @diaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Food Diary'**
  String get diaryTitle;

  /// No description provided for @diaryPrevDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get diaryPrevDay;

  /// No description provided for @diaryNextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get diaryNextDay;

  /// No description provided for @diarySummaryToday.
  ///
  /// In en, this message translates to:
  /// **'Today’s summary'**
  String get diarySummaryToday;

  /// No description provided for @diarySummaryDay.
  ///
  /// In en, this message translates to:
  /// **'Day summary'**
  String get diarySummaryDay;

  /// No description provided for @diaryInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'About these numbers'**
  String get diaryInfoTitle;

  /// No description provided for @diaryInfoBody.
  ///
  /// In en, this message translates to:
  /// **'Nutrition values are estimates from USDA FoodData Central and the foods you create. “Partial” means some foods you logged have no data for that nutrient; “Unavailable” means none do. RUVA doesn’t set targets or judge what you eat.'**
  String get diaryInfoBody;

  /// No description provided for @diaryMicros.
  ///
  /// In en, this message translates to:
  /// **'Vitamins & minerals'**
  String get diaryMicros;

  /// No description provided for @diaryMealEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet — that’s perfectly fine.'**
  String get diaryMealEmpty;

  /// No description provided for @diaryKcal.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal'**
  String diaryKcal(String kcal);

  /// No description provided for @diaryEst.
  ///
  /// In en, this message translates to:
  /// **'(est.)'**
  String get diaryEst;

  /// No description provided for @diaryEntryLabel.
  ///
  /// In en, this message translates to:
  /// **'{name}, {time}, {amount}'**
  String diaryEntryLabel(String name, String time, String amount);

  /// No description provided for @diaryChangeAmount.
  ///
  /// In en, this message translates to:
  /// **'Change amount'**
  String get diaryChangeAmount;

  /// No description provided for @diaryRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get diaryRemove;

  /// No description provided for @diaryRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed'**
  String diaryRemoved(String name);

  /// No description provided for @diaryAddFood.
  ///
  /// In en, this message translates to:
  /// **'Add food'**
  String get diaryAddFood;

  /// No description provided for @addFoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Food'**
  String get addFoodTitle;

  /// No description provided for @addFoodTo.
  ///
  /// In en, this message translates to:
  /// **'to {meal} · {date}'**
  String addFoodTo(String meal, String date);

  /// No description provided for @addFoodDatabase.
  ///
  /// In en, this message translates to:
  /// **'Food database'**
  String get addFoodDatabase;

  /// No description provided for @addFoodSearch.
  ///
  /// In en, this message translates to:
  /// **'Search foods…'**
  String get addFoodSearch;

  /// No description provided for @addFoodSource.
  ///
  /// In en, this message translates to:
  /// **'USDA FoodData Central & Open Food Facts · values are estimates'**
  String get addFoodSource;

  /// No description provided for @addFoodLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading foods…'**
  String get addFoodLoading;

  /// No description provided for @addFoodRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get addFoodRecent;

  /// No description provided for @addFoodSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get addFoodSaved;

  /// No description provided for @addFoodResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get addFoodResults;

  /// No description provided for @addFoodNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No foods match “{query}”. You can create your own.'**
  String addFoodNoMatch(String query);

  /// No description provided for @addFoodPer100.
  ///
  /// In en, this message translates to:
  /// **'100 g · {kcal} kcal · {protein} g protein (est.)'**
  String addFoodPer100(String kcal, String protein);

  /// No description provided for @addFoodNoData.
  ///
  /// In en, this message translates to:
  /// **'Nutrition unavailable'**
  String get addFoodNoData;

  /// No description provided for @addFoodYours.
  ///
  /// In en, this message translates to:
  /// **'Your food'**
  String get addFoodYours;

  /// No description provided for @addFoodSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected item'**
  String get addFoodSelected;

  /// No description provided for @addFoodClear.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get addFoodClear;

  /// No description provided for @addFoodLess.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get addFoodLess;

  /// No description provided for @addFoodMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get addFoodMore;

  /// No description provided for @addFoodAbout.
  ///
  /// In en, this message translates to:
  /// **'≈ {kcal} kcal (est.)'**
  String addFoodAbout(String kcal);

  /// No description provided for @addFoodMeal.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get addFoodMeal;

  /// No description provided for @addFoodTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get addFoodTime;

  /// No description provided for @addFoodAddTo.
  ///
  /// In en, this message translates to:
  /// **'Add to {meal}'**
  String addFoodAddTo(String meal);

  /// No description provided for @addFoodAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added to {meal}'**
  String addFoodAdded(String name, String meal);

  /// No description provided for @addFoodSave.
  ///
  /// In en, this message translates to:
  /// **'Save to favourites'**
  String get addFoodSave;

  /// No description provided for @addFoodUnsave.
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get addFoodUnsave;

  /// No description provided for @addFoodCreate.
  ///
  /// In en, this message translates to:
  /// **'Create custom food'**
  String get addFoodCreate;

  /// No description provided for @customTitle.
  ///
  /// In en, this message translates to:
  /// **'Your own food'**
  String get customTitle;

  /// No description provided for @customName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get customName;

  /// No description provided for @customServing.
  ///
  /// In en, this message translates to:
  /// **'Serving size'**
  String get customServing;

  /// No description provided for @customPerServing.
  ///
  /// In en, this message translates to:
  /// **'Nutrition per serving · optional'**
  String get customPerServing;

  /// No description provided for @customHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank anything you don’t know — it will show as unavailable, never as zero.'**
  String get customHint;

  /// No description provided for @customSave.
  ///
  /// In en, this message translates to:
  /// **'Save and select'**
  String get customSave;

  /// No description provided for @customNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get customNameRequired;

  /// No description provided for @customServingRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a serving size in grams.'**
  String get customServingRequired;

  /// No description provided for @customServingLabel.
  ///
  /// In en, this message translates to:
  /// **'1 serving'**
  String get customServingLabel;

  /// No description provided for @settingsFoodData.
  ///
  /// In en, this message translates to:
  /// **'Food data'**
  String get settingsFoodData;

  /// No description provided for @settingsFoodDataSub.
  ///
  /// In en, this message translates to:
  /// **'Foods: USDA FoodData Central, SR Legacy (public domain). Scanned packaged foods: Open Food Facts (Open Database Licence). Values are estimates.'**
  String get settingsFoodDataSub;

  /// No description provided for @diaryRecipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get diaryRecipes;

  /// No description provided for @diaryRecipesSub.
  ///
  /// In en, this message translates to:
  /// **'What you can make'**
  String get diaryRecipesSub;

  /// No description provided for @recipesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get recipesTitle;

  /// No description provided for @recipesEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Smart recipe planner'**
  String get recipesEyebrow;

  /// No description provided for @recipesHero.
  ///
  /// In en, this message translates to:
  /// **'What you can make'**
  String get recipesHero;

  /// No description provided for @recipesHeroSub.
  ///
  /// In en, this message translates to:
  /// **'{items} in your kitchen · {found}'**
  String recipesHeroSub(String items, String found);

  /// No description provided for @recipesFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no matches yet} =1{1 recipe found} other{{count} recipes found}}'**
  String recipesFound(int count);

  /// No description provided for @recipesTagline.
  ///
  /// In en, this message translates to:
  /// **'Built from what you already have — less waste, less stress.'**
  String get recipesTagline;

  /// No description provided for @recipesSearch.
  ///
  /// In en, this message translates to:
  /// **'Search recipes by name…'**
  String get recipesSearch;

  /// No description provided for @recipesShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get recipesShow;

  /// No description provided for @recipesShowAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get recipesShowAll;

  /// No description provided for @recipesShowReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to cook'**
  String get recipesShowReady;

  /// No description provided for @recipesShowExpiring.
  ///
  /// In en, this message translates to:
  /// **'Uses expiring items'**
  String get recipesShowExpiring;

  /// No description provided for @recipesShowSaved.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get recipesShowSaved;

  /// No description provided for @recipesDiet.
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get recipesDiet;

  /// No description provided for @recipesDietAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get recipesDietAny;

  /// No description provided for @recipesAllergyNote.
  ///
  /// In en, this message translates to:
  /// **'Hiding recipes with: {list}. Ingredient lists can’t guarantee a recipe is free from allergens or cross-contamination — always check labels.'**
  String recipesAllergyNote(String list);

  /// No description provided for @recipesAllergyGeneric.
  ///
  /// In en, this message translates to:
  /// **'Ingredient lists can’t guarantee a recipe is free from allergens or cross-contamination — always check labels.'**
  String get recipesAllergyGeneric;

  /// No description provided for @recipesPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Recipes come from TheMealDB online. Only ingredient names and search words are sent.'**
  String get recipesPrivacy;

  /// No description provided for @recipesEmptyKitchen.
  ///
  /// In en, this message translates to:
  /// **'Add ingredients to My Kitchen and RUVA will suggest what you can make. You can still search by name.'**
  String get recipesEmptyKitchen;

  /// No description provided for @recipesNone.
  ///
  /// In en, this message translates to:
  /// **'No recipes match these filters.'**
  String get recipesNone;

  /// No description provided for @recipesOffline.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t reach the recipe catalogue. Check your connection and try again.'**
  String get recipesOffline;

  /// No description provided for @recipesRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get recipesRetry;

  /// No description provided for @recipesAvailable.
  ///
  /// In en, this message translates to:
  /// **'{have} of {total} ingredients available'**
  String recipesAvailable(int have, int total);

  /// No description provided for @recipesMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing: {list}'**
  String recipesMissing(String list);

  /// No description provided for @recipesUsesExpiring.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Uses 1 item expiring soon} other{Uses {count} items expiring soon}}'**
  String recipesUsesExpiring(int count);

  /// No description provided for @recipesSave.
  ///
  /// In en, this message translates to:
  /// **'Save to favourites'**
  String get recipesSave;

  /// No description provided for @recipesUnsave.
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get recipesUnsave;

  /// No description provided for @recipesCookedOn.
  ///
  /// In en, this message translates to:
  /// **'Cooked {date}'**
  String recipesCookedOn(String date);

  /// No description provided for @recipeIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get recipeIngredients;

  /// No description provided for @recipeTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} total'**
  String recipeTotal(int count);

  /// No description provided for @recipeAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get recipeAvailable;

  /// No description provided for @recipeMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get recipeMissing;

  /// No description provided for @recipeSubstitute.
  ///
  /// In en, this message translates to:
  /// **'Substitute: {missing} → {have} (you have it)'**
  String recipeSubstitute(String missing, String have);

  /// No description provided for @recipeBatch.
  ///
  /// In en, this message translates to:
  /// **'Batch size'**
  String get recipeBatch;

  /// No description provided for @recipeBatchHint.
  ///
  /// In en, this message translates to:
  /// **'Amounts are scaled from the original recipe. The catalogue doesn’t list servings or cooking times.'**
  String get recipeBatchHint;

  /// No description provided for @recipeSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get recipeSteps;

  /// No description provided for @recipeNutrition.
  ///
  /// In en, this message translates to:
  /// **'Estimated nutrition'**
  String get recipeNutrition;

  /// No description provided for @recipeNutritionNone.
  ///
  /// In en, this message translates to:
  /// **'Nutrition isn’t available for this recipe, so diary entries show it as unavailable.'**
  String get recipeNutritionNone;

  /// No description provided for @recipeMarkCooked.
  ///
  /// In en, this message translates to:
  /// **'Mark as cooked'**
  String get recipeMarkCooked;

  /// No description provided for @recipeCooked.
  ///
  /// In en, this message translates to:
  /// **'Marked as cooked. Update quantities in My Kitchen if you used things up.'**
  String get recipeCooked;

  /// No description provided for @recipeLog.
  ///
  /// In en, this message translates to:
  /// **'Log to Food Diary'**
  String get recipeLog;

  /// No description provided for @recipeLogWhich.
  ///
  /// In en, this message translates to:
  /// **'Which meal?'**
  String get recipeLogWhich;

  /// No description provided for @recipeLogged.
  ///
  /// In en, this message translates to:
  /// **'Logged to {meal}'**
  String recipeLogged(String meal);

  /// No description provided for @recipeAlreadyLogged.
  ///
  /// In en, this message translates to:
  /// **'Already in today’s {meal}'**
  String recipeAlreadyLogged(String meal);

  /// No description provided for @recipeServing.
  ///
  /// In en, this message translates to:
  /// **'1 serving'**
  String get recipeServing;

  /// No description provided for @recipeAddMissing.
  ///
  /// In en, this message translates to:
  /// **'Add missing to shopping list'**
  String get recipeAddMissing;

  /// No description provided for @recipeAddedMissing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Already on your shopping list} =1{1 item added to your shopping list} other{{count} items added to your shopping list}}'**
  String recipeAddedMissing(int count);

  /// No description provided for @recipeSource.
  ///
  /// In en, this message translates to:
  /// **'Recipe from TheMealDB'**
  String get recipeSource;

  /// No description provided for @recipeNotFound.
  ///
  /// In en, this message translates to:
  /// **'This recipe couldn’t be loaded. Check your connection and try again.'**
  String get recipeNotFound;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan a barcode'**
  String get scanTitle;

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the barcode on the pack. Product data comes from Open Food Facts.'**
  String get scanHint;

  /// No description provided for @scanType.
  ///
  /// In en, this message translates to:
  /// **'Type the barcode instead'**
  String get scanType;

  /// No description provided for @scanNumber.
  ///
  /// In en, this message translates to:
  /// **'Barcode number'**
  String get scanNumber;

  /// No description provided for @scanLookUp.
  ///
  /// In en, this message translates to:
  /// **'Look up'**
  String get scanLookUp;

  /// No description provided for @scanInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the 8–14 digits under the barcode.'**
  String get scanInvalid;

  /// No description provided for @scanTorch.
  ///
  /// In en, this message translates to:
  /// **'Torch'**
  String get scanTorch;

  /// No description provided for @scanLooking.
  ///
  /// In en, this message translates to:
  /// **'Looking up the product…'**
  String get scanLooking;

  /// No description provided for @scanCameraError.
  ///
  /// In en, this message translates to:
  /// **'The camera isn’t available. You can type the barcode instead.'**
  String get scanCameraError;

  /// No description provided for @scanNotFound.
  ///
  /// In en, this message translates to:
  /// **'{code} isn’t in Open Food Facts yet — add it from the label.'**
  String scanNotFound(String code);

  /// No description provided for @scanOffline.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t look up the barcode. Check your connection and try again.'**
  String get scanOffline;

  /// No description provided for @scanAddFromLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode {code}. Copy the values from the nutrition label; next time the scan will find it.'**
  String scanAddFromLabel(String code);

  /// No description provided for @foodPack.
  ///
  /// In en, this message translates to:
  /// **'Whole pack'**
  String get foodPack;

  /// No description provided for @foodPackaged.
  ///
  /// In en, this message translates to:
  /// **'Packaged food'**
  String get foodPackaged;

  /// No description provided for @addFoodPer100ml.
  ///
  /// In en, this message translates to:
  /// **'100 ml · {kcal} kcal · {protein} g protein (est.)'**
  String addFoodPer100ml(String kcal, String protein);

  /// No description provided for @customGrams.
  ///
  /// In en, this message translates to:
  /// **'Grams'**
  String get customGrams;

  /// No description provided for @customMl.
  ///
  /// In en, this message translates to:
  /// **'Millilitres'**
  String get customMl;

  /// No description provided for @logHow.
  ///
  /// In en, this message translates to:
  /// **'How do you want to log it?'**
  String get logHow;

  /// No description provided for @logSearch.
  ///
  /// In en, this message translates to:
  /// **'Search foods'**
  String get logSearch;

  /// No description provided for @logSearchSub.
  ///
  /// In en, this message translates to:
  /// **'Food database, recent and favourites'**
  String get logSearchSub;

  /// No description provided for @logScanSub.
  ///
  /// In en, this message translates to:
  /// **'Packaged foods and drinks'**
  String get logScanSub;

  /// No description provided for @logPhotoSub.
  ///
  /// In en, this message translates to:
  /// **'AI estimate from a photo — you check it first'**
  String get logPhotoSub;

  /// No description provided for @photoTitle.
  ///
  /// In en, this message translates to:
  /// **'Snap a meal photo'**
  String get photoTitle;

  /// No description provided for @photoYourPhoto.
  ///
  /// In en, this message translates to:
  /// **'Your meal photo'**
  String get photoYourPhoto;

  /// No description provided for @photoEstimating.
  ///
  /// In en, this message translates to:
  /// **'Estimating what’s on the plate…'**
  String get photoEstimating;

  /// No description provided for @photoCheck.
  ///
  /// In en, this message translates to:
  /// **'AI estimate — check every item before adding. Rename anything it got wrong and adjust the amounts. Photo estimates are often 20–40% off, especially for oil, sauces and hidden ingredients.'**
  String get photoCheck;

  /// No description provided for @photoItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item found} other{{count} items found}}'**
  String photoItems(int count);

  /// No description provided for @photoRename.
  ///
  /// In en, this message translates to:
  /// **'Rename {name}'**
  String photoRename(String name);

  /// No description provided for @photoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String photoRemove(String name);

  /// No description provided for @photoAdd.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 item to {meal}} other{Add {count} items to {meal}}}'**
  String photoAdd(int count, String meal);

  /// No description provided for @photoLogged.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item added to {meal}} other{{count} items added to {meal}}}'**
  String photoLogged(int count, String meal);

  /// No description provided for @photoLabel.
  ///
  /// In en, this message translates to:
  /// **'photo estimate'**
  String get photoLabel;

  /// No description provided for @photoRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get photoRetake;

  /// No description provided for @photoGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get photoGallery;

  /// No description provided for @photoPrivacy.
  ///
  /// In en, this message translates to:
  /// **'The photo is sent to Google Gemini to estimate the meal. Nothing else about you is sent.'**
  String get photoPrivacy;

  /// No description provided for @photoNotFood.
  ///
  /// In en, this message translates to:
  /// **'No food was recognised in that photo. Try again with the whole plate in view.'**
  String get photoNotFood;

  /// No description provided for @photoNoKey.
  ///
  /// In en, this message translates to:
  /// **'Meal photos need a Gemini API key. Add one in Settings → Meal photo estimates.'**
  String get photoNoKey;

  /// No description provided for @photoKeyError.
  ///
  /// In en, this message translates to:
  /// **'Gemini didn’t accept the API key. Check it in Settings → Meal photo estimates.'**
  String get photoKeyError;

  /// No description provided for @photoOffline.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t reach Gemini. Check your connection and try again.'**
  String get photoOffline;

  /// No description provided for @photoCameraError.
  ///
  /// In en, this message translates to:
  /// **'The camera isn’t available. Try choosing a photo from the gallery.'**
  String get photoCameraError;

  /// No description provided for @settingsPhotoKey.
  ///
  /// In en, this message translates to:
  /// **'Meal photo estimates'**
  String get settingsPhotoKey;

  /// No description provided for @settingsPhotoKeyNone.
  ///
  /// In en, this message translates to:
  /// **'No key'**
  String get settingsPhotoKeyNone;

  /// No description provided for @settingsPhotoKeyOwn.
  ///
  /// In en, this message translates to:
  /// **'Your key'**
  String get settingsPhotoKeyOwn;

  /// No description provided for @settingsPhotoKeyBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'Built-in key'**
  String get settingsPhotoKeyBuiltIn;

  /// No description provided for @settingsPhotoKeyBody.
  ///
  /// In en, this message translates to:
  /// **'Meal photos are estimated by Google Gemini using an API key. Paste your own key to use it instead of the built-in one; it’s stored only on this phone.'**
  String get settingsPhotoKeyBody;

  /// No description provided for @settingsPhotoKeyField.
  ///
  /// In en, this message translates to:
  /// **'Gemini API key'**
  String get settingsPhotoKeyField;

  /// No description provided for @settingsPhotoKeyClear.
  ///
  /// In en, this message translates to:
  /// **'Remove my key'**
  String get settingsPhotoKeyClear;

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
