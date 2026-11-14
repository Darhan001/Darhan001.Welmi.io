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
  /// **'Recipes'**
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

  /// No description provided for @unitCm.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get unitCm;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @unitLb.
  ///
  /// In en, this message translates to:
  /// **'lb'**
  String get unitLb;

  /// No description provided for @unitKm.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get unitKm;

  /// No description provided for @unitMi.
  ///
  /// In en, this message translates to:
  /// **'mi'**
  String get unitMi;

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
  /// **'Recipes'**
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
  /// **'{weight} — goal'**
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

  /// No description provided for @notifOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Set up reminders'**
  String get notifOpenSettings;

  /// No description provided for @notifTurnOnHint.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications so the app can remind you about water, meals and activity.'**
  String get notifTurnOnHint;

  /// No description provided for @notifNoReminders.
  ///
  /// In en, this message translates to:
  /// **'All reminders are off'**
  String get notifNoReminders;

  /// No description provided for @notifScheduleHint.
  ///
  /// In en, this message translates to:
  /// **'Your daily reminder schedule. Tap a reminder to change its time.'**
  String get notifScheduleHint;

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
  /// **'Current Weight'**
  String get currentWeightLabel;

  /// No description provided for @targetWeight.
  ///
  /// In en, this message translates to:
  /// **'Target Weight'**
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

  /// No description provided for @weightInSet.
  ///
  /// In en, this message translates to:
  /// **'Weight in set {count} ({unit})'**
  String weightInSet(Object count, Object unit);

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

  /// No description provided for @feedbackEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a message before sending.'**
  String get feedbackEmptyMessage;

  /// No description provided for @feedbackMessageTooLong.
  ///
  /// In en, this message translates to:
  /// **'The message is too long. Maximum length is 3000 characters.'**
  String get feedbackMessageTooLong;

  /// No description provided for @feedbackSessionError.
  ///
  /// In en, this message translates to:
  /// **'Could not verify your session. Restart the app and try again.'**
  String get feedbackSessionError;

  /// No description provided for @feedbackRateLimitError.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Wait a moment and try again.'**
  String get feedbackRateLimitError;

  /// No description provided for @feedbackSendError.
  ///
  /// In en, this message translates to:
  /// **'Could not send your message. Check your connection and try again.'**
  String get feedbackSendError;

  /// No description provided for @feedbackFunctionMissing.
  ///
  /// In en, this message translates to:
  /// **'The feedback service is not deployed yet. Please try again later.'**
  String get feedbackFunctionMissing;

  /// No description provided for @feedbackSecretsMissing.
  ///
  /// In en, this message translates to:
  /// **'The feedback service is not configured. Please try again later.'**
  String get feedbackSecretsMissing;

  /// No description provided for @feedbackTelegramError.
  ///
  /// In en, this message translates to:
  /// **'Telegram could not deliver the message. Please try again later.'**
  String get feedbackTelegramError;

  /// No description provided for @feedbackFunctionError.
  ///
  /// In en, this message translates to:
  /// **'The feedback service is temporarily unavailable. Please try again later.'**
  String get feedbackFunctionError;

  /// No description provided for @feedbackNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the feedback service. Check your connection and try again.'**
  String get feedbackNetworkError;

  /// No description provided for @voiceErrorNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Voice recognition needs the internet.'**
  String get voiceErrorNoInternet;

  /// No description provided for @voiceErrorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition is unavailable right now. Please try again later.'**
  String get voiceErrorUnavailable;

  /// No description provided for @voiceErrorRecord.
  ///
  /// In en, this message translates to:
  /// **'Could not start recording. Please try again.'**
  String get voiceErrorRecord;

  /// No description provided for @voiceErrorPermissionSettings.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is denied. Allow it in your phone settings.'**
  String get voiceErrorPermissionSettings;

  /// No description provided for @ttsPlay.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get ttsPlay;

  /// No description provided for @ttsStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get ttsStop;

  /// No description provided for @ttsReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get ttsReplay;

  /// No description provided for @ttsVoiceSettings.
  ///
  /// In en, this message translates to:
  /// **'Speech voice'**
  String get ttsVoiceSettings;

  /// No description provided for @ttsVoiceDefault.
  ///
  /// In en, this message translates to:
  /// **'Default voice'**
  String get ttsVoiceDefault;

  /// No description provided for @ttsVoicesEmpty.
  ///
  /// In en, this message translates to:
  /// **'This device has no voices for this language. Install a speech engine in the system settings.'**
  String get ttsVoicesEmpty;

  /// No description provided for @ttsErrorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Speech playback is not available on this device.'**
  String get ttsErrorUnavailable;

  /// No description provided for @aiErrorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The AI assistant did not respond. Check your connection and try again.'**
  String get aiErrorUnavailable;

  /// No description provided for @voiceFoodNotRecognized.
  ///
  /// In en, this message translates to:
  /// **'Could not identify the food. Please try again.'**
  String get voiceFoodNotRecognized;

  /// No description provided for @voiceFoodAnalysisError.
  ///
  /// In en, this message translates to:
  /// **'Could not analyze the food. Please try again.'**
  String get voiceFoodAnalysisError;

  /// No description provided for @weightInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid weight'**
  String get weightInvalid;

  /// No description provided for @weightSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save your weight. Check your connection and try again.'**
  String get weightSaveError;

  /// No description provided for @weightSaved.
  ///
  /// In en, this message translates to:
  /// **'Weight saved'**
  String get weightSaved;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Check your connection and try again.'**
  String get saveError;

  /// No description provided for @signInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save your data'**
  String get signInRequired;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navScanner.
  ///
  /// In en, this message translates to:
  /// **'Food scanner'**
  String get navScanner;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @heightInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a height between 100 and 250 cm'**
  String get heightInvalid;

  /// No description provided for @voiceErrorLanguage.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition for this language is not installed. Add it in the Google voice typing settings.'**
  String get voiceErrorLanguage;

  /// No description provided for @voiceListening.
  ///
  /// In en, this message translates to:
  /// **'Speak, I am listening…'**
  String get voiceListening;

  /// No description provided for @biometricTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Welmi'**
  String get biometricTitle;

  /// No description provided for @biometricReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm your identity to open Welmi'**
  String get biometricReason;

  /// No description provided for @biometricHint.
  ///
  /// In en, this message translates to:
  /// **'Touch the fingerprint sensor'**
  String get biometricHint;

  /// No description provided for @notifClearDelivered.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get notifClearDelivered;

  /// No description provided for @notifClearedDelivered.
  ///
  /// In en, this message translates to:
  /// **'Notifications cleared. Reminders stay on.'**
  String get notifClearedDelivered;

  /// No description provided for @voiceSayAgain.
  ///
  /// In en, this message translates to:
  /// **'Say again'**
  String get voiceSayAgain;

  /// No description provided for @addToDiary.
  ///
  /// In en, this message translates to:
  /// **'Add to diary'**
  String get addToDiary;

  /// No description provided for @voiceDoneRecognize.
  ///
  /// In en, this message translates to:
  /// **'Done, recognize'**
  String get voiceDoneRecognize;

  /// No description provided for @scannerTitle.
  ///
  /// In en, this message translates to:
  /// **'AI scanner'**
  String get scannerTitle;

  /// No description provided for @scannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Meal photo → calories and macros'**
  String get scannerSubtitle;

  /// No description provided for @scannerTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of your food'**
  String get scannerTakePhoto;

  /// No description provided for @scannerHint.
  ///
  /// In en, this message translates to:
  /// **'Welmi AI will estimate calories, protein, fat and carbs'**
  String get scannerHint;

  /// No description provided for @scannerAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing photo...'**
  String get scannerAnalyzing;

  /// No description provided for @scannerNotRecognized.
  ///
  /// In en, this message translates to:
  /// **'Welmi AI couldn\'t recognize the food. Try another photo.'**
  String get scannerNotRecognized;

  /// No description provided for @scannerAiError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the AI. Check your connection.'**
  String get scannerAiError;

  /// No description provided for @scannerCameraError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the camera'**
  String get scannerCameraError;

  /// No description provided for @scannerGalleryError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the gallery'**
  String get scannerGalleryError;

  /// No description provided for @scannerRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get scannerRetake;

  /// No description provided for @scannerToDiary.
  ///
  /// In en, this message translates to:
  /// **'To diary'**
  String get scannerToDiary;

  /// No description provided for @scannerAdded.
  ///
  /// In en, this message translates to:
  /// **'Added: {kcal} kcal'**
  String scannerAdded(Object kcal);

  /// No description provided for @gramsShort.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get gramsShort;

  /// No description provided for @activityStepsToGoal.
  ///
  /// In en, this message translates to:
  /// **'{steps} steps to goal'**
  String activityStepsToGoal(Object steps);

  /// No description provided for @activityGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached! 🎉'**
  String get activityGoalReached;

  /// No description provided for @activityStepsUnit.
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get activityStepsUnit;

  /// No description provided for @activityGoalSteps.
  ///
  /// In en, this message translates to:
  /// **'{steps} steps'**
  String activityGoalSteps(Object steps);

  /// No description provided for @activityDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get activityDistance;

  /// No description provided for @activityEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get activityEnergy;

  /// No description provided for @activityGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get activityGoal;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesShort;

  /// No description provided for @activityHealthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pull steps and calories automatically'**
  String get activityHealthSubtitle;

  /// No description provided for @activitySyncShort.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get activitySyncShort;

  /// No description provided for @activityTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Tip of the day'**
  String get activityTipTitle;

  /// No description provided for @activityTipLow.
  ///
  /// In en, this message translates to:
  /// **'Move more! Try to reach at least 8,000 steps today 🚶'**
  String get activityTipLow;

  /// No description provided for @activityTipMid.
  ///
  /// In en, this message translates to:
  /// **'Good, but you can do more! Add a 15-minute walk 🌳'**
  String get activityTipMid;

  /// No description provided for @activityTipHigh.
  ///
  /// In en, this message translates to:
  /// **'Great! Almost at your goal! 💪'**
  String get activityTipHigh;

  /// No description provided for @activityTipDone.
  ///
  /// In en, this message translates to:
  /// **'Goal reached! You\'re amazing! 🎉'**
  String get activityTipDone;

  /// No description provided for @activityLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load activity. Check your connection.'**
  String get activityLoadError;

  /// No description provided for @healthInstallHint.
  ///
  /// In en, this message translates to:
  /// **'Install Health Connect to sync your steps'**
  String get healthInstallHint;

  /// No description provided for @healthSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced: {steps} steps · {kcal} kcal'**
  String healthSynced(Object kcal, Object steps);

  /// No description provided for @healthSleepSuffix.
  ///
  /// In en, this message translates to:
  /// **' · sleep {hours} h'**
  String healthSleepSuffix(Object hours);

  /// No description provided for @healthNotAuthorized.
  ///
  /// In en, this message translates to:
  /// **'Health data access was not granted'**
  String get healthNotAuthorized;

  /// No description provided for @healthUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Sync is only available on a phone'**
  String get healthUnsupported;

  /// No description provided for @healthError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get data from Health Connect'**
  String get healthError;

  /// No description provided for @historyRecentDays.
  ///
  /// In en, this message translates to:
  /// **'Recent days'**
  String get historyRecentDays;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log your steps, water or a workout'**
  String get historyEmptySubtitle;

  /// No description provided for @historyLogButton.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get historyLogButton;

  /// No description provided for @historyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load history. Check your connection.'**
  String get historyLoadError;

  /// No description provided for @waterAddedMl.
  ///
  /// In en, this message translates to:
  /// **'+{ml} ml of water'**
  String waterAddedMl(Object ml);

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @waterMlLabel.
  ///
  /// In en, this message translates to:
  /// **'ml of water'**
  String get waterMlLabel;

  /// No description provided for @historySteps30.
  ///
  /// In en, this message translates to:
  /// **'steps in 30 days'**
  String get historySteps30;

  /// No description provided for @historyWater14.
  ///
  /// In en, this message translates to:
  /// **'water in 14 days'**
  String get historyWater14;

  /// No description provided for @historyActiveDays.
  ///
  /// In en, this message translates to:
  /// **'active days'**
  String get historyActiveDays;

  /// No description provided for @litersValue.
  ///
  /// In en, this message translates to:
  /// **'{value} L'**
  String litersValue(Object value);

  /// No description provided for @weekLostValue.
  ///
  /// In en, this message translates to:
  /// **'Lost {amount}'**
  String weekLostValue(Object amount);

  /// No description provided for @weekGainedValue.
  ///
  /// In en, this message translates to:
  /// **'Gained {amount}'**
  String weekGainedValue(Object amount);

  /// No description provided for @currentWeightUnit.
  ///
  /// In en, this message translates to:
  /// **'Current weight ({unit})'**
  String currentWeightUnit(Object unit);

  /// No description provided for @weightEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No weight entries yet'**
  String get weightEmptyTitle;

  /// No description provided for @weightEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record your weight to track progress toward your goal'**
  String get weightEmptySubtitle;

  /// No description provided for @waterRemainingMl.
  ///
  /// In en, this message translates to:
  /// **'{ml} ml left'**
  String waterRemainingMl(Object ml);

  /// No description provided for @waterOfGoal.
  ///
  /// In en, this message translates to:
  /// **'of {goal} ml'**
  String waterOfGoal(Object goal);

  /// No description provided for @mlValue.
  ///
  /// In en, this message translates to:
  /// **'{ml} ml'**
  String mlValue(Object ml);

  /// No description provided for @waterWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'Water this week'**
  String get waterWeekTitle;

  /// No description provided for @waterDrunk.
  ///
  /// In en, this message translates to:
  /// **'Drunk today'**
  String get waterDrunk;

  /// No description provided for @feedbackCategoryBug.
  ///
  /// In en, this message translates to:
  /// **'Bug'**
  String get feedbackCategoryBug;

  /// No description provided for @feedbackCategoryIdea.
  ///
  /// In en, this message translates to:
  /// **'Idea'**
  String get feedbackCategoryIdea;

  /// No description provided for @supportOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the app. Contact us: {contact}'**
  String supportOpenFailed(Object contact);

  /// No description provided for @authGoogleSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get authGoogleSigningIn;

  /// No description provided for @authGoogleBrowserHint.
  ///
  /// In en, this message translates to:
  /// **'A browser window will open to sign in with Google'**
  String get authGoogleBrowserHint;

  /// No description provided for @authAlmostDone.
  ///
  /// In en, this message translates to:
  /// **'Almost done!'**
  String get authAlmostDone;

  /// No description provided for @authGoogleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google to save your progress'**
  String get authGoogleSubtitle;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in with Google. Please try again later.'**
  String get authGoogleFailed;

  /// No description provided for @recipeSignInToAdd.
  ///
  /// In en, this message translates to:
  /// **'Sign in to add the dish to your diary'**
  String get recipeSignInToAdd;

  /// No description provided for @recipeAddedToMeal.
  ///
  /// In en, this message translates to:
  /// **'Recipe added to “{meal}”'**
  String recipeAddedToMeal(String meal);

  /// No description provided for @recipeAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add the recipe. Check your connection.'**
  String get recipeAddFailed;

  /// No description provided for @recipeServingInfo.
  ///
  /// In en, this message translates to:
  /// **'1 serving · Welmi recipe'**
  String get recipeServingInfo;

  /// No description provided for @offErrRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Open Food Facts is limiting requests. Wait a minute and try again.'**
  String get offErrRateLimited;

  /// No description provided for @offErrTimeout.
  ///
  /// In en, this message translates to:
  /// **'Open Food Facts did not respond in time. Check your connection and try again.'**
  String get offErrTimeout;

  /// No description provided for @offErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach Open Food Facts. Check your connection and try again.'**
  String get offErrNetwork;

  /// No description provided for @offErrRequest.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load data from Open Food Facts. Please try again.'**
  String get offErrRequest;

  /// No description provided for @offErrUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Open Food Facts is temporarily unavailable (code {code}).'**
  String offErrUnavailable(Object code);

  /// No description provided for @offErrBadResponse.
  ///
  /// In en, this message translates to:
  /// **'Open Food Facts returned an invalid response. Try again later.'**
  String get offErrBadResponse;

  /// No description provided for @offErrTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Try again in {seconds} s.'**
  String offErrTooMany(Object seconds);

  /// No description provided for @foodDbSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed. Check your connection and try again.'**
  String get foodDbSearchFailed;

  /// No description provided for @foodDbTitle.
  ///
  /// In en, this message translates to:
  /// **'Food database'**
  String get foodDbTitle;

  /// No description provided for @foodDbSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open Food Facts · values per 100 g'**
  String get foodDbSubtitle;

  /// No description provided for @foodDbSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Name or barcode'**
  String get foodDbSearchHint;

  /// No description provided for @clearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearAction;

  /// No description provided for @foodDbScanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get foodDbScanBarcode;

  /// No description provided for @foodDbFound.
  ///
  /// In en, this message translates to:
  /// **'Found: {count}'**
  String foodDbFound(Object count);

  /// No description provided for @foodDbStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Find a product by name'**
  String get foodDbStartTitle;

  /// No description provided for @foodDbStartBody.
  ///
  /// In en, this message translates to:
  /// **'Or scan the barcode on the package. Nutrition is recalculated for your portion.'**
  String get foodDbStartBody;

  /// No description provided for @foodDbStartFootnote.
  ///
  /// In en, this message translates to:
  /// **'The data is community-contributed and may be incomplete — we show “—” when a value is missing.'**
  String get foodDbStartFootnote;

  /// No description provided for @foodDbNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get foodDbNotFoundTitle;

  /// No description provided for @foodDbNothingFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get foodDbNothingFoundTitle;

  /// No description provided for @foodDbNotFoundBarcodeBody.
  ///
  /// In en, this message translates to:
  /// **'This barcode isn\'t in Open Food Facts. Check the digits or add the product manually.'**
  String get foodDbNotFoundBarcodeBody;

  /// No description provided for @foodDbNothingFoundBody.
  ///
  /// In en, this message translates to:
  /// **'Check the name or scan the barcode. You can also add the product manually in the diary.'**
  String get foodDbNothingFoundBody;

  /// No description provided for @foodDbSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching Open Food Facts...'**
  String get foodDbSearching;

  /// No description provided for @foodNoNutritionData.
  ///
  /// In en, this message translates to:
  /// **'No nutrition data'**
  String get foodNoNutritionData;

  /// No description provided for @foodCaloriesOnly.
  ///
  /// In en, this message translates to:
  /// **'Calories only, no macros'**
  String get foodCaloriesOnly;

  /// No description provided for @foodKcalPer100.
  ///
  /// In en, this message translates to:
  /// **'kcal / 100 g'**
  String get foodKcalPer100;

  /// No description provided for @macroProteinShort.
  ///
  /// In en, this message translates to:
  /// **'P'**
  String get macroProteinShort;

  /// No description provided for @macroFatShort.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get macroFatShort;

  /// No description provided for @macroCarbsShort.
  ///
  /// In en, this message translates to:
  /// **'C'**
  String get macroCarbsShort;

  /// No description provided for @foodPer100NoData.
  ///
  /// In en, this message translates to:
  /// **'Nutrition: no data'**
  String get foodPer100NoData;

  /// No description provided for @foodPer100.
  ///
  /// In en, this message translates to:
  /// **'Per 100 g: {values}'**
  String foodPer100(Object values);

  /// No description provided for @foodKcalEstimatedNote.
  ///
  /// In en, this message translates to:
  /// **'Calories are estimated from macros: the database has no value.'**
  String get foodKcalEstimatedNote;

  /// No description provided for @foodMacrosIncompleteNote.
  ///
  /// In en, this message translates to:
  /// **'Not all nutrients are filled in — “—” means no data.'**
  String get foodMacrosIncompleteNote;

  /// No description provided for @nutrientProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get nutrientProtein;

  /// No description provided for @nutrientFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get nutrientFat;

  /// No description provided for @nutrientCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get nutrientCarbs;

  /// No description provided for @nutrientCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get nutrientCalories;

  /// No description provided for @foodNoNutritionCard.
  ///
  /// In en, this message translates to:
  /// **'Open Food Facts has no nutrition data for this product. Add the entry manually from the diary.'**
  String get foodNoNutritionCard;

  /// No description provided for @foodServingPrefix.
  ///
  /// In en, this message translates to:
  /// **'serving {size}'**
  String foodServingPrefix(Object size);

  /// No description provided for @torchFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t turn on the flashlight'**
  String get torchFailed;

  /// No description provided for @barcodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'No product with barcode {barcode} was found in Open Food Facts. Check the package or add the entry manually.'**
  String barcodeNotFound(Object barcode);

  /// No description provided for @barcodeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the product. Check your connection and try again.'**
  String get barcodeLoadFailed;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @barcodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcodeTitle;

  /// No description provided for @barcodeAimHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the package'**
  String get barcodeAimHint;

  /// No description provided for @torch.
  ///
  /// In en, this message translates to:
  /// **'Flashlight'**
  String get torch;

  /// No description provided for @barcodeScanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get barcodeScanAgain;

  /// No description provided for @barcodeFormatsNote.
  ///
  /// In en, this message translates to:
  /// **'Supports EAN-8, EAN-13, UPC-A, UPC-E and Code 128.\nData: Open Food Facts.'**
  String get barcodeFormatsNote;

  /// No description provided for @barcodeLookingUp.
  ///
  /// In en, this message translates to:
  /// **'Looking up the product...'**
  String get barcodeLookingUp;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable'**
  String get cameraUnavailable;

  /// No description provided for @cameraUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access in your phone settings or type the barcode into the search field.'**
  String get cameraUnavailableHint;

  /// No description provided for @foodNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'The name can\'t be empty.'**
  String get foodNameEmpty;

  /// No description provided for @foodKcalInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter calories as a whole number.'**
  String get foodKcalInvalid;

  /// No description provided for @foodGramsRange.
  ///
  /// In en, this message translates to:
  /// **'Portion weight must be between 1 and 5000 g.'**
  String get foodGramsRange;

  /// No description provided for @foodEditEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get foodEditEntry;

  /// No description provided for @foodPortionWeightG.
  ///
  /// In en, this message translates to:
  /// **'Portion weight, g'**
  String get foodPortionWeightG;

  /// No description provided for @foodRecalcNote.
  ///
  /// In en, this message translates to:
  /// **'Calories and macros are recalculated automatically when the weight changes.'**
  String get foodRecalcNote;

  /// No description provided for @nutrientProteinG.
  ///
  /// In en, this message translates to:
  /// **'Protein, g'**
  String get nutrientProteinG;

  /// No description provided for @nutrientFatG.
  ///
  /// In en, this message translates to:
  /// **'Fat, g'**
  String get nutrientFatG;

  /// No description provided for @nutrientCarbsG.
  ///
  /// In en, this message translates to:
  /// **'Carbs, g'**
  String get nutrientCarbsG;

  /// No description provided for @foodPortionTitle.
  ///
  /// In en, this message translates to:
  /// **'Portion'**
  String get foodPortionTitle;

  /// No description provided for @foodPortionWeight.
  ///
  /// In en, this message translates to:
  /// **'Portion weight'**
  String get foodPortionWeight;

  /// No description provided for @foodEnterGramsRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a portion weight between 1 and 5000 g.'**
  String get foodEnterGramsRange;

  /// No description provided for @foodNoCaloriesCantSave.
  ///
  /// In en, this message translates to:
  /// **'The database has no calories for this product, so the entry can\'t be saved.'**
  String get foodNoCaloriesCantSave;

  /// No description provided for @gramsValue.
  ///
  /// In en, this message translates to:
  /// **'{value} g'**
  String gramsValue(Object value);

  /// No description provided for @foodEnterGramsToSee.
  ///
  /// In en, this message translates to:
  /// **'Enter the weight to see the calculation.'**
  String get foodEnterGramsToSee;

  /// No description provided for @foodDataSource.
  ///
  /// In en, this message translates to:
  /// **'Data: Open Food Facts (open database)'**
  String get foodDataSource;

  /// No description provided for @diaryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load data'**
  String get diaryLoadError;

  /// No description provided for @diaryEntryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Entry updated'**
  String get diaryEntryUpdated;

  /// No description provided for @diaryEntryUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the entry'**
  String get diaryEntryUpdateFailed;

  /// No description provided for @diaryDeleteEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete entry?'**
  String get diaryDeleteEntryTitle;

  /// No description provided for @diaryDeleteEntryBody.
  ///
  /// In en, this message translates to:
  /// **'The entry will be removed from the diary.'**
  String get diaryDeleteEntryBody;

  /// No description provided for @diaryDeleteNamedBody.
  ///
  /// In en, this message translates to:
  /// **'“{name}” will be removed from the diary.'**
  String diaryDeleteNamedBody(Object name);

  /// No description provided for @diaryEntryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Entry deleted'**
  String get diaryEntryDeleted;

  /// No description provided for @diaryEntryDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the entry'**
  String get diaryEntryDeleteFailed;

  /// No description provided for @diaryAddByVoice.
  ///
  /// In en, this message translates to:
  /// **'Add by voice'**
  String get diaryAddByVoice;

  /// No description provided for @diaryVoiceShort.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get diaryVoiceShort;

  /// No description provided for @diaryFindInDatabase.
  ///
  /// In en, this message translates to:
  /// **'Find a product in Open Food Facts'**
  String get diaryFindInDatabase;

  /// No description provided for @diaryDatabaseShort.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get diaryDatabaseShort;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @voiceFoodClarifyFirst.
  ///
  /// In en, this message translates to:
  /// **'Specify the amount to get an approximate estimate.'**
  String get voiceFoodClarifyFirst;

  /// No description provided for @voiceFoodGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong during recognition'**
  String get voiceFoodGenericError;

  /// No description provided for @kcalApprox.
  ///
  /// In en, this message translates to:
  /// **'~{kcal} kcal'**
  String kcalApprox(Object kcal);

  /// No description provided for @kcalValue.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal'**
  String kcalValue(Object kcal);

  /// No description provided for @voiceFoodClarifyHint.
  ///
  /// In en, this message translates to:
  /// **'For example: 150 grams'**
  String get voiceFoodClarifyHint;

  /// No description provided for @voiceFoodClarify.
  ///
  /// In en, this message translates to:
  /// **'Clarify'**
  String get voiceFoodClarify;

  /// No description provided for @voiceFoodListening.
  ///
  /// In en, this message translates to:
  /// **'Listening... ({time})'**
  String voiceFoodListening(Object time);

  /// No description provided for @voiceFoodExample.
  ///
  /// In en, this message translates to:
  /// **'For example: “Two eggs, two slices of bread and a banana”'**
  String get voiceFoodExample;

  /// No description provided for @voiceFoodAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'AI is analyzing the food...'**
  String get voiceFoodAnalyzing;

  /// No description provided for @voiceFoodRecognized.
  ///
  /// In en, this message translates to:
  /// **'Recognized:'**
  String get voiceFoodRecognized;

  /// No description provided for @voiceFoodEstimate.
  ///
  /// In en, this message translates to:
  /// **'Approximate estimate:'**
  String get voiceFoodEstimate;

  /// No description provided for @voiceFoodHideEdit.
  ///
  /// In en, this message translates to:
  /// **'Hide editing'**
  String get voiceFoodHideEdit;

  /// No description provided for @voiceFoodEditData.
  ///
  /// In en, this message translates to:
  /// **'Edit values'**
  String get voiceFoodEditData;

  /// No description provided for @voiceFoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice input: {meal}'**
  String voiceFoodTitle(Object meal);

  /// No description provided for @voiceFoodSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Say the dish and the amount'**
  String get voiceFoodSubtitle;

  /// No description provided for @homeDiarySummary.
  ///
  /// In en, this message translates to:
  /// **'{consumed} of {goal} kcal · {protein} g protein'**
  String homeDiarySummary(Object consumed, Object goal, Object protein);

  /// No description provided for @bfEstimateTitle.
  ///
  /// In en, this message translates to:
  /// **'Body fat estimate'**
  String get bfEstimateTitle;

  /// No description provided for @bfEstimateNoData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data for the calculation.\n\nRequired: height and sex in your profile, plus waist and neck measurements (and hips for women). Add measurements and try again.'**
  String get bfEstimateNoData;

  /// No description provided for @bfEstimateMethodMale.
  ///
  /// In en, this message translates to:
  /// **'Calculated with the U.S. Navy method from waist and neck circumference and height.\n\nThis is an approximate estimate, not a measurement. The method\'s error is several percentage points.'**
  String get bfEstimateMethodMale;

  /// No description provided for @bfEstimateMethodFemale.
  ///
  /// In en, this message translates to:
  /// **'Calculated with the U.S. Navy method from waist, neck and hip circumference and height.\n\nThis is an approximate estimate, not a measurement. The method\'s error is several percentage points.'**
  String get bfEstimateMethodFemale;

  /// No description provided for @bfCatExtremelyLow.
  ///
  /// In en, this message translates to:
  /// **'⚡ Extremely low'**
  String get bfCatExtremelyLow;

  /// No description provided for @bfCatAthletic.
  ///
  /// In en, this message translates to:
  /// **'💪 Athletic'**
  String get bfCatAthletic;

  /// No description provided for @bfCatNormal.
  ///
  /// In en, this message translates to:
  /// **'✅ Normal'**
  String get bfCatNormal;

  /// No description provided for @bfCatAboveNormal.
  ///
  /// In en, this message translates to:
  /// **'📈 Above normal'**
  String get bfCatAboveNormal;

  /// No description provided for @bfCatHigh.
  ///
  /// In en, this message translates to:
  /// **'⚠️ High'**
  String get bfCatHigh;

  /// No description provided for @bfHeaderCaps.
  ///
  /// In en, this message translates to:
  /// **'BODY FAT %'**
  String get bfHeaderCaps;

  /// No description provided for @progressLast28Days.
  ///
  /// In en, this message translates to:
  /// **'Last 28 days'**
  String get progressLast28Days;

  /// No description provided for @legendHasEntry.
  ///
  /// In en, this message translates to:
  /// **'has entry'**
  String get legendHasEntry;

  /// No description provided for @legendToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get legendToday;

  /// No description provided for @legendTapDay.
  ///
  /// In en, this message translates to:
  /// **'tap a day'**
  String get legendTapDay;

  /// No description provided for @bfMethodCaliper.
  ///
  /// In en, this message translates to:
  /// **'caliper'**
  String get bfMethodCaliper;

  /// No description provided for @bfMethodScale.
  ///
  /// In en, this message translates to:
  /// **'scale'**
  String get bfMethodScale;

  /// No description provided for @bfMethodEstimated.
  ///
  /// In en, this message translates to:
  /// **'estimate'**
  String get bfMethodEstimated;

  /// No description provided for @bfMethodManual.
  ///
  /// In en, this message translates to:
  /// **'manual'**
  String get bfMethodManual;

  /// No description provided for @bfEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No body fat data yet'**
  String get bfEmptyTitle;

  /// No description provided for @bfEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log your body fat percentage to track changes'**
  String get bfEmptySubtitle;

  /// No description provided for @bfDynamics.
  ///
  /// In en, this message translates to:
  /// **'Body fat trend'**
  String get bfDynamics;

  /// No description provided for @bfNoEntriesInPeriod.
  ///
  /// In en, this message translates to:
  /// **'No body fat entries in the selected period'**
  String get bfNoEntriesInPeriod;

  /// No description provided for @bfEstimateDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'An estimate from measurements — not a medical measurement.'**
  String get bfEstimateDisclaimer;

  /// No description provided for @bfEstimateFromMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Estimate from measurements'**
  String get bfEstimateFromMeasurements;

  /// No description provided for @historyLabel.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyLabel;

  /// No description provided for @progressNoEntriesDay.
  ///
  /// In en, this message translates to:
  /// **'No entries for this day.'**
  String get progressNoEntriesDay;

  /// No description provided for @bfEstimatedSuffix.
  ///
  /// In en, this message translates to:
  /// **'{label} (estimate)'**
  String bfEstimatedSuffix(Object label);

  /// No description provided for @chartNeedTwoEntries.
  ///
  /// In en, this message translates to:
  /// **'At least 2 entries are needed in the selected period\n({count} of 2)'**
  String chartNeedTwoEntries(Object count);

  /// No description provided for @measEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No measurements yet'**
  String get measEmptyTitle;

  /// No description provided for @measEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log your chest, waist, hips and arm measurements'**
  String get measEmptySubtitle;

  /// No description provided for @measLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest measurements'**
  String get measLatest;

  /// No description provided for @measDynamics.
  ///
  /// In en, this message translates to:
  /// **'Measurements trend'**
  String get measDynamics;

  /// No description provided for @measNoEntriesInPeriod.
  ///
  /// In en, this message translates to:
  /// **'No “{metric}” measurements in the selected period'**
  String measNoEntriesInPeriod(Object metric);

  /// No description provided for @currentWeightCaps.
  ///
  /// In en, this message translates to:
  /// **'CURRENT WEIGHT'**
  String get currentWeightCaps;

  /// No description provided for @bfChipCaliper.
  ///
  /// In en, this message translates to:
  /// **'Caliper'**
  String get bfChipCaliper;

  /// No description provided for @bfChipScale.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get bfChipScale;

  /// No description provided for @bfChipManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get bfChipManual;

  /// No description provided for @bfRangeError.
  ///
  /// In en, this message translates to:
  /// **'Enter a body fat value between 2 and 70%'**
  String get bfRangeError;

  /// No description provided for @bfEstimateSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved as an estimated value'**
  String get bfEstimateSaved;

  /// No description provided for @progressEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show yet'**
  String get progressEmptyTitle;

  /// No description provided for @progressEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start logging weight, measurements and body fat\nto see your progress'**
  String get progressEmptySubtitle;

  /// No description provided for @progressRecordFirstWeight.
  ///
  /// In en, this message translates to:
  /// **'Log your first weight'**
  String get progressRecordFirstWeight;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String daysCount(Object days);

  /// No description provided for @progressActivityOfEntries.
  ///
  /// In en, this message translates to:
  /// **'Logging activity'**
  String get progressActivityOfEntries;

  /// No description provided for @workoutGeneralFocus.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get workoutGeneralFocus;

  /// No description provided for @premiumGateTitle.
  ///
  /// In en, this message translates to:
  /// **'This feature is available in Welmi Premium'**
  String get premiumGateTitle;

  /// No description provided for @premiumGateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Access is checked against a verified store subscription.'**
  String get premiumGateSubtitle;

  /// No description provided for @premiumGateButton.
  ///
  /// In en, this message translates to:
  /// **'View Premium'**
  String get premiumGateButton;

  /// No description provided for @profileBmrTdee.
  ///
  /// In en, this message translates to:
  /// **'BMR {bmr} kcal · TDEE {tdee} kcal'**
  String profileBmrTdee(Object bmr, Object tdee);

  /// No description provided for @unsavedChangesBody.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. They will be lost.'**
  String get unsavedChangesBody;

  /// No description provided for @stayAction.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stayAction;

  /// No description provided for @leaveAction.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaveAction;

  /// No description provided for @profileUserUnknown.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t identify the user'**
  String get profileUserUnknown;

  /// No description provided for @profilePhotoNotUploaded.
  ///
  /// In en, this message translates to:
  /// **'The photo didn\'t upload'**
  String get profilePhotoNotUploaded;

  /// No description provided for @profileSavedWithWarning.
  ///
  /// In en, this message translates to:
  /// **'Profile saved. {warning}'**
  String profileSavedWithWarning(Object warning);

  /// No description provided for @profileLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading profile...'**
  String get profileLoading;

  /// No description provided for @profileMyProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get profileMyProfile;

  /// No description provided for @profileWeightGoal.
  ///
  /// In en, this message translates to:
  /// **'Weight goal'**
  String get profileWeightGoal;

  /// No description provided for @profileCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get profileCurrent;

  /// No description provided for @profileLeftToLose.
  ///
  /// In en, this message translates to:
  /// **'Left to lose'**
  String get profileLeftToLose;

  /// No description provided for @profileLeftToGain.
  ///
  /// In en, this message translates to:
  /// **'Left to gain'**
  String get profileLeftToGain;

  /// No description provided for @profileTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get profileTarget;

  /// No description provided for @subscriptionActiveShort.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get subscriptionActiveShort;

  /// No description provided for @subscriptionChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get subscriptionChoose;

  /// No description provided for @subManage.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get subManage;

  /// No description provided for @subActiveMessage.
  ///
  /// In en, this message translates to:
  /// **'Subscription is active.'**
  String get subActiveMessage;

  /// No description provided for @subOfferUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Offer unavailable'**
  String get subOfferUnavailable;

  /// No description provided for @subContinuePrice.
  ///
  /// In en, this message translates to:
  /// **'Continue · {price}'**
  String subContinuePrice(Object price);

  /// No description provided for @subRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get subRestore;

  /// No description provided for @subRefreshOffers.
  ///
  /// In en, this message translates to:
  /// **'Refresh offers'**
  String get subRefreshOffers;

  /// No description provided for @subTermsNote.
  ///
  /// In en, this message translates to:
  /// **'Payment and subscription terms are shown by the store before you confirm the purchase. You can manage auto-renewal in the store settings.'**
  String get subTermsNote;

  /// No description provided for @subHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'More ways to take care of yourself'**
  String get subHeroSubtitle;

  /// No description provided for @subInPremium.
  ///
  /// In en, this message translates to:
  /// **'In Premium'**
  String get subInPremium;

  /// No description provided for @subFeatureScanner.
  ///
  /// In en, this message translates to:
  /// **'Smart food scanner'**
  String get subFeatureScanner;

  /// No description provided for @subFeatureWorkouts.
  ///
  /// In en, this message translates to:
  /// **'AI workout plans'**
  String get subFeatureWorkouts;

  /// No description provided for @subFeatureAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Detailed analytics and measurements'**
  String get subFeatureAnalytics;

  /// No description provided for @subFeatureHealth.
  ///
  /// In en, this message translates to:
  /// **'Health Connect sync'**
  String get subFeatureHealth;

  /// No description provided for @subFeatureNoAds.
  ///
  /// In en, this message translates to:
  /// **'No ads'**
  String get subFeatureNoAds;

  /// No description provided for @subPlanMonth.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get subPlanMonth;

  /// No description provided for @subPlanYear.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get subPlanYear;

  /// No description provided for @subPremiumActive.
  ///
  /// In en, this message translates to:
  /// **'Premium is active'**
  String get subPremiumActive;

  /// No description provided for @subValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String subValidUntil(Object date);

  /// No description provided for @subErrStore.
  ///
  /// In en, this message translates to:
  /// **'Store error. Please try again.'**
  String get subErrStore;

  /// No description provided for @subErrStoreUnavailableDevice.
  ///
  /// In en, this message translates to:
  /// **'The store is not available on this device.'**
  String get subErrStoreUnavailableDevice;

  /// No description provided for @subErrStoreUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The store is currently unavailable.'**
  String get subErrStoreUnavailable;

  /// No description provided for @subErrProductsMissing.
  ///
  /// In en, this message translates to:
  /// **'Plans are not available in the store yet. Try again later.'**
  String get subErrProductsMissing;

  /// No description provided for @subErrProductsLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load store offers.'**
  String get subErrProductsLoad;

  /// No description provided for @subErrEntitlement.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check Premium status.'**
  String get subErrEntitlement;

  /// No description provided for @subErrPlanNotFound.
  ///
  /// In en, this message translates to:
  /// **'The plan was not found in the store.'**
  String get subErrPlanNotFound;

  /// No description provided for @subErrSignInToSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your Welmi account to subscribe.'**
  String get subErrSignInToSubscribe;

  /// No description provided for @subErrPurchaseNotStarted.
  ///
  /// In en, this message translates to:
  /// **'The store didn\'t start the purchase. Please try again.'**
  String get subErrPurchaseNotStarted;

  /// No description provided for @subErrPurchaseStart.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the purchase.'**
  String get subErrPurchaseStart;

  /// No description provided for @subErrSignInToRestore.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Welmi to restore your subscription.'**
  String get subErrSignInToRestore;

  /// No description provided for @subErrRestore.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t restore purchases.'**
  String get subErrRestore;

  /// No description provided for @subErrManageUnsupported.
  ///
  /// In en, this message translates to:
  /// **'You can manage the subscription on a device with the App Store or Google Play.'**
  String get subErrManageUnsupported;

  /// No description provided for @subErrManageOpen.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open subscription management.'**
  String get subErrManageOpen;

  /// No description provided for @subErrPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'The store didn\'t complete the purchase.'**
  String get subErrPurchaseFailed;

  /// No description provided for @subErrVerification.
  ///
  /// In en, this message translates to:
  /// **'The purchase was received, but server verification didn\'t finish. Tap “Restore purchases” a bit later.'**
  String get subErrVerification;

  /// No description provided for @subNoticeNoActive.
  ///
  /// In en, this message translates to:
  /// **'No active subscription found.'**
  String get subNoticeNoActive;

  /// No description provided for @subNoticeCancelled.
  ///
  /// In en, this message translates to:
  /// **'Purchase cancelled.'**
  String get subNoticeCancelled;

  /// No description provided for @subNoticeActivated.
  ///
  /// In en, this message translates to:
  /// **'Welmi Premium is activated.'**
  String get subNoticeActivated;

  /// No description provided for @calcStatusAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your data...'**
  String get calcStatusAnalyzing;

  /// No description provided for @calcStatusMetabolism.
  ///
  /// In en, this message translates to:
  /// **'Calculating metabolism...'**
  String get calcStatusMetabolism;

  /// No description provided for @calcStatusMacros.
  ///
  /// In en, this message translates to:
  /// **'Calculating calories and macros...'**
  String get calcStatusMacros;

  /// No description provided for @calcStatusPersonalReady.
  ///
  /// In en, this message translates to:
  /// **'Your personal plan is ready! ✅'**
  String get calcStatusPersonalReady;

  /// No description provided for @calcStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Your plan is ready! ✅'**
  String get calcStatusReady;

  /// No description provided for @calcProteinShort.
  ///
  /// In en, this message translates to:
  /// **'protein'**
  String get calcProteinShort;

  /// No description provided for @calcFatShort.
  ///
  /// In en, this message translates to:
  /// **'fat'**
  String get calcFatShort;

  /// No description provided for @calcCarbsShort.
  ///
  /// In en, this message translates to:
  /// **'carbs'**
  String get calcCarbsShort;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language / Тил'**
  String get languageLabel;

  /// No description provided for @perDaySuffix.
  ///
  /// In en, this message translates to:
  /// **'/day'**
  String get perDaySuffix;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Your path to health'**
  String get splashTagline;

  /// No description provided for @model3dTimeout.
  ///
  /// In en, this message translates to:
  /// **'The model took too long to load'**
  String get model3dTimeout;

  /// No description provided for @model3dRotateHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to rotate the model'**
  String get model3dRotateHint;

  /// No description provided for @model3dFailed.
  ///
  /// In en, this message translates to:
  /// **'The 3D model didn\'t load'**
  String get model3dFailed;

  /// No description provided for @model3dFailedReason.
  ///
  /// In en, this message translates to:
  /// **'3D model: {reason}'**
  String model3dFailedReason(Object reason);

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @rangeLastDaysShort.
  ///
  /// In en, this message translates to:
  /// **'last {days} d'**
  String rangeLastDaysShort(Object days);

  /// No description provided for @filtersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTitle;

  /// No description provided for @recipeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Find a dish or ingredient'**
  String get recipeSearchHint;

  /// No description provided for @recipePopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get recipePopular;

  /// No description provided for @recipeResults.
  ///
  /// In en, this message translates to:
  /// **'Results · {count}'**
  String recipeResults(Object count);

  /// No description provided for @resetAction.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetAction;

  /// No description provided for @recipeFilterProteinFrom.
  ///
  /// In en, this message translates to:
  /// **'Protein from'**
  String get recipeFilterProteinFrom;

  /// No description provided for @recipeFilterTimeUpTo.
  ///
  /// In en, this message translates to:
  /// **'Time up to'**
  String get recipeFilterTimeUpTo;

  /// No description provided for @recipeFilterDiet.
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get recipeFilterDiet;

  /// No description provided for @recipeDietVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get recipeDietVegetarian;

  /// No description provided for @recipeDietSugarFree.
  ///
  /// In en, this message translates to:
  /// **'Sugar-free'**
  String get recipeDietSugarFree;

  /// No description provided for @showAction.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get showAction;

  /// No description provided for @anyOption.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get anyOption;

  /// No description provided for @filterUpToKcal.
  ///
  /// In en, this message translates to:
  /// **'Up to {value} kcal'**
  String filterUpToKcal(Object value);

  /// No description provided for @filterFromGrams.
  ///
  /// In en, this message translates to:
  /// **'From {value} g'**
  String filterFromGrams(Object value);

  /// No description provided for @filterUpToMinutes.
  ///
  /// In en, this message translates to:
  /// **'Up to {value} min'**
  String filterUpToMinutes(Object value);

  /// No description provided for @recipeMetaWeight.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min · {grams} g'**
  String recipeMetaWeight(Object grams, Object minutes);

  /// No description provided for @recipeMetaProtein.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min · P {protein} g'**
  String recipeMetaProtein(Object minutes, Object protein);

  /// No description provided for @favoriteRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get favoriteRemove;

  /// No description provided for @favoriteAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get favoriteAdd;

  /// No description provided for @recipeNothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found.\nTry changing the search or filters.'**
  String get recipeNothingFound;

  /// No description provided for @recipesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Recipes are coming soon.'**
  String get recipesComingSoon;

  /// No description provided for @recipeNoPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'No photo: {label}'**
  String recipeNoPhotoLabel(Object label);

  /// No description provided for @recipePhotoSoon.
  ///
  /// In en, this message translates to:
  /// **'Photo coming soon'**
  String get recipePhotoSoon;

  /// No description provided for @recipeAddToMeal.
  ///
  /// In en, this message translates to:
  /// **'Add to a meal'**
  String get recipeAddToMeal;

  /// No description provided for @recipeBonAppetit.
  ///
  /// In en, this message translates to:
  /// **'Enjoy your meal!'**
  String get recipeBonAppetit;

  /// No description provided for @recipePhotoCredit.
  ///
  /// In en, this message translates to:
  /// **'Photo: {credit}'**
  String recipePhotoCredit(Object credit);

  /// No description provided for @recipeStep.
  ///
  /// In en, this message translates to:
  /// **'Step {step}'**
  String recipeStep(Object step);

  /// No description provided for @recipeCook.
  ///
  /// In en, this message translates to:
  /// **'Cook'**
  String get recipeCook;

  /// No description provided for @recipeAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get recipeAsk;

  /// No description provided for @recipeAskPrompt.
  ///
  /// In en, this message translates to:
  /// **'I\'m cooking “{title}” ({kcal} kcal, P {protein} g, F {fat} g, C {carbs} g). Tell me:'**
  String recipeAskPrompt(
    Object carbs,
    Object fat,
    Object kcal,
    Object protein,
    Object title,
  );

  /// No description provided for @recipeNutritionTitle.
  ///
  /// In en, this message translates to:
  /// **'Calories and nutrients'**
  String get recipeNutritionTitle;

  /// No description provided for @recipeMicros.
  ///
  /// In en, this message translates to:
  /// **'Fiber {fiber} g · Sugar {sugar} g · Sodium {sodium} mg'**
  String recipeMicros(Object fiber, Object sodium, Object sugar);

  /// No description provided for @recipeNutritionDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Calories and macros are estimates per serving based on the ingredients. TheMealDB does not publish nutrition data.'**
  String get recipeNutritionDisclaimer;

  /// No description provided for @recipeIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients · servings: {servings}'**
  String recipeIngredients(Object servings);

  /// No description provided for @recipeCooking.
  ///
  /// In en, this message translates to:
  /// **'Preparation'**
  String get recipeCooking;

  /// No description provided for @recipeStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String recipeStepOf(Object step, Object total);

  /// No description provided for @recipeFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get recipeFinish;

  /// No description provided for @recipeNextStep.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get recipeNextStep;

  /// No description provided for @notifChannelWater.
  ///
  /// In en, this message translates to:
  /// **'Welmi · Water'**
  String get notifChannelWater;

  /// No description provided for @notifChannelWaterDesc.
  ///
  /// In en, this message translates to:
  /// **'Water reminders'**
  String get notifChannelWaterDesc;

  /// No description provided for @notifChannelMeals.
  ///
  /// In en, this message translates to:
  /// **'Welmi · Meals'**
  String get notifChannelMeals;

  /// No description provided for @notifChannelMealsDesc.
  ///
  /// In en, this message translates to:
  /// **'Breakfast, lunch and dinner'**
  String get notifChannelMealsDesc;

  /// No description provided for @notifChannelActivity.
  ///
  /// In en, this message translates to:
  /// **'Welmi · Activity'**
  String get notifChannelActivity;

  /// No description provided for @notifChannelActivityDesc.
  ///
  /// In en, this message translates to:
  /// **'Activity and evening reminders'**
  String get notifChannelActivityDesc;

  /// No description provided for @notifTestBody.
  ///
  /// In en, this message translates to:
  /// **'Local notifications are working!'**
  String get notifTestBody;

  /// No description provided for @remWaterTitle.
  ///
  /// In en, this message translates to:
  /// **'💧 Time to drink water'**
  String get remWaterTitle;

  /// No description provided for @remWaterBody.
  ///
  /// In en, this message translates to:
  /// **'Keep up with your daily water goal in Welmi'**
  String get remWaterBody;

  /// No description provided for @remBreakfastTitle.
  ///
  /// In en, this message translates to:
  /// **'🍳 Breakfast'**
  String get remBreakfastTitle;

  /// No description provided for @remBreakfastBody.
  ///
  /// In en, this message translates to:
  /// **'Time for breakfast — log your meal in the diary'**
  String get remBreakfastBody;

  /// No description provided for @remLunchTitle.
  ///
  /// In en, this message translates to:
  /// **'🍽 Lunch'**
  String get remLunchTitle;

  /// No description provided for @remLunchBody.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget lunch — add your meal to the diary'**
  String get remLunchBody;

  /// No description provided for @remDinnerTitle.
  ///
  /// In en, this message translates to:
  /// **'🌙 Dinner'**
  String get remDinnerTitle;

  /// No description provided for @remDinnerBody.
  ///
  /// In en, this message translates to:
  /// **'Dinner time — log your meal in Welmi'**
  String get remDinnerBody;

  /// No description provided for @remActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'🏃 Time to move'**
  String get remActivityTitle;

  /// No description provided for @remActivityBody.
  ///
  /// In en, this message translates to:
  /// **'A little activity brings you closer to your goal'**
  String get remActivityBody;

  /// No description provided for @remEveningTitle.
  ///
  /// In en, this message translates to:
  /// **'✨ Review your day'**
  String get remEveningTitle;

  /// No description provided for @remEveningBody.
  ///
  /// In en, this message translates to:
  /// **'Check your water, meals and weight in Welmi before bed'**
  String get remEveningBody;

  /// No description provided for @waterEveryHour.
  ///
  /// In en, this message translates to:
  /// **'Every hour'**
  String get waterEveryHour;

  /// No description provided for @waterEveryHours.
  ///
  /// In en, this message translates to:
  /// **'Every {hours} h'**
  String waterEveryHours(int hours);

  /// No description provided for @waterEveryMinutes.
  ///
  /// In en, this message translates to:
  /// **'Every {minutes} min'**
  String waterEveryMinutes(int minutes);

  /// No description provided for @macroOfGoalGrams.
  ///
  /// In en, this message translates to:
  /// **'{total} / {goal} g'**
  String macroOfGoalGrams(int total, int goal);
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
