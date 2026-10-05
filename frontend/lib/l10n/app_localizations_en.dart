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
  String get settingsTarget => 'Target';

  @override
  String get settings24h => '24-hour clock';

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
  String get settingsPrivacy => 'Privacy & data';

  @override
  String get settingsDataStays => 'Your data stays on this phone';

  @override
  String get settingsDataStaysSub => 'Nothing is uploaded or shared. There are no accounts or ads.';

  @override
  String get settingsDeleteAll => 'Delete all data';

  @override
  String get settingsDeleteAllSub => 'Sessions, settings and reminders';

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
  String get notifWaterBody => 'A gentle reminder to have some water, if you\'d like.';

  @override
  String get waterTitle => 'Water';

  @override
  String get waterToday => 'WATER TODAY';

  @override
  String waterAdd(String amount) {
    return 'Add $amount';
  }

  @override
  String get waterAddCustom => 'Add amount';

  @override
  String waterEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
      zero: 'No entries',
    );
    return '$_temp0';
  }

  @override
  String get waterEmpty => 'No water recorded for this day.';

  @override
  String get waterDayTotal => 'Total for the day';

  @override
  String waterAmountLabel(String unit) {
    return 'AMOUNT ($unit)';
  }

  @override
  String get waterTimeLabel => 'TIME';

  @override
  String waterInvalidAmount(String max) {
    return 'Enter an amount between 1 and $max.';
  }

  @override
  String get waterEditTitle => 'Water entry';

  @override
  String get waterAddTitle => 'Add water';

  @override
  String waterEntrySemantics(String amount, String time) {
    return '$amount at $time. Edit';
  }

  @override
  String get previousDay => 'Previous day';

  @override
  String get nextDay => 'Next day';

  @override
  String get today => 'Today';

  @override
  String get settingsUnits => 'Units';

  @override
  String get unitMl => 'ml';

  @override
  String get unitFlOz => 'fl oz';

  @override
  String get settingsWaterReminders => 'Water reminders';

  @override
  String get settingsWaterRemindersSub => 'Every 2 hours, 8 AM to 8 PM';

  @override
  String get awTitle => 'Activity & Water';

  @override
  String get awWaterTab => 'Water';

  @override
  String get awActivityTab => 'Activity';

  @override
  String waterOfGoal(String goal) {
    return 'of $goal goal';
  }

  @override
  String get waterCustomAmount => 'Custom amount';

  @override
  String get waterTodaysEntries => 'Today\'s entries';

  @override
  String get waterNoneYet => 'No water logged yet today.';

  @override
  String get waterGoalReached => 'Goal reached — lovely work.';

  @override
  String get waterKeepGoing => 'Nice pace — every glass counts.';

  @override
  String get waterEditGoal => 'Daily water goal';

  @override
  String get waterGoalHint => 'A personal goal you choose. Needs vary from person to person.';

  @override
  String entryOptions(String entry) {
    return 'Options for $entry';
  }

  @override
  String get edit => 'Edit';

  @override
  String get activityRecent => 'Recent activity';

  @override
  String get activityNone => 'No activities logged yet.';

  @override
  String get activityLogTitle => 'Log an activity';

  @override
  String get activityEditTitle => 'Edit activity';

  @override
  String get activityType => 'Type';

  @override
  String get activityWalk => 'Walk';

  @override
  String get activityRun => 'Run';

  @override
  String get activityCycle => 'Cycle';

  @override
  String get activityStrength => 'Strength';

  @override
  String get activityYoga => 'Yoga';

  @override
  String get activityOther => 'Other';

  @override
  String get activityDuration => 'Duration';

  @override
  String activityMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get activityIntensity => 'Intensity (optional)';

  @override
  String get intensityLight => 'Light';

  @override
  String get intensityModerate => 'Moderate';

  @override
  String get intensityHeavy => 'Heavy';

  @override
  String get activityNotes => 'Notes (optional)';

  @override
  String get activityWhen => 'Date & time';

  @override
  String get activityLogButton => 'Log activity';

  @override
  String activityLogged(String type, int minutes) {
    return '$type logged — $minutes min';
  }

  @override
  String get activityFutureError => 'The start time can\'t be in the future.';

  @override
  String get decreaseMinute => '1 minute less';

  @override
  String get increaseMinute => '1 minute more';

  @override
  String get activityToday => 'ACTIVITY TODAY';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsRemindersOptional => 'Reminders (all optional)';

  @override
  String get settingsAboutSafety => 'About & safety';

  @override
  String get settingsDiet => 'Dietary preferences';

  @override
  String get settingsAllergies => 'Allergies';

  @override
  String get settingsHowItWorks => 'How RUVA works + safety notes';

  @override
  String get settingsHowItWorksBody =>
      'RUVA helps you record fasting times, water, activity and — soon — meals and your kitchen, all on this phone. Fasting milestones and nutrition values are estimates, not measurements. RUVA does not diagnose anything. Speak with a qualified healthcare professional before changing how you eat.';

  @override
  String get settingsFooter => 'Made with care. Not medical advice.';

  @override
  String settingsCurrentState(String state) {
    return 'Current state: $state';
  }

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get done => 'Done';

  @override
  String get unitsMetric => 'Metric';

  @override
  String get unitsImperial => 'Imperial';

  @override
  String get dietNone => 'No preference';

  @override
  String get dietVegetarian => 'Vegetarian';

  @override
  String get dietVegan => 'Vegan';

  @override
  String get dietPescatarian => 'Pescatarian';

  @override
  String get dietHalal => 'Halal';

  @override
  String get allergiesNone => 'None';

  @override
  String get allergiesHint =>
      'Recipes with these ingredients will never be suggested. Always check labels — a database can\'t guarantee a food is allergen-free.';

  @override
  String get allergenEggs => 'Eggs';

  @override
  String get allergenDairy => 'Dairy';

  @override
  String get allergenPeanuts => 'Peanuts';

  @override
  String get allergenTreeNuts => 'Tree nuts';

  @override
  String get allergenGluten => 'Gluten';

  @override
  String get allergenSoy => 'Soy';

  @override
  String get allergenFish => 'Fish';

  @override
  String get allergenShellfish => 'Shellfish';

  @override
  String get allergenSesame => 'Sesame';

  @override
  String get profileAddName => 'Add your name';

  @override
  String get profileEditHint => 'Edit profile';

  @override
  String get profileTitle => 'Your profile';

  @override
  String get profileOptional => 'Optional. Your name is only used to greet you and stays on this phone.';

  @override
  String get profileNameLabel => 'Name';

  @override
  String profileMemberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get historyAll => 'All';

  @override
  String get historyFasting => 'Fasting';

  @override
  String get historyRecentDays => 'Recent days';

  @override
  String get historyNothingRecent => 'Nothing recorded in the last two weeks. That\'s completely fine.';

  @override
  String get historyNothingLogged => 'Nothing logged';

  @override
  String get historyDaySummary => 'Day summary';

  @override
  String get historySkipFine => 'Skipping a day is completely fine.';

  @override
  String get historyQuote => '“Trends are guides, not grades. Skip a day anytime.”';

  @override
  String get historyFastInProgress => 'Fast in progress';

  @override
  String historyFastDone(String duration, String status) {
    return '$duration fast · $status';
  }

  @override
  String historyWater(String amount) {
    return '$amount water';
  }

  @override
  String historyActivity(String duration) {
    return '$duration activity';
  }

  @override
  String historyWaterEntries(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count entries', one: '1 entry');
    return '$amount of water · $_temp0';
  }

  @override
  String get weekdayInitialsSundayFirst => 'S,M,T,W,T,F,S';

  @override
  String get trendEyebrow => 'Fasting · last 14 days';

  @override
  String get trendAverageFast => 'average fast';

  @override
  String get trendLongest => 'Longest';

  @override
  String get trendTotal => 'Total';

  @override
  String trendFastCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count fasts', one: '1 fast');
    return '$_temp0';
  }

  @override
  String get trendEmpty => 'No completed fasts in the last 14 days.';

  @override
  String trendSemantics(String average, String longest, int count, String range) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count fasts', one: '1 fast');
    return 'Fasting, last 14 days ($range): average fast $average, longest $longest, $_temp0.';
  }

  @override
  String get kitchenTitle => 'My Kitchen';

  @override
  String get kitchenEyebrow => 'Nutrition';

  @override
  String get kitchenSearch => 'Search your kitchen…';

  @override
  String get kitchenAll => 'All';

  @override
  String get catProtein => 'Protein';

  @override
  String get catCarbs => 'Carbs';

  @override
  String get catVegetables => 'Vegetables';

  @override
  String get catFruits => 'Fruits';

  @override
  String get catFatsNutsSeeds => 'Fats, nuts & seeds';

  @override
  String get catDairy => 'Dairy & alternatives';

  @override
  String get catHerbsSpices => 'Herbs & spices';

  @override
  String get catPantry => 'Pantry essentials';

  @override
  String get stateFresh => 'Fresh';

  @override
  String get stateFrozen => 'Frozen';

  @override
  String get stateCanned => 'Canned';

  @override
  String get stateDried => 'Dried';

  @override
  String get kitchenOverview => 'Kitchen overview';

  @override
  String kitchenItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count items', one: '1 item');
    return '$_temp0';
  }

  @override
  String get kitchenWellStocked => 'Your pantry is well stocked.';

  @override
  String get kitchenShoppingTrip => 'Time for a shopping trip.';

  @override
  String get kitchenEmptyOverview => 'Add what you have at home to get started.';

  @override
  String get kitchenExpiringSoon => 'Expiring soon';

  @override
  String get kitchenLowStock => 'Low stock';

  @override
  String kitchenInYourKitchen(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count items', one: '1 item');
    return 'In your kitchen · $_temp0';
  }

  @override
  String get kitchenNothingHere => 'Nothing here yet.';

  @override
  String get kitchenNoMatches => 'No ingredients match your search.';

  @override
  String get kitchenAddIngredient => 'Add Ingredient';

  @override
  String get kitchenExpiresToday => 'Expires today';

  @override
  String kitchenExpiresIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Expires in $days days',
      one: 'Expires in 1 day',
    );
    return '$_temp0';
  }

  @override
  String kitchenExpired(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Expired $days days ago',
      one: 'Expired 1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get ingredientAddTitle => 'Add Ingredient';

  @override
  String get ingredientEditTitle => 'Edit Ingredient';

  @override
  String get ingredientStatusEyebrow => 'Status';

  @override
  String get ingredientNewEntry => 'New Stock Entry';

  @override
  String get ingredientNewEntrySub => 'Adding to your main inventory';

  @override
  String get ingredientUpdate => 'Update Stock';

  @override
  String get ingredientUpdateSub => 'Editing an item in your inventory';

  @override
  String get ingredientName => 'Name';

  @override
  String get ingredientNameHint => 'e.g. Baby spinach';

  @override
  String get ingredientCategory => 'Category (one or more)';

  @override
  String get ingredientQuantity => 'Quantity & unit';

  @override
  String get ingredientState => 'State';

  @override
  String get ingredientDates => 'Dates (optional)';

  @override
  String get ingredientPurchased => 'Purchased';

  @override
  String get ingredientExpires => 'Expires';

  @override
  String get ingredientNotSet => 'Not set';

  @override
  String ingredientClearDate(String label) {
    return 'Clear $label date';
  }

  @override
  String get ingredientLowStockAt => 'Low-stock alert at (optional)';

  @override
  String get ingredientLowStockHint => 'e.g. 2';

  @override
  String get ingredientBrand => 'Brand (optional)';

  @override
  String get ingredientBrandHint => 'e.g. Woolworths';

  @override
  String get ingredientNotes => 'Notes (optional)';

  @override
  String get ingredientNotesHint => 'Anything to remember';

  @override
  String get ingredientSave => 'Save ingredient';

  @override
  String ingredientSaved(String name) {
    return '$name saved to My Kitchen';
  }

  @override
  String get ingredientMarkFinished => 'Mark as finished';

  @override
  String ingredientFinished(String name) {
    return '$name marked as finished';
  }

  @override
  String get ingredientRemove => 'Remove from kitchen';

  @override
  String ingredientRemoveConfirm(String name) {
    return 'Remove $name?';
  }

  @override
  String get ingredientRemoveBody =>
      'This deletes the item and its history. To keep a record, mark it as finished instead.';

  @override
  String ingredientRemoved(String name) {
    return '$name removed';
  }

  @override
  String get errNameRequired => 'Please enter a name.';

  @override
  String get errQuantityInvalid => 'Enter a quantity of 0 or more.';

  @override
  String get errLowStockInvalid => 'Enter a low-stock amount of 0 or more, or leave it empty.';

  @override
  String get errExpiryBeforePurchase => 'The expiry date can\'t be before the purchase date.';

  @override
  String kitchenItemSemantics(String name, String quantity, String state) {
    return '$name, $quantity, $state';
  }

  @override
  String get notifDailyBody => 'Your daily reminder. Open the app to start or review a session.';
}
