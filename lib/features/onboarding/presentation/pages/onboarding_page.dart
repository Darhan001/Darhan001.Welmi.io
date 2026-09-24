import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/models/onboarding_data.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/services/notification_service.dart';
import 'package:lumina/core/services/push_notification_service.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/onboarding/presentation/widgets/welcome_step.dart';
import 'package:lumina/features/onboarding/presentation/widgets/goal_step.dart';
import 'package:lumina/features/onboarding/presentation/widgets/gender_step.dart';
import 'package:lumina/features/onboarding/presentation/widgets/height_step.dart';
import 'package:lumina/features/onboarding/presentation/widgets/weight_step.dart';
import 'package:lumina/features/onboarding/presentation/widgets/target_weight_step.dart';
import 'package:lumina/features/onboarding/presentation/widgets/birth_date_step.dart';
import 'package:lumina/features/onboarding/presentation/widgets/activity_step.dart';
import 'package:lumina/features/onboarding/presentation/widgets/goal_speed_step.dart';
import 'package:lumina/features/onboarding/presentation/widgets/google_auth_step.dart';
import 'package:lumina/features/onboarding/presentation/widgets/calculation_step.dart';
import 'package:lumina/features/main/presentation/pages/main_shell.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _currentPage = 0;
  final int _totalSteps = 11; 
  final OnboardingData _data = OnboardingData();
  final AuthService _auth = AuthService();

  void _nextPage() {
    if (_currentPage < _totalSteps - 1) {
      setState(() => _currentPage++);
    }
  }

  void _onLoadingComplete() {
    _auth.markOnboardingComplete();
    _requestNotifications();
    // Профиль уже создан → теперь можно сохранить push-токен
    // (FK device_tokens.user_id → profiles.id).
    if (!kIsWeb) PushNotificationService().registerTokenIfNeeded();
    Navigator.of(context).pushReplacement(
      smoothPageRoute(const MainShell()),
    );
  }

  Future<void> _requestNotifications() async {
    try {
      final notifications = NotificationService();
      await notifications.initialize();
      final granted = await notifications.requestPermissions();
      if (granted) await notifications.rescheduleAll();
    } catch (_) {}
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopNavigation(tc),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _buildStep(key: ValueKey(_currentPage)),
              ),
            ),
            _buildBottomButton(tc),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({required Key key}) {
    return KeyedSubtree(
      key: key,
      child: <Widget>[
        const WelcomeStep(),
        GoalStep(
          selectedGoal: _data.goal,
          onGoalChanged: (goal) => setState(() => _data.goal = goal),
        ),
        GenderStep(
          selectedGender: _data.gender,
          onGenderChanged: (gender) =>
              setState(() => _data.gender = gender),
        ),
        HeightStep(
          height: _data.height,
          onHeightChanged: (h) => setState(() => _data.height = h),
        ),
        WeightStep(
          weight: _data.currentWeight,
          onWeightChanged: (w) =>
              setState(() => _data.currentWeight = w),
        ),
        TargetWeightStep(
          currentWeight: _data.currentWeight,
          targetWeight: _data.targetWeight,
          onTargetChanged: (w) =>
              setState(() => _data.targetWeight = w),
        ),
        BirthDateStep(
          birthDate: _data.birthDate,
          onDateChanged: (d) =>
              setState(() => _data.birthDate = d),
        ),
        ActivityStep(
          selectedActivity: _data.activityLevel,
          onActivityChanged: (a) =>
              setState(() => _data.activityLevel = a),
        ),
        GoalSpeedStep(
          goalSpeed: _data.goalSpeed,
          onSpeedChanged: (s) =>
              setState(() => _data.goalSpeed = s),
        ),
        GoogleAuthStep(
          onSuccess: _nextPage,
          onSkip: _nextPage,
        ),
        CalculationStep(
          data: _data,
          onComplete: _onLoadingComplete,
        ),
      ][_currentPage],
    );
  }

  Widget _buildTopNavigation(ThemeColors tc) {
    if (_currentPage == 10) return const SizedBox(height: 20);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentPage > 0)
                GestureDetector(
                  onTap: _previousPage,
                  child: Icon(Icons.arrow_back, size: 24, color: tc.text),
                )
              else
                const SizedBox(width: 24),
              
              if (_currentPage == 7)
                GestureDetector(
                  onTap: _nextPage,
                  child: Text('Пропустить',
                      style: GoogleFonts.inter(
                          color: tc.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                )
              else
                const SizedBox(),

              Text(
                '${_currentPage + 1} из $_totalSteps',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: tc.textSecondary,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                  height: 2,
                  width: double.infinity,
                  color: tc.divider),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                height: 2,
                width: MediaQuery.of(context).size.width *
                    ((_currentPage + 1) / _totalSteps),
                color: tc.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(ThemeColors tc) {
    if (_currentPage == 9 || _currentPage == 10) return const SizedBox.shrink();

    String text = 'Далее';
    bool showArrow = false;

    if (_currentPage == 0) text = 'Начать';
    if (_currentPage == 1) {
      text = 'Цель';
      showArrow = true;
    }
    if (_currentPage == 8) text = 'Готово';

    final bool canProceed = _canGoNext();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: ElevatedButton(
        onPressed: canProceed ? _nextPage : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canProceed ? tc.primary : tc.divider,
          foregroundColor: tc.textOnPrimary,
          disabledBackgroundColor: tc.divider,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text,
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            if (showArrow) ...[
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 20, color: tc.textOnPrimary),
            ]
          ],
        ),
      ),
    );
  }

  bool _canGoNext() {
    switch (_currentPage) {
      case 1:
        return _data.goal != null;
      case 2:
        return _data.gender != null;
      case 7:
        return _data.activityLevel != null;
      default:
        return true;
    }
  }
}
