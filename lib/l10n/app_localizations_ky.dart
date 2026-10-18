// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kirghiz Kyrgyz (`ky`).
class AppLocalizationsKy extends AppLocalizations {
  AppLocalizationsKy([String locale = 'ky']) : super(locale);

  @override
  String get appName => 'Welmi';

  @override
  String get greetingMorning => 'Эртең менен жакшы';

  @override
  String get greetingAfternoon => 'Күнүңүз жакшы';

  @override
  String get greetingEvening => 'Кечиңиз жакшы';

  @override
  String get greetingNight => 'Түнүңүз жакшы';

  @override
  String get guest => 'Конок';

  @override
  String get user => 'Колдонуучу';

  @override
  String dailyTipOver80(Object remaining) {
    return 'Мыкты! $remaining ккал калды';
  }

  @override
  String dailyTipBetween30(Object consumed, Object goal) {
    return '$goal ккалдан $consumed ккал жедиңиз';
  }

  @override
  String get dailyTipLateNight => 'Кечки убакыт — тамак жазуу керек';

  @override
  String get dailyTipBreakfast => 'Тамакты жазуу убагы келди! 🍳';

  @override
  String get dailyTipLunch => 'Түшкү тамакты жазуу убагы келди! 🥗';

  @override
  String get dailyTipDinner => 'Кечки тамакты жазуу убагы келди! 🍽️';

  @override
  String get dailyTipSnack => 'Тамак-ашты жазуу убагы келди! 🍎';

  @override
  String get loadingData => 'Деректерди жүктөө...';

  @override
  String get remaining => 'Калды';

  @override
  String ofKcal(Object goal) {
    return '$goal ККАЛдан';
  }

  @override
  String get protein => 'БЕЛОК';

  @override
  String get fat => 'МАЙ';

  @override
  String get carbs => 'УГЛЕВОД';

  @override
  String get steps => 'ЖОЛДОР';

  @override
  String get water => 'СУУ';

  @override
  String get weight => 'Салмак';

  @override
  String get goal => 'МАКСАТ';

  @override
  String get todayEaten => 'Бүгүн жеген';

  @override
  String get foodDiary => 'Тамак-аш күнүмдүгү';

  @override
  String get aiAssistant => 'AI жардамчы';

  @override
  String get aiAssistantDesc => 'Тамак-аш БЖУ, машыгуу планы жана кеңештер';

  @override
  String get drawerWorkouts => 'Машыгуулар';

  @override
  String get drawerMyGoals => 'Менин максаттарым';

  @override
  String get drawerMealPlan => 'Рецепттер';

  @override
  String get drawerActivityHistory => 'Активдүүлүк тарыхы';

  @override
  String get drawerSettings => 'Жөндөөлөр';

  @override
  String get drawerSupport => 'Колдоо';

  @override
  String get drawerLogout => 'Чыгуу';

  @override
  String get drawerLogoutConfirm => 'Аккаунттан чыгууну каалайсызбы?';

  @override
  String get drawerCancel => 'Жокко чыгаруу';

  @override
  String get welmiPremium => 'Welmi Premium';

  @override
  String get userDefault => 'Колдонуучу';

  @override
  String get settingsTitle => 'Жөндөөлөр';

  @override
  String get editProfile => 'Прошти өзгөртүү';

  @override
  String get security => 'Коопсуздук';

  @override
  String get biometricLogin => 'Биометриялык кирүү';

  @override
  String get biometricSubtitle => 'Бармак изи же Face ID';

  @override
  String get sync => 'Синхрондоо';

  @override
  String get googleFitAppleHealth => 'Google Fit / Apple Health';

  @override
  String get healthConnected => 'Туташтырылды ✓';

  @override
  String get healthDisconnected =>
      'Жолдорду жана калорияларды автоматтык түрдө алуу';

  @override
  String get healthConnect => 'Туташтыруу';

  @override
  String get healthInstallPrompt =>
      'Синхрондоо үчүн Health Connect тиркемесин орнотуңуз';

  @override
  String get healthInstall => 'Орнотуу';

  @override
  String get healthNoAccess =>
      'Уруксат берилген жок. Телефонуңузда Health Connect ачыңыз жана Welmi үчүн уруксат бериңиз';

  @override
  String healthConnectedSuccess(Object steps) {
    return 'Туташтырылды ✓ · $steps жол синхрондоштурулду';
  }

  @override
  String get notificationsTitle => 'Эскертүүлөр';

  @override
  String get pushNotifications => 'Push-эскертүүлөр';

  @override
  String get pushNotificationsSubtitle => 'Суу жана тамак-аш эскертүүлөрү';

  @override
  String get waterReminders => 'Суу эскертүүлөрү';

  @override
  String get waterRemindersSubtitle => 'Ар 2 саатта 8:00ден 20:00гө чейин';

  @override
  String get mealReminders => 'Тамак-аш эскертүүлөрү';

  @override
  String get mealRemindersSubtitle =>
      'Эртеңки тамак 8:30 · Түшкү тамак 13:00 · Кечки тамак 19:00';

  @override
  String get appearance => 'Тышкы көрүнүш';

  @override
  String get themeSystem => 'Системалык';

  @override
  String get themeLight => 'Жарык';

  @override
  String get themeDark => 'Караңгы';

  @override
  String get themeSystemDescription =>
      '«Системалык» — тема телефондун жөндөөлөрү менен өзгөрөт';

  @override
  String get measurementUnits => 'Өлчөө бирликтери';

  @override
  String get metricUnits => 'Метрикалык (кг, км)';

  @override
  String get imperialUnits => 'Империялык (фунт, миль)';

  @override
  String get unitCm => 'см';

  @override
  String get unitKg => 'кг';

  @override
  String get unitLb => 'lb';

  @override
  String get unitKm => 'км';

  @override
  String get unitMi => 'mi';

  @override
  String get widgetTitle => 'Виджет';

  @override
  String get widgetWaterTitle => '«Суу» виджети';

  @override
  String get widgetWaterDescription =>
      'Үстөлдү узак басыңыз → Виджеттер → Welmi';

  @override
  String get aboutApp => 'Тиркеме жөнүндө';

  @override
  String get version => 'Версия';

  @override
  String get privacyPolicy => 'Купуялуулук саясаты';

  @override
  String get termsOfUse => 'Колдонуу шарттары';

  @override
  String get madeWithLove => 'Махабат менен жасалган ❤️ — Welmi';

  @override
  String get notificationsEnabled => 'Эскертүүлөр ишке киргизилди';

  @override
  String get notificationsDisabled => 'Эскертүүлөр өчүрүлдү';

  @override
  String get notifMasterSubtitle => 'Суу, тамак-аш, активдүүлүк';

  @override
  String get notifReminders => 'Эскертүүлөр';

  @override
  String get notifEvening => 'Кечки эскертүү';

  @override
  String get notifWaterInterval => 'Эскертүү аралыгы';

  @override
  String get notifPickTime => 'Убакытты тандa';

  @override
  String get notifEvery30Min => 'Ар 30 мүнөт сайын';

  @override
  String get notifEvery1h => 'Ар саат сайын';

  @override
  String get notifEvery90Min => 'Ар 1,5 саат сайын';

  @override
  String get notifEvery2h => 'Ар 2 саат сайын';

  @override
  String get notifEvery3h => 'Ар 3 саат сайын';

  @override
  String get notifTestButton => 'Сыноо эскертүү жөнөтүү';

  @override
  String get notifTestSent => 'Сыноо эскертүү жөнөтүлдү!';

  @override
  String get notifPermissionDenied => 'Эскертүүлөргө уруксат берилген жок';

  @override
  String get notifPermissionGranted => 'Уруксат алынды!';

  @override
  String get notifPermissionBanner =>
      'Эскертүүлөргө уруксат бер — болбосо эскертүүлөр көрүнбөйт';

  @override
  String get biometricEnabled => 'Биометрия ишке киргизилди';

  @override
  String get biometricDisabled => 'Биометрия өчүрүлдү';

  @override
  String get biometricFailed => 'Жекени тактоо мүмкүн болгон жок';

  @override
  String get profileUpdated => 'Профиль жаңыланды!';

  @override
  String unitsChanged(Object units) {
    return 'Бирликтер өзгөртүлдү: $units';
  }

  @override
  String get workouts => 'Машыгуулар';

  @override
  String get myPlan => 'Менин планым: 2-жума';

  @override
  String get whereDoYouTrain => 'Кайда машыгуудасыз?';

  @override
  String get trainSubtitle => 'Жабдыгыңызга ылайык көнүгүүлөрдү тандайбыз';

  @override
  String get noEquipment => 'Жабдыксız';

  @override
  String get noEquipmentSubtitle =>
      'Тек гана дене салмак: отуруу, көтөрүү, планка';

  @override
  String get dumbbells => 'Гантельдер';

  @override
  String get dumbbellsSubtitle => 'Үй машыгуулары үчүн гантель набору';

  @override
  String get calisthenics => 'Турник жана резинки';

  @override
  String get calisthenicsSubtitle => 'Турник, фитнес-резинки, коврик';

  @override
  String get gym => 'Спорт зал';

  @override
  String get gymSubtitle => 'Штанга, гантельдер, тренажерлёр — толук зал';

  @override
  String get generatingPlan => 'План даярдалууда...';

  @override
  String get aiAnalyzing => 'AI параметрлериңизди талдоодо';

  @override
  String get restDay => 'Эс алуу күнү';

  @override
  String get restDaySubtitle => 'Эс алыңыз жана күчүңүздү топтоңуз';

  @override
  String exercisesCount(Object count) {
    return 'Көнүгүүлөр — $count';
  }

  @override
  String get failedToLoadPlan => 'План жүктөлгөн жок. Интернетти текшериңиз.';

  @override
  String get retry => 'Кайра аракет';

  @override
  String planGeneratingSnackbar(Object label) {
    return '«$label» үчүн план — даярдалууда…';
  }

  @override
  String get aiChatTitle => 'AI Чат';

  @override
  String get gymtoneTrainer => 'GYMTONE ТРЕНЕР';

  @override
  String get aiWelcomeGreeting =>
      'Салам!\nМен сизге машыгуулар,\nплан жана тамак-аш боюнча жардам бере алам';

  @override
  String get aiSuggestion1 => 'Эмне үчүн менин планым ушундай курулган?';

  @override
  String get aiSuggestion2 => 'Натыйжалар качан күтүлөт?';

  @override
  String get aiSuggestion3 => 'Планды өзгөртүү';

  @override
  String get aiNewChat => 'Жаңы чат';

  @override
  String get aiNewChatConfirm =>
      'Жаңы диалогду баштообу? Акыркы тарых өчүрүлөт.';

  @override
  String get aiStart => 'Баштоо';

  @override
  String get aiErrorConnection =>
      'AI\'дан жооп алуу мүмкүн болгон жок. Интернет байланышын текшериңиз жана кайра аракет кылыңыз.';

  @override
  String get aiHintLoading => 'Жоопту күтүңүз...';

  @override
  String get aiHintInput => 'Сурооңузду жазыңыз';

  @override
  String get aiJustNow => 'азыр';

  @override
  String aiMinutesAgo(Object minutes) {
    return '$minutes мүн мурун';
  }

  @override
  String get voiceMessageLabel => 'Үн билдирүү';

  @override
  String get voiceSend => 'Үн билдирүү жөнөтүү';

  @override
  String get voiceRecording => 'Жазылып жатат…';

  @override
  String get voiceTranscribing => 'Сүйлөө таанылып жатат…';

  @override
  String get voiceCancel => 'Жокко чыгаруу';

  @override
  String get voiceErrorPermission =>
      'Үн билдирүү жөнөтүү үчүн микрофонго уруксат бериңиз.';

  @override
  String get voiceErrorTranscribe =>
      'Сүйлөөнү таануу мүмкүн болгон жок. Кайра аракет кылыңыз.';

  @override
  String get mealPlanTitle => 'Рецепттер';

  @override
  String get whereDoYouLive => 'Кайда жашайсыз?';

  @override
  String get mealPlanCountrySubtitle =>
      'AI жергиликтүү ашкананын тамактарын тандайт';

  @override
  String get generateMealPlan => 'Тамак-аш планы түзүлүүдө...';

  @override
  String get mealPlanAiSelecting => 'Welmi AI эң сонун менюну тандоодо';

  @override
  String mealPlanLocalCuisine(Object country) {
    return '🍜 Жергиликтүү ашкана: $country';
  }

  @override
  String get mealPlanFailed => 'План жүктөлгөн жок';

  @override
  String get mealPlanRetry => 'Кайра аракет';

  @override
  String get selectCountry => 'Өлкөнү тандаңыз';

  @override
  String cuisineOf(Object country) {
    return 'Ашкана: $country';
  }

  @override
  String fromGoalKcal(Object goal) {
    return '$goal ккалдан';
  }

  @override
  String get mealsCount => 'тамак';

  @override
  String get generatedByAi => 'Welmi AI тарабынан түзүлгөн';

  @override
  String generatedByAiCountry(Object country) {
    return 'Welmi AI тарабынан түзүлгөн · $country ашканасы';
  }

  @override
  String get previewMenu => 'Предварителүү меню';

  @override
  String previewMenuCountry(Object country) {
    return 'Предварителүү меню · $country ашканасы';
  }

  @override
  String get historyTitle => 'Активдүүлүк тарыхы';

  @override
  String get loginToViewHistory => 'Тарыхты көрүү үчүн кириңиз';

  @override
  String get loadingHistory => 'Тарых жүктөлүүдө...';

  @override
  String get stepsLast30Days => 'жол 30 күндө';

  @override
  String get waterLast14Days => 'суу 14 күндө';

  @override
  String get activeDays => 'активдүү күндөр';

  @override
  String get noRecordsYet => 'Азырынча жазуулар жок';

  @override
  String get noRecordsSubtitle => 'Жолдорду, сууну же машыгууну жазыңыз';

  @override
  String get logEntry => 'Жазуу';

  @override
  String get recentDays => 'Акыркы күндөр';

  @override
  String get active => 'Активдүү';

  @override
  String get today => 'Бүгүн';

  @override
  String get yesterday => 'Кечээ';

  @override
  String get whatToLog => 'Эмнени жазуу керек?';

  @override
  String get whatToLogSubtitle => 'Жолдорду, сууну же машыгууну';

  @override
  String get activityLog => 'Активдүүлүк';

  @override
  String get activityLogSubtitle => 'Жолдор, мүнөт, аралык';

  @override
  String get waterLog => 'Суу';

  @override
  String get waterLogSubtitle => 'Ичкен сууну кошуу';

  @override
  String get exerciseLog => 'Көнүгүү';

  @override
  String get exerciseLogSubtitle => 'Отуруу, планка, пресс ж.б.';

  @override
  String get logActivity => 'Активдүүлүктү жазуу';

  @override
  String get stepsLabel => 'Жолдор';

  @override
  String get stepsHint => 'Мисалы: 8000';

  @override
  String get minutesLabel => 'Мүнөт';

  @override
  String get kmLabel => 'Км';

  @override
  String get addWater => 'Суу кошуу';

  @override
  String waterDrunkToday(Object ml) {
    return 'Бүгүн ичилген: $ml мл';
  }

  @override
  String get glass => 'Стакан';

  @override
  String get bottle => 'Бөтөлкө';

  @override
  String get liter => 'Литр';

  @override
  String get addExercise => 'Көнүгүү кошуу';

  @override
  String get setsLabel => 'Жол-жобо';

  @override
  String get repsLabel => 'Кайталоо';

  @override
  String get selectExercise => 'Көнүгүүнү тандаңыз';

  @override
  String exerciseAddedToHistory(Object name) {
    return '$name — тарыхка кошулду';
  }

  @override
  String get activitySaved => 'Активдүүлүк сакталды';

  @override
  String get exerciseSquats => 'Отуруу';

  @override
  String get exercisePushups => 'Түшүү';

  @override
  String get exercisePlank => 'Планка';

  @override
  String get exerciseRunning => 'Жүгүрүү';

  @override
  String get exerciseWalking => 'Басуу';

  @override
  String get exerciseAbs => 'Пресс';

  @override
  String get exerciseRope => 'Аркан';

  @override
  String get exerciseBike => 'Велосипед';

  @override
  String get exerciseYoga => 'Йога';

  @override
  String get exerciseStretch => 'Чоюлуу';

  @override
  String get diaryTitle => 'Күнүмдүк';

  @override
  String get loadingDiary => 'Күнүмдүктү жүктөө...';

  @override
  String get todayLabel => 'Бүгүн';

  @override
  String remainingKcal(Object remaining) {
    return '$remaining ккал калды';
  }

  @override
  String get nothingAdded => 'Эч нерсе кошулган жок';

  @override
  String get addButton => 'Кошуу';

  @override
  String get breakfast => 'Эртеңки тамак';

  @override
  String get lunch => 'Түшкү тамак';

  @override
  String get dinner => 'Кечки тамак';

  @override
  String get snack => 'Тамак-аш';

  @override
  String addFoodTo(Object meal) {
    return '$meal кошуу';
  }

  @override
  String get foodName => 'Аты';

  @override
  String get foodNameHint => 'Мисалы: Овсянка данектер менен';

  @override
  String get kcalLabel => 'Калория (ккал)';

  @override
  String get proteinGrams => 'Белок (г)';

  @override
  String get fatGrams => 'Май (г)';

  @override
  String get carbsGrams => 'Углевод (г)';

  @override
  String get description => 'Түшүндүрмө';

  @override
  String get descriptionHint => '250г, 200мл...';

  @override
  String get loginToSave => 'Деректерди сактоо үчүн кириңиз';

  @override
  String get enterNameAndCalories => 'Атты жана калорияны киргизиңиз';

  @override
  String get weightTitle => 'Салмак';

  @override
  String get recordWeight => 'Салмакты жазуу';

  @override
  String get save => 'Сактоо';

  @override
  String get startWeight => 'Баштапкы';

  @override
  String get goalWeight => 'Максат';

  @override
  String get currentWeightKg => 'Азыркы салмак (кг)';

  @override
  String get weightLost => 'Жоготулган';

  @override
  String get weightToGoal => 'Максатка';

  @override
  String get weightDynamics => 'Салмак динамикасы';

  @override
  String weightEntries(Object count) {
    return '$count жазуу';
  }

  @override
  String percentToGoal(Object percent) {
    return '$percent% максатка';
  }

  @override
  String weekChange(Object days) {
    return 'Акыркы $days күндө';
  }

  @override
  String weekLost(Object amount) {
    return '$amount кг жоготулду';
  }

  @override
  String weekGained(Object amount) {
    return '$amount кг кошулду';
  }

  @override
  String get kgPerWeek => 'кг/жума';

  @override
  String get goalTitle => 'Менин максатым';

  @override
  String get goalType => 'Максат түрү';

  @override
  String get goalWeightLoss => 'Салмакты төмөндөтүү';

  @override
  String get goalMaintain => 'Сактоо';

  @override
  String get goalGain => 'Кошуу';

  @override
  String get goalNotSelected => 'Тандалган жок';

  @override
  String get goalTapToSelect => 'Максатты тандаоо үчүн ✏️ басыңыз';

  @override
  String get goalMaintainDesc => 'Азыркы салмакты сактоо';

  @override
  String goalDaysToGoal(Object days) {
    return '~$days күн максатка';
  }

  @override
  String goalDaysSinceStart(Object days) {
    return '$days күн башталгандан бери';
  }

  @override
  String goalTargetWeight(Object weight) {
    return '$weight — максат';
  }

  @override
  String get editGoal => 'Максатты өзгөртүү';

  @override
  String get goalTypeLabel => 'Максат түрү';

  @override
  String get goalLoseWeight => 'Салмакты төмөндөтүү';

  @override
  String get goalMaintainWeight => 'Сактоо';

  @override
  String get goalGainWeight => 'Кошуу';

  @override
  String get targetWeightLabel => 'Максат салмак';

  @override
  String get goalSpeedLabel => 'Ылдамдык (кг/жума)';

  @override
  String get enterValidWeight => 'Туура максат салмакты киргизиңиз';

  @override
  String get selectGoalType => 'Максат түрүн тандаңыз';

  @override
  String get goalUpdated => 'Максат жаңыланды!';

  @override
  String get comparison => 'Салыштыруу';

  @override
  String get was => 'Болчу';

  @override
  String get now => 'Азыр';

  @override
  String get milestones => 'Прогресс вехалары';

  @override
  String get avgPerDay => 'Орточо';

  @override
  String get daysRemaining => 'Калган күндөр';

  @override
  String get completed => 'бүттү';

  @override
  String get start => 'Баштапкы';

  @override
  String get motivation => 'Мотивация';

  @override
  String progressDone(Object remaining) {
    return 'Мыкты! $remaining ккал калды';
  }

  @override
  String get aiInsightFillProfile => 'Жеке кеңеш алуу үчүн прошти толтуруңуз ✨';

  @override
  String get aiInsightStartTracking =>
      'Прогресссти көрүү үчүн салмакты жазыңыз! 🚀';

  @override
  String aiInsightGreatPace(Object days) {
    return 'Мыкты темп! ~$days күндө максатка жетесиз 🎯';
  }

  @override
  String get aiInsightAlmostThere => 'Сиз дээрлик максатка жетип калдыңыз!';

  @override
  String get aiInsightSteadyProgress => 'Туруктуу прогресс. Улантыңыз! 💪';

  @override
  String get aiInsightSlowProgress =>
      'Прогресс байма-бай. Активдүүлүктү көбөйтүүнү же тамак-ашты өзгөртүүнү аракет кылыңыз. 📈';

  @override
  String get aiInsightOnTrack =>
      'Сиз туура жолдо! Кичинекей кадамдар чоң натыйжаларга алып келет. 🌟';

  @override
  String get motivationQuote1 =>
      'Кичинекей кадамдар чоң натыйжаларга алып келет 🌱';

  @override
  String get motivationQuote2 =>
      'Сиз өз максатыңызга бара жатасыз — улантыңыз! 💪';

  @override
  String get motivationQuote3 => 'Ар күн — жакшыраак болуу мүмкүнчүлүгү ✨';

  @override
  String get motivationQuote4 =>
      'Сиздин денеңиз — эң ишенимдүү долбооруңуз 🏗️';

  @override
  String get motivationQuote5 =>
      'Эч качан баш тартпаңыз. Улуу нерселер убакытты талап кылат ⏳';

  @override
  String get progressTitle => 'Прогресс';

  @override
  String get progressFilterAll => 'Бардык';

  @override
  String get progressFilterMeasurements => 'Өлчөөлөр';

  @override
  String get progressFilterBodyFat => '% Май';

  @override
  String get progressLoadError =>
      'Деректерди жүктөө мүмкүн болгон жок. Байланышты текшериңиз.';

  @override
  String get quickActions => 'Тез аракеттер';

  @override
  String get recordWeightAction => 'Салмакты жазуу';

  @override
  String get recordMeasurements => 'Өлчөөлөрдү жазуу';

  @override
  String get recordBodyFat => '% Майды жазуу';

  @override
  String get chestCm => 'Көкүрөк (см)';

  @override
  String get waistCm => 'Бел (см)';

  @override
  String get hipsCm => 'Калчык (см)';

  @override
  String get armCm => 'Кол (см)';

  @override
  String get thighCm => 'Бут (см)';

  @override
  String get neckCm => 'Моюн (см)';

  @override
  String get discardChanges => 'Өзгөртүүлөрдү жокко чыгаруу?';

  @override
  String get discardChangesDesc => 'Сакталбаган өзгөртүүлөрүңүз жоголот.';

  @override
  String get keepEditing => 'Түзөтүүнү улантуу';

  @override
  String get discard => 'Жокко чыгаруу';

  @override
  String get notificationsPageTitle => 'Эскертүүлөр';

  @override
  String get notifOpenSettings => 'Эскертмелерди жөндөө';

  @override
  String get notifTurnOnHint =>
      'Колдонмо суу, тамак жана активдүүлүк жөнүндө эскертиши үчүн билдирмелерди күйгүзүңүз.';

  @override
  String get notifNoReminders => 'Бардык эскертмелер өчүк';

  @override
  String get notifScheduleHint =>
      'Күнүмдүк эскертмелердин графиги. Убакытты өзгөртүү үчүн эскертмени басыңыз.';

  @override
  String get editProfileTitle => 'Түзөтүү';

  @override
  String get personalInfo => 'Жеке маалымат';

  @override
  String get nameLabel => 'Аты';

  @override
  String get genderLabel => 'Жынысы';

  @override
  String get male => 'Эркек';

  @override
  String get female => 'Аял';

  @override
  String get birthDate => 'Туулган күнү';

  @override
  String get bodyType => 'Дене түзүлүшү';

  @override
  String get heightCm => 'Бийиктик (см)';

  @override
  String get currentWeightLabel => 'Азыркы салмак';

  @override
  String get targetWeight => 'Максат салмак';

  @override
  String get tapPhotoToChange => 'Сүрөттү өзгөртүү үчүн басыңыз';

  @override
  String get changePhoto => 'Сүрөттү өзгөртүү';

  @override
  String get gallery => 'Галерея';

  @override
  String get camera => 'Камера';

  @override
  String get saveChanges => 'Өзгөртүүлөрдү сактоо';

  @override
  String get discardChangesQuestion => 'Өзгөртүүлөрдү жокко чыгаруу?';

  @override
  String get discardChangesDescShort => 'Сакталбаган өзгөртүүлөр жоголот.';

  @override
  String get subscriptionTitle => 'Жазылуу';

  @override
  String get unlockAll => 'Бардык мүмкүнчүлүктөрдү\nачыңыз';

  @override
  String get freeTrial7Days =>
      '7 күн акысыз сынап көрүңүз.\nКаалаган учурда жокко чыгарыңыз.';

  @override
  String get featureFoodScanner => 'Акылдуу тамак-аш сканер';

  @override
  String get featureMealPlans => 'Жеке тамак-аш пландары';

  @override
  String get featureMacroAnalytics => 'Так макро аналитика';

  @override
  String get featureNoAds => 'Жарнама жок';

  @override
  String get monthPlan => 'Айлык';

  @override
  String get yearPlan => 'Жылдык';

  @override
  String get yearDiscount => '-60%';

  @override
  String get startFreeTrial => 'Акысыз сыноону баштоо';

  @override
  String get trialTerms =>
      'Төлөм сыноо мезгилинин аягына 24 саат калганда автоматтык түрдө алынат. Узарткыңыз келбесе, жөндөөлөрдөн жокко чыгарыңыз.';

  @override
  String get supportTitle => 'Колдоо';

  @override
  String get writeToUs => 'Бизге жазыңыз';

  @override
  String get telegram => 'Telegram';

  @override
  String get faq => 'Көп берилүүчү суроолор';

  @override
  String get feedback => 'Кайра байланыш';

  @override
  String get feedbackSubtitle => 'Эмнени жакшыртса болорун жазыңыз';

  @override
  String get feedbackHint => 'Ойлоруңуз жана сунуштарыңыз...';

  @override
  String get send => 'Жөнөтүү';

  @override
  String get thankYouFeedback => 'Отзивиңиз үчүн рахмат! 🙌';

  @override
  String get faqQ1 => 'Максатты кантип өзгөртсө болот?';

  @override
  String get faqA1 =>
      'Менин профилден → Менин максаттарымдан барыңыз. Ал жерде максатты, салмакты жана параметрлерди өзгөртсөңүз болот.';

  @override
  String get faqQ2 => 'Прогресссти кантип баштапкы абалга келтирсе болот?';

  @override
  String get faqA2 =>
      'Прогресс максат өзгөртүлгөндө автоматтык түрдө баштапкы абалга келтирилет. Ошондой эле жазууларды кол менен өчүрсө болот.';

  @override
  String get faqQ3 => 'Сканер эмне үчүн иштебейт?';

  @override
  String get faqA3 =>
      'Камерага уруксат бергениңизди текшериңиз. Маселе чечилбесе — тиркемени кайра баштаңыз.';

  @override
  String get faqQ4 => 'Жазылууну кантип өчүрсө болот?';

  @override
  String get faqA4 =>
      'Жазылууну App Store же Google Play\'dеги аккаунт жөндөөлөрүнөн өчүрсөңүз болот.';

  @override
  String get faqQ5 => 'Менин_DERектерим коопсузбу?';

  @override
  String get faqA5 =>
      'Ооба, бардык деректер Supabase колдонуу менен шифрленген түрдө сакталат. Биз деректерди үчүнчү жактарга бербейбиз.';

  @override
  String get onboardingWelcome => 'Кош\nкелиңиз!';

  @override
  String get onboardingWelcomeSubtitle =>
      'Бир нече суроого жооп бериңиз, биз сиздин жеке тамак-аш планын түзөбүз';

  @override
  String get onboardingGenderTitle => 'Жынысыңызды көрсөтүңүз';

  @override
  String get onboardingGenderSubtitle =>
      'Бул метаболизмиңиз үчүн эсептөөлөрдү такыраак жөндөөгө жардам берет';

  @override
  String get onboardingGoalTitle => 'Максатыңыз эмне?';

  @override
  String get onboardingGoalSubtitle =>
      'Башкы багытты тандаңыз, биз тамак-аш\nпланын ылайыкташтыра алалы.';

  @override
  String get onboardingLoseWeight => 'Салмакты төмөндөтүү';

  @override
  String get onboardingLoseWeightDesc =>
      'Коопсуз калория тартыштыгы аркылуу\nсалмакты төмөндөтүү';

  @override
  String get onboardingGainWeight => 'Салмак кошуу';

  @override
  String get onboardingGainWeightDesc =>
      'Калория артыкчылыгы жана\nмышцы өсүүсү үчүн негиз';

  @override
  String get onboardingMaintainWeight => 'Салмакты сактоо';

  @override
  String get onboardingMaintainWeightDesc =>
      'Азыркы форманы жана ден соолукту\nсаактоо үчүн энергия балансы';

  @override
  String get onboardingHeightTitle => 'Бийиктигиңиз канча?';

  @override
  String get onboardingHeightSubtitle =>
      'Бул күнүмдүк нормаңызды такыраак эсептөөгө жардам берет';

  @override
  String get onboardingWeightTitle => 'Азыр канча\nсалмактасыз?';

  @override
  String get onboardingWeightSubtitle =>
      'Бул калория нормаңызды эсептөөгө жардам берет';

  @override
  String get onboardingTargetTitle => 'Канча салмакка\nжеткиңиз келет?';

  @override
  String get onboardingTargetSubtitle => 'Биз аракет кылган максатты коюңуз';

  @override
  String onboardingTargetFromCurrent(Object diff) {
    return 'Азыркы салмактан $diff кг';
  }

  @override
  String get onboardingBirthTitle => 'Туулган күнүңүз канча?';

  @override
  String get onboardingBirthSubtitle =>
      'Бул маалымат калория нормаңызды\nтакыраак эсептөөгө жардам берет';

  @override
  String get onboardingActivityTitle => 'Канча активдүүсүз?';

  @override
  String get onboardingActivitySubtitle =>
      'Бул калория нормаңызды\nтакыраак эсептөөгө жардам берет';

  @override
  String get activitySedentary => 'Аз кыймылдуу';

  @override
  String get activitySedentaryDesc => 'Кеңсе иши, дээрлик спорт жок.';

  @override
  String get activityLight => 'Жеңил активдүүлүк';

  @override
  String get activityLightDesc => 'Апта сайын 1-2 машыгуу же сейилдөө.';

  @override
  String get activityModerate => 'Орто активдүүлүк';

  @override
  String get activityModerateDesc => 'Апта сайын 3-5 машыгуу, активдүү жашоо.';

  @override
  String get activityHigh => 'Жогорку активдүүлүк';

  @override
  String get activityHighDesc => 'Күнүмдүк интенсивдүү машыгуулар.';

  @override
  String get onboardingSpeedTitle =>
      'Максатка канча\nылдамдыкта жеткиңиз келет?';

  @override
  String get onboardingSpeedSubtitle => 'Ыңгайлуу темпти тандаңыз';

  @override
  String get optimal => 'Оптималдуу';

  @override
  String get slow => 'Жай';

  @override
  String get fast => 'Тез';

  @override
  String get onboardingGoogleTitle => 'Дээрлик даяр!';

  @override
  String get onboardingGoogleSubtitle =>
      'Прогрессиңизди сактоо үчүн Google аркылуу кириңиз';

  @override
  String get onboardingGoogleError =>
      'Google аркылуу кирүү мүмкүн болгон жок. Supabase Dashboardдогу Google провайдер жөндөөлөрүн текшериңиз.';

  @override
  String get onboardingGoogleBrowserHint =>
      'Google аркылуу кирүү үчүн браузер терезеси ачылат';

  @override
  String get authError => 'Авторизация катасы. Кайра аракет кылыңыз.';

  @override
  String get authTimeout => 'Күтүү убакыты өттү. Кайра аракет кылыңыз.';

  @override
  String get continueWithGoogle => 'Google менен улантуу';

  @override
  String get onboardingCalcAnalysis => 'Деректерди талдоо';

  @override
  String get onboardingCalcAnalysisSub => 'Параметрлериңизди иштетүүдө...';

  @override
  String get onboardingCalcCalories => 'Калория эсептөө';

  @override
  String get onboardingCalcCaloriesSub => 'Калория нормаңызды эсептөөдө...';

  @override
  String get onboardingCalcWorkout => 'Жеке машыгуу';

  @override
  String get onboardingCalcWorkoutSub => 'Машыгуу программасын түзүүдө...';

  @override
  String get onboardingCalcMeal => 'Тамак-аш планы';

  @override
  String get onboardingCalcMealSub => 'Жумалык рационду түзүүдө...';

  @override
  String get onboardingCalcWater => 'Суу балансы';

  @override
  String get onboardingCalcWaterSub => 'Суу режимин жөндөөдө...';

  @override
  String get onboardingCalcDone => 'Даяр!';

  @override
  String get onboardingCalcDoneSub => 'Дээрлик бүттү...';

  @override
  String get onboardingPlanReady => 'Сиздин жеке планыңыз даяр!';

  @override
  String get onboardingPlanReadyDesc =>
      'Биз максатыңызга жетүү үчүн\nидеалдуу балансты эсептедик.';

  @override
  String get onboardingPlanGoal => 'КҮНҮМДҮК НОРМА';

  @override
  String onboardingPlanSpeed(Object speed) {
    return '$speed кг / жума';
  }

  @override
  String get onboardingSkip => 'Өткөрүү';

  @override
  String get onboardingNext => 'Кийинки';

  @override
  String get onboardingStart => 'Баштоо';

  @override
  String get onboardingGoalButton => 'Максат';

  @override
  String get onboardingDone => 'Даяр';

  @override
  String stepOutOf(Object total) {
    return '$total дан';
  }

  @override
  String get cm => 'см';

  @override
  String get ft => 'фут';

  @override
  String get kg => 'кг';

  @override
  String get lbs => 'фунт';

  @override
  String get configErrorTitle => 'Конфигурация берилген жок';

  @override
  String get configErrorDesc =>
      'Тиркемени параметр менен иштетиңиз:\n\nflutter run --dart-define-from-file=env.json\n\nenv.json файлы долбоордун тамырында болушу керек\nжана SUPABASE_URL, SUPABASE_ANON_KEY,\nGEMINI_NUTRITION_API_KEY, OPENROUTER_API_KEY,\nSCANNER_API_KEY, SENTRY_DSN камтышы керек.';

  @override
  String get accessRestricted => 'Кирүү чектелген';

  @override
  String get accessRestrictedSubtitle => 'Кирүү үчүн жекени тактаңыз';

  @override
  String get unlockButton => 'Ачуу';

  @override
  String get progress_meas_chest => 'Көкүрөк';

  @override
  String get progress_meas_waist => 'Бел';

  @override
  String get progress_meas_hips => 'Калчык';

  @override
  String get progress_meas_arm => 'Кол';

  @override
  String get progress_meas_thigh => 'Бут';

  @override
  String get progress_meas_neck => 'Моюн';

  @override
  String get restFinished => 'Эс алуу бүттү — алга! 💪';

  @override
  String repsInSet(Object count) {
    return '$count жол-жободогу кайталоо';
  }

  @override
  String weightInKg(Object count) {
    return '$count жол-жободогу салмак (кг)';
  }

  @override
  String get exampleReps => 'Мисалы: 12';

  @override
  String get exampleWeight => 'Мисалы: 8.5';

  @override
  String get replaceExercise => 'Көнүгүүнү алмаштыруу';

  @override
  String alternativesForMuscle(Object muscle) {
    return '«$muscle» булчуңдары үчүн альтернативалар';
  }

  @override
  String exerciseReplaced(Object name) {
    return 'Көнүгүү «$name» менен алмаштырылды';
  }

  @override
  String get markAtLeastOneSet => 'Кеминде бир бүткөн жол-жобону белгилеңиз ✓';

  @override
  String get workoutRecorded => 'Машыгуу жазылды!';

  @override
  String get sets => 'жол-жобо';

  @override
  String get kgLabel => 'кг';

  @override
  String get volume => 'көлөм';

  @override
  String get great => 'Мыкты';

  @override
  String restTimer(Object seconds) {
    return 'ЭС АЛУУ: $seconds сек';
  }

  @override
  String get howToPerform => 'Кандайча аткаруу керек';

  @override
  String get replace => 'Алмаштыруу';

  @override
  String get coachTip => 'Тренер кеңеши';

  @override
  String get kcal => 'ккал';

  @override
  String get repsHeader => 'КАЙТАЛОО';

  @override
  String get weightHeader => 'САЛМАК (КГ)';

  @override
  String get addSet => '+ Жол-жобо кошуу';

  @override
  String get saveResult => 'НАТИЯЖАНЫ САКТОО';

  @override
  String get defaultTip =>
      'Техникага көңүл буруңуз, шашылбаңыз жана жол-жоболордун арасында эс алыңыз.';

  @override
  String get startWithComfortableWeight =>
      '💡 Ыңгайлуу салмактан баштаңыз, бардык жол-жоболорду таза аткарганда кошуңуз.';

  @override
  String get cancel => 'Жокко чыгаруу';

  @override
  String get done => 'Даяр';

  @override
  String get buildNumber => 'Куруу';

  @override
  String get packageName => 'Пакет';

  @override
  String get privacyPolicyIntro =>
      'Welmi сиздин купуялуулугуңуздун баасын төлөйт. Бул Купуялуулук саясаты сиздин жеке маалыматыңызды кантип чогултабыз, колдонобуз жана коргойбуз деп түшүндүрөт.';

  @override
  String get privacyDataTitle => '1. Деректерди чогултуу';

  @override
  String get privacyDataContent =>
      'Биз төмөнкү маалыматтарды кызматтарыбызды камсыз кылуу жана жакшыртуу үчүн чогултабыз:\n\n• Жеке маалымат: ат, жынысы, туулган күнү, бийиктиги, салмагы\n• Ден соолук маалыматы: жолдор, калориялар, суу кабыл алуу, салмак өзгөрүүлөрү\n• Колдонуу маалыматы: тиркемени колдонуу статистикасы\n• Түзүлүш маалыматы: түзүлүш модели, ОС версиясы\n\nДен соолук маалыматы сиздин ачык макулдугуңуз менен гана Health Connect (Android) же HealthKit (iOS) аркылуу чогултулат.';

  @override
  String get privacyUsageTitle => '2. Деректерди кантип колдонобуз';

  @override
  String get privacyUsageContent =>
      'Биз чогултулган деректерди төмөнкү максаттарда колдонобуз:\n\n• Жеке тамак-аш жана машыгуу пландарын түзүү\n• Ден соолук максаттарыңызга жетүү прогрессиңизди көзөмөлдөө\n• Суу, тамак-аш жана машыгуу эскертүүлөрүн жөнөтүү\n• AI сунуштарынын сапатын жакшыртуу\n• Тиркеменин коопсуздугун камсыз кылуу';

  @override
  String get privacyStorageTitle => '3. Деректерди сактоо';

  @override
  String get privacyStorageContent =>
      'Бардык деректер Supabase (PostgreSQL) колдонуу менен шифрленген түрдө сакталат. Сиздин деректериңиз аккаунтуңуз менен байланышкан жана үчүнчү жактарга жеткиликсиз.';

  @override
  String get privacySharingTitle => '4. Деректерди бөлүшүү';

  @override
  String get privacySharingContent =>
      'Биз СИЗДИН ЖЕКЕ ДЕРЕКТЕРИҢИЗДИ үчүнчү жактарга САТПАЙБЫЗ, алмаштырбайбыз жана бербейбиз, төмөнкү учурлардан тышкары:\n\n• Мыйзам талап кылган учурда\n• Welmi жана анын колдонуучуларынын укуктарын коргоо үчүн\n• Сиздин ачык макулдугуңуз менен';

  @override
  String get privacyRightsTitle => '5. Укуктарыңыз';

  @override
  String get privacyRightsContent =>
      'Сиздин укугуңуз бар:\n\n• Тиркемедеги бардык деректериңизди көрүү (Профиль → Түзөтүү)\n• Аккаунтту жана бардык деректерди өчүрүүнү сурануу\n• Эскертүүлөрдөн каалаган убакта баш тартуу\n• Health Connectти каалаган убакта өчүрүү\n\nДеректерди өчүрүү үчүн «Колдоо» бөлүмү аркылуу биз менен байланышыңыз.';

  @override
  String get privacySecurityContent =>
      'Биз өнөр жай стандарттык коопсуздук чараларын ишке ашырабыз:\n\n• Өткөрүүдө деректерди шифрлөө (TLS/SSL)\n• Сактоодо деректерди шифрлөө\n• Google OAuth аркылуу аутентификация\n• Деректер базасында Row-Level Security (RLS)';

  @override
  String get privacyChildrenTitle => '6. Балдардын купуялуулугу';

  @override
  String get privacyChildrenContent =>
      'Welmi 13 жаштан төмөн балдар үчүн арналган эмес. Биз 13 жаштан төмөн балдардан жеке маалыматты атайылап чогултпайбыз.';

  @override
  String get privacyChangesTitle => '7. Саясаттагы өзгөртүүлөр';

  @override
  String get privacyChangesContent =>
      'Биз бул Купуялуулук саясатын мезгил-мезгили менен жаңырта алабыз. Өзгөртүүлөр тиркемеде жарыяланат.';

  @override
  String get privacyLastUpdated => 'Акыркы жаңыртуу: 2026-жылдын августу';

  @override
  String get contactTitle => '8. Байланыш';

  @override
  String get privacyContactContent =>
      'Бул Купуялуулук саясаты жөнүндө суроолоруңуз болсо, биз менен байланышыңыз:\n\n• Telegram: @welmi_support\n• Email: support@welmi.app';

  @override
  String get termsIntro =>
      'Welmi\'ге кош келиңиз. Тиркемени колдонуу менен сиз бул Колдонуу шарттарына макул болосуз. Аларды акырын менен окуңуз.';

  @override
  String get termsAcceptanceTitle => '1. Шарттарды кабыл алуу';

  @override
  String get termsAcceptanceContent =>
      'Welmi\'ни орнотуу жана колдонуу менен сиз бул Колдонуу шарттарына макул болосуз. Бул шарттардын кайсы бөлүгү менен макул болбосоңуз, тиркемени колдонбоңуз.';

  @override
  String get termsServiceTitle => '2. Кызматтын сүрөттөлүшү';

  @override
  String get termsServiceContent =>
      'Welmi — тамак-аш, суу кабыл алуу, дене активдүүлүгү жана салмакты көзөмөлдөө үчүн мобилдик тиркеме. Тиркеме төмөнкүлөрдү камсыз кылат:\n\n• AI тамак-аш жана машыгуу пландары\n• Тамак-аш күнүмдүгү жана калория эсептөө\n• Суу эскертүүлөрү\n• Прогресс аналитикасы\n• Health Connect / HealthKit интеграциясы\n\nБардык сунуштар маалыматтык мүнөздө жана медициналык кеңеш болуп саналбайт.';

  @override
  String get termsAccountTitle => '3. Аккаунтуңуз';

  @override
  String get termsAccountContent =>
      'Сиз аккаунтуңуздун купуялуулугу үчүн жоопкерсиз. Тиркемени колдонуу боюнча бардык иш-аракеттер үчүн жоопкерсиз.';

  @override
  String get termsSubscriptionTitle => '4. Жазылуу жана төлөм';

  @override
  String get termsSubscriptionContent =>
      'Welmi акысыз сыноо мезгилин сунуштайт, андан кийин толук кирүү үчүн жазылуу талап кылынат. Төлөм App Store (iOS) же Google Play (Android) аркылуу ишке ашырылат. Сиз жазылууну каалаган убакта магазиндин жөндөөлөрүнөн өчүрө аласыз.';

  @override
  String get termsContentTitle => '5. Колдонуучу контент';

  @override
  String get termsContentContent =>
      'Сиз тиркемеге киргизген деректердин бардык укуктарын сактайсыз. Биз сиздин жеке маалыматыңызга, тамак-аш же машыгуу жазууларыңызга ээлик кылган жокпуз.';

  @override
  String get termsProhibitedTitle => '6. Тыйуу салынган аракеттер';

  @override
  String get termsProhibitedContent =>
      'Сиз ТӨМӨНКҮЛӨРДҮ ЖАСАБАҢЫЗ:\n\n• Тиркемени мыйзамсыз максаттарда колдонуу\n• Тиркемени же анын серверлерин бузууга аракет кылуу\n• Зыяндуу программаларды таратуу\n• AI өзгөчөлүктөрүн бузуп колдонуу\n• Тиркемени кайра сатуу же таратуу\n• Башка адамдын атынан чыгуу';

  @override
  String get termsDisclaimerTitle => '7. Жоопкерликтен баш тартуу';

  @override
  String get termsDisclaimerContent =>
      'Welmi «бардык түрлөрү боюнча» кепилдиксиз берилет. Биз төмөнкүлөрдү кепилдиктебейбиз:\n\n• Токтотулбай же ката жок иштөө\n• AI тарабынан түзүлгөн сунуштардын тактыгы\n• Бардык түзүлүштөр менен шайкештик\n\nАр кандай диета же машыгуу программасын баштоодон мурун дарыгер менен кеңешүүнү сунуштайбыз.';

  @override
  String get termsLiabilityTitle => '8. Жоопкерликтин чектөөсү';

  @override
  String get termsLiabilityContent =>
      'Welmi жана анын иштеп чыгуучулары тиркемени колдонуудан келип чыккан кандайдыр бир кыйыр, учурдук же кыйыр зыяндар үчүн жоопкер эмес.';

  @override
  String get termsTerminationTitle => '9. Кирүүнү токтотуу';

  @override
  String get termsTerminationContent =>
      'Биз сиздин тиркемеге кирүүңүздү каалаган убакта, эскертүү менен же эскертүүсүз, токтотуу же токтотуу укугун сактайбыз.';

  @override
  String get termsChangesTitle => '10. Шарттардагы өзгөртүүлөр';

  @override
  String get termsChangesContent =>
      'Биз бул Шарттарды каалаган убакта өзгөртө алабыз. Жаңыртылган шарттар тиркемеде жарыяланат.';

  @override
  String get termsLastUpdated => 'Акыркы жаңыртуу: 2026-жылдын августу';

  @override
  String get termsContactContent =>
      'Бул Колдонуу шарттары жөнүндө суроолоруңуз болсо, биз менен байланышыңыз:\n\n• Telegram: @welmi_support\n• Email: support@welmi.app';

  @override
  String get securityTitle => 'Коопсуздук';

  @override
  String get feedbackEmptyMessage => 'Жөнөтүүдөн мурун билдирүү жазыңыз.';

  @override
  String get feedbackMessageTooLong =>
      'Билдирүү өтө узун. Максималдуу узундугу — 3000 белги.';

  @override
  String get feedbackSessionError =>
      'Сессияны текшерүү мүмкүн болгон жок. Тиркемени кайра ачып көрүңүз.';

  @override
  String get feedbackRateLimitError =>
      'Өтө көп суроо-талап. Бир аз күтүп, кайра аракет кылыңыз.';

  @override
  String get feedbackSendError =>
      'Билдирүү жөнөтүлгөн жок. Интернетти текшерип, кайра аракет кылыңыз.';

  @override
  String get feedbackFunctionMissing =>
      'Пикир билдирүү кызматы жарыялана элек. Кийин кайра аракет кылыңыз.';

  @override
  String get feedbackSecretsMissing =>
      'Пикир билдирүү кызматы орнотулган эмес. Кийин кайра аракет кылыңыз.';

  @override
  String get feedbackTelegramError =>
      'Telegram билдирүүнү жеткире алган жок. Кийин кайра аракет кылыңыз.';

  @override
  String get feedbackFunctionError =>
      'Пикир билдирүү кызматы убактылуу жеткиликсиз. Кийин кайра аракет кылыңыз.';

  @override
  String get feedbackNetworkError =>
      'Кызматка туташуу мүмкүн болгон жок. Интернетти текшерип, кайра аракет кылыңыз.';

  @override
  String get voiceErrorNoInternet =>
      'Интернет жок. Үндү таануу үчүн интернет керек.';

  @override
  String get voiceErrorUnavailable =>
      'Үн таануу азыр жеткиликсиз. Кийинчерээк аракет кылыңыз.';

  @override
  String get voiceErrorRecord =>
      'Жазууну баштоо мүмкүн болгон жок. Кайра аракет кылыңыз.';

  @override
  String get voiceErrorPermissionSettings =>
      'Микрофонго уруксат жок. Телефондун жөндөөлөрүндө уруксат бериңиз.';

  @override
  String get ttsPlay => 'Угуу';

  @override
  String get ttsStop => 'Токтотуу';

  @override
  String get ttsReplay => 'Кайра угуу';

  @override
  String get ttsVoiceSettings => 'Үн';

  @override
  String get ttsVoiceDefault => 'Демейки үн';

  @override
  String get ttsVoicesEmpty =>
      'Бул түзмөктө бул тил үчүн үн жок. Тутум жөндөөлөрүнөн үн кошуңуз.';

  @override
  String get ttsErrorUnavailable => 'Бул түзмөктө үн ойнотуу жеткиликсиз.';

  @override
  String get aiErrorUnavailable =>
      'AI-жардамчы жооп берген жок. Туташууңузду текшерип, кайра аракет кылыңыз.';

  @override
  String get voiceFoodNotRecognized =>
      'Продуктууларды аныктоо мүмкүн болгон жок. Кайра аракет кылыңыз.';

  @override
  String get voiceFoodAnalysisError =>
      'Продуктуларды талдоодо ката кетти. Кайра аракет кылыңыз.';

  @override
  String get weightInvalid => 'Туура салмакты киргизиңиз';

  @override
  String get weightSaveError =>
      'Салмакты сактоо мүмкүн болгон жок. Интернетти текшерип, кайра аракет кылыңыз.';

  @override
  String get weightSaved => 'Салмак сакталды';

  @override
  String get saveError =>
      'Сактоо мүмкүн болгон жок. Интернетти текшерип, кайра аракет кылыңыз.';

  @override
  String get signInRequired => 'Маалыматтарды сактоо үчүн аккаунтка кириңиз';

  @override
  String get navHome => 'Башкы бет';

  @override
  String get navScanner => 'Тамак сканери';

  @override
  String get navProfile => 'Профиль';

  @override
  String get heightInvalid => 'Боюңузду 100дөн 250 смге чейин киргизиңиз';
}
