enum GoalType { loseWeight, gainWeight, maintainWeight }

enum Gender { male, female }

enum ActivityLevel { sedentary, light, moderate, high }

class OnboardingData {
  GoalType? goal;
  Gender? gender;
  double height = 175; // cm
  double currentWeight = 72; // kg
  double targetWeight = 70; // kg
  DateTime birthDate = DateTime(1995, 1, 1);
  ActivityLevel? activityLevel;
  double goalSpeed = 0.5; // kg per week

  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // BMR using Mifflin-St Jeor equation
  int get bmr {
    if (gender == null) return 0;
    final weight = currentWeight;
    final heightCm = height;
    final ageYears = age;

    if (gender == Gender.male) {
      return (10 * weight + 6.25 * heightCm - 5 * ageYears + 5).round();
    } else {
      return (10 * weight + 6.25 * heightCm - 5 * ageYears - 161).round();
    }
  }

  // TDEE based on activity level
  int get tdee {
    switch (activityLevel) {
      case ActivityLevel.sedentary:
        return (bmr * 1.2).round();
      case ActivityLevel.light:
        return (bmr * 1.375).round();
      case ActivityLevel.moderate:
        return (bmr * 1.55).round();
      case ActivityLevel.high:
        return (bmr * 1.725).round();
      case null:
        return bmr;
    }
  }

  // Daily calorie target based on goal and speed
  int get dailyCalories {
    if (goal == null) return tdee;
    final deficit = (goalSpeed * 1100).round(); // ~1100 kcal per kg of fat
    switch (goal) {
      case GoalType.loseWeight:
        return (tdee - deficit).clamp(1200, tdee);
      case GoalType.gainWeight:
        return tdee + deficit;
      case GoalType.maintainWeight:
        return tdee;
      case null:
        return tdee;
    }
  }

  int get proteinGrams => (currentWeight * 1.6).round(); // 1.6g per kg
  int get fatGrams => (dailyCalories * 0.25 / 9).round(); // 25% from fat
  int get carbGrams =>
      ((dailyCalories - proteinGrams * 4 - fatGrams * 9) / 4).round();
}
