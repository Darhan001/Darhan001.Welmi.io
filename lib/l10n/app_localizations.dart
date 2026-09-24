import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ky.dart';
import 'app_localizations_ru.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ky'),
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Welmi'**
  String get appName;

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

  /// No description provided for @greetingNight.
  ///
  /// In en, this message translates to:
  /// **'Good night'**
  String get greetingNight;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @dailyTipOver80.
  ///
  /// In en, this message translates to:
  /// **'Great! {remaining} kcal left'**
  String dailyTipOver80(Object remaining);

  /// No description provided for @dailyTipBetween30.
  ///
  /// In en, this message translates to:
  /// **'Eaten {consumed} kcal out of {goal}'**
  String dailyTipBetween30(Object consumed, Object goal);

  /// No description provided for @dailyTipLateNight.
  ///
  /// In en, this message translates to:
  /// **'Late night — time to log a snack'**
  String get dailyTipLateNight;

  /// No description provided for @dailyTipBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Time to log breakfast! 🍳'**
  String get dailyTipBreakfast;

  /// No description provided for @dailyTipLunch.
  ///
  /// In en, this message translates to:
  /// **'Time to log lunch! 🥗'**
  String get dailyTipLunch;

  /// No description provided for @dailyTipDinner.
  ///
  /// In en, this message translates to:
  /// **'Time to log dinner! 🍽️'**
  String get dailyTipDinner;

  /// No description provided for @dailyTipSnack.
  ///
  /// In en, this message translates to:
  /// **'Time to log a snack! 🍎'**
  String get dailyTipSnack;

  /// No description provided for @loadingData.
  ///
  /// In en, this message translates to:
  /// **'Loading data...'**
  String get loadingData;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @ofKcal.
  ///
  /// In en, this message translates to:
  /// **'of {goal} KCAL'**
  String ofKcal(Object goal);

  /// No description provided for @protein.
  ///
  /// In en, this message translates to:
  /// **'PROTEIN'**
  String get protein;

  /// No description provided for @fat.
  ///
  /// In en, this message translates to:
  /// **'FAT'**
  String get fat;

  /// No description provided for @carbs.
  ///
  /// In en, this message translates to:
  /// **'CARBS'**
  String get carbs;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'STEPS'**
  String get steps;

  /// No description provided for @water.
  ///
  /// In en, this message translates to:
  /// **'WATER'**
  String get water;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'WEIGHT'**
  String get weight;

  /// No description provided for @goal.
  ///
  /// In en, this message translates to:
  /// **'GOAL'**
  String get goal;

  /// No description provided for @todayEaten.
  ///
  /// In en, this message translates to:
  /// **'Today eaten'**
  String get todayEaten;

  /// No description provided for @foodDiary.
  ///
  /// In en, this message translates to:
  /// **'Food Diary'**
  String get foodDiary;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @aiAssistantDesc.
  ///
  /// In en, this message translates to:
  /// **'Product macros, workout plan and tips'**
  String get aiAssistantDesc;

  /// No description provided for @drawerWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get drawerWorkouts;

  /// No description provided for @drawerMyGoals.
  ///
  /// In en, this message translates to:
  /// **'My Goals'**
  String get drawerMyGoals;

  /// No description provided for @drawerMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Meal Plan'**
  String get drawerMealPlan;

  /// No description provided for @drawerActivityHistory.
  ///
  /// In en, this message translates to:
  /// **'Activity History'**
  String get drawerActivityHistory;

  /// No description provided for @drawerSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get drawerSettings;

  /// No description provided for @drawerSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get drawerSupport;

  /// No description provided for @drawerLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get drawerLogout;

  /// No description provided for @drawerLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of your account?'**
  String get drawerLogoutConfirm;

  /// No description provided for @drawerCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get drawerCancel;

  /// No description provided for @welmiPremium.
  ///
  /// In en, this message translates to:
  /// **'Welmi Premium'**
  String get welmiPremium;

  /// No description provided for @userDefault.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userDefault;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @biometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get biometricLogin;

  /// No description provided for @biometricSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint or Face ID'**
  String get biometricSubtitle;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @googleFitAppleHealth.
  ///
  /// In en, this message translates to:
  /// **'Google Fit / Apple Health'**
  String get googleFitAppleHealth;

  /// No description provided for @healthConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected ✓'**
  String get healthConnected;

  /// No description provided for @healthDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Auto-sync steps and calories'**
  String get healthDisconnected;

  /// No description provided for @healthConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get healthConnect;

  /// No description provided for @healthInstallPrompt.
  ///
  /// In en, this message translates to:
  /// **'Install Health Connect app for sync'**
  String get healthInstallPrompt;

  /// No description provided for @healthInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get healthInstall;

  /// No description provided for @healthNoAccess.
  ///
  /// In en, this message translates to:
  /// **'Access denied. Open Health Connect on your phone and allow access for Welmi'**
  String get healthNoAccess;

  /// No description provided for @healthConnectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connected ✓ · Synced {steps} steps'**
  String healthConnectedSuccess(Object steps);

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders for water and food'**
  String get pushNotificationsSubtitle;

  /// No description provided for @waterReminders.
  ///
  /// In en, this message translates to:
  /// **'Water Reminders'**
  String get waterReminders;

  /// No description provided for @waterRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every 2 hours from 8:00 to 20:00'**
  String get waterRemindersSubtitle;

  /// No description provided for @mealReminders.
  ///
  /// In en, this message translates to:
  /// **'Meal Reminders'**
  String get mealReminders;

  /// No description provided for @mealRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Breakfast 8:30 · Lunch 13:00 · Dinner 19:00'**
  String get mealRemindersSubtitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystemDescription.
  ///
  /// In en, this message translates to:
  /// **'\"System\" — theme changes with phone settings'**
  String get themeSystemDescription;

  /// No description provided for @measurementUnits.
  ///
  /// In en, this message translates to:
  /// **'Measurement Units'**
  String get measurementUnits;

  /// No description provided for @metricUnits.
  ///
  /// In en, this message translates to:
  /// **'Metric (kg, km)'**
  String get metricUnits;

  /// No description provided for @imperialUnits.
  ///
  /// In en, this message translates to:
  /// **'Imperial (lbs, miles)'**
  String get imperialUnits;

  /// No description provided for @widgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Widget'**
  String get widgetTitle;

  /// No description provided for @widgetWaterTitle.
  ///
  /// In en, this message translates to:
  /// **'Water Widget'**
  String get widgetWaterTitle;

  /// No description provided for @widgetWaterDescription.
  ///
  /// In en, this message translates to:
  /// **'Long-press on home screen → Widgets → Welmi'**
  String get widgetWaterDescription;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @madeWithLove.
  ///
  /// In en, this message translates to:
  /// **'Made with ❤️ — Welmi'**
  String get madeWithLove;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled'**
  String get notificationsDisabled;

  /// No description provided for @notifMasterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Water, meals, activity'**
  String get notifMasterSubtitle;

  /// No description provided for @notifReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get notifReminders;

  /// No description provided for @notifEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening reminder'**
  String get notifEvening;

  /// No description provided for @notifWaterInterval.
  ///
  /// In en, this message translates to:
  /// **'Reminder interval'**
  String get notifWaterInterval;

  /// No description provided for @notifPickTime.
  ///
  /// In en, this message translates to:
  /// **'Choose time'**
  String get notifPickTime;

  /// No description provided for @notifEvery30Min.
  ///
  /// In en, this message translates to:
  /// **'Every 30 min'**
  String get notifEvery30Min;

  /// No description provided for @notifEvery1h.
  ///
  /// In en, this message translates to:
  /// **'Every 1 hour'**
  String get notifEvery1h;

  /// No description provided for @notifEvery90Min.
  ///
  /// In en, this message translates to:
  /// **'Every 1.5 hours'**
  String get notifEvery90Min;

  /// No description provided for @notifEvery2h.
  ///
  /// In en, this message translates to:
  /// **'Every 2 hours'**
  String get notifEvery2h;

  /// No description provided for @notifEvery3h.
  ///
  /// In en, this message translates to:
  /// **'Every 3 hours'**
  String get notifEvery3h;

  /// No description provided for @notifTestButton.
  ///
  /// In en, this message translates to:
  /// **'Send test notification'**
  String get notifTestButton;

  /// No description provided for @notifTestSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent!'**
  String get notifTestSent;

  /// No description provided for @notifPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission denied'**
  String get notifPermissionDenied;

  /// No description provided for @notifPermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Permission granted!'**
  String get notifPermissionGranted;

  /// No description provided for @notifPermissionBanner.
  ///
  /// In en, this message translates to:
  /// **'Tap to allow notifications — otherwise reminders won\'t appear'**
  String get notifPermissionBanner;

  /// No description provided for @biometricEnabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric enabled'**
  String get biometricEnabled;

  /// No description provided for @biometricDisabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric disabled'**
  String get biometricDisabled;

  /// No description provided for @biometricFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not verify identity'**
  String get biometricFailed;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated!'**
  String get profileUpdated;

  /// No description provided for @unitsChanged.
  ///
  /// In en, this message translates to:
  /// **'Units changed: {units}'**
  String unitsChanged(Object units);

  /// No description provided for @workouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get workouts;

  /// No description provided for @myPlan.
  ///
  /// In en, this message translates to:
  /// **'My plan: Week 2'**
  String get myPlan;

  /// No description provided for @whereDoYouTrain.
  ///
  /// In en, this message translates to:
  /// **'Where do you train?'**
  String get whereDoYouTrain;

  /// No description provided for @trainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll match exercises to your equipment'**
  String get trainSubtitle;

  /// No description provided for @noEquipment.
  ///
  /// In en, this message translates to:
  /// **'No equipment'**
  String get noEquipment;

  /// No description provided for @noEquipmentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight only: push-ups, squats, plank'**
  String get noEquipmentSubtitle;

  /// No description provided for @dumbbells.
  ///
  /// In en, this message translates to:
  /// **'Dumbbells'**
  String get dumbbells;

  /// No description provided for @dumbbellsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Dumbbell set for home workouts'**
  String get dumbbellsSubtitle;

  /// No description provided for @calisthenics.
  ///
  /// In en, this message translates to:
  /// **'Pull-up bar & bands'**
  String get calisthenics;

  /// No description provided for @calisthenicsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pull-up bar, resistance bands, yoga mat'**
  String get calisthenicsSubtitle;

  /// No description provided for @gym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get gym;

  /// No description provided for @gymSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Barbells, dumbbells, machines — full gym'**
  String get gymSubtitle;

  /// No description provided for @generatingPlan.
  ///
  /// In en, this message translates to:
  /// **'Building your plan...'**
  String get generatingPlan;

  /// No description provided for @aiAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'AI is analyzing your parameters'**
  String get aiAnalyzing;

  /// No description provided for @restDay.
  ///
  /// In en, this message translates to:
  /// **'Rest Day'**
  String get restDay;

  /// No description provided for @restDaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recover and build strength'**
  String get restDaySubtitle;

  /// No description provided for @exercisesCount.
  ///
  /// In en, this message translates to:
  /// **'Exercises — {count}'**
  String exercisesCount(Object count);

  /// No description provided for @failedToLoadPlan.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load plan. Check your internet.'**
  String get failedToLoadPlan;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @planGeneratingSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Plan for \"{label}\" — generating…'**
  String planGeneratingSnackbar(Object label);

  /// No description provided for @aiChatTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get aiChatTitle;

  /// No description provided for @gymtoneTrainer.
  ///
  /// In en, this message translates to:
  /// **'GYMTONE TRAINER'**
  String get gymtoneTrainer;

  /// No description provided for @aiWelcomeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, there!\nI can help you with\nworkouts, plans and nutrition'**
  String get aiWelcomeGreeting;

  /// No description provided for @aiSuggestion1.
  ///
  /// In en, this message translates to:
  /// **'Why is my plan built this way?'**
  String get aiSuggestion1;

  /// No description provided for @aiSuggestion2.
  ///
  /// In en, this message translates to:
  /// **'When will I see results?'**
  String get aiSuggestion2;

  /// No description provided for @aiSuggestion3.
  ///
  /// In en, this message translates to:
  /// **'Adjust the plan'**
  String get aiSuggestion3;

  /// No description provided for @aiNewChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get aiNewChat;

  /// No description provided for @aiNewChatConfirm.
  ///
  /// In en, this message translates to:
  /// **'Start a new dialog? Current history will be cleared.'**
  String get aiNewChatConfirm;

  /// No description provided for @aiStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get aiStart;

  /// No description provided for @aiErrorConnection.
  ///
  /// In en, this message translates to:
  /// **'Could not get a response from AI. Check your internet connection and try again.'**
  String get aiErrorConnection;

  /// No description provided for @aiHintLoading.
  ///
  /// In en, this message translates to:
  /// **'Waiting for reply...'**
  String get aiHintLoading;

  /// No description provided for @aiHintInput.
  ///
  /// In en, this message translates to:
  /// **'Type your question'**
  String get aiHintInput;

  /// No description provided for @aiJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get aiJustNow;

  /// No description provided for @aiMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String aiMinutesAgo(Object minutes);

  /// No description provided for @voiceMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get voiceMessageLabel;

  /// No description provided for @voiceSend.
  ///
  /// In en, this message translates to:
  /// **'Send voice message'**
  String get voiceSend;

  /// No description provided for @voiceRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording…'**
  String get voiceRecording;

  /// No description provided for @voiceTranscribing.
  ///
  /// In en, this message translates to:
  /// **'Recognizing speech…'**
  String get voiceTranscribing;

  /// No description provided for @voiceCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get voiceCancel;

  /// No description provided for @voiceErrorPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow microphone access to send voice messages.'**
  String get voiceErrorPermission;

  /// No description provided for @voiceErrorTranscribe.
  ///
  /// In en, this message translates to:
  /// **'Could not recognize speech. Please try again.'**
  String get voiceErrorTranscribe;

  /// No description provided for @mealPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal Plan'**
  String get mealPlanTitle;

  /// No description provided for @whereDoYouLive.
  ///
  /// In en, this message translates to:
  /// **'Where do you live?'**
  String get whereDoYouLive;

  /// No description provided for @mealPlanCountrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI will pick dishes from local cuisine'**
  String get mealPlanCountrySubtitle;

  /// No description provided for @generateMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Generating meal plan...'**
  String get generateMealPlan;

  /// No description provided for @mealPlanAiSelecting.
  ///
  /// In en, this message translates to:
  /// **'Welmi AI is picking the perfect menu'**
  String get mealPlanAiSelecting;

  /// No description provided for @mealPlanLocalCuisine.
  ///
  /// In en, this message translates to:
  /// **'Local cuisine: {country}'**
  String mealPlanLocalCuisine(Object country);

  /// No description provided for @mealPlanFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load plan'**
  String get mealPlanFailed;

  /// No description provided for @mealPlanRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get mealPlanRetry;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select country'**
  String get selectCountry;

  /// No description provided for @cuisineOf.
  ///
  /// In en, this message translates to:
  /// **'Cuisine: {country}'**
  String cuisineOf(Object country);

  /// No description provided for @fromGoalKcal.
  ///
  /// In en, this message translates to:
  /// **'of {goal} kcal'**
  String fromGoalKcal(Object goal);

  /// No description provided for @mealsCount.
  ///
  /// In en, this message translates to:
  /// **'meals'**
  String get mealsCount;

  /// No description provided for @generatedByAi.
  ///
  /// In en, this message translates to:
  /// **'Generated by Welmi AI'**
  String get generatedByAi;

  /// No description provided for @generatedByAiCountry.
  ///
  /// In en, this message translates to:
  /// **'Generated by Welmi AI · {country} cuisine'**
  String generatedByAiCountry(Object country);

  /// No description provided for @previewMenu.
  ///
  /// In en, this message translates to:
  /// **'Preliminary menu'**
  String get previewMenu;

  /// No description provided for @previewMenuCountry.
  ///
  /// In en, this message translates to:
  /// **'Preliminary menu · {country} cuisine'**
  String previewMenuCountry(Object country);

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity History'**
  String get historyTitle;

  /// No description provided for @loginToViewHistory.
  ///
  /// In en, this message translates to:
  /// **'Log in to see history'**
  String get loginToViewHistory;

  /// No description provided for @loadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Loading history...'**
  String get loadingHistory;

  /// No description provided for @stepsLast30Days.
  ///
  /// In en, this message translates to:
  /// **'steps in 30 days'**
  String get stepsLast30Days;

  /// No description provided for @waterLast14Days.
  ///
  /// In en, this message translates to:
  /// **'water in 14 days'**
  String get waterLast14Days;

  /// No description provided for @activeDays.
  ///
  /// In en, this message translates to:
  /// **'active days'**
  String get activeDays;

  /// No description provided for @noRecordsYet.
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get noRecordsYet;

  /// No description provided for @noRecordsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log steps, water or a workout'**
  String get noRecordsSubtitle;

  /// No description provided for @logEntry.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get logEntry;

  /// No description provided for @recentDays.
  ///
  /// In en, this message translates to:
  /// **'Recent Days'**
  String get recentDays;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @whatToLog.
  ///
  /// In en, this message translates to:
  /// **'What to log?'**
  String get whatToLog;

  /// No description provided for @whatToLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Steps, water or a workout'**
  String get whatToLogSubtitle;

  /// No description provided for @activityLog.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityLog;

  /// No description provided for @activityLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Steps, minutes, distance'**
  String get activityLogSubtitle;

  /// No description provided for @waterLog.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get waterLog;

  /// No description provided for @waterLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add water intake'**
  String get waterLogSubtitle;

  /// No description provided for @exerciseLog.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get exerciseLog;

  /// No description provided for @exerciseLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Squats, plank, abs, etc.'**
  String get exerciseLogSubtitle;

  /// No description provided for @logActivity.
  ///
  /// In en, this message translates to:
  /// **'Log Activity'**
  String get logActivity;

  /// No description provided for @stepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get stepsLabel;

  /// No description provided for @stepsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g.: 8000'**
  String get stepsHint;

  /// No description provided for @minutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutesLabel;

  /// No description provided for @kmLabel.
  ///
  /// In en, this message translates to:
  /// **'Km'**
  String get kmLabel;

  /// No description provided for @addWater.
  ///
  /// In en, this message translates to:
  /// **'Add Water'**
  String get addWater;

  /// No description provided for @waterDrunkToday.
  ///
  /// In en, this message translates to:
  /// **'Drunk today: {ml} ml'**
  String waterDrunkToday(Object ml);

  /// No description provided for @glass.
  ///
  /// In en, this message translates to:
  /// **'Glass'**
  String get glass;

  /// No description provided for @bottle.
  ///
  /// In en, this message translates to:
  /// **'Bottle'**
  String get bottle;

  /// No description provided for @liter.
  ///
  /// In en, this message translates to:
  /// **'Liter'**
  String get liter;

  /// No description provided for @addExercise.
  ///
  /// In en, this message translates to:
  /// **'Add Exercise'**
  String get addExercise;

  /// No description provided for @setsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get setsLabel;

  /// No description provided for @repsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get repsLabel;

  /// No description provided for @selectExercise.
  ///
  /// In en, this message translates to:
  /// **'Select an exercise'**
  String get selectExercise;

  /// No description provided for @exerciseAddedToHistory.
  ///
  /// In en, this message translates to:
  /// **'{name} — added to history'**
  String exerciseAddedToHistory(Object name);

  /// No description provided for @activitySaved.
  ///
  /// In en, this message translates to:
  /// **'Activity saved'**
  String get activitySaved;

  /// No description provided for @exerciseSquats.
  ///
  /// In en, this message translates to:
  /// **'Squats'**
  String get exerciseSquats;

  /// No description provided for @exercisePushups.
  ///
  /// In en, this message translates to:
  /// **'Push-ups'**
  String get exercisePushups;

  /// No description provided for @exercisePlank.
  ///
  /// In en, this message translates to:
  /// **'Plank'**
  String get exercisePlank;

  /// No description provided for @exerciseRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get exerciseRunning;

  /// No description provided for @exerciseWalking.
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get exerciseWalking;

  /// No description provided for @exerciseAbs.
  ///
  /// In en, this message translates to:
  /// **'Abs'**
  String get exerciseAbs;

  /// No description provided for @exerciseRope.
  ///
  /// In en, this message translates to:
  /// **'Jump Rope'**
  String get exerciseRope;

  /// No description provided for @exerciseBike.
  ///
  /// In en, this message translates to:
  /// **'Bicycle'**
  String get exerciseBike;

  /// No description provided for @exerciseYoga.
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get exerciseYoga;

  /// No description provided for @exerciseStretch.
  ///
  /// In en, this message translates to:
  /// **'Stretching'**
  String get exerciseStretch;

  /// No description provided for @diaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get diaryTitle;

  /// No description provided for @loadingDiary.
  ///
  /// In en, this message translates to:
  /// **'Loading diary...'**
  String get loadingDiary;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @remainingKcal.
  ///
  /// In en, this message translates to:
  /// **'{remaining} kcal left'**
  String remainingKcal(Object remaining);

  /// No description provided for @nothingAdded.
  ///
  /// In en, this message translates to:
  /// **'Nothing added'**
  String get nothingAdded;

  /// No description provided for @addButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addButton;

  /// No description provided for @breakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get breakfast;

  /// No description provided for @lunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get lunch;

  /// No description provided for @dinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get dinner;

  /// No description provided for @snack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get snack;

  /// No description provided for @addFoodTo.
  ///
  /// In en, this message translates to:
  /// **'Add to {meal}'**
  String addFoodTo(Object meal);

  /// No description provided for @foodName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get foodName;

  /// No description provided for @foodNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g.: Oatmeal with berries'**
  String get foodNameHint;

  /// No description provided for @kcalLabel.
  ///
  /// In en, this message translates to:
  /// **'Calories (kcal)'**
  String get kcalLabel;

  /// No description provided for @proteinGrams.
  ///
  /// In en, this message translates to:
  /// **'Protein (g)'**
  String get proteinGrams;

  /// No description provided for @fatGrams.
  ///
  /// In en, this message translates to:
  /// **'Fat (g)'**
  String get fatGrams;

  /// No description provided for @carbsGrams.
  ///
  /// In en, this message translates to:
  /// **'Carbs (g)'**
  String get carbsGrams;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'250g, 200ml...'**
  String get descriptionHint;

  /// No description provided for @loginToSave.
  ///
  /// In en, this message translates to:
  /// **'Log in to save data'**
  String get loginToSave;

  /// No description provided for @enterNameAndCalories.
  ///
  /// In en, this message translates to:
  /// **'Enter name and calories'**
  String get enterNameAndCalories;

  /// No description provided for @weightTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightTitle;

  /// No description provided for @recordWeight.
  ///
  /// In en, this message translates to:
  /// **'Record Weight'**
  String get recordWeight;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @startWeight.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startWeight;

  /// No description provided for @goalWeight.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goalWeight;

  /// No description provided for @currentWeightKg.
  ///
  /// In en, this message translates to:
  /// **'Current weight (kg)'**
  String get currentWeightKg;

  /// No description provided for @weightLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get weightLost;

  /// No description provided for @weightToGoal.
  ///
  /// In en, this message translates to:
  /// **'To goal'**
  String get weightToGoal;

  /// No description provided for @weightDynamics.
  ///
  /// In en, this message translates to:
  /// **'Weight Dynamics'**
  String get weightDynamics;

  /// No description provided for @weightEntries.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String weightEntries(Object count);

  /// No description provided for @percentToGoal.
  ///
  /// In en, this message translates to:
  /// **'{percent}% to goal'**
  String percentToGoal(Object percent);

  /// No description provided for @weekChange.
  ///
  /// In en, this message translates to:
  /// **'Last {days} days'**
  String weekChange(Object days);

  /// No description provided for @weekLost.
  ///
  /// In en, this message translates to:
  /// **'Lost {amount} kg'**
  String weekLost(Object amount);

  /// No description provided for @weekGained.
  ///
  /// In en, this message translates to:
  /// **'Gained {amount} kg'**
  String weekGained(Object amount);

  /// No description provided for @kgPerWeek.
  ///
  /// In en, this message translates to:
  /// **'kg/week'**
  String get kgPerWeek;

  /// No description provided for @goalTitle.
  ///
  /// In en, this message translates to:
  /// **'My Goal'**
  String get goalTitle;

  /// No description provided for @goalType.
  ///
  /// In en, this message translates to:
  /// **'Goal Type'**
  String get goalType;

  /// No description provided for @goalWeightLoss.
  ///
  /// In en, this message translates to:
  /// **'Weight Loss'**
  String get goalWeightLoss;

  /// No description provided for @goalMaintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain'**
  String get goalMaintain;

  /// No description provided for @goalGain.
  ///
  /// In en, this message translates to:
  /// **'Gain'**
  String get goalGain;

  /// No description provided for @goalNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get goalNotSelected;

  /// No description provided for @goalTapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap ✏️ to select a goal'**
  String get goalTapToSelect;

  /// No description provided for @goalMaintainDesc.
  ///
  /// In en, this message translates to:
  /// **'Maintaining current weight'**
  String get goalMaintainDesc;

  /// No description provided for @goalDaysToGoal.
  ///
  /// In en, this message translates to:
  /// **'~{days} days to goal'**
  String goalDaysToGoal(Object days);

  /// No description provided for @goalDaysSinceStart.
  ///
  /// In en, this message translates to:
  /// **'{days} days since start'**
  String goalDaysSinceStart(Object days);

  /// No description provided for @goalTargetWeight.
  ///
  /// In en, this message translates to:
  /// **'{weight} kg — goal'**
  String goalTargetWeight(Object weight);

  /// No description provided for @editGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit Goal'**
  String get editGoal;

  /// No description provided for @goalTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal Type'**
  String get goalTypeLabel;

  /// No description provided for @goalLoseWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight Loss'**
  String get goalLoseWeight;

  /// No description provided for @goalMaintainWeight.
  ///
  /// In en, this message translates to:
  /// **'Maintain'**
  String get goalMaintainWeight;

  /// No description provided for @goalGainWeight.
  ///
  /// In en, this message translates to:
  /// **'Gain'**
  String get goalGainWeight;

  /// No description provided for @targetWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Target Weight'**
  String get targetWeightLabel;

  /// No description provided for @goalSpeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Speed (kg/week)'**
  String get goalSpeedLabel;

  /// No description provided for @enterValidWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid target weight'**
  String get enterValidWeight;

  /// No description provided for @selectGoalType.
  ///
  /// In en, this message translates to:
  /// **'Select a goal type'**
  String get selectGoalType;

  /// No description provided for @goalUpdated.
  ///
  /// In en, this message translates to:
  /// **'Goal updated!'**
  String get goalUpdated;

  /// No description provided for @comparison.
  ///
  /// In en, this message translates to:
  /// **'Comparison'**
  String get comparison;

  /// No description provided for @was.
  ///
  /// In en, this message translates to:
  /// **'Was'**
  String get was;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @milestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get milestones;

  /// No description provided for @avgPerDay.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get avgPerDay;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'Days left'**
  String get daysRemaining;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get completed;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @motivation.
  ///
  /// In en, this message translates to:
  /// **'Motivation'**
  String get motivation;

  /// No description provided for @progressDone.
  ///
  /// In en, this message translates to:
  /// **'Great! {remaining} kcal left'**
  String progressDone(Object remaining);

  /// No description provided for @aiInsightFillProfile.
  ///
  /// In en, this message translates to:
  /// **'Fill in your profile to get personalized insights ✨'**
  String get aiInsightFillProfile;

  /// No description provided for @aiInsightStartTracking.
  ///
  /// In en, this message translates to:
  /// **'Start logging weight to see progress! 🚀'**
  String get aiInsightStartTracking;

  /// No description provided for @aiInsightGreatPace.
  ///
  /// In en, this message translates to:
  /// **'Great pace! You\'ll reach your goal in ~{days} days 🎯'**
  String aiInsightGreatPace(Object days);

  /// No description provided for @aiInsightAlmostThere.
  ///
  /// In en, this message translates to:
  /// **'You\'re almost there!'**
  String get aiInsightAlmostThere;

  /// No description provided for @aiInsightSteadyProgress.
  ///
  /// In en, this message translates to:
  /// **'Steady progress. Keep it up! 💪'**
  String get aiInsightSteadyProgress;

  /// No description provided for @aiInsightSlowProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress is slow. Try increasing activity or adjusting nutrition. 📈'**
  String get aiInsightSlowProgress;

  /// No description provided for @aiInsightOnTrack.
  ///
  /// In en, this message translates to:
  /// **'You\'re on track! Small steps lead to big results. 🌟'**
  String get aiInsightOnTrack;

  /// No description provided for @motivationQuote1.
  ///
  /// In en, this message translates to:
  /// **'Small steps lead to big results 🌱'**
  String get motivationQuote1;

  /// No description provided for @motivationQuote2.
  ///
  /// In en, this message translates to:
  /// **'You\'re already on your way — keep going! 💪'**
  String get motivationQuote2;

  /// No description provided for @motivationQuote3.
  ///
  /// In en, this message translates to:
  /// **'Every day is a chance to be better ✨'**
  String get motivationQuote3;

  /// No description provided for @motivationQuote4.
  ///
  /// In en, this message translates to:
  /// **'Your body is your most faithful project 🏗️'**
  String get motivationQuote4;

  /// No description provided for @motivationQuote5.
  ///
  /// In en, this message translates to:
  /// **'Never give up. Great things take time ⏳'**
  String get motivationQuote5;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// No description provided for @progressFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get progressFilterAll;

  /// No description provided for @progressFilterMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get progressFilterMeasurements;

  /// No description provided for @progressFilterBodyFat.
  ///
  /// In en, this message translates to:
  /// **'% Body Fat'**
  String get progressFilterBodyFat;

  /// No description provided for @progressLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load data. Check your connection.'**
  String get progressLoadError;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @recordWeightAction.
  ///
  /// In en, this message translates to:
  /// **'Record Weight'**
  String get recordWeightAction;

  /// No description provided for @recordMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Record Measurements'**
  String get recordMeasurements;

  /// No description provided for @recordBodyFat.
  ///
  /// In en, this message translates to:
  /// **'Record % Body Fat'**
  String get recordBodyFat;

  /// No description provided for @chestCm.
  ///
  /// In en, this message translates to:
  /// **'Chest (cm)'**
  String get chestCm;

  /// No description provided for @waistCm.
  ///
  /// In en, this message translates to:
  /// **'Waist (cm)'**
  String get waistCm;

  /// No description provided for @hipsCm.
  ///
  /// In en, this message translates to:
  /// **'Hips (cm)'**
  String get hipsCm;

  /// No description provided for @armCm.
  ///
  /// In en, this message translates to:
  /// **'Arm (cm)'**
  String get armCm;

  /// No description provided for @thighCm.
  ///
  /// In en, this message translates to:
  /// **'Thigh (cm)'**
  String get thighCm;

  /// No description provided for @neckCm.
  ///
  /// In en, this message translates to:
  /// **'Neck (cm)'**
  String get neckCm;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChanges;

  /// No description provided for @discardChangesDesc.
  ///
  /// In en, this message translates to:
  /// **'Your unsaved changes will be lost.'**
  String get discardChangesDesc;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep Editing'**
  String get keepEditing;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @notificationsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsPageTitle;

  /// No description provided for @inbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inbox;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @notifWaterReminder.
  ///
  /// In en, this message translates to:
  /// **'Time to drink water!'**
  String get notifWaterReminder;

  /// No description provided for @notifWaterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve drunk 60% of your daily goal'**
  String get notifWaterSubtitle;

  /// No description provided for @notifLunchReminder.
  ///
  /// In en, this message translates to:
  /// **'Lunchtime'**
  String get notifLunchReminder;

  /// No description provided for @notifLunchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget to log a meal'**
  String get notifLunchSubtitle;

  /// No description provided for @notifWeightResult.
  ///
  /// In en, this message translates to:
  /// **'New result!'**
  String get notifWeightResult;

  /// No description provided for @notifWeightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your weight dropped by 0.4 kg'**
  String get notifWeightSubtitle;

  /// No description provided for @notifMotivation.
  ///
  /// In en, this message translates to:
  /// **'Motivation of the day'**
  String get notifMotivation;

  /// No description provided for @notifMotivationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Small steps lead to big results'**
  String get notifMotivationSubtitle;

  /// No description provided for @notif15MinAgo.
  ///
  /// In en, this message translates to:
  /// **'15 min ago'**
  String get notif15MinAgo;

  /// No description provided for @notif2HoursAgo.
  ///
  /// In en, this message translates to:
  /// **'2 hours ago'**
  String get notif2HoursAgo;

  /// No description provided for @notif1DayAgo.
  ///
  /// In en, this message translates to:
  /// **'1 day ago'**
  String get notif1DayAgo;

  /// No description provided for @notif2DaysAgo.
  ///
  /// In en, this message translates to:
  /// **'2 days ago'**
  String get notif2DaysAgo;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get editProfileTitle;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderLabel;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @birthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth Date'**
  String get birthDate;

  /// No description provided for @bodyType.
  ///
  /// In en, this message translates to:
  /// **'Body Type'**
  String get bodyType;

  /// No description provided for @heightCm.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get heightCm;

  /// No description provided for @currentWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Weight (kg)'**
  String get currentWeightLabel;

  /// No description provided for @targetWeight.
  ///
  /// In en, this message translates to:
  /// **'Target Weight (kg)'**
  String get targetWeight;

  /// No description provided for @tapPhotoToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap photo to change'**
  String get tapPhotoToChange;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @discardChangesQuestion.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChangesQuestion;

  /// No description provided for @discardChangesDescShort.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes will be lost.'**
  String get discardChangesDescShort;

  /// No description provided for @subscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionTitle;

  /// No description provided for @unlockAll.
  ///
  /// In en, this message translates to:
  /// **'Unlock all\npossibilities'**
  String get unlockAll;

  /// No description provided for @freeTrial7Days.
  ///
  /// In en, this message translates to:
  /// **'Try free for 7 days.\nCancel anytime.'**
  String get freeTrial7Days;

  /// No description provided for @featureFoodScanner.
  ///
  /// In en, this message translates to:
  /// **'Smart food scanner'**
  String get featureFoodScanner;

  /// No description provided for @featureMealPlans.
  ///
  /// In en, this message translates to:
  /// **'Personalized meal plans'**
  String get featureMealPlans;

  /// No description provided for @featureMacroAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Detailed macro analytics'**
  String get featureMacroAnalytics;

  /// No description provided for @featureNoAds.
  ///
  /// In en, this message translates to:
  /// **'No ads'**
  String get featureNoAds;

  /// No description provided for @monthPlan.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthPlan;

  /// No description provided for @yearPlan.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearPlan;

  /// No description provided for @yearDiscount.
  ///
  /// In en, this message translates to:
  /// **'-60%'**
  String get yearDiscount;

  /// No description provided for @startFreeTrial.
  ///
  /// In en, this message translates to:
  /// **'Start Free Trial'**
  String get startFreeTrial;

  /// No description provided for @trialTerms.
  ///
  /// In en, this message translates to:
  /// **'Payment will be charged 24 hours before the end of the trial period. Cancel in settings if you don\'t wish to renew.'**
  String get trialTerms;

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportTitle;

  /// No description provided for @writeToUs.
  ///
  /// In en, this message translates to:
  /// **'Write to Us'**
  String get writeToUs;

  /// No description provided for @telegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get telegram;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get faq;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @feedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us what can be improved'**
  String get feedbackSubtitle;

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Your ideas and suggestions...'**
  String get feedbackHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @thankYouFeedback.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your feedback! 🙌'**
  String get thankYouFeedback;

  /// No description provided for @faqQ1.
  ///
  /// In en, this message translates to:
  /// **'How to change my goal?'**
  String get faqQ1;

  /// No description provided for @faqA1.
  ///
  /// In en, this message translates to:
  /// **'Go to My Profile → My Goals. There you can change your goal, weight and parameters.'**
  String get faqA1;

  /// No description provided for @faqQ2.
  ///
  /// In en, this message translates to:
  /// **'How to reset progress?'**
  String get faqQ2;

  /// No description provided for @faqA2.
  ///
  /// In en, this message translates to:
  /// **'Progress is automatically reset when you change your goal. You can also delete records manually.'**
  String get faqA2;

  /// No description provided for @faqQ3.
  ///
  /// In en, this message translates to:
  /// **'Why doesn\'t the scanner work?'**
  String get faqQ3;

  /// No description provided for @faqA3.
  ///
  /// In en, this message translates to:
  /// **'Make sure you\'ve given camera permission. If the problem persists — restart the app.'**
  String get faqA3;

  /// No description provided for @faqQ4.
  ///
  /// In en, this message translates to:
  /// **'How to cancel subscription?'**
  String get faqQ4;

  /// No description provided for @faqA4.
  ///
  /// In en, this message translates to:
  /// **'You can cancel your subscription in your account settings in the App Store or Google Play.'**
  String get faqA4;

  /// No description provided for @faqQ5.
  ///
  /// In en, this message translates to:
  /// **'Are my data safe?'**
  String get faqQ5;

  /// No description provided for @faqA5.
  ///
  /// In en, this message translates to:
  /// **'Yes, all data is stored encrypted using Supabase. We don\'t share data with third parties.'**
  String get faqA5;

  /// No description provided for @onboardingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get onboardingWelcome;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Answer a few questions and we\'ll create your personalized meal plan'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingGenderTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your gender?'**
  String get onboardingGenderTitle;

  /// No description provided for @onboardingGenderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This helps us set more accurate calculations for your metabolism'**
  String get onboardingGenderSubtitle;

  /// No description provided for @onboardingGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your goal?'**
  String get onboardingGoalTitle;

  /// No description provided for @onboardingGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the main direction so we can\nadjust your meal plan.'**
  String get onboardingGoalSubtitle;

  /// No description provided for @onboardingLoseWeight.
  ///
  /// In en, this message translates to:
  /// **'Lose weight'**
  String get onboardingLoseWeight;

  /// No description provided for @onboardingLoseWeightDesc.
  ///
  /// In en, this message translates to:
  /// **'Weight loss through a safe\ncalorie deficit'**
  String get onboardingLoseWeightDesc;

  /// No description provided for @onboardingGainWeight.
  ///
  /// In en, this message translates to:
  /// **'Gain weight'**
  String get onboardingGainWeight;

  /// No description provided for @onboardingGainWeightDesc.
  ///
  /// In en, this message translates to:
  /// **'Calorie surplus focused on\nbuilding muscle foundation'**
  String get onboardingGainWeightDesc;

  /// No description provided for @onboardingMaintainWeight.
  ///
  /// In en, this message translates to:
  /// **'Maintain weight'**
  String get onboardingMaintainWeight;

  /// No description provided for @onboardingMaintainWeightDesc.
  ///
  /// In en, this message translates to:
  /// **'Energy balance to maintain\ncurrent form and health'**
  String get onboardingMaintainWeightDesc;

  /// No description provided for @onboardingHeightTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your height?'**
  String get onboardingHeightTitle;

  /// No description provided for @onboardingHeightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This helps us calculate your daily intake more accurately'**
  String get onboardingHeightSubtitle;

  /// No description provided for @onboardingWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'How much do you weigh\nnow?'**
  String get onboardingWeightTitle;

  /// No description provided for @onboardingWeightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This helps us calculate your calorie intake'**
  String get onboardingWeightSubtitle;

  /// No description provided for @onboardingTargetTitle.
  ///
  /// In en, this message translates to:
  /// **'What weight do you\nwant to reach?'**
  String get onboardingTargetTitle;

  /// No description provided for @onboardingTargetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set the goal we\'ll work towards'**
  String get onboardingTargetSubtitle;

  /// No description provided for @onboardingTargetFromCurrent.
  ///
  /// In en, this message translates to:
  /// **'{diff} kg from current weight'**
  String onboardingTargetFromCurrent(Object diff);

  /// No description provided for @onboardingBirthTitle.
  ///
  /// In en, this message translates to:
  /// **'When were you born?'**
  String get onboardingBirthTitle;

  /// No description provided for @onboardingBirthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This info helps us calculate your\ncalorie intake more accurately'**
  String get onboardingBirthSubtitle;

  /// No description provided for @onboardingActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'How active are you?'**
  String get onboardingActivityTitle;

  /// No description provided for @onboardingActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'This helps us calculate your\ncalorie intake more accurately'**
  String get onboardingActivitySubtitle;

  /// No description provided for @activitySedentary.
  ///
  /// In en, this message translates to:
  /// **'Sedentary'**
  String get activitySedentary;

  /// No description provided for @activitySedentaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Office work, almost no exercise.'**
  String get activitySedentaryDesc;

  /// No description provided for @activityLight.
  ///
  /// In en, this message translates to:
  /// **'Light Activity'**
  String get activityLight;

  /// No description provided for @activityLightDesc.
  ///
  /// In en, this message translates to:
  /// **'1-2 workouts per week or walks.'**
  String get activityLightDesc;

  /// No description provided for @activityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate Activity'**
  String get activityModerate;

  /// No description provided for @activityModerateDesc.
  ///
  /// In en, this message translates to:
  /// **'3-5 workouts per week, active lifestyle.'**
  String get activityModerateDesc;

  /// No description provided for @activityHigh.
  ///
  /// In en, this message translates to:
  /// **'High Activity'**
  String get activityHigh;

  /// No description provided for @activityHighDesc.
  ///
  /// In en, this message translates to:
  /// **'Daily intense workouts.'**
  String get activityHighDesc;

  /// No description provided for @onboardingSpeedTitle.
  ///
  /// In en, this message translates to:
  /// **'How fast do you want to\nreach your goal?'**
  String get onboardingSpeedTitle;

  /// No description provided for @onboardingSpeedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a comfortable pace'**
  String get onboardingSpeedSubtitle;

  /// No description provided for @optimal.
  ///
  /// In en, this message translates to:
  /// **'Optimal'**
  String get optimal;

  /// No description provided for @slow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get slow;

  /// No description provided for @fast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get fast;

  /// No description provided for @onboardingGoogleTitle.
  ///
  /// In en, this message translates to:
  /// **'Almost there!'**
  String get onboardingGoogleTitle;

  /// No description provided for @onboardingGoogleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google to save your progress'**
  String get onboardingGoogleSubtitle;

  /// No description provided for @onboardingGoogleError.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in with Google. Check Google provider settings in Supabase Dashboard.'**
  String get onboardingGoogleError;

  /// No description provided for @onboardingGoogleBrowserHint.
  ///
  /// In en, this message translates to:
  /// **'A browser window will open for Google sign-in'**
  String get onboardingGoogleBrowserHint;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'Authorization error. Please try again.'**
  String get authError;

  /// No description provided for @authTimeout.
  ///
  /// In en, this message translates to:
  /// **'Wait time exceeded. Please try again.'**
  String get authTimeout;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @onboardingCalcAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Analyzing Data'**
  String get onboardingCalcAnalysis;

  /// No description provided for @onboardingCalcAnalysisSub.
  ///
  /// In en, this message translates to:
  /// **'Processing your parameters...'**
  String get onboardingCalcAnalysisSub;

  /// No description provided for @onboardingCalcCalories.
  ///
  /// In en, this message translates to:
  /// **'Calculating Calories'**
  String get onboardingCalcCalories;

  /// No description provided for @onboardingCalcCaloriesSub.
  ///
  /// In en, this message translates to:
  /// **'Calculating your calorie intake...'**
  String get onboardingCalcCaloriesSub;

  /// No description provided for @onboardingCalcWorkout.
  ///
  /// In en, this message translates to:
  /// **'Personalized Workout'**
  String get onboardingCalcWorkout;

  /// No description provided for @onboardingCalcWorkoutSub.
  ///
  /// In en, this message translates to:
  /// **'Creating your workout program...'**
  String get onboardingCalcWorkoutSub;

  /// No description provided for @onboardingCalcMeal.
  ///
  /// In en, this message translates to:
  /// **'Meal Plan'**
  String get onboardingCalcMeal;

  /// No description provided for @onboardingCalcMealSub.
  ///
  /// In en, this message translates to:
  /// **'Planning your weekly diet...'**
  String get onboardingCalcMealSub;

  /// No description provided for @onboardingCalcWater.
  ///
  /// In en, this message translates to:
  /// **'Water Balance'**
  String get onboardingCalcWater;

  /// No description provided for @onboardingCalcWaterSub.
  ///
  /// In en, this message translates to:
  /// **'Setting up your water intake...'**
  String get onboardingCalcWaterSub;

  /// No description provided for @onboardingCalcDone.
  ///
  /// In en, this message translates to:
  /// **'Done!'**
  String get onboardingCalcDone;

  /// No description provided for @onboardingCalcDoneSub.
  ///
  /// In en, this message translates to:
  /// **'Almost finished...'**
  String get onboardingCalcDoneSub;

  /// No description provided for @onboardingPlanReady.
  ///
  /// In en, this message translates to:
  /// **'Your personalized plan is ready!'**
  String get onboardingPlanReady;

  /// No description provided for @onboardingPlanReadyDesc.
  ///
  /// In en, this message translates to:
  /// **'We calculated the perfect balance to\nachieve your goal.'**
  String get onboardingPlanReadyDesc;

  /// No description provided for @onboardingPlanGoal.
  ///
  /// In en, this message translates to:
  /// **'DAILY INTAKE'**
  String get onboardingPlanGoal;

  /// No description provided for @onboardingPlanSpeed.
  ///
  /// In en, this message translates to:
  /// **'{speed} kg / week'**
  String onboardingPlanSpeed(Object speed);

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onboardingStart;

  /// No description provided for @onboardingGoalButton.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get onboardingGoalButton;

  /// No description provided for @onboardingDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get onboardingDone;

  /// No description provided for @stepOutOf.
  ///
  /// In en, this message translates to:
  /// **'of {total}'**
  String stepOutOf(Object total);

  /// No description provided for @cm.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get cm;

  /// No description provided for @ft.
  ///
  /// In en, this message translates to:
  /// **'feet'**
  String get ft;

  /// No description provided for @kg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kg;

  /// No description provided for @lbs.
  ///
  /// In en, this message translates to:
  /// **'lbs'**
  String get lbs;

  /// No description provided for @configErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Configuration not provided'**
  String get configErrorTitle;

  /// No description provided for @configErrorDesc.
  ///
  /// In en, this message translates to:
  /// **'Run the app with the parameter:\n\nflutter run --dart-define-from-file=env.json\n\nThe env.json file must be in the project root\nand contain SUPABASE_URL, SUPABASE_ANON_KEY,\nGEMINI_NUTRITION_API_KEY, OPENROUTER_API_KEY,\nSCANNER_API_KEY, SENTRY_DSN.'**
  String get configErrorDesc;

  /// No description provided for @accessRestricted.
  ///
  /// In en, this message translates to:
  /// **'Access Restricted'**
  String get accessRestricted;

  /// No description provided for @accessRestrictedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to enter'**
  String get accessRestrictedSubtitle;

  /// No description provided for @unlockButton.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockButton;

  /// No description provided for @progress_meas_chest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get progress_meas_chest;

  /// No description provided for @progress_meas_waist.
  ///
  /// In en, this message translates to:
  /// **'Waist'**
  String get progress_meas_waist;

  /// No description provided for @progress_meas_hips.
  ///
  /// In en, this message translates to:
  /// **'Hips'**
  String get progress_meas_hips;

  /// No description provided for @progress_meas_arm.
  ///
  /// In en, this message translates to:
  /// **'Arm'**
  String get progress_meas_arm;

  /// No description provided for @progress_meas_thigh.
  ///
  /// In en, this message translates to:
  /// **'Thigh'**
  String get progress_meas_thigh;

  /// No description provided for @progress_meas_neck.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get progress_meas_neck;

  /// No description provided for @restFinished.
  ///
  /// In en, this message translates to:
  /// **'Rest\'s over — let\'s go! 💪'**
  String get restFinished;

  /// No description provided for @repsInSet.
  ///
  /// In en, this message translates to:
  /// **'Reps in set {count}'**
  String repsInSet(Object count);

  /// No description provided for @weightInKg.
  ///
  /// In en, this message translates to:
  /// **'Weight in set {count} (kg)'**
  String weightInKg(Object count);

  /// No description provided for @exampleReps.
  ///
  /// In en, this message translates to:
  /// **'e.g.: 12'**
  String get exampleReps;

  /// No description provided for @exampleWeight.
  ///
  /// In en, this message translates to:
  /// **'e.g.: 8.5'**
  String get exampleWeight;

  /// No description provided for @replaceExercise.
  ///
  /// In en, this message translates to:
  /// **'Replace Exercise'**
  String get replaceExercise;

  /// No description provided for @alternativesForMuscle.
  ///
  /// In en, this message translates to:
  /// **'Alternatives for \"{muscle}\" muscles'**
  String alternativesForMuscle(Object muscle);

  /// No description provided for @exerciseReplaced.
  ///
  /// In en, this message translates to:
  /// **'Exercise replaced with \"{name}\"'**
  String exerciseReplaced(Object name);

  /// No description provided for @markAtLeastOneSet.
  ///
  /// In en, this message translates to:
  /// **'Mark at least one completed set ✓'**
  String get markAtLeastOneSet;

  /// No description provided for @workoutRecorded.
  ///
  /// In en, this message translates to:
  /// **'Workout recorded!'**
  String get workoutRecorded;

  /// No description provided for @sets.
  ///
  /// In en, this message translates to:
  /// **'sets'**
  String get sets;

  /// No description provided for @kgLabel.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kgLabel;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'volume'**
  String get volume;

  /// No description provided for @great.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get great;

  /// No description provided for @restTimer.
  ///
  /// In en, this message translates to:
  /// **'REST: {seconds} sec'**
  String restTimer(Object seconds);

  /// No description provided for @howToPerform.
  ///
  /// In en, this message translates to:
  /// **'How to Perform'**
  String get howToPerform;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @coachTip.
  ///
  /// In en, this message translates to:
  /// **'Coach Tip'**
  String get coachTip;

  /// No description provided for @kcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get kcal;

  /// No description provided for @repsHeader.
  ///
  /// In en, this message translates to:
  /// **'REPS'**
  String get repsHeader;

  /// No description provided for @weightHeader.
  ///
  /// In en, this message translates to:
  /// **'WEIGHT (KG)'**
  String get weightHeader;

  /// No description provided for @addSet.
  ///
  /// In en, this message translates to:
  /// **'+ Add Set'**
  String get addSet;

  /// No description provided for @saveResult.
  ///
  /// In en, this message translates to:
  /// **'SAVE RESULT'**
  String get saveResult;

  /// No description provided for @defaultTip.
  ///
  /// In en, this message translates to:
  /// **'Focus on technique, don\'t rush and rest between sets. Progress comes with consistency!'**
  String get defaultTip;

  /// No description provided for @startWithComfortableWeight.
  ///
  /// In en, this message translates to:
  /// **'💡 Start with a comfortable weight and add more when you complete all sets cleanly.'**
  String get startWithComfortableWeight;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @buildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get buildNumber;

  /// No description provided for @packageName.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get packageName;

  /// No description provided for @privacyPolicyIntro.
  ///
  /// In en, this message translates to:
  /// **'Welmi respects your privacy. This Privacy Policy explains how we collect, use, and protect your personal information.'**
  String get privacyPolicyIntro;

  /// No description provided for @privacyDataTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Data Collection'**
  String get privacyDataTitle;

  /// No description provided for @privacyDataContent.
  ///
  /// In en, this message translates to:
  /// **'We collect the following information to provide and improve our services:\n\n• Personal data: name, gender, date of birth, height, weight\n• Health data: steps, calories, water intake, weight changes\n• Usage data: app usage statistics, screen views\n• Device information: device model, operating system version\n\nHealth data is collected only with your explicit consent through Health Connect (Android) or HealthKit (iOS).'**
  String get privacyDataContent;

  /// No description provided for @privacyUsageTitle.
  ///
  /// In en, this message translates to:
  /// **'2. How We Use Data'**
  String get privacyUsageTitle;

  /// No description provided for @privacyUsageContent.
  ///
  /// In en, this message translates to:
  /// **'We use collected data to:\n\n• Generate personalized meal plans and workout programs\n• Track your progress toward health goals\n• Send reminders for water, meals, and workouts\n• Improve the quality of our AI recommendations\n• Ensure app security and prevent abuse'**
  String get privacyUsageContent;

  /// No description provided for @privacyStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Data Storage'**
  String get privacyStorageTitle;

  /// No description provided for @privacyStorageContent.
  ///
  /// In en, this message translates to:
  /// **'All data is stored securely using Supabase (PostgreSQL) with encryption at rest and in transit. Your data is associated with your account and is not accessible to third parties. Data may be stored in data centers located in various regions.'**
  String get privacyStorageContent;

  /// No description provided for @privacySharingTitle.
  ///
  /// In en, this message translates to:
  /// **'4. Data Sharing'**
  String get privacySharingTitle;

  /// No description provided for @privacySharingContent.
  ///
  /// In en, this message translates to:
  /// **'We do NOT sell, trade, or share your personal data with third parties, except:\n\n• When required by law\n• To protect the rights and safety of Welmi and its users\n• With your explicit consent\n\nWe use third-party services (Supabase, Google, Sentry) that may process data according to their own privacy policies.'**
  String get privacySharingContent;

  /// No description provided for @privacyRightsTitle.
  ///
  /// In en, this message translates to:
  /// **'5. Your Rights'**
  String get privacyRightsTitle;

  /// No description provided for @privacyRightsContent.
  ///
  /// In en, this message translates to:
  /// **'You have the right to:\n\n• View all your data in the app (Profile → Edit)\n• Request deletion of your account and all data\n• Opt out of notifications at any time\n• Disconnect Health Connect at any time\n\nTo delete your data, contact us through the Support section.'**
  String get privacyRightsContent;

  /// No description provided for @privacySecurityContent.
  ///
  /// In en, this message translates to:
  /// **'We implement industry-standard security measures:\n\n• Data encryption in transit (TLS/SSL)\n• Data encryption at rest\n• Authentication via Google OAuth\n• Row-Level Security (RLS) in the database\n\nNo method of transmission or storage is 100% secure, but we do our best to protect your information.'**
  String get privacySecurityContent;

  /// No description provided for @privacyChildrenTitle.
  ///
  /// In en, this message translates to:
  /// **'6. Children\'s Privacy'**
  String get privacyChildrenTitle;

  /// No description provided for @privacyChildrenContent.
  ///
  /// In en, this message translates to:
  /// **'Welmi is not intended for children under 13. We do not knowingly collect personal information from children under 13. If you believe we have collected such information, please contact us immediately.'**
  String get privacyChildrenContent;

  /// No description provided for @privacyChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'7. Changes to This Policy'**
  String get privacyChangesTitle;

  /// No description provided for @privacyChangesContent.
  ///
  /// In en, this message translates to:
  /// **'We may update this Privacy Policy from time to time. Changes will be posted in the app and will take effect upon publication. We recommend checking this page periodically.'**
  String get privacyChangesContent;

  /// No description provided for @privacyLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: August 2026'**
  String get privacyLastUpdated;

  /// No description provided for @contactTitle.
  ///
  /// In en, this message translates to:
  /// **'8. Contact'**
  String get contactTitle;

  /// No description provided for @privacyContactContent.
  ///
  /// In en, this message translates to:
  /// **'If you have any questions about this Privacy Policy, please contact us:\n\n• Telegram: @welmi_support\n• Email: support@welmi.app'**
  String get privacyContactContent;

  /// No description provided for @termsIntro.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Welmi. By using our application, you agree to these Terms of Use. Please read them carefully.'**
  String get termsIntro;

  /// No description provided for @termsAcceptanceTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Acceptance of Terms'**
  String get termsAcceptanceTitle;

  /// No description provided for @termsAcceptanceContent.
  ///
  /// In en, this message translates to:
  /// **'By installing and using Welmi, you agree to these Terms of Use. If you do not agree with any part of these terms, you should not use the application.'**
  String get termsAcceptanceContent;

  /// No description provided for @termsServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Description of Service'**
  String get termsServiceTitle;

  /// No description provided for @termsServiceContent.
  ///
  /// In en, this message translates to:
  /// **'Welmi is a mobile application for tracking nutrition, water intake, physical activity, and weight. The app provides:\n\n• AI-powered meal and workout plans\n• Food diary and calorie tracking\n• Water intake reminders\n• Progress analytics\n• Integration with Health Connect / HealthKit\n\nAll recommendations are informational and do not constitute medical advice.'**
  String get termsServiceContent;

  /// No description provided for @termsAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Your Account'**
  String get termsAccountTitle;

  /// No description provided for @termsAccountContent.
  ///
  /// In en, this message translates to:
  /// **'You are responsible for maintaining the confidentiality of your account. You agree to provide accurate information during registration and keep it updated. You are responsible for all activities that occur under your account.'**
  String get termsAccountContent;

  /// No description provided for @termsSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'4. Subscription and Payments'**
  String get termsSubscriptionTitle;

  /// No description provided for @termsSubscriptionContent.
  ///
  /// In en, this message translates to:
  /// **'Welmi offers a free trial period, after which a subscription is required for full access. Payment is processed through the App Store (iOS) or Google Play (Android). You can cancel your subscription at any time in your store account settings. The free trial automatically converts to a paid subscription unless canceled 24 hours before the trial ends.'**
  String get termsSubscriptionContent;

  /// No description provided for @termsContentTitle.
  ///
  /// In en, this message translates to:
  /// **'5. User Content'**
  String get termsContentTitle;

  /// No description provided for @termsContentContent.
  ///
  /// In en, this message translates to:
  /// **'You retain all rights to the data you enter into the app. We do not claim ownership of your personal data, meal entries, or workout logs. You grant us a limited license to process this data solely to provide you with the service.'**
  String get termsContentContent;

  /// No description provided for @termsProhibitedTitle.
  ///
  /// In en, this message translates to:
  /// **'6. Prohibited Actions'**
  String get termsProhibitedTitle;

  /// No description provided for @termsProhibitedContent.
  ///
  /// In en, this message translates to:
  /// **'You must NOT:\n\n• Use the app for illegal purposes\n• Attempt to hack or gain unauthorized access to the app or its servers\n• Distribute malware or harmful code\n• Misuse AI features to generate harmful content\n• Resell or redistribute the app or its content\n• Impersonate another person'**
  String get termsProhibitedContent;

  /// No description provided for @termsDisclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'7. Disclaimer'**
  String get termsDisclaimerTitle;

  /// No description provided for @termsDisclaimerContent.
  ///
  /// In en, this message translates to:
  /// **'Welmi is provided \'as is\' without warranties of any kind. We do not guarantee:\n\n• Uninterrupted or error-free operation\n• Accuracy of AI-generated recommendations\n• Compatibility with all devices\n\nWe recommend consulting a doctor before starting any diet or exercise program.'**
  String get termsDisclaimerContent;

  /// No description provided for @termsLiabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'8. Limitation of Liability'**
  String get termsLiabilityTitle;

  /// No description provided for @termsLiabilityContent.
  ///
  /// In en, this message translates to:
  /// **'Welmi and its developers are not liable for any indirect, incidental, or consequential damages arising from the use of the application, including but not limited to health issues resulting from following the app\'s recommendations.'**
  String get termsLiabilityContent;

  /// No description provided for @termsTerminationTitle.
  ///
  /// In en, this message translates to:
  /// **'9. Termination'**
  String get termsTerminationTitle;

  /// No description provided for @termsTerminationContent.
  ///
  /// In en, this message translates to:
  /// **'We reserve the right to terminate or suspend your access to the app at any time, with or without notice, for conduct that violates these Terms or is harmful to other users or the application.'**
  String get termsTerminationContent;

  /// No description provided for @termsChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'10. Changes to Terms'**
  String get termsChangesTitle;

  /// No description provided for @termsChangesContent.
  ///
  /// In en, this message translates to:
  /// **'We may modify these Terms at any time. Updated terms will be posted in the app. Continued use of the app after changes constitutes acceptance of the new terms.'**
  String get termsChangesContent;

  /// No description provided for @termsLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: August 2026'**
  String get termsLastUpdated;

  /// No description provided for @termsContactContent.
  ///
  /// In en, this message translates to:
  /// **'For questions about these Terms of Use, contact us:\n\n• Telegram: @welmi_support\n• Email: support@welmi.app'**
  String get termsContactContent;

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ky', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ky':
      return AppLocalizationsKy();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
