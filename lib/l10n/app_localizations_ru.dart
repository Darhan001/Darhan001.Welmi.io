// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Welmi';

  @override
  String get greetingMorning => 'Доброе утро';

  @override
  String get greetingAfternoon => 'Добрый день';

  @override
  String get greetingEvening => 'Добрый вечер';

  @override
  String get greetingNight => 'Доброй ночи';

  @override
  String get guest => 'Гость';

  @override
  String get user => 'Пользователь';

  @override
  String dailyTipOver80(Object remaining) {
    return 'Отлично! Осталось $remaining ккал';
  }

  @override
  String dailyTipBetween30(Object consumed, Object goal) {
    return 'Съедено $consumed ккал из $goal';
  }

  @override
  String get dailyTipLateNight => 'Поздняя ночь — пора записать перекус';

  @override
  String get dailyTipBreakfast => 'Пора записать завтрак! 🍳';

  @override
  String get dailyTipLunch => 'Пора записать обед! 🥗';

  @override
  String get dailyTipDinner => 'Пора записать ужин! 🍽️';

  @override
  String get dailyTipSnack => 'Пора записать перекус! 🍎';

  @override
  String get loadingData => 'Загружаем данные...';

  @override
  String get remaining => 'Осталось';

  @override
  String ofKcal(Object goal) {
    return 'из $goal ККАЛ';
  }

  @override
  String get protein => 'БЕЛКИ';

  @override
  String get fat => 'ЖИРЫ';

  @override
  String get carbs => 'УГЛЕВОДЫ';

  @override
  String get steps => 'ШАГИ';

  @override
  String get water => 'ВОДА';

  @override
  String get weight => 'ВЕС';

  @override
  String get goal => 'ЦЕЛЬ';

  @override
  String get todayEaten => 'Сегодня съедено';

  @override
  String get foodDiary => 'Дневник питания';

  @override
  String get aiAssistant => 'AI-помощник';

  @override
  String get aiAssistantDesc => 'БЖУ продукта, план тренировок и советы';

  @override
  String get drawerWorkouts => 'Тренировки';

  @override
  String get drawerMyGoals => 'Мои цели';

  @override
  String get drawerMealPlan => 'Рецепты';

  @override
  String get drawerActivityHistory => 'История активности';

  @override
  String get drawerSettings => 'Настройки';

  @override
  String get drawerSupport => 'Поддержка';

  @override
  String get drawerLogout => 'Выйти';

  @override
  String get drawerLogoutConfirm => 'Ты уверен, что хочешь выйти из аккаунта?';

  @override
  String get drawerCancel => 'Отмена';

  @override
  String get welmiPremium => 'Welmi Premium';

  @override
  String get userDefault => 'Пользователь';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get editProfile => 'Изменить профиль';

  @override
  String get security => 'Безопасность';

  @override
  String get biometricLogin => 'Вход по биометрии';

  @override
  String get biometricSubtitle => 'Отпечаток пальца или FaceID';

  @override
  String get sync => 'Синхронизация';

  @override
  String get googleFitAppleHealth => 'Google Fit / Apple Health';

  @override
  String get healthConnected => 'Подключено ✓';

  @override
  String get healthDisconnected => 'Автоматически подтянуть шаги и калории';

  @override
  String get healthConnect => 'Подключить';

  @override
  String get healthInstallPrompt =>
      'Установи приложение Health Connect для синхронизации';

  @override
  String get healthInstall => 'Установить';

  @override
  String get healthNoAccess =>
      'Доступ не получен. Открой Health Connect на телефоне и разреши доступ для Welmi';

  @override
  String healthConnectedSuccess(Object steps) {
    return 'Подключено ✓ · Синхронизировано $steps шагов';
  }

  @override
  String get notificationsTitle => 'Уведомления';

  @override
  String get pushNotifications => 'Push-уведомления';

  @override
  String get pushNotificationsSubtitle => 'Напоминания о воде и еде';

  @override
  String get waterReminders => 'Напоминания о воде';

  @override
  String get waterRemindersSubtitle => 'Каждые 2 часа с 8:00 до 20:00';

  @override
  String get mealReminders => 'Напоминания о еде';

  @override
  String get mealRemindersSubtitle => 'Завтрак 8:30 · Обед 13:00 · Ужин 19:00';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeSystemDescription =>
      '«Системная» — тема меняется вместе с настройками телефона';

  @override
  String get measurementUnits => 'Единицы измерения';

  @override
  String get metricUnits => 'Метрические (кг, км)';

  @override
  String get imperialUnits => 'Имперские (фунты, мили)';

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
  String get widgetWaterTitle => 'Виджет «Вода»';

  @override
  String get widgetWaterDescription =>
      'Зажми палец на рабочем столе → Виджеты → Welmi';

  @override
  String get aboutApp => 'О приложении';

  @override
  String get version => 'Версия';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get termsOfUse => 'Условия использования';

  @override
  String get madeWithLove => 'Сделано с ❤️ — Welmi';

  @override
  String get notificationsEnabled => 'Уведомления включены';

  @override
  String get notificationsDisabled => 'Уведомления выключены';

  @override
  String get notifMasterSubtitle => 'Вода, питание, активность';

  @override
  String get notifReminders => 'Напоминания';

  @override
  String get notifEvening => 'Вечернее напоминание';

  @override
  String get notifWaterInterval => 'Интервал напоминаний';

  @override
  String get notifPickTime => 'Выбери время';

  @override
  String get notifEvery30Min => 'Каждые 30 минут';

  @override
  String get notifEvery1h => 'Каждый час';

  @override
  String get notifEvery90Min => 'Каждые 1,5 часа';

  @override
  String get notifEvery2h => 'Каждые 2 часа';

  @override
  String get notifEvery3h => 'Каждые 3 часа';

  @override
  String get notifTestButton => 'Отправить тестовое уведомление';

  @override
  String get notifTestSent => 'Тестовое уведомление отправлено!';

  @override
  String get notifPermissionDenied => 'Разрешение на уведомления не выдано';

  @override
  String get notifPermissionGranted => 'Разрешение получено!';

  @override
  String get notifPermissionBanner =>
      'Нажми, чтобы разрешить уведомления — иначе напоминания не появятся';

  @override
  String get biometricEnabled => 'Биометрия включена';

  @override
  String get biometricDisabled => 'Биометрия отключена';

  @override
  String get biometricFailed => 'Не удалось подтвердить личность';

  @override
  String get profileUpdated => 'Профиль обновлён!';

  @override
  String unitsChanged(Object units) {
    return 'Единицы изменены: $units';
  }

  @override
  String get workouts => 'Тренировки';

  @override
  String get myPlan => 'Мой план: Неделя 2';

  @override
  String get whereDoYouTrain => 'Где ты тренируешься?';

  @override
  String get trainSubtitle => 'Подберём упражнения под твой инвентарь';

  @override
  String get noEquipment => 'Без инвентаря';

  @override
  String get noEquipmentSubtitle =>
      'Только вес тела: отжимания, приседания, планка';

  @override
  String get dumbbells => 'Гантели';

  @override
  String get dumbbellsSubtitle => 'Набор гантелей для домашних тренировок';

  @override
  String get calisthenics => 'Турник и резинки';

  @override
  String get calisthenicsSubtitle => 'Турник, фитнес-резинки, коврик';

  @override
  String get gym => 'Спортзал';

  @override
  String get gymSubtitle => 'Штанга, гантели, тренажёры — полный зал';

  @override
  String get generatingPlan => 'Составляем план...';

  @override
  String get aiAnalyzing => 'AI анализирует твои параметры';

  @override
  String get restDay => 'День отдыха';

  @override
  String get restDaySubtitle => 'Восстанавливайся и набирайся сил';

  @override
  String exercisesCount(Object count) {
    return 'Упражнения — $count';
  }

  @override
  String get failedToLoadPlan => 'Не удалось загрузить план. Проверь интернет.';

  @override
  String get retry => 'Повторить';

  @override
  String planGeneratingSnackbar(Object label) {
    return 'План под «$label» — составляем…';
  }

  @override
  String get aiChatTitle => 'AI Чат';

  @override
  String get gymtoneTrainer => 'GYMTONE ТРЕНЕР';

  @override
  String get aiWelcomeGreeting =>
      'Привет!\nЯ могу помочь тебе с\nтренировками, планом и питанием';

  @override
  String get aiSuggestion1 => 'Почему мой план так построен?';

  @override
  String get aiSuggestion2 => 'Когда ждать результаты?';

  @override
  String get aiSuggestion3 => 'Скорректировать план';

  @override
  String get aiNewChat => 'Новый чат';

  @override
  String get aiNewChatConfirm =>
      'Начать новый диалог? Текущая история будет очищена.';

  @override
  String get aiStart => 'Начать';

  @override
  String get aiErrorConnection =>
      'Не удалось получить ответ от AI. Проверь подключение к интернету и попробуй ещё раз.';

  @override
  String get aiHintLoading => 'Подожди ответа...';

  @override
  String get aiHintInput => 'Напишите свой вопрос';

  @override
  String get aiJustNow => 'только что';

  @override
  String aiMinutesAgo(Object minutes) {
    return '$minutes мин назад';
  }

  @override
  String get voiceMessageLabel => 'Голосовое сообщение';

  @override
  String get voiceSend => 'Отправить голосовое';

  @override
  String get voiceRecording => 'Идёт запись…';

  @override
  String get voiceTranscribing => 'Распознаю речь…';

  @override
  String get voiceCancel => 'Отмена';

  @override
  String get voiceErrorPermission =>
      'Разреши доступ к микрофону, чтобы отправлять голосовые.';

  @override
  String get voiceErrorTranscribe =>
      'Не удалось распознать речь. Попробуй ещё раз.';

  @override
  String get mealPlanTitle => 'Рецепты';

  @override
  String get whereDoYouLive => 'Где ты живёшь?';

  @override
  String get mealPlanCountrySubtitle => 'AI подберёт блюда местной кухни';

  @override
  String get generateMealPlan => 'Генерируем план питания...';

  @override
  String get mealPlanAiSelecting => 'Welmi AI подбирает идеальное меню';

  @override
  String mealPlanLocalCuisine(Object country) {
    return '🍜 Местная кухня: $country';
  }

  @override
  String get mealPlanFailed => 'Не удалось загрузить план';

  @override
  String get mealPlanRetry => 'Повторить';

  @override
  String get selectCountry => 'Выбрать страну';

  @override
  String cuisineOf(Object country) {
    return 'Кухня: $country';
  }

  @override
  String fromGoalKcal(Object goal) {
    return 'из $goal ккал';
  }

  @override
  String get mealsCount => 'приёма пищи';

  @override
  String get generatedByAi => 'Сгенерировано Welmi AI';

  @override
  String generatedByAiCountry(Object country) {
    return 'Сгенерировано Welmi AI · кухня $country';
  }

  @override
  String get previewMenu => 'Предварительное меню';

  @override
  String previewMenuCountry(Object country) {
    return 'Предварительное меню · кухня $country';
  }

  @override
  String get historyTitle => 'История активности';

  @override
  String get loginToViewHistory => 'Войди в аккаунт, чтобы увидеть историю';

  @override
  String get loadingHistory => 'Загружаем историю...';

  @override
  String get stepsLast30Days => 'шагов за 30 дней';

  @override
  String get waterLast14Days => 'воды за 14 дней';

  @override
  String get activeDays => 'активных дней';

  @override
  String get noRecordsYet => 'Пока нет записей';

  @override
  String get noRecordsSubtitle => 'Запиши шаги, воду или тренировку';

  @override
  String get logEntry => 'Записать';

  @override
  String get recentDays => 'Последние дни';

  @override
  String get active => 'Активный';

  @override
  String get today => 'Сегодня';

  @override
  String get yesterday => 'Вчера';

  @override
  String get whatToLog => 'Что записать?';

  @override
  String get whatToLogSubtitle => 'Шаги, воду или тренировку';

  @override
  String get activityLog => 'Активность';

  @override
  String get activityLogSubtitle => 'Шаги, минуты, дистанция';

  @override
  String get waterLog => 'Вода';

  @override
  String get waterLogSubtitle => 'Добавить выпитую воду';

  @override
  String get exerciseLog => 'Упражнение';

  @override
  String get exerciseLogSubtitle => 'Приседания, планка, пресс и др.';

  @override
  String get logActivity => 'Записать активность';

  @override
  String get stepsLabel => 'Шаги';

  @override
  String get stepsHint => 'Например: 8000';

  @override
  String get minutesLabel => 'Минуты';

  @override
  String get kmLabel => 'Км';

  @override
  String get addWater => 'Добавить воду';

  @override
  String waterDrunkToday(Object ml) {
    return 'Сегодня выпито: $ml мл';
  }

  @override
  String get glass => 'Стакан';

  @override
  String get bottle => 'Бутылка';

  @override
  String get liter => 'Литр';

  @override
  String get addExercise => 'Добавить упражнение';

  @override
  String get setsLabel => 'Подходы';

  @override
  String get repsLabel => 'Повторения';

  @override
  String get selectExercise => 'Выбери упражнение';

  @override
  String exerciseAddedToHistory(Object name) {
    return '$name — добавлено в историю';
  }

  @override
  String get activitySaved => 'Активность сохранена';

  @override
  String get exerciseSquats => 'Приседания';

  @override
  String get exercisePushups => 'Отжимания';

  @override
  String get exercisePlank => 'Планка';

  @override
  String get exerciseRunning => 'Бег';

  @override
  String get exerciseWalking => 'Ходьба';

  @override
  String get exerciseAbs => 'Пресс';

  @override
  String get exerciseRope => 'Скакалка';

  @override
  String get exerciseBike => 'Велосипед';

  @override
  String get exerciseYoga => 'Йога';

  @override
  String get exerciseStretch => 'Растяжка';

  @override
  String get diaryTitle => 'Дневник';

  @override
  String get loadingDiary => 'Загружаем дневник...';

  @override
  String get todayLabel => 'Сегодня';

  @override
  String remainingKcal(Object remaining) {
    return 'Осталось $remaining ккал';
  }

  @override
  String get nothingAdded => 'Ничего не добавлено';

  @override
  String get addButton => 'Добавить';

  @override
  String get breakfast => 'Завтрак';

  @override
  String get lunch => 'Обед';

  @override
  String get dinner => 'Ужин';

  @override
  String get snack => 'Перекус';

  @override
  String addFoodTo(Object meal) {
    return 'Добавить в $meal';
  }

  @override
  String get foodName => 'Название';

  @override
  String get foodNameHint => 'Например: Овсянка с ягодами';

  @override
  String get kcalLabel => 'Калории (ккал)';

  @override
  String get proteinGrams => 'Белки (г)';

  @override
  String get fatGrams => 'Жиры (г)';

  @override
  String get carbsGrams => 'Углеводы (г)';

  @override
  String get description => 'Описание';

  @override
  String get descriptionHint => '250г, 200мл...';

  @override
  String get loginToSave => 'Войди в аккаунт, чтобы сохранять данные';

  @override
  String get enterNameAndCalories => 'Введи название и калории';

  @override
  String get weightTitle => 'Вес';

  @override
  String get recordWeight => 'Записать вес';

  @override
  String get save => 'Сохранить';

  @override
  String get startWeight => 'Старт';

  @override
  String get goalWeight => 'Цель';

  @override
  String get currentWeightKg => 'Текущий вес (кг)';

  @override
  String get weightLost => 'Потеряно';

  @override
  String get weightToGoal => 'До цели';

  @override
  String get weightDynamics => 'Динамика веса';

  @override
  String weightEntries(Object count) {
    return '$count записей';
  }

  @override
  String percentToGoal(Object percent) {
    return '$percent% к цели';
  }

  @override
  String weekChange(Object days) {
    return 'За последние $days дней';
  }

  @override
  String weekLost(Object amount) {
    return 'Потеряно $amount кг';
  }

  @override
  String weekGained(Object amount) {
    return 'Набрано $amount кг';
  }

  @override
  String get kgPerWeek => 'кг/нед';

  @override
  String get goalTitle => 'Моя цель';

  @override
  String get goalType => 'Тип цели';

  @override
  String get goalWeightLoss => 'Похудение';

  @override
  String get goalMaintain => 'Поддержание';

  @override
  String get goalGain => 'Набор';

  @override
  String get goalNotSelected => 'Не выбран';

  @override
  String get goalTapToSelect => 'Нажми ✏️, чтобы выбрать цель';

  @override
  String get goalMaintainDesc => 'Поддержание текущего веса';

  @override
  String goalDaysToGoal(Object days) {
    return '~$days дней до цели';
  }

  @override
  String goalDaysSinceStart(Object days) {
    return '$days дней с начала пути';
  }

  @override
  String goalTargetWeight(Object weight) {
    return '$weight — цель';
  }

  @override
  String get editGoal => 'Изменить цель';

  @override
  String get goalTypeLabel => 'Тип цели';

  @override
  String get goalLoseWeight => 'Похудение';

  @override
  String get goalMaintainWeight => 'Поддержание';

  @override
  String get goalGainWeight => 'Набор';

  @override
  String get targetWeightLabel => 'Целевой вес';

  @override
  String get goalSpeedLabel => 'Скорость (кг/нед)';

  @override
  String get enterValidWeight => 'Введите корректный целевой вес';

  @override
  String get selectGoalType => 'Выберите тип цели';

  @override
  String get goalUpdated => 'Цель обновлена!';

  @override
  String get comparison => 'Сравнение';

  @override
  String get was => 'Было';

  @override
  String get now => 'Сейчас';

  @override
  String get milestones => 'Вехи прогресса';

  @override
  String get avgPerDay => 'В среднем';

  @override
  String get daysRemaining => 'Осталось дней';

  @override
  String get completed => 'выполнено';

  @override
  String get start => 'Старт';

  @override
  String get motivation => 'Мотивация';

  @override
  String progressDone(Object remaining) {
    return 'Отлично! Осталось $remaining ккал';
  }

  @override
  String get aiInsightFillProfile =>
      'Заполни профиль, чтобы получить персональные инсайты ✨';

  @override
  String get aiInsightStartTracking =>
      'Начни записывать вес, чтобы увидеть прогресс! 🚀';

  @override
  String aiInsightGreatPace(Object days) {
    return 'Отличный темп! Достигнешь цели через ~$days дней 🎯';
  }

  @override
  String get aiInsightAlmostThere => 'Ты уже почти у цели!';

  @override
  String get aiInsightSteadyProgress =>
      'Хороший устойчивый прогресс. Продолжай в том же духе! 💪';

  @override
  String get aiInsightSlowProgress =>
      'Прогресс идёт медленно. Попробуй увеличить активность или скорректировать питание. 📈';

  @override
  String get aiInsightOnTrack =>
      'Ты на верном пути! Маленькие шаги ведут к большим результатам. 🌟';

  @override
  String get motivationQuote1 =>
      'Маленькие шаги ведут к большим результатам 🌱';

  @override
  String get motivationQuote2 => 'Ты уже на пути к своей цели — продолжай! 💪';

  @override
  String get motivationQuote3 => 'Каждый день — это шанс стать лучше ✨';

  @override
  String get motivationQuote4 => 'Твоё тело — твой самый верный проект 🏗️';

  @override
  String get motivationQuote5 =>
      'Никогда не сдавайся. Великие вещи требуют времени ⏳';

  @override
  String get progressTitle => 'Прогресс';

  @override
  String get progressFilterAll => 'Все';

  @override
  String get progressFilterMeasurements => 'Замеры';

  @override
  String get progressFilterBodyFat => '% жира';

  @override
  String get progressLoadError =>
      'Не удалось загрузить данные. Проверьте подключение.';

  @override
  String get quickActions => 'Быстрые действия';

  @override
  String get recordWeightAction => 'Записать вес';

  @override
  String get recordMeasurements => 'Записать замеры';

  @override
  String get recordBodyFat => 'Записать % жира';

  @override
  String get chestCm => 'Грудь (см)';

  @override
  String get waistCm => 'Талия (см)';

  @override
  String get hipsCm => 'Бёдра (см)';

  @override
  String get armCm => 'Рука (см)';

  @override
  String get thighCm => 'Бедро (см)';

  @override
  String get neckCm => 'Шея (см)';

  @override
  String get discardChanges => 'Отменить изменения?';

  @override
  String get discardChangesDesc =>
      'Все несохранённые изменения будут потеряны.';

  @override
  String get keepEditing => 'Продолжить редактирование';

  @override
  String get discard => 'Отменить';

  @override
  String get notificationsPageTitle => 'Уведомления';

  @override
  String get notifOpenSettings => 'Настроить напоминания';

  @override
  String get notifTurnOnHint =>
      'Включи уведомления, чтобы приложение напоминало о воде, еде и активности.';

  @override
  String get notifNoReminders => 'Все напоминания выключены';

  @override
  String get notifScheduleHint =>
      'Расписание напоминаний на каждый день. Нажми на напоминание, чтобы изменить время.';

  @override
  String get editProfileTitle => 'Редактирование';

  @override
  String get personalInfo => 'Личная информация';

  @override
  String get nameLabel => 'Имя';

  @override
  String get genderLabel => 'Пол';

  @override
  String get male => 'Мужской';

  @override
  String get female => 'Женский';

  @override
  String get birthDate => 'Дата рождения';

  @override
  String get bodyType => 'Телосложение';

  @override
  String get heightCm => 'Рост (см)';

  @override
  String get currentWeightLabel => 'Текущий вес';

  @override
  String get targetWeight => 'Целевой вес';

  @override
  String get tapPhotoToChange => 'Нажми на фото, чтобы изменить';

  @override
  String get changePhoto => 'Изменить фото';

  @override
  String get gallery => 'Галерея';

  @override
  String get camera => 'Камера';

  @override
  String get saveChanges => 'Сохранить изменения';

  @override
  String get discardChangesQuestion => 'Отменить изменения?';

  @override
  String get discardChangesDescShort =>
      'Несохранённые изменения будут потеряны.';

  @override
  String get subscriptionTitle => 'Подписка';

  @override
  String get unlockAll => 'Открой все\nвозможности';

  @override
  String get freeTrial7Days =>
      'Попробуй бесплатно 7 дней.\nОтмена в любой момент.';

  @override
  String get featureFoodScanner => 'Умный сканер еды и продуктов';

  @override
  String get featureMealPlans => 'Персональные планы питания';

  @override
  String get featureMacroAnalytics => 'Подробная аналитика макросов';

  @override
  String get featureNoAds => 'Никакой рекламы';

  @override
  String get monthPlan => 'Месяц';

  @override
  String get yearPlan => 'Год';

  @override
  String get yearDiscount => '-60%';

  @override
  String get startFreeTrial => 'Начать бесплатный период';

  @override
  String get trialTerms =>
      'Оплата спишется автоматически за 24 часа до конца пробного периода. Отмените в настройках, если не желаете продлевать.';

  @override
  String get supportTitle => 'Поддержка';

  @override
  String get writeToUs => 'Написать нам';

  @override
  String get telegram => 'Telegram';

  @override
  String get faq => 'Частые вопросы';

  @override
  String get feedback => 'Обратная связь';

  @override
  String get feedbackSubtitle => 'Напиши, что можно улучшить';

  @override
  String get feedbackHint => 'Твои идеи и пожелания...';

  @override
  String get send => 'Отправить';

  @override
  String get thankYouFeedback => 'Спасибо за отзыв! 🙌';

  @override
  String get faqQ1 => 'Как изменить цель?';

  @override
  String get faqA1 =>
      'Зайди в Мой профиль → Мои цели. Там можно изменить цель, вес и параметры.';

  @override
  String get faqQ2 => 'Как сбросить прогресс?';

  @override
  String get faqA2 =>
      'Прогресс сбрасывается автоматически при изменении цели. Также можно удалить записи вручную.';

  @override
  String get faqQ3 => 'Почему не работает сканер?';

  @override
  String get faqA3 =>
      'Убедись, что ты дал разрешение на камеру. Если проблема остаётся — перезапусти приложение.';

  @override
  String get faqQ4 => 'Как отключить подписку?';

  @override
  String get faqA4 =>
      'Подписку можно отключить в настройках твоего аккаунта в App Store или Google Play.';

  @override
  String get faqQ5 => 'Мои данные в безопасности?';

  @override
  String get faqA5 =>
      'Да, все данные хранятся в зашифрованном виде с использованием Supabase. Мы не передаём данные третьим лицам.';

  @override
  String get onboardingWelcome => 'Добро\nпожаловать!';

  @override
  String get onboardingWelcomeSubtitle =>
      'Ответь на несколько вопросов, и мы составим твой персональный план питания';

  @override
  String get onboardingGenderTitle => 'Укажи свой пол';

  @override
  String get onboardingGenderSubtitle =>
      'Это поможет нам точнее настроить расчеты для твоего метаболизма';

  @override
  String get onboardingGoalTitle => 'Какая у тебя цель?';

  @override
  String get onboardingGoalSubtitle =>
      'Выбери главное направление, чтобы мы могли\nнастроить план питания.';

  @override
  String get onboardingLoseWeight => 'Похудеть';

  @override
  String get onboardingLoseWeightDesc =>
      'Снижение веса за счет создания\nбезопасного дефицита калорий';

  @override
  String get onboardingGainWeight => 'Набрать массу';

  @override
  String get onboardingGainWeightDesc =>
      'Профицит калорий и фокус на\nбазис для роста мышц';

  @override
  String get onboardingMaintainWeight => 'Поддерживать вес';

  @override
  String get onboardingMaintainWeightDesc =>
      'Баланс энергии для сохранения\nтекущей формы и здоровья';

  @override
  String get onboardingHeightTitle => 'Какой у тебя рост?';

  @override
  String get onboardingHeightSubtitle =>
      'Это поможет нам точнее рассчитать твою дневную норму';

  @override
  String get onboardingWeightTitle => 'Сколько ты весишь\nсейчас?';

  @override
  String get onboardingWeightSubtitle =>
      'Это поможет нам рассчитать твою норму калорий';

  @override
  String get onboardingTargetTitle => 'Какой вес хочешь\nдостичь?';

  @override
  String get onboardingTargetSubtitle =>
      'Установи цель, к которой мы будем стремиться';

  @override
  String onboardingTargetFromCurrent(Object diff) {
    return '$diff кг от текущего веса';
  }

  @override
  String get onboardingBirthTitle => 'Когда ты родился?';

  @override
  String get onboardingBirthSubtitle =>
      'Эта информация поможет нам точнее\nрассчитать твою норму калорий';

  @override
  String get onboardingActivityTitle => 'Насколько ты активен?';

  @override
  String get onboardingActivitySubtitle =>
      'Это поможет нам точнее рассчитать твою\nнорму калорий';

  @override
  String get activitySedentary => 'Малоподвижный';

  @override
  String get activitySedentaryDesc => 'Офисная работа, почти без спорта.';

  @override
  String get activityLight => 'Лёгкая активность';

  @override
  String get activityLightDesc => '1-2 тренировки в неделю или прогулки.';

  @override
  String get activityModerate => 'Средняя активность';

  @override
  String get activityModerateDesc =>
      '3-5 тренировок в неделю, активный образ жизни.';

  @override
  String get activityHigh => 'Высокая активность';

  @override
  String get activityHighDesc => 'Ежедневные интенсивные тренировки.';

  @override
  String get onboardingSpeedTitle => 'Как быстро хочешь достичь\nцели?';

  @override
  String get onboardingSpeedSubtitle => 'Выбери комфортный для себя темп';

  @override
  String get optimal => 'Оптимально';

  @override
  String get slow => 'Медленно';

  @override
  String get fast => 'Быстро';

  @override
  String get onboardingGoogleTitle => 'Почти готово!';

  @override
  String get onboardingGoogleSubtitle =>
      'Войди через Google, чтобы сохранить свой прогресс';

  @override
  String get onboardingGoogleError =>
      'Не удалось войти через Google. Проверьте настройки Google провайдера в Supabase Dashboard.';

  @override
  String get onboardingGoogleBrowserHint =>
      'Откроется окно браузера для входа через Google';

  @override
  String get authError => 'Ошибка авторизации. Попробуйте ещё раз.';

  @override
  String get authTimeout => 'Время ожидания истекло. Попробуйте ещё раз.';

  @override
  String get continueWithGoogle => 'Продолжить с Google';

  @override
  String get onboardingCalcAnalysis => 'Анализ данных';

  @override
  String get onboardingCalcAnalysisSub => 'Обрабатываю твои параметры...';

  @override
  String get onboardingCalcCalories => 'Расчёт калорий';

  @override
  String get onboardingCalcCaloriesSub => 'Рассчитываю твою норму калорий...';

  @override
  String get onboardingCalcWorkout => 'Персональная тренировка';

  @override
  String get onboardingCalcWorkoutSub => 'Создаю программу тренировок...';

  @override
  String get onboardingCalcMeal => 'План питания';

  @override
  String get onboardingCalcMealSub => 'Составляю рацион на неделю...';

  @override
  String get onboardingCalcWater => 'Водный баланс';

  @override
  String get onboardingCalcWaterSub => 'Настраиваю режим воды...';

  @override
  String get onboardingCalcDone => 'Готово!';

  @override
  String get onboardingCalcDoneSub => 'Почти закончили...';

  @override
  String get onboardingPlanReady => 'Твой персональный план готов!';

  @override
  String get onboardingPlanReadyDesc =>
      'Мы рассчитали идеальный баланс для\nдостижения твоей цели.';

  @override
  String get onboardingPlanGoal => 'ДНЕВНАЯ НОРМА';

  @override
  String onboardingPlanSpeed(Object speed) {
    return '$speed кг / нед';
  }

  @override
  String get onboardingSkip => 'Пропустить';

  @override
  String get onboardingNext => 'Далее';

  @override
  String get onboardingStart => 'Начать';

  @override
  String get onboardingGoalButton => 'Цель';

  @override
  String get onboardingDone => 'Готово';

  @override
  String stepOutOf(Object total) {
    return 'из $total';
  }

  @override
  String get cm => 'см';

  @override
  String get ft => 'футы';

  @override
  String get kg => 'кг';

  @override
  String get lbs => 'фунты';

  @override
  String get configErrorTitle => 'Не передана конфигурация';

  @override
  String get configErrorDesc =>
      'Запустите приложение с параметром:\n\nflutter run --dart-define-from-file=env.json\n\nФайл env.json должен лежать в корне проекта\nи содержать SUPABASE_URL, SUPABASE_ANON_KEY,\nGEMINI_NUTRITION_API_KEY, OPENROUTER_API_KEY,\nSCANNER_API_KEY, SENTRY_DSN.';

  @override
  String get accessRestricted => 'Доступ ограничен';

  @override
  String get accessRestrictedSubtitle => 'Подтвердите личность для входа';

  @override
  String get unlockButton => 'Разблокировать';

  @override
  String get progress_meas_chest => 'Грудь';

  @override
  String get progress_meas_waist => 'Талия';

  @override
  String get progress_meas_hips => 'Бёдра';

  @override
  String get progress_meas_arm => 'Рука';

  @override
  String get progress_meas_thigh => 'Бедро';

  @override
  String get progress_meas_neck => 'Шея';

  @override
  String get restFinished => 'Отдых закончился — вперёд! 💪';

  @override
  String repsInSet(Object count) {
    return 'Повторения в подходе $count';
  }

  @override
  String weightInSet(Object count, Object unit) {
    return 'Вес в подходе $count ($unit)';
  }

  @override
  String get exampleReps => 'Например: 12';

  @override
  String get exampleWeight => 'Например: 8.5';

  @override
  String get replaceExercise => 'Заменить упражнение';

  @override
  String alternativesForMuscle(Object muscle) {
    return 'Альтернативы для мышц «$muscle»';
  }

  @override
  String exerciseReplaced(Object name) {
    return 'Упражнение заменено на «$name»';
  }

  @override
  String get markAtLeastOneSet => 'Отметь хотя бы один выполненный подход ✓';

  @override
  String get workoutRecorded => 'Тренировка записана!';

  @override
  String get sets => 'подходов';

  @override
  String get kgLabel => 'кг';

  @override
  String get volume => 'объём';

  @override
  String get great => 'Отлично';

  @override
  String restTimer(Object seconds) {
    return 'ОТДЫХ: $seconds сек';
  }

  @override
  String get howToPerform => 'Как выполнять';

  @override
  String get replace => 'Заменить';

  @override
  String get coachTip => 'Совет';

  @override
  String get kcal => 'ккал';

  @override
  String get repsHeader => 'ПОВТОРЕНИЯ';

  @override
  String get weightHeader => 'ВЕС (КГ)';

  @override
  String get addSet => '+ Добавить подход';

  @override
  String get saveResult => 'ЗАПИСАТЬ РЕЗУЛЬТАТ';

  @override
  String get defaultTip =>
      'Следи за техникой, не торопись и отдыхай между подходами. Прогресс приходит с регулярностью!';

  @override
  String get startWithComfortableWeight =>
      '💡 Начинай с комфортного веса и добавляй его, когда сделаешь все подходы чисто.';

  @override
  String get cancel => 'Отмена';

  @override
  String get done => 'Готово';

  @override
  String get buildNumber => 'Сборка';

  @override
  String get packageName => 'Пакет';

  @override
  String get privacyPolicyIntro =>
      'Welmi уважает вашу приватность. В этой Политике конфиденциальности объясняется, как мы собираем, используем и защищаем вашу личную информацию.';

  @override
  String get privacyDataTitle => '1. Сбор данных';

  @override
  String get privacyDataContent =>
      'Мы собираем следующую информацию для предоставления и улучшения наших услуг:\n\n• Личные данные: имя, пол, дата рождения, рост, вес\n• Данные о здоровье: шаги, калории, потребление воды, изменения веса\n• Данные об использовании: статистика использования приложения, просмотренные экраны\n• Информация об устройстве: модель устройства, версия ОС\n\nДанные о здоровье собираются только с вашего явного согласия через Health Connect (Android) или HealthKit (iOS).';

  @override
  String get privacyUsageTitle => '2. Как мы используем данные';

  @override
  String get privacyUsageContent =>
      'Мы используем собранные данные для:\n\n• Генерации персональных планов питания и тренировок\n• Отслеживания вашего прогресса к целям здоровья\n• Отправки напоминаний о воде, еде и тренировках\n• Улучшения качества рекомендаций AI\n• Обеспечения безопасности приложения и предотвращения злоупотреблений';

  @override
  String get privacyStorageTitle => '3. Хранение данных';

  @override
  String get privacyStorageContent =>
      'Все данные хранятся безопасно с использованием Supabase (PostgreSQL) с шифрованием при хранении и передаче. Ваши данные привязаны к вашей учётной записи и недоступны третьим лицам.';

  @override
  String get privacySharingTitle => '4. Передача данных';

  @override
  String get privacySharingContent =>
      'Мы НЕ продаём, не обмениваем и не передаём ваши личные данные третьим лицам, за исключением:\n\n• Когда это требуется по закону\n• Для защиты прав и безопасности Welmi и его пользователей\n• С вашего явного согласия';

  @override
  String get privacyRightsTitle => '5. Ваши права';

  @override
  String get privacyRightsContent =>
      'Вы имеете право:\n\n• Просматривать все свои данные в приложении (Профиль → Редактировать)\n• Запросить удаление учётной записи и всех данных\n• Отказаться от уведомлений в любое время\n• Отключить Health Connect в любое время\n\nДля удаления данных свяжитесь с нами через раздел «Поддержка».';

  @override
  String get privacySecurityContent =>
      'Мы реализуем стандартные меры безопасности:\n\n• Шифрование данных при передаче (TLS/SSL)\n• Шифрование данных при хранении\n• Аутентификация через Google OAuth\n• Row-Level Security (RLS) в базе данных';

  @override
  String get privacyChildrenTitle => '6. Конфиденциальность детей';

  @override
  String get privacyChildrenContent =>
      'Welmi не предназначен для детей младше 13 лет. Мы намеренно не собираем личную информацию от детей младше 13 лет. Если вы считаете, что мы собрали такую информацию, немедленно свяжитесь с нами.';

  @override
  String get privacyChangesTitle => '7. Изменения в политике';

  @override
  String get privacyChangesContent =>
      'Мы можем обновлять эту Политику конфиденциальности время от времени. Изменения будут опубликованы в приложении и вступят в силу с момента публикации.';

  @override
  String get privacyLastUpdated => 'Последнее обновление: август 2026';

  @override
  String get contactTitle => '8. Контакты';

  @override
  String get privacyContactContent =>
      'Если у вас есть вопросы о Политике конфиденциальности, свяжитесь с нами:\n\n• Telegram: @welmi_support\n• Email: support@welmi.app';

  @override
  String get termsIntro =>
      'Добро пожаловать в Welmi. Используя наше приложение, вы соглашаетесь с настоящими Условиями использования. Пожалуйста, прочитайте их внимательно.';

  @override
  String get termsAcceptanceTitle => '1. Принятие условий';

  @override
  String get termsAcceptanceContent =>
      'Устанавливая и используя Welmi, вы соглашаетесь с настоящими Условиями использования. Если вы не согласны с какой-либо частью этих условий, вы не должны использовать приложение.';

  @override
  String get termsServiceTitle => '2. Описание сервиса';

  @override
  String get termsServiceContent =>
      'Welmi — это мобильное приложение для отслеживания питания, потребления воды, физической активности и веса. Приложение предоставляет:\n\n• AI-планы питания и тренировок\n• Дневник питания и подсчёт калорий\n• Напоминания о воде\n• Аналитику прогресса\n• Интеграцию с Health Connect / HealthKit\n\nВсе рекомендации носят информационный характер и не являются медицинскими советами.';

  @override
  String get termsAccountTitle => '3. Ваша учётная запись';

  @override
  String get termsAccountContent =>
      'Вы несёте ответственность за конфиденциальность своей учётной записи. Вы соглашаетесь предоставить точную информацию при регистрации и поддерживать её в актуальном состоянии.';

  @override
  String get termsSubscriptionTitle => '4. Подписка и оплата';

  @override
  String get termsSubscriptionContent =>
      'Welmi предлагает бесплатный пробный период, после которого для полного доступа требуется подписка. Оплата осуществляется через App Store (iOS) или Google Play (Android). Вы можете отменить подписку в любое время в настройках магазина. Пробный период автоматически переходит в платную подписку, если не отменён за 24 часа до окончания.';

  @override
  String get termsContentTitle => '5. Пользовательский контент';

  @override
  String get termsContentContent =>
      'Вы сохраняете все права на данные, которые вводите в приложение. Мы не претендуем на владение вашими личными данными, записями о еде или тренировках.';

  @override
  String get termsProhibitedTitle => '6. Запрещённые действия';

  @override
  String get termsProhibitedContent =>
      'Вы НЕ должны:\n\n• Использовать приложение в незаконных целях\n• Пытаться взломать или получить несанкционированный доступ к приложению или его серверам\n• Распространять вредоносное ПО\n• Неправомерно использовать функции AI\n• Перепродавать или распространять приложение\n• Выдавать себя за другого человека';

  @override
  String get termsDisclaimerTitle => '7. Отказ от ответственности';

  @override
  String get termsDisclaimerContent =>
      'Welmi предоставляется «как есть» без каких-либо гарантий. Мы не гарантируем:\n\n• Непрерывную или бесперебойную работу\n• Точность рекомендаций, сгенерированных AI\n• Совместимость со всеми устройствами\n\nРекомендуем проконсультироваться с врачом перед началом любой диеты или программы тренировок.';

  @override
  String get termsLiabilityTitle => '8. Ограничение ответственности';

  @override
  String get termsLiabilityContent =>
      'Welmi и его разработчики не несут ответственности за косвенные, случайные или косвенные убытки, возникающие в результате использования приложения, включая, но не ограничиваясь, проблемы со здоровьем, следующие из рекомендаций приложения.';

  @override
  String get termsTerminationTitle => '9. Прекращение доступа';

  @override
  String get termsTerminationContent =>
      'Мы оставляем за собой право прекратить или приостановить ваш доступ к приложению в любое время, с уведомлением или без него, за поведение, нарушающее настоящие Условия.';

  @override
  String get termsChangesTitle => '10. Изменения в условиях';

  @override
  String get termsChangesContent =>
      'Мы можем изменять эти Условия в любое время. Обновлённые условия будут опубликованы в приложении. Продолжение использования приложения после изменений означает.acceptance новых условий.';

  @override
  String get termsLastUpdated => 'Последнее обновление: август 2026';

  @override
  String get termsContactContent =>
      'По вопросам настоящих Условий использования свяжитесь с нами:\n\n• Telegram: @welmi_support\n• Email: support@welmi.app';

  @override
  String get securityTitle => 'Безопасность';

  @override
  String get feedbackEmptyMessage => 'Напиши сообщение перед отправкой.';

  @override
  String get feedbackMessageTooLong =>
      'Сообщение слишком длинное. Максимум 3000 символов.';

  @override
  String get feedbackSessionError =>
      'Не удалось подтвердить сессию. Перезапусти приложение и попробуй снова.';

  @override
  String get feedbackRateLimitError =>
      'Слишком много запросов. Подожди немного и попробуй снова.';

  @override
  String get feedbackSendError =>
      'Не удалось отправить сообщение. Проверь интернет и попробуй ещё раз.';

  @override
  String get feedbackFunctionMissing =>
      'Сервис обратной связи ещё не опубликован. Попробуй позже.';

  @override
  String get feedbackSecretsMissing =>
      'Сервис обратной связи не настроен. Попробуй позже.';

  @override
  String get feedbackTelegramError =>
      'Telegram временно не доставил сообщение. Попробуй ещё раз позже.';

  @override
  String get feedbackFunctionError =>
      'Сервис обратной связи временно недоступен. Попробуй позже.';

  @override
  String get feedbackNetworkError =>
      'Нет соединения с сервисом. Проверь интернет и попробуй снова.';

  @override
  String get voiceErrorNoInternet =>
      'Нет интернета. Для распознавания голоса нужен интернет.';

  @override
  String get voiceErrorUnavailable =>
      'Распознавание речи сейчас недоступно. Попробуй позже.';

  @override
  String get voiceErrorRecord => 'Не удалось начать запись. Попробуй ещё раз.';

  @override
  String get voiceErrorPermissionSettings =>
      'Доступ к микрофону запрещён. Разреши его в настройках телефона.';

  @override
  String get ttsPlay => 'Озвучить';

  @override
  String get ttsStop => 'Остановить';

  @override
  String get ttsReplay => 'Повторить';

  @override
  String get ttsVoiceSettings => 'Голос озвучивания';

  @override
  String get ttsVoiceDefault => 'Голос по умолчанию';

  @override
  String get ttsVoicesEmpty =>
      'На устройстве нет голосов для этого языка. Установите синтезатор речи в системных настройках.';

  @override
  String get ttsErrorUnavailable =>
      'Озвучивание недоступно на этом устройстве.';

  @override
  String get aiErrorUnavailable =>
      'AI-помощник не ответил. Проверь подключение и попробуй ещё раз.';

  @override
  String get voiceFoodNotRecognized =>
      'Не удалось определить продукты. Попробуй ещё раз.';

  @override
  String get voiceFoodAnalysisError =>
      'Ошибка анализа продуктов. Попробуй ещё раз.';

  @override
  String get weightInvalid => 'Введи корректный вес';

  @override
  String get weightSaveError =>
      'Не удалось сохранить вес. Проверь интернет и попробуй ещё раз.';

  @override
  String get weightSaved => 'Вес сохранён';

  @override
  String get saveError =>
      'Не удалось сохранить. Проверь интернет и попробуй ещё раз.';

  @override
  String get signInRequired => 'Войди в аккаунт, чтобы сохранять данные';

  @override
  String get navHome => 'Главная';

  @override
  String get navScanner => 'Сканер еды';

  @override
  String get navProfile => 'Профиль';

  @override
  String get heightInvalid => 'Введи рост от 100 до 250 см';

  @override
  String get voiceErrorLanguage =>
      'Распознавание этого языка не установлено. Добавь его в настройках голосового ввода Google.';

  @override
  String get voiceListening => 'Говори, я слушаю…';

  @override
  String get biometricTitle => 'Вход в Welmi';

  @override
  String get biometricReason => 'Подтверди личность, чтобы открыть Welmi';

  @override
  String get biometricHint => 'Приложи палец к сканеру';

  @override
  String get notifClearDelivered => 'Очистить';

  @override
  String get notifClearedDelivered =>
      'Уведомления очищены. Напоминания продолжат работать.';

  @override
  String get voiceSayAgain => 'Сказать заново';

  @override
  String get addToDiary => 'Добавить в дневник';

  @override
  String get voiceDoneRecognize => 'Готово, распознать';

  @override
  String get scannerTitle => 'AI-сканер';

  @override
  String get scannerSubtitle => 'Фото блюда → калории и БЖУ';

  @override
  String get scannerTakePhoto => 'Сфотографируй еду';

  @override
  String get scannerHint =>
      'Welmi AI определит калории, белки, жиры и углеводы';

  @override
  String get scannerAnalyzing => 'Анализируем фото...';

  @override
  String get scannerNotRecognized =>
      'Welmi AI не удалось распознать еду. Попробуй другое фото.';

  @override
  String get scannerAiError => 'Ошибка связи с AI. Проверь интернет.';

  @override
  String get scannerCameraError => 'Не удалось открыть камеру';

  @override
  String get scannerGalleryError => 'Не удалось открыть галерею';

  @override
  String get scannerRetake => 'Заново';

  @override
  String get scannerToDiary => 'В дневник';

  @override
  String scannerAdded(Object kcal) {
    return 'Добавлено: $kcal ккал';
  }

  @override
  String get gramsShort => 'г';

  @override
  String activityStepsToGoal(Object steps) {
    return '$steps шагов до цели';
  }

  @override
  String get activityGoalReached => 'Цель достигнута! 🎉';

  @override
  String get activityStepsUnit => 'шагов';

  @override
  String activityGoalSteps(Object steps) {
    return '$steps шагов';
  }

  @override
  String get activityDistance => 'Дистанция';

  @override
  String get activityEnergy => 'Энергия';

  @override
  String get activityGoal => 'Цель';

  @override
  String get minutesShort => 'мин';

  @override
  String get activityHealthSubtitle => 'Подтянуть шаги и калории автоматически';

  @override
  String get activitySyncShort => 'Синхр.';

  @override
  String get activityTipTitle => 'Совет дня';

  @override
  String get activityTipLow =>
      'Больше двигайся! Постарайся сделать хотя бы 8000 шагов сегодня 🚶';

  @override
  String get activityTipMid =>
      'Хорошо, можно и больше! Добавь 15 мин прогулки 🌳';

  @override
  String get activityTipHigh => 'Отлично! Ещё немного до цели! 💪';

  @override
  String get activityTipDone => 'Цель достигнута! Ты невероятен! 🎉';

  @override
  String get activityLoadError =>
      'Не удалось загрузить активность. Проверь интернет.';

  @override
  String get healthInstallHint =>
      'Для синхронизации шагов установи приложение Health Connect';

  @override
  String healthSynced(Object kcal, Object steps) {
    return 'Синхронизировано: $steps шагов · $kcal ккал';
  }

  @override
  String healthSleepSuffix(Object hours) {
    return ' · сон $hours ч';
  }

  @override
  String get healthNotAuthorized => 'Доступ к данным здоровья не получен';

  @override
  String get healthUnsupported => 'Синхронизация доступна только на телефоне';

  @override
  String get healthError => 'Не удалось получить данные из Health Connect';

  @override
  String get historyRecentDays => 'Последние дни';

  @override
  String get historyEmptyTitle => 'Пока нет записей';

  @override
  String get historyEmptySubtitle => 'Запиши шаги, воду или тренировку';

  @override
  String get historyLogButton => 'Записать';

  @override
  String get historyLoadError =>
      'Не удалось загрузить историю. Проверь интернет.';

  @override
  String waterAddedMl(Object ml) {
    return '+$ml мл воды';
  }

  @override
  String get refresh => 'Обновить';

  @override
  String get waterMlLabel => 'мл воды';

  @override
  String get historySteps30 => 'шагов за 30 дней';

  @override
  String get historyWater14 => 'воды за 14 дней';

  @override
  String get historyActiveDays => 'активных дней';

  @override
  String litersValue(Object value) {
    return '$value л';
  }

  @override
  String weekLostValue(Object amount) {
    return 'Потеряно $amount';
  }

  @override
  String weekGainedValue(Object amount) {
    return 'Набрано $amount';
  }

  @override
  String currentWeightUnit(Object unit) {
    return 'Текущий вес ($unit)';
  }

  @override
  String get weightEmptyTitle => 'Пока нет записей веса';

  @override
  String get weightEmptySubtitle =>
      'Запиши вес, чтобы следить за прогрессом к цели';

  @override
  String waterRemainingMl(Object ml) {
    return 'Осталось $ml мл';
  }

  @override
  String waterOfGoal(Object goal) {
    return 'из $goal мл';
  }

  @override
  String mlValue(Object ml) {
    return '$ml мл';
  }

  @override
  String get waterWeekTitle => 'Вода за неделю';

  @override
  String get waterDrunk => 'Выпито сегодня';

  @override
  String get feedbackCategoryBug => 'Ошибка';

  @override
  String get feedbackCategoryIdea => 'Идея';

  @override
  String supportOpenFailed(Object contact) {
    return 'Не удалось открыть приложение. Напишите нам: $contact';
  }

  @override
  String get authGoogleSigningIn => 'Авторизация…';

  @override
  String get authGoogleBrowserHint =>
      'Откроется окно браузера для входа через Google';

  @override
  String get authAlmostDone => 'Почти готово!';

  @override
  String get authGoogleSubtitle =>
      'Войди через Google, чтобы сохранить свой прогресс';

  @override
  String get authContinueWithGoogle => 'Продолжить с Google';

  @override
  String get authGoogleFailed =>
      'Не удалось войти через Google. Попробуйте позже.';

  @override
  String get recipeSignInToAdd => 'Войдите, чтобы добавить блюдо в дневник';

  @override
  String recipeAddedToMeal(String meal) {
    return 'Рецепт добавлен в «$meal»';
  }

  @override
  String get recipeAddFailed =>
      'Не удалось добавить рецепт. Проверьте подключение.';

  @override
  String get recipeServingInfo => '1 порция · рецепт Welmi';

  @override
  String get offErrRateLimited =>
      'Open Food Facts ограничил частоту запросов. Подожди минуту и повтори.';

  @override
  String get offErrTimeout =>
      'Open Food Facts не ответил вовремя. Проверь интернет и повтори.';

  @override
  String get offErrNetwork =>
      'Нет связи с Open Food Facts. Проверь интернет и повтори.';

  @override
  String get offErrRequest =>
      'Не удалось загрузить данные из Open Food Facts. Попробуй ещё раз.';

  @override
  String offErrUnavailable(Object code) {
    return 'Open Food Facts временно недоступен (код $code).';
  }

  @override
  String get offErrBadResponse =>
      'Open Food Facts вернул некорректный ответ. Попробуй позже.';

  @override
  String offErrTooMany(Object seconds) {
    return 'Слишком много запросов. Повтори через $seconds с.';
  }

  @override
  String get foodDbSearchFailed =>
      'Не удалось выполнить поиск. Проверь интернет и повтори.';

  @override
  String get foodDbTitle => 'База продуктов';

  @override
  String get foodDbSubtitle => 'Open Food Facts · значения на 100 г';

  @override
  String get foodDbSearchHint => 'Название или штрихкод';

  @override
  String get clearAction => 'Очистить';

  @override
  String get foodDbScanBarcode => 'Сканировать штрихкод';

  @override
  String foodDbFound(Object count) {
    return 'Найдено: $count';
  }

  @override
  String get foodDbStartTitle => 'Найди продукт по названию';

  @override
  String get foodDbStartBody =>
      'Или отсканируй штрихкод упаковки. Пищевая ценность пересчитается на твою порцию.';

  @override
  String get foodDbStartFootnote =>
      'Данные добровольные и могут быть неполными — мы показываем «—», если значения нет в базе.';

  @override
  String get foodDbNotFoundTitle => 'Продукт не найден';

  @override
  String get foodDbNothingFoundTitle => 'Ничего не найдено';

  @override
  String get foodDbNotFoundBarcodeBody =>
      'Этого штрихкода нет в Open Food Facts. Проверь цифры или добавь продукт вручную.';

  @override
  String get foodDbNothingFoundBody =>
      'Проверь название или отсканируй штрихкод. Продукт можно добавить вручную в дневнике.';

  @override
  String get foodDbSearching => 'Ищем в Open Food Facts...';

  @override
  String get foodNoNutritionData => 'Нет данных о пищевой ценности';

  @override
  String get foodCaloriesOnly => 'Калорийность без БЖУ';

  @override
  String get foodKcalPer100 => 'ккал / 100 г';

  @override
  String get macroProteinShort => 'Б';

  @override
  String get macroFatShort => 'Ж';

  @override
  String get macroCarbsShort => 'У';

  @override
  String get foodPer100NoData => 'Пищевая ценность: нет данных';

  @override
  String foodPer100(Object values) {
    return 'На 100 г: $values';
  }

  @override
  String get foodKcalEstimatedNote =>
      'Калорийность рассчитана из БЖУ: в базе её нет.';

  @override
  String get foodMacrosIncompleteNote =>
      'В базе заполнены не все нутриенты — «—» означает «нет данных».';

  @override
  String get nutrientProtein => 'Белки';

  @override
  String get nutrientFat => 'Жиры';

  @override
  String get nutrientCarbs => 'Углеводы';

  @override
  String get nutrientCalories => 'Калории';

  @override
  String get foodNoNutritionCard =>
      'В Open Food Facts у этого продукта нет пищевой ценности. Добавь запись вручную из дневника.';

  @override
  String foodServingPrefix(Object size) {
    return 'порция $size';
  }

  @override
  String get torchFailed => 'Не удалось включить фонарик';

  @override
  String barcodeNotFound(Object barcode) {
    return 'Продукт со штрихкодом $barcode не найден в Open Food Facts. Проверь упаковку или добавь запись вручную.';
  }

  @override
  String get barcodeLoadFailed =>
      'Не удалось загрузить продукт. Проверь интернет и повтори.';

  @override
  String get back => 'Назад';

  @override
  String get barcodeTitle => 'Штрихкод';

  @override
  String get barcodeAimHint => 'Наведи камеру на упаковку';

  @override
  String get torch => 'Фонарик';

  @override
  String get barcodeScanAgain => 'Сканировать снова';

  @override
  String get barcodeFormatsNote =>
      'Поддерживаются EAN-8, EAN-13, UPC-A, UPC-E и Code 128.\nДанные: Open Food Facts.';

  @override
  String get barcodeLookingUp => 'Ищем продукт...';

  @override
  String get cameraUnavailable => 'Камера недоступна';

  @override
  String get cameraUnavailableHint =>
      'Разреши доступ к камере в настройках телефона или введи штрихкод в строке поиска.';

  @override
  String get foodNameEmpty => 'Название не может быть пустым.';

  @override
  String get foodKcalInvalid => 'Укажи калорийность целым числом.';

  @override
  String get foodGramsRange => 'Масса порции должна быть от 1 до 5000 г.';

  @override
  String get foodEditEntry => 'Изменить запись';

  @override
  String get foodPortionWeightG => 'Масса порции, г';

  @override
  String get foodRecalcNote =>
      'При изменении массы калории и БЖУ пересчитываются автоматически.';

  @override
  String get nutrientProteinG => 'Белки, г';

  @override
  String get nutrientFatG => 'Жиры, г';

  @override
  String get nutrientCarbsG => 'Углеводы, г';

  @override
  String get foodPortionTitle => 'Порция';

  @override
  String get foodPortionWeight => 'Масса порции';

  @override
  String get foodEnterGramsRange => 'Укажи массу порции от 1 до 5000 г.';

  @override
  String get foodNoCaloriesCantSave =>
      'В базе нет калорийности этого продукта — запись нельзя сохранить.';

  @override
  String gramsValue(Object value) {
    return '$value г';
  }

  @override
  String get foodEnterGramsToSee => 'Введи массу, чтобы увидеть расчёт.';

  @override
  String get foodDataSource => 'Данные: Open Food Facts (открытая база)';

  @override
  String get diaryLoadError => 'Ошибка загрузки данных';

  @override
  String get diaryEntryUpdated => 'Запись обновлена';

  @override
  String get diaryEntryUpdateFailed => 'Не удалось обновить запись';

  @override
  String get diaryDeleteEntryTitle => 'Удалить запись?';

  @override
  String get diaryDeleteEntryBody => 'Запись будет удалена из дневника.';

  @override
  String diaryDeleteNamedBody(Object name) {
    return '«$name» будет удалена из дневника.';
  }

  @override
  String get diaryEntryDeleted => 'Запись удалена';

  @override
  String get diaryEntryDeleteFailed => 'Не удалось удалить запись';

  @override
  String get diaryAddByVoice => 'Добавить голосом';

  @override
  String get diaryVoiceShort => 'Голос';

  @override
  String get diaryFindInDatabase => 'Найти продукт в Open Food Facts';

  @override
  String get diaryDatabaseShort => 'База';

  @override
  String get deleteAction => 'Удалить';

  @override
  String get editAction => 'Изменить';

  @override
  String get voiceFoodClarifyFirst =>
      'Уточните количество продукта, чтобы получить примерную оценку.';

  @override
  String get voiceFoodGenericError => 'Произошла ошибка при распознавании';

  @override
  String kcalApprox(Object kcal) {
    return '~$kcal ккал';
  }

  @override
  String kcalValue(Object kcal) {
    return '$kcal ккал';
  }

  @override
  String get voiceFoodClarifyHint => 'Например: 150 грамм';

  @override
  String get voiceFoodClarify => 'Уточнить';

  @override
  String voiceFoodListening(Object time) {
    return 'Слушаю... ($time)';
  }

  @override
  String get voiceFoodExample =>
      'Например: «Два яйца, два куска хлеба и банан»';

  @override
  String get voiceFoodAnalyzing => 'AI анализирует продукты...';

  @override
  String get voiceFoodRecognized => 'Распознано:';

  @override
  String get voiceFoodEstimate => 'Примерная оценка:';

  @override
  String get voiceFoodHideEdit => 'Скрыть правку';

  @override
  String get voiceFoodEditData => 'Изменить данные';

  @override
  String voiceFoodTitle(Object meal) {
    return 'Голосовой ввод: $meal';
  }

  @override
  String get voiceFoodSubtitle => 'Назови блюдо и количество';

  @override
  String homeDiarySummary(Object consumed, Object goal, Object protein) {
    return '$consumed из $goal ккал · $proteinг белка';
  }

  @override
  String get bfEstimateTitle => 'Оценка % жира';

  @override
  String get bfEstimateNoData =>
      'Недостаточно данных для расчёта.\n\nНужны: рост и пол в профиле, а также замеры талии и шеи (для женщин — ещё и бёдер). Добавьте замеры и попробуйте снова.';

  @override
  String get bfEstimateMethodMale =>
      'Расчёт по методу ВМФ США (Navy) на основе обхватов талии, шеи и роста.\n\nЭто приблизительная оценка, а не измерение. Погрешность метода — несколько процентных пунктов.';

  @override
  String get bfEstimateMethodFemale =>
      'Расчёт по методу ВМФ США (Navy) на основе обхватов талии, шеи, бёдер и роста.\n\nЭто приблизительная оценка, а не измерение. Погрешность метода — несколько процентных пунктов.';

  @override
  String get bfCatExtremelyLow => '⚡ Экстремально низкий';

  @override
  String get bfCatAthletic => '💪 Спортивный';

  @override
  String get bfCatNormal => '✅ Нормальный';

  @override
  String get bfCatAboveNormal => '📈 Выше нормы';

  @override
  String get bfCatHigh => '⚠️ Высокий';

  @override
  String get bfHeaderCaps => '% ЖИРА В ТЕЛЕ';

  @override
  String get progressLast28Days => 'Последние 28 дней';

  @override
  String get legendHasEntry => 'есть запись';

  @override
  String get legendToday => 'сегодня';

  @override
  String get legendTapDay => 'нажмите на день';

  @override
  String get bfMethodCaliper => 'калипер';

  @override
  String get bfMethodScale => 'весы';

  @override
  String get bfMethodEstimated => 'оценка';

  @override
  String get bfMethodManual => 'вручную';

  @override
  String get bfEmptyTitle => 'Пока нет данных о % жира';

  @override
  String get bfEmptySubtitle =>
      'Запишите процент жира в теле, чтобы отслеживать изменения';

  @override
  String get bfDynamics => 'Динамика % жира';

  @override
  String get bfNoEntriesInPeriod => 'За выбранный период нет записей % жира';

  @override
  String get bfEstimateDisclaimer =>
      'Оценочный расчёт по замерам — не медицинское измерение.';

  @override
  String get bfEstimateFromMeasurements => 'Оценить по замерам';

  @override
  String get historyLabel => 'История';

  @override
  String get progressNoEntriesDay => 'За этот день записей нет.';

  @override
  String bfEstimatedSuffix(Object label) {
    return '$label (оценка)';
  }

  @override
  String chartNeedTwoEntries(Object count) {
    return 'Нужно минимум 2 записи за выбранный период\n($count из 2)';
  }

  @override
  String get measEmptyTitle => 'Пока нет замеров';

  @override
  String get measEmptySubtitle => 'Запишите объёмы груди, талии, бёдер и рук';

  @override
  String get measLatest => 'Последние замеры';

  @override
  String get measDynamics => 'Динамика замеров';

  @override
  String measNoEntriesInPeriod(Object metric) {
    return 'За выбранный период нет замеров «$metric»';
  }

  @override
  String get currentWeightCaps => 'ТЕКУЩИЙ ВЕС';

  @override
  String get bfChipCaliper => 'Калипер';

  @override
  String get bfChipScale => 'Весы';

  @override
  String get bfChipManual => 'Вручную';

  @override
  String get bfRangeError => 'Введи % жира от 2 до 70';

  @override
  String get bfEstimateSaved => 'Оценка сохранена как оценочное значение';

  @override
  String get progressEmptyTitle => 'Нет данных для отображения';

  @override
  String get progressEmptySubtitle =>
      'Начните записывать вес, замеры и процент жира,\nчтобы увидеть свой прогресс';

  @override
  String get progressRecordFirstWeight => 'Записать первый вес';

  @override
  String daysCount(Object days) {
    return '$days дней';
  }

  @override
  String get progressActivityOfEntries => 'Активность записей';

  @override
  String get workoutGeneralFocus => 'Общая';

  @override
  String get premiumGateTitle => 'Эта функция доступна в Welmi Premium';

  @override
  String get premiumGateSubtitle =>
      'Статус проверяется по подтверждённой подписке магазина.';

  @override
  String get premiumGateButton => 'Посмотреть Premium';

  @override
  String profileBmrTdee(Object bmr, Object tdee) {
    return 'BMR $bmr ккал · TDEE $tdee ккал';
  }

  @override
  String get unsavedChangesBody =>
      'У вас есть несохранённые изменения. Они будут потеряны.';

  @override
  String get stayAction => 'Остаться';

  @override
  String get leaveAction => 'Выйти';

  @override
  String get profileUserUnknown => 'Не удалось определить пользователя';

  @override
  String get profilePhotoNotUploaded => 'Фото не загрузилось';

  @override
  String profileSavedWithWarning(Object warning) {
    return 'Профиль сохранён. $warning';
  }

  @override
  String get profileLoading => 'Загружаем профиль...';

  @override
  String get profileMyProfile => 'Мой профиль';

  @override
  String get profileWeightGoal => 'Цель веса';

  @override
  String get profileCurrent => 'Текущий';

  @override
  String get profileLeftToLose => 'Осталось сбросить';

  @override
  String get profileLeftToGain => 'Осталось набрать';

  @override
  String get profileTarget => 'Целевой';

  @override
  String get subscriptionActiveShort => 'Активна';

  @override
  String get subscriptionChoose => 'Выбрать';

  @override
  String get subManage => 'Управлять подпиской';

  @override
  String get subActiveMessage => 'Подписка активна.';

  @override
  String get subOfferUnavailable => 'Предложение недоступно';

  @override
  String subContinuePrice(Object price) {
    return 'Продолжить · $price';
  }

  @override
  String get subRestore => 'Восстановить покупки';

  @override
  String get subRefreshOffers => 'Обновить предложения';

  @override
  String get subTermsNote =>
      'Оплата и условия подписки показываются магазином перед подтверждением покупки. Управлять автопродлением можно в настройках магазина.';

  @override
  String get subHeroSubtitle => 'Больше возможностей для заботы о себе';

  @override
  String get subInPremium => 'В Premium';

  @override
  String get subFeatureScanner => 'Умный сканер еды';

  @override
  String get subFeatureWorkouts => 'Планы тренировок от AI';

  @override
  String get subFeatureAnalytics => 'Подробная аналитика и замеры';

  @override
  String get subFeatureHealth => 'Синхронизация с Health Connect';

  @override
  String get subFeatureNoAds => 'Без рекламы';

  @override
  String get subPlanMonth => 'На месяц';

  @override
  String get subPlanYear => 'На год';

  @override
  String get subPremiumActive => 'Premium активен';

  @override
  String subValidUntil(Object date) {
    return 'Действует до $date';
  }

  @override
  String get subErrStore => 'Ошибка магазина. Попробуйте ещё раз.';

  @override
  String get subErrStoreUnavailableDevice =>
      'Магазин покупок недоступен на этом устройстве.';

  @override
  String get subErrStoreUnavailable => 'Магазин покупок сейчас недоступен.';

  @override
  String get subErrProductsMissing =>
      'Тарифы пока недоступны в магазине. Попробуйте позже.';

  @override
  String get subErrProductsLoad => 'Не удалось загрузить предложения магазина.';

  @override
  String get subErrEntitlement => 'Не удалось проверить статус Premium.';

  @override
  String get subErrPlanNotFound => 'Тариф не найден в магазине.';

  @override
  String get subErrSignInToSubscribe =>
      'Для оформления подписки войдите в аккаунт Welmi.';

  @override
  String get subErrPurchaseNotStarted =>
      'Магазин не запустил покупку. Попробуйте ещё раз.';

  @override
  String get subErrPurchaseStart => 'Не удалось начать покупку.';

  @override
  String get subErrSignInToRestore =>
      'Войдите в Welmi, чтобы восстановить подписку.';

  @override
  String get subErrRestore => 'Не удалось восстановить покупки.';

  @override
  String get subErrManageUnsupported =>
      'Управлять подпиской можно на устройстве с App Store или Google Play.';

  @override
  String get subErrManageOpen => 'Не удалось открыть управление подпиской.';

  @override
  String get subErrPurchaseFailed => 'Магазин не завершил покупку.';

  @override
  String get subErrVerification =>
      'Покупка получена, но серверная проверка не завершилась. Нажмите «Восстановить покупки» чуть позже.';

  @override
  String get subNoticeNoActive => 'Активная подписка не найдена.';

  @override
  String get subNoticeCancelled => 'Покупка отменена.';

  @override
  String get subNoticeActivated => 'Welmi Premium активирован.';

  @override
  String get calcStatusAnalyzing => 'Анализируем твои данные...';

  @override
  String get calcStatusMetabolism => 'Рассчитываем метаболизм...';

  @override
  String get calcStatusMacros => 'Считаем калории и БЖУ...';

  @override
  String get calcStatusPersonalReady => 'Персональный план готов! ✅';

  @override
  String get calcStatusReady => 'План готов! ✅';

  @override
  String get calcProteinShort => 'белки';

  @override
  String get calcFatShort => 'жиры';

  @override
  String get calcCarbsShort => 'углев.';

  @override
  String get chooseLanguage => 'Выбери язык';

  @override
  String get languageLabel => 'Язык / Тил';

  @override
  String get perDaySuffix => '/день';

  @override
  String get splashTagline => 'Твой путь к здоровью';

  @override
  String get model3dTimeout => 'Модель не успела загрузиться';

  @override
  String get model3dRotateHint => 'Вращай модель пальцем';

  @override
  String get model3dFailed => '3D-модель не загрузилась';

  @override
  String model3dFailedReason(Object reason) {
    return '3D-модель: $reason';
  }

  @override
  String get tryAgain => 'Попробовать снова';

  @override
  String rangeLastDaysShort(Object days) {
    return 'за $days дн.';
  }

  @override
  String get filtersTitle => 'Фильтры';

  @override
  String get recipeSearchHint => 'Найти блюдо или ингредиент';

  @override
  String get recipePopular => 'Популярные';

  @override
  String recipeResults(Object count) {
    return 'Результаты · $count';
  }

  @override
  String get resetAction => 'Сбросить';

  @override
  String get recipeFilterProteinFrom => 'Белок от';

  @override
  String get recipeFilterTimeUpTo => 'Время до';

  @override
  String get recipeFilterDiet => 'Питание';

  @override
  String get recipeDietVegetarian => 'Вегетарианские';

  @override
  String get recipeDietSugarFree => 'Без сахара';

  @override
  String get showAction => 'Показать';

  @override
  String get anyOption => 'Любое';

  @override
  String filterUpToKcal(Object value) {
    return 'До $value ккал';
  }

  @override
  String filterFromGrams(Object value) {
    return 'От $value г';
  }

  @override
  String filterUpToMinutes(Object value) {
    return 'До $value мин';
  }

  @override
  String recipeMetaWeight(Object grams, Object minutes) {
    return '$minutes мин · $grams г';
  }

  @override
  String recipeMetaProtein(Object minutes, Object protein) {
    return '$minutes мин · Б $protein г';
  }

  @override
  String get favoriteRemove => 'Убрать из избранного';

  @override
  String get favoriteAdd => 'В избранное';

  @override
  String get recipeNothingFound =>
      'Ничего не найдено.\nПопробуйте изменить запрос или фильтры.';

  @override
  String get recipesComingSoon => 'Рецепты скоро появятся.';

  @override
  String recipeNoPhotoLabel(Object label) {
    return 'Нет фото: $label';
  }

  @override
  String get recipePhotoSoon => 'Фото скоро появится';

  @override
  String get recipeAddToMeal => 'Добавить в приём пищи';

  @override
  String get recipeBonAppetit => 'Приятного аппетита!';

  @override
  String recipePhotoCredit(Object credit) {
    return 'Фото: $credit';
  }

  @override
  String recipeStep(Object step) {
    return 'Шаг $step';
  }

  @override
  String get recipeCook => 'Готовить';

  @override
  String get recipeAsk => 'Спросить';

  @override
  String recipeAskPrompt(
    Object carbs,
    Object fat,
    Object kcal,
    Object protein,
    Object title,
  ) {
    return 'Я готовлю рецепт «$title» ($kcal ккал, Б $protein г, Ж $fat г, У $carbs г). Подскажи:';
  }

  @override
  String get recipeNutritionTitle => 'Калории и нутриенты';

  @override
  String recipeMicros(Object fiber, Object sodium, Object sugar) {
    return 'Клетчатка $fiber г · Сахар $sugar г · Натрий $sodium мг';
  }

  @override
  String get recipeNutritionDisclaimer =>
      'КБЖУ — оценочные значения на порцию по составу рецепта. TheMealDB не публикует пищевую ценность.';

  @override
  String recipeIngredients(Object servings) {
    return 'Ингредиенты · $servings порция';
  }

  @override
  String get recipeCooking => 'Приготовление';

  @override
  String recipeStepOf(Object step, Object total) {
    return 'Шаг $step из $total';
  }

  @override
  String get recipeFinish => 'Завершить';

  @override
  String get recipeNextStep => 'Следующий шаг';

  @override
  String get notifChannelWater => 'Welmi · Вода';

  @override
  String get notifChannelWaterDesc => 'Напоминания о воде';

  @override
  String get notifChannelMeals => 'Welmi · Питание';

  @override
  String get notifChannelMealsDesc => 'Завтрак, обед и ужин';

  @override
  String get notifChannelActivity => 'Welmi · Активность';

  @override
  String get notifChannelActivityDesc => 'Активность и вечерние напоминания';

  @override
  String get notifTestBody => 'Локальные уведомления работают!';

  @override
  String get remWaterTitle => '💧 Пора выпить воды';

  @override
  String get remWaterBody => 'Не забывай о дневной цели по воде в Welmi';

  @override
  String get remBreakfastTitle => '🍳 Завтрак';

  @override
  String get remBreakfastBody =>
      'Время позавтракать и записать приём пищи в дневник';

  @override
  String get remLunchTitle => '🍽 Обед';

  @override
  String get remLunchBody =>
      'Не забудь пообедать и внести приём пищи в дневник';

  @override
  String get remDinnerTitle => '🌙 Ужин';

  @override
  String get remDinnerBody => 'Время ужина — запиши приём пищи в Welmi';

  @override
  String get remActivityTitle => '🏃 Время подвигаться';

  @override
  String get remActivityBody => 'Немного активности приблизит тебя к цели';

  @override
  String get remEveningTitle => '✨ Подведи итоги дня';

  @override
  String get remEveningBody => 'Проверь воду, питание и вес в Welmi перед сном';

  @override
  String get waterEveryHour => 'Каждый час';

  @override
  String waterEveryHours(int hours) {
    return 'Каждые $hours ч';
  }

  @override
  String waterEveryMinutes(int minutes) {
    return 'Каждые $minutes мин';
  }

  @override
  String macroOfGoalGrams(int total, int goal) {
    return '$total / $goal г';
  }
}
