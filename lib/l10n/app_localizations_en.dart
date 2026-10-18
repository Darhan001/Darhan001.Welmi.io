// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Welmi';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get greetingNight => 'Good night';

  @override
  String get guest => 'Guest';

  @override
  String get user => 'User';

  @override
  String dailyTipOver80(Object remaining) {
    return 'Great! $remaining kcal left';
  }

  @override
  String dailyTipBetween30(Object consumed, Object goal) {
    return 'Eaten $consumed kcal out of $goal';
  }

  @override
  String get dailyTipLateNight => 'Late night — time to log a snack';

  @override
  String get dailyTipBreakfast => 'Time to log breakfast! 🍳';

  @override
  String get dailyTipLunch => 'Time to log lunch! 🥗';

  @override
  String get dailyTipDinner => 'Time to log dinner! 🍽️';

  @override
  String get dailyTipSnack => 'Time to log a snack! 🍎';

  @override
  String get loadingData => 'Loading data...';

  @override
  String get remaining => 'Remaining';

  @override
  String ofKcal(Object goal) {
    return 'of $goal KCAL';
  }

  @override
  String get protein => 'PROTEIN';

  @override
  String get fat => 'FAT';

  @override
  String get carbs => 'CARBS';

  @override
  String get steps => 'STEPS';

  @override
  String get water => 'WATER';

  @override
  String get weight => 'WEIGHT';

  @override
  String get goal => 'GOAL';

  @override
  String get todayEaten => 'Today eaten';

  @override
  String get foodDiary => 'Food Diary';

  @override
  String get aiAssistant => 'AI Assistant';

  @override
  String get aiAssistantDesc => 'Product macros, workout plan and tips';

  @override
  String get drawerWorkouts => 'Workouts';

  @override
  String get drawerMyGoals => 'My Goals';

  @override
  String get drawerMealPlan => 'Recipes';

  @override
  String get drawerActivityHistory => 'Activity History';

  @override
  String get drawerSettings => 'Settings';

  @override
  String get drawerSupport => 'Support';

  @override
  String get drawerLogout => 'Logout';

  @override
  String get drawerLogoutConfirm =>
      'Are you sure you want to log out of your account?';

  @override
  String get drawerCancel => 'Cancel';

  @override
  String get welmiPremium => 'Welmi Premium';

  @override
  String get userDefault => 'User';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get security => 'Security';

  @override
  String get biometricLogin => 'Biometric Login';

  @override
  String get biometricSubtitle => 'Fingerprint or Face ID';

  @override
  String get sync => 'Sync';

  @override
  String get googleFitAppleHealth => 'Google Fit / Apple Health';

  @override
  String get healthConnected => 'Connected ✓';

  @override
  String get healthDisconnected => 'Auto-sync steps and calories';

  @override
  String get healthConnect => 'Connect';

  @override
  String get healthInstallPrompt => 'Install Health Connect app for sync';

  @override
  String get healthInstall => 'Install';

  @override
  String get healthNoAccess =>
      'Access denied. Open Health Connect on your phone and allow access for Welmi';

  @override
  String healthConnectedSuccess(Object steps) {
    return 'Connected ✓ · Synced $steps steps';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get pushNotificationsSubtitle => 'Reminders for water and food';

  @override
  String get waterReminders => 'Water Reminders';

  @override
  String get waterRemindersSubtitle => 'Every 2 hours from 8:00 to 20:00';

  @override
  String get mealReminders => 'Meal Reminders';

  @override
  String get mealRemindersSubtitle =>
      'Breakfast 8:30 · Lunch 13:00 · Dinner 19:00';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystemDescription =>
      '\"System\" — theme changes with phone settings';

  @override
  String get measurementUnits => 'Measurement Units';

  @override
  String get metricUnits => 'Metric (kg, km)';

  @override
  String get imperialUnits => 'Imperial (lbs, miles)';

  @override
  String get unitCm => 'cm';

  @override
  String get unitKg => 'kg';

  @override
  String get unitLb => 'lb';

  @override
  String get unitKm => 'km';

  @override
  String get unitMi => 'mi';

  @override
  String get widgetTitle => 'Widget';

  @override
  String get widgetWaterTitle => 'Water Widget';

  @override
  String get widgetWaterDescription =>
      'Long-press on home screen → Widgets → Welmi';

  @override
  String get aboutApp => 'About App';

  @override
  String get version => 'Version';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get madeWithLove => 'Made with ❤️ — Welmi';

  @override
  String get notificationsEnabled => 'Notifications enabled';

  @override
  String get notificationsDisabled => 'Notifications disabled';

  @override
  String get notifMasterSubtitle => 'Water, meals, activity';

  @override
  String get notifReminders => 'Reminders';

  @override
  String get notifEvening => 'Evening reminder';

  @override
  String get notifWaterInterval => 'Reminder interval';

  @override
  String get notifPickTime => 'Choose time';

  @override
  String get notifEvery30Min => 'Every 30 min';

  @override
  String get notifEvery1h => 'Every 1 hour';

  @override
  String get notifEvery90Min => 'Every 1.5 hours';

  @override
  String get notifEvery2h => 'Every 2 hours';

  @override
  String get notifEvery3h => 'Every 3 hours';

  @override
  String get notifTestButton => 'Send test notification';

  @override
  String get notifTestSent => 'Test notification sent!';

  @override
  String get notifPermissionDenied => 'Notification permission denied';

  @override
  String get notifPermissionGranted => 'Permission granted!';

  @override
  String get notifPermissionBanner =>
      'Tap to allow notifications — otherwise reminders won\'t appear';

  @override
  String get biometricEnabled => 'Biometric enabled';

  @override
  String get biometricDisabled => 'Biometric disabled';

  @override
  String get biometricFailed => 'Could not verify identity';

  @override
  String get profileUpdated => 'Profile updated!';

  @override
  String unitsChanged(Object units) {
    return 'Units changed: $units';
  }

  @override
  String get workouts => 'Workouts';

  @override
  String get myPlan => 'My plan: Week 2';

  @override
  String get whereDoYouTrain => 'Where do you train?';

  @override
  String get trainSubtitle => 'We\'ll match exercises to your equipment';

  @override
  String get noEquipment => 'No equipment';

  @override
  String get noEquipmentSubtitle => 'Bodyweight only: push-ups, squats, plank';

  @override
  String get dumbbells => 'Dumbbells';

  @override
  String get dumbbellsSubtitle => 'Dumbbell set for home workouts';

  @override
  String get calisthenics => 'Pull-up bar & bands';

  @override
  String get calisthenicsSubtitle => 'Pull-up bar, resistance bands, yoga mat';

  @override
  String get gym => 'Gym';

  @override
  String get gymSubtitle => 'Barbells, dumbbells, machines — full gym';

  @override
  String get generatingPlan => 'Building your plan...';

  @override
  String get aiAnalyzing => 'AI is analyzing your parameters';

  @override
  String get restDay => 'Rest Day';

  @override
  String get restDaySubtitle => 'Recover and build strength';

  @override
  String exercisesCount(Object count) {
    return 'Exercises — $count';
  }

  @override
  String get failedToLoadPlan => 'Couldn\'t load plan. Check your internet.';

  @override
  String get retry => 'Retry';

  @override
  String planGeneratingSnackbar(Object label) {
    return 'Plan for \"$label\" — generating…';
  }

  @override
  String get aiChatTitle => 'AI Chat';

  @override
  String get gymtoneTrainer => 'GYMTONE TRAINER';

  @override
  String get aiWelcomeGreeting =>
      'Hi, there!\nI can help you with\nworkouts, plans and nutrition';

  @override
  String get aiSuggestion1 => 'Why is my plan built this way?';

  @override
  String get aiSuggestion2 => 'When will I see results?';

  @override
  String get aiSuggestion3 => 'Adjust the plan';

  @override
  String get aiNewChat => 'New Chat';

  @override
  String get aiNewChatConfirm =>
      'Start a new dialog? Current history will be cleared.';

  @override
  String get aiStart => 'Start';

  @override
  String get aiErrorConnection =>
      'Could not get a response from AI. Check your internet connection and try again.';

  @override
  String get aiHintLoading => 'Waiting for reply...';

  @override
  String get aiHintInput => 'Type your question';

  @override
  String get aiJustNow => 'just now';

  @override
  String aiMinutesAgo(Object minutes) {
    return '$minutes min ago';
  }

  @override
  String get voiceMessageLabel => 'Voice message';

  @override
  String get voiceSend => 'Send voice message';

  @override
  String get voiceRecording => 'Recording…';

  @override
  String get voiceTranscribing => 'Recognizing speech…';

  @override
  String get voiceCancel => 'Cancel';

  @override
  String get voiceErrorPermission =>
      'Allow microphone access to send voice messages.';

  @override
  String get voiceErrorTranscribe =>
      'Could not recognize speech. Please try again.';

  @override
  String get mealPlanTitle => 'Recipes';

  @override
  String get whereDoYouLive => 'Where do you live?';

  @override
  String get mealPlanCountrySubtitle =>
      'AI will pick dishes from local cuisine';

  @override
  String get generateMealPlan => 'Generating meal plan...';

  @override
  String get mealPlanAiSelecting => 'Welmi AI is picking the perfect menu';

  @override
  String mealPlanLocalCuisine(Object country) {
    return 'Local cuisine: $country';
  }

  @override
  String get mealPlanFailed => 'Couldn\'t load plan';

  @override
  String get mealPlanRetry => 'Retry';

  @override
  String get selectCountry => 'Select country';

  @override
  String cuisineOf(Object country) {
    return 'Cuisine: $country';
  }

  @override
  String fromGoalKcal(Object goal) {
    return 'of $goal kcal';
  }

  @override
  String get mealsCount => 'meals';

  @override
  String get generatedByAi => 'Generated by Welmi AI';

  @override
  String generatedByAiCountry(Object country) {
    return 'Generated by Welmi AI · $country cuisine';
  }

  @override
  String get previewMenu => 'Preliminary menu';

  @override
  String previewMenuCountry(Object country) {
    return 'Preliminary menu · $country cuisine';
  }

  @override
  String get historyTitle => 'Activity History';

  @override
  String get loginToViewHistory => 'Log in to see history';

  @override
  String get loadingHistory => 'Loading history...';

  @override
  String get stepsLast30Days => 'steps in 30 days';

  @override
  String get waterLast14Days => 'water in 14 days';

  @override
  String get activeDays => 'active days';

  @override
  String get noRecordsYet => 'No records yet';

  @override
  String get noRecordsSubtitle => 'Log steps, water or a workout';

  @override
  String get logEntry => 'Log';

  @override
  String get recentDays => 'Recent Days';

  @override
  String get active => 'Active';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get whatToLog => 'What to log?';

  @override
  String get whatToLogSubtitle => 'Steps, water or a workout';

  @override
  String get activityLog => 'Activity';

  @override
  String get activityLogSubtitle => 'Steps, minutes, distance';

  @override
  String get waterLog => 'Water';

  @override
  String get waterLogSubtitle => 'Add water intake';

  @override
  String get exerciseLog => 'Exercise';

  @override
  String get exerciseLogSubtitle => 'Squats, plank, abs, etc.';

  @override
  String get logActivity => 'Log Activity';

  @override
  String get stepsLabel => 'Steps';

  @override
  String get stepsHint => 'e.g.: 8000';

  @override
  String get minutesLabel => 'Minutes';

  @override
  String get kmLabel => 'Km';

  @override
  String get addWater => 'Add Water';

  @override
  String waterDrunkToday(Object ml) {
    return 'Drunk today: $ml ml';
  }

  @override
  String get glass => 'Glass';

  @override
  String get bottle => 'Bottle';

  @override
  String get liter => 'Liter';

  @override
  String get addExercise => 'Add Exercise';

  @override
  String get setsLabel => 'Sets';

  @override
  String get repsLabel => 'Reps';

  @override
  String get selectExercise => 'Select an exercise';

  @override
  String exerciseAddedToHistory(Object name) {
    return '$name — added to history';
  }

  @override
  String get activitySaved => 'Activity saved';

  @override
  String get exerciseSquats => 'Squats';

  @override
  String get exercisePushups => 'Push-ups';

  @override
  String get exercisePlank => 'Plank';

  @override
  String get exerciseRunning => 'Running';

  @override
  String get exerciseWalking => 'Walking';

  @override
  String get exerciseAbs => 'Abs';

  @override
  String get exerciseRope => 'Jump Rope';

  @override
  String get exerciseBike => 'Bicycle';

  @override
  String get exerciseYoga => 'Yoga';

  @override
  String get exerciseStretch => 'Stretching';

  @override
  String get diaryTitle => 'Diary';

  @override
  String get loadingDiary => 'Loading diary...';

  @override
  String get todayLabel => 'Today';

  @override
  String remainingKcal(Object remaining) {
    return '$remaining kcal left';
  }

  @override
  String get nothingAdded => 'Nothing added';

  @override
  String get addButton => 'Add';

  @override
  String get breakfast => 'Breakfast';

  @override
  String get lunch => 'Lunch';

  @override
  String get dinner => 'Dinner';

  @override
  String get snack => 'Snack';

  @override
  String addFoodTo(Object meal) {
    return 'Add to $meal';
  }

  @override
  String get foodName => 'Name';

  @override
  String get foodNameHint => 'e.g.: Oatmeal with berries';

  @override
  String get kcalLabel => 'Calories (kcal)';

  @override
  String get proteinGrams => 'Protein (g)';

  @override
  String get fatGrams => 'Fat (g)';

  @override
  String get carbsGrams => 'Carbs (g)';

  @override
  String get description => 'Description';

  @override
  String get descriptionHint => '250g, 200ml...';

  @override
  String get loginToSave => 'Log in to save data';

  @override
  String get enterNameAndCalories => 'Enter name and calories';

  @override
  String get weightTitle => 'Weight';

  @override
  String get recordWeight => 'Record Weight';

  @override
  String get save => 'Save';

  @override
  String get startWeight => 'Start';

  @override
  String get goalWeight => 'Goal';

  @override
  String get currentWeightKg => 'Current weight (kg)';

  @override
  String get weightLost => 'Lost';

  @override
  String get weightToGoal => 'To goal';

  @override
  String get weightDynamics => 'Weight Dynamics';

  @override
  String weightEntries(Object count) {
    return '$count entries';
  }

  @override
  String percentToGoal(Object percent) {
    return '$percent% to goal';
  }

  @override
  String weekChange(Object days) {
    return 'Last $days days';
  }

  @override
  String weekLost(Object amount) {
    return 'Lost $amount kg';
  }

  @override
  String weekGained(Object amount) {
    return 'Gained $amount kg';
  }

  @override
  String get kgPerWeek => 'kg/week';

  @override
  String get goalTitle => 'My Goal';

  @override
  String get goalType => 'Goal Type';

  @override
  String get goalWeightLoss => 'Weight Loss';

  @override
  String get goalMaintain => 'Maintain';

  @override
  String get goalGain => 'Gain';

  @override
  String get goalNotSelected => 'Not selected';

  @override
  String get goalTapToSelect => 'Tap ✏️ to select a goal';

  @override
  String get goalMaintainDesc => 'Maintaining current weight';

  @override
  String goalDaysToGoal(Object days) {
    return '~$days days to goal';
  }

  @override
  String goalDaysSinceStart(Object days) {
    return '$days days since start';
  }

  @override
  String goalTargetWeight(Object weight) {
    return '$weight — goal';
  }

  @override
  String get editGoal => 'Edit Goal';

  @override
  String get goalTypeLabel => 'Goal Type';

  @override
  String get goalLoseWeight => 'Weight Loss';

  @override
  String get goalMaintainWeight => 'Maintain';

  @override
  String get goalGainWeight => 'Gain';

  @override
  String get targetWeightLabel => 'Target Weight';

  @override
  String get goalSpeedLabel => 'Speed (kg/week)';

  @override
  String get enterValidWeight => 'Enter a valid target weight';

  @override
  String get selectGoalType => 'Select a goal type';

  @override
  String get goalUpdated => 'Goal updated!';

  @override
  String get comparison => 'Comparison';

  @override
  String get was => 'Was';

  @override
  String get now => 'Now';

  @override
  String get milestones => 'Milestones';

  @override
  String get avgPerDay => 'Average';

  @override
  String get daysRemaining => 'Days left';

  @override
  String get completed => 'completed';

  @override
  String get start => 'Start';

  @override
  String get motivation => 'Motivation';

  @override
  String progressDone(Object remaining) {
    return 'Great! $remaining kcal left';
  }

  @override
  String get aiInsightFillProfile =>
      'Fill in your profile to get personalized insights ✨';

  @override
  String get aiInsightStartTracking =>
      'Start logging weight to see progress! 🚀';

  @override
  String aiInsightGreatPace(Object days) {
    return 'Great pace! You\'ll reach your goal in ~$days days 🎯';
  }

  @override
  String get aiInsightAlmostThere => 'You\'re almost there!';

  @override
  String get aiInsightSteadyProgress => 'Steady progress. Keep it up! 💪';

  @override
  String get aiInsightSlowProgress =>
      'Progress is slow. Try increasing activity or adjusting nutrition. 📈';

  @override
  String get aiInsightOnTrack =>
      'You\'re on track! Small steps lead to big results. 🌟';

  @override
  String get motivationQuote1 => 'Small steps lead to big results 🌱';

  @override
  String get motivationQuote2 => 'You\'re already on your way — keep going! 💪';

  @override
  String get motivationQuote3 => 'Every day is a chance to be better ✨';

  @override
  String get motivationQuote4 => 'Your body is your most faithful project 🏗️';

  @override
  String get motivationQuote5 => 'Never give up. Great things take time ⏳';

  @override
  String get progressTitle => 'Progress';

  @override
  String get progressFilterAll => 'All';

  @override
  String get progressFilterMeasurements => 'Measurements';

  @override
  String get progressFilterBodyFat => '% Body Fat';

  @override
  String get progressLoadError => 'Couldn\'t load data. Check your connection.';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get recordWeightAction => 'Record Weight';

  @override
  String get recordMeasurements => 'Record Measurements';

  @override
  String get recordBodyFat => 'Record % Body Fat';

  @override
  String get chestCm => 'Chest (cm)';

  @override
  String get waistCm => 'Waist (cm)';

  @override
  String get hipsCm => 'Hips (cm)';

  @override
  String get armCm => 'Arm (cm)';

  @override
  String get thighCm => 'Thigh (cm)';

  @override
  String get neckCm => 'Neck (cm)';

  @override
  String get discardChanges => 'Discard changes?';

  @override
  String get discardChangesDesc => 'Your unsaved changes will be lost.';

  @override
  String get keepEditing => 'Keep Editing';

  @override
  String get discard => 'Discard';

  @override
  String get notificationsPageTitle => 'Notifications';

  @override
  String get notifOpenSettings => 'Set up reminders';

  @override
  String get notifTurnOnHint =>
      'Turn on notifications so the app can remind you about water, meals and activity.';

  @override
  String get notifNoReminders => 'All reminders are off';

  @override
  String get notifScheduleHint =>
      'Your daily reminder schedule. Tap a reminder to change its time.';

  @override
  String get editProfileTitle => 'Editing';

  @override
  String get personalInfo => 'Personal Information';

  @override
  String get nameLabel => 'Name';

  @override
  String get genderLabel => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get birthDate => 'Birth Date';

  @override
  String get bodyType => 'Body Type';

  @override
  String get heightCm => 'Height (cm)';

  @override
  String get currentWeightLabel => 'Current Weight';

  @override
  String get targetWeight => 'Target Weight';

  @override
  String get tapPhotoToChange => 'Tap photo to change';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get gallery => 'Gallery';

  @override
  String get camera => 'Camera';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get discardChangesQuestion => 'Discard changes?';

  @override
  String get discardChangesDescShort => 'Unsaved changes will be lost.';

  @override
  String get subscriptionTitle => 'Subscription';

  @override
  String get unlockAll => 'Unlock all\npossibilities';

  @override
  String get freeTrial7Days => 'Try free for 7 days.\nCancel anytime.';

  @override
  String get featureFoodScanner => 'Smart food scanner';

  @override
  String get featureMealPlans => 'Personalized meal plans';

  @override
  String get featureMacroAnalytics => 'Detailed macro analytics';

  @override
  String get featureNoAds => 'No ads';

  @override
  String get monthPlan => 'Monthly';

  @override
  String get yearPlan => 'Yearly';

  @override
  String get yearDiscount => '-60%';

  @override
  String get startFreeTrial => 'Start Free Trial';

  @override
  String get trialTerms =>
      'Payment will be charged 24 hours before the end of the trial period. Cancel in settings if you don\'t wish to renew.';

  @override
  String get supportTitle => 'Support';

  @override
  String get writeToUs => 'Write to Us';

  @override
  String get telegram => 'Telegram';

  @override
  String get faq => 'Frequently Asked Questions';

  @override
  String get feedback => 'Feedback';

  @override
  String get feedbackSubtitle => 'Tell us what can be improved';

  @override
  String get feedbackHint => 'Your ideas and suggestions...';

  @override
  String get send => 'Send';

  @override
  String get thankYouFeedback => 'Thanks for your feedback! 🙌';

  @override
  String get faqQ1 => 'How to change my goal?';

  @override
  String get faqA1 =>
      'Go to My Profile → My Goals. There you can change your goal, weight and parameters.';

  @override
  String get faqQ2 => 'How to reset progress?';

  @override
  String get faqA2 =>
      'Progress is automatically reset when you change your goal. You can also delete records manually.';

  @override
  String get faqQ3 => 'Why doesn\'t the scanner work?';

  @override
  String get faqA3 =>
      'Make sure you\'ve given camera permission. If the problem persists — restart the app.';

  @override
  String get faqQ4 => 'How to cancel subscription?';

  @override
  String get faqA4 =>
      'You can cancel your subscription in your account settings in the App Store or Google Play.';

  @override
  String get faqQ5 => 'Are my data safe?';

  @override
  String get faqA5 =>
      'Yes, all data is stored encrypted using Supabase. We don\'t share data with third parties.';

  @override
  String get onboardingWelcome => 'Welcome!';

  @override
  String get onboardingWelcomeSubtitle =>
      'Answer a few questions and we\'ll create your personalized meal plan';

  @override
  String get onboardingGenderTitle => 'What\'s your gender?';

  @override
  String get onboardingGenderSubtitle =>
      'This helps us set more accurate calculations for your metabolism';

  @override
  String get onboardingGoalTitle => 'What\'s your goal?';

  @override
  String get onboardingGoalSubtitle =>
      'Choose the main direction so we can\nadjust your meal plan.';

  @override
  String get onboardingLoseWeight => 'Lose weight';

  @override
  String get onboardingLoseWeightDesc =>
      'Weight loss through a safe\ncalorie deficit';

  @override
  String get onboardingGainWeight => 'Gain weight';

  @override
  String get onboardingGainWeightDesc =>
      'Calorie surplus focused on\nbuilding muscle foundation';

  @override
  String get onboardingMaintainWeight => 'Maintain weight';

  @override
  String get onboardingMaintainWeightDesc =>
      'Energy balance to maintain\ncurrent form and health';

  @override
  String get onboardingHeightTitle => 'What\'s your height?';

  @override
  String get onboardingHeightSubtitle =>
      'This helps us calculate your daily intake more accurately';

  @override
  String get onboardingWeightTitle => 'How much do you weigh\nnow?';

  @override
  String get onboardingWeightSubtitle =>
      'This helps us calculate your calorie intake';

  @override
  String get onboardingTargetTitle => 'What weight do you\nwant to reach?';

  @override
  String get onboardingTargetSubtitle => 'Set the goal we\'ll work towards';

  @override
  String onboardingTargetFromCurrent(Object diff) {
    return '$diff kg from current weight';
  }

  @override
  String get onboardingBirthTitle => 'When were you born?';

  @override
  String get onboardingBirthSubtitle =>
      'This info helps us calculate your\ncalorie intake more accurately';

  @override
  String get onboardingActivityTitle => 'How active are you?';

  @override
  String get onboardingActivitySubtitle =>
      'This helps us calculate your\ncalorie intake more accurately';

  @override
  String get activitySedentary => 'Sedentary';

  @override
  String get activitySedentaryDesc => 'Office work, almost no exercise.';

  @override
  String get activityLight => 'Light Activity';

  @override
  String get activityLightDesc => '1-2 workouts per week or walks.';

  @override
  String get activityModerate => 'Moderate Activity';

  @override
  String get activityModerateDesc => '3-5 workouts per week, active lifestyle.';

  @override
  String get activityHigh => 'High Activity';

  @override
  String get activityHighDesc => 'Daily intense workouts.';

  @override
  String get onboardingSpeedTitle =>
      'How fast do you want to\nreach your goal?';

  @override
  String get onboardingSpeedSubtitle => 'Choose a comfortable pace';

  @override
  String get optimal => 'Optimal';

  @override
  String get slow => 'Slow';

  @override
  String get fast => 'Fast';

  @override
  String get onboardingGoogleTitle => 'Almost there!';

  @override
  String get onboardingGoogleSubtitle =>
      'Sign in with Google to save your progress';

  @override
  String get onboardingGoogleError =>
      'Could not sign in with Google. Check Google provider settings in Supabase Dashboard.';

  @override
  String get onboardingGoogleBrowserHint =>
      'A browser window will open for Google sign-in';

  @override
  String get authError => 'Authorization error. Please try again.';

  @override
  String get authTimeout => 'Wait time exceeded. Please try again.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get onboardingCalcAnalysis => 'Analyzing Data';

  @override
  String get onboardingCalcAnalysisSub => 'Processing your parameters...';

  @override
  String get onboardingCalcCalories => 'Calculating Calories';

  @override
  String get onboardingCalcCaloriesSub => 'Calculating your calorie intake...';

  @override
  String get onboardingCalcWorkout => 'Personalized Workout';

  @override
  String get onboardingCalcWorkoutSub => 'Creating your workout program...';

  @override
  String get onboardingCalcMeal => 'Meal Plan';

  @override
  String get onboardingCalcMealSub => 'Planning your weekly diet...';

  @override
  String get onboardingCalcWater => 'Water Balance';

  @override
  String get onboardingCalcWaterSub => 'Setting up your water intake...';

  @override
  String get onboardingCalcDone => 'Done!';

  @override
  String get onboardingCalcDoneSub => 'Almost finished...';

  @override
  String get onboardingPlanReady => 'Your personalized plan is ready!';

  @override
  String get onboardingPlanReadyDesc =>
      'We calculated the perfect balance to\nachieve your goal.';

  @override
  String get onboardingPlanGoal => 'DAILY INTAKE';

  @override
  String onboardingPlanSpeed(Object speed) {
    return '$speed kg / week';
  }

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Start';

  @override
  String get onboardingGoalButton => 'Goal';

  @override
  String get onboardingDone => 'Done';

  @override
  String stepOutOf(Object total) {
    return 'of $total';
  }

  @override
  String get cm => 'cm';

  @override
  String get ft => 'feet';

  @override
  String get kg => 'kg';

  @override
  String get lbs => 'lbs';

  @override
  String get configErrorTitle => 'Configuration not provided';

  @override
  String get configErrorDesc =>
      'Run the app with the parameter:\n\nflutter run --dart-define-from-file=env.json\n\nThe env.json file must be in the project root\nand contain SUPABASE_URL, SUPABASE_ANON_KEY,\nGEMINI_NUTRITION_API_KEY, OPENROUTER_API_KEY,\nSCANNER_API_KEY, SENTRY_DSN.';

  @override
  String get accessRestricted => 'Access Restricted';

  @override
  String get accessRestrictedSubtitle => 'Verify your identity to enter';

  @override
  String get unlockButton => 'Unlock';

  @override
  String get progress_meas_chest => 'Chest';

  @override
  String get progress_meas_waist => 'Waist';

  @override
  String get progress_meas_hips => 'Hips';

  @override
  String get progress_meas_arm => 'Arm';

  @override
  String get progress_meas_thigh => 'Thigh';

  @override
  String get progress_meas_neck => 'Neck';

  @override
  String get restFinished => 'Rest\'s over — let\'s go! 💪';

  @override
  String repsInSet(Object count) {
    return 'Reps in set $count';
  }

  @override
  String weightInKg(Object count) {
    return 'Weight in set $count (kg)';
  }

  @override
  String get exampleReps => 'e.g.: 12';

  @override
  String get exampleWeight => 'e.g.: 8.5';

  @override
  String get replaceExercise => 'Replace Exercise';

  @override
  String alternativesForMuscle(Object muscle) {
    return 'Alternatives for \"$muscle\" muscles';
  }

  @override
  String exerciseReplaced(Object name) {
    return 'Exercise replaced with \"$name\"';
  }

  @override
  String get markAtLeastOneSet => 'Mark at least one completed set ✓';

  @override
  String get workoutRecorded => 'Workout recorded!';

  @override
  String get sets => 'sets';

  @override
  String get kgLabel => 'kg';

  @override
  String get volume => 'volume';

  @override
  String get great => 'Great';

  @override
  String restTimer(Object seconds) {
    return 'REST: $seconds sec';
  }

  @override
  String get howToPerform => 'How to Perform';

  @override
  String get replace => 'Replace';

  @override
  String get coachTip => 'Coach Tip';

  @override
  String get kcal => 'kcal';

  @override
  String get repsHeader => 'REPS';

  @override
  String get weightHeader => 'WEIGHT (KG)';

  @override
  String get addSet => '+ Add Set';

  @override
  String get saveResult => 'SAVE RESULT';

  @override
  String get defaultTip =>
      'Focus on technique, don\'t rush and rest between sets. Progress comes with consistency!';

  @override
  String get startWithComfortableWeight =>
      '💡 Start with a comfortable weight and add more when you complete all sets cleanly.';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get buildNumber => 'Build';

  @override
  String get packageName => 'Package';

  @override
  String get privacyPolicyIntro =>
      'Welmi respects your privacy. This Privacy Policy explains how we collect, use, and protect your personal information.';

  @override
  String get privacyDataTitle => '1. Data Collection';

  @override
  String get privacyDataContent =>
      'We collect the following information to provide and improve our services:\n\n• Personal data: name, gender, date of birth, height, weight\n• Health data: steps, calories, water intake, weight changes\n• Usage data: app usage statistics, screen views\n• Device information: device model, operating system version\n\nHealth data is collected only with your explicit consent through Health Connect (Android) or HealthKit (iOS).';

  @override
  String get privacyUsageTitle => '2. How We Use Data';

  @override
  String get privacyUsageContent =>
      'We use collected data to:\n\n• Generate personalized meal plans and workout programs\n• Track your progress toward health goals\n• Send reminders for water, meals, and workouts\n• Improve the quality of our AI recommendations\n• Ensure app security and prevent abuse';

  @override
  String get privacyStorageTitle => '3. Data Storage';

  @override
  String get privacyStorageContent =>
      'All data is stored securely using Supabase (PostgreSQL) with encryption at rest and in transit. Your data is associated with your account and is not accessible to third parties. Data may be stored in data centers located in various regions.';

  @override
  String get privacySharingTitle => '4. Data Sharing';

  @override
  String get privacySharingContent =>
      'We do NOT sell, trade, or share your personal data with third parties, except:\n\n• When required by law\n• To protect the rights and safety of Welmi and its users\n• With your explicit consent\n\nWe use third-party services (Supabase, Google, Sentry) that may process data according to their own privacy policies.';

  @override
  String get privacyRightsTitle => '5. Your Rights';

  @override
  String get privacyRightsContent =>
      'You have the right to:\n\n• View all your data in the app (Profile → Edit)\n• Request deletion of your account and all data\n• Opt out of notifications at any time\n• Disconnect Health Connect at any time\n\nTo delete your data, contact us through the Support section.';

  @override
  String get privacySecurityContent =>
      'We implement industry-standard security measures:\n\n• Data encryption in transit (TLS/SSL)\n• Data encryption at rest\n• Authentication via Google OAuth\n• Row-Level Security (RLS) in the database\n\nNo method of transmission or storage is 100% secure, but we do our best to protect your information.';

  @override
  String get privacyChildrenTitle => '6. Children\'s Privacy';

  @override
  String get privacyChildrenContent =>
      'Welmi is not intended for children under 13. We do not knowingly collect personal information from children under 13. If you believe we have collected such information, please contact us immediately.';

  @override
  String get privacyChangesTitle => '7. Changes to This Policy';

  @override
  String get privacyChangesContent =>
      'We may update this Privacy Policy from time to time. Changes will be posted in the app and will take effect upon publication. We recommend checking this page periodically.';

  @override
  String get privacyLastUpdated => 'Last updated: August 2026';

  @override
  String get contactTitle => '8. Contact';

  @override
  String get privacyContactContent =>
      'If you have any questions about this Privacy Policy, please contact us:\n\n• Telegram: @welmi_support\n• Email: support@welmi.app';

  @override
  String get termsIntro =>
      'Welcome to Welmi. By using our application, you agree to these Terms of Use. Please read them carefully.';

  @override
  String get termsAcceptanceTitle => '1. Acceptance of Terms';

  @override
  String get termsAcceptanceContent =>
      'By installing and using Welmi, you agree to these Terms of Use. If you do not agree with any part of these terms, you should not use the application.';

  @override
  String get termsServiceTitle => '2. Description of Service';

  @override
  String get termsServiceContent =>
      'Welmi is a mobile application for tracking nutrition, water intake, physical activity, and weight. The app provides:\n\n• AI-powered meal and workout plans\n• Food diary and calorie tracking\n• Water intake reminders\n• Progress analytics\n• Integration with Health Connect / HealthKit\n\nAll recommendations are informational and do not constitute medical advice.';

  @override
  String get termsAccountTitle => '3. Your Account';

  @override
  String get termsAccountContent =>
      'You are responsible for maintaining the confidentiality of your account. You agree to provide accurate information during registration and keep it updated. You are responsible for all activities that occur under your account.';

  @override
  String get termsSubscriptionTitle => '4. Subscription and Payments';

  @override
  String get termsSubscriptionContent =>
      'Welmi offers a free trial period, after which a subscription is required for full access. Payment is processed through the App Store (iOS) or Google Play (Android). You can cancel your subscription at any time in your store account settings. The free trial automatically converts to a paid subscription unless canceled 24 hours before the trial ends.';

  @override
  String get termsContentTitle => '5. User Content';

  @override
  String get termsContentContent =>
      'You retain all rights to the data you enter into the app. We do not claim ownership of your personal data, meal entries, or workout logs. You grant us a limited license to process this data solely to provide you with the service.';

  @override
  String get termsProhibitedTitle => '6. Prohibited Actions';

  @override
  String get termsProhibitedContent =>
      'You must NOT:\n\n• Use the app for illegal purposes\n• Attempt to hack or gain unauthorized access to the app or its servers\n• Distribute malware or harmful code\n• Misuse AI features to generate harmful content\n• Resell or redistribute the app or its content\n• Impersonate another person';

  @override
  String get termsDisclaimerTitle => '7. Disclaimer';

  @override
  String get termsDisclaimerContent =>
      'Welmi is provided \'as is\' without warranties of any kind. We do not guarantee:\n\n• Uninterrupted or error-free operation\n• Accuracy of AI-generated recommendations\n• Compatibility with all devices\n\nWe recommend consulting a doctor before starting any diet or exercise program.';

  @override
  String get termsLiabilityTitle => '8. Limitation of Liability';

  @override
  String get termsLiabilityContent =>
      'Welmi and its developers are not liable for any indirect, incidental, or consequential damages arising from the use of the application, including but not limited to health issues resulting from following the app\'s recommendations.';

  @override
  String get termsTerminationTitle => '9. Termination';

  @override
  String get termsTerminationContent =>
      'We reserve the right to terminate or suspend your access to the app at any time, with or without notice, for conduct that violates these Terms or is harmful to other users or the application.';

  @override
  String get termsChangesTitle => '10. Changes to Terms';

  @override
  String get termsChangesContent =>
      'We may modify these Terms at any time. Updated terms will be posted in the app. Continued use of the app after changes constitutes acceptance of the new terms.';

  @override
  String get termsLastUpdated => 'Last updated: August 2026';

  @override
  String get termsContactContent =>
      'For questions about these Terms of Use, contact us:\n\n• Telegram: @welmi_support\n• Email: support@welmi.app';

  @override
  String get securityTitle => 'Security';

  @override
  String get feedbackEmptyMessage => 'Enter a message before sending.';

  @override
  String get feedbackMessageTooLong =>
      'The message is too long. Maximum length is 3000 characters.';

  @override
  String get feedbackSessionError =>
      'Could not verify your session. Restart the app and try again.';

  @override
  String get feedbackRateLimitError =>
      'Too many requests. Wait a moment and try again.';

  @override
  String get feedbackSendError =>
      'Could not send your message. Check your connection and try again.';

  @override
  String get feedbackFunctionMissing =>
      'The feedback service is not deployed yet. Please try again later.';

  @override
  String get feedbackSecretsMissing =>
      'The feedback service is not configured. Please try again later.';

  @override
  String get feedbackTelegramError =>
      'Telegram could not deliver the message. Please try again later.';

  @override
  String get feedbackFunctionError =>
      'The feedback service is temporarily unavailable. Please try again later.';

  @override
  String get feedbackNetworkError =>
      'Could not reach the feedback service. Check your connection and try again.';

  @override
  String get voiceErrorNoInternet =>
      'No internet connection. Voice recognition needs the internet.';

  @override
  String get voiceErrorUnavailable =>
      'Speech recognition is unavailable right now. Please try again later.';

  @override
  String get voiceErrorRecord => 'Could not start recording. Please try again.';

  @override
  String get voiceErrorPermissionSettings =>
      'Microphone access is denied. Allow it in your phone settings.';

  @override
  String get ttsPlay => 'Listen';

  @override
  String get ttsStop => 'Stop';

  @override
  String get ttsReplay => 'Replay';

  @override
  String get ttsVoiceSettings => 'Speech voice';

  @override
  String get ttsVoiceDefault => 'Default voice';

  @override
  String get ttsVoicesEmpty =>
      'This device has no voices for this language. Install a speech engine in the system settings.';

  @override
  String get ttsErrorUnavailable =>
      'Speech playback is not available on this device.';

  @override
  String get aiErrorUnavailable =>
      'The AI assistant did not respond. Check your connection and try again.';

  @override
  String get voiceFoodNotRecognized =>
      'Could not identify the food. Please try again.';

  @override
  String get voiceFoodAnalysisError =>
      'Could not analyze the food. Please try again.';

  @override
  String get weightInvalid => 'Enter a valid weight';

  @override
  String get weightSaveError =>
      'Could not save your weight. Check your connection and try again.';

  @override
  String get weightSaved => 'Weight saved';

  @override
  String get saveError =>
      'Could not save. Check your connection and try again.';

  @override
  String get signInRequired => 'Sign in to save your data';

  @override
  String get navHome => 'Home';

  @override
  String get navScanner => 'Food scanner';

  @override
  String get navProfile => 'Profile';

  @override
  String get heightInvalid => 'Enter a height between 100 and 250 cm';
}
