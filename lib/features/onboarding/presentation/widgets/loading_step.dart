import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';

class LoadingStep extends StatefulWidget {
  final VoidCallback onComplete;

  const LoadingStep({super.key, required this.onComplete});

  @override
  State<LoadingStep> createState() => _LoadingStepState();
}

class _LoadingStepState extends State<LoadingStep>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  int _currentStatus = 0;

  final List<_LoadingStatus> _statuses = const [
    _LoadingStatus(
      icon: Icons.analytics_outlined,
      title: 'Анализ данных',
      subtitle: 'Обрабатываю твои параметры...',
    ),
    _LoadingStatus(
      icon: Icons.calculate_outlined,
      title: 'Расчёт калорий',
      subtitle: 'Рассчитываю твою норму калорий...',
    ),
    _LoadingStatus(
      icon: Icons.fitness_center_outlined,
      title: 'Персональная тренировка',
      subtitle: 'Создаю программу тренировок...',
    ),
    _LoadingStatus(
      icon: Icons.restaurant_menu_outlined,
      title: 'План питания',
      subtitle: 'Составляю рацион на неделю...',
    ),
    _LoadingStatus(
      icon: Icons.water_drop_outlined,
      title: 'Водный баланс',
      subtitle: 'Настраиваю режим воды...',
    ),
    _LoadingStatus(
      icon: Icons.auto_awesome,
      title: 'Готово!',
      subtitle: 'Почти закончили...',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..addListener(() {
        final newIndex =
            (_progressController.value * _statuses.length).floor().clamp(
                0, _statuses.length - 1);
        if (newIndex != _currentStatus) {
          setState(() => _currentStatus = newIndex);
        }
      });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) widget.onComplete();
        });
      }
    });

    _progressController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _statuses[_currentStatus];
    final isLastStep = _currentStatus == _statuses.length - 1;
    final tc = ThemeColors.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: tc.isDark
              ? [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF121212),
                ]
              : [
                  const Color(0xFFF9F7F2),
                  const Color(0xFFF0EDE6),
                ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon circle
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  final scale = 1.0 + (_pulseController.value * 0.05);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: tc.card,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: tc.shadow(0.06 * _pulseController.value + 0.02),
                            blurRadius: 30 * (1.0 + _pulseController.value * 0.3),
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Icon(
                          status.icon,
                          key: ValueKey(_currentStatus),
                          color: isLastStep ? tc.green : tc.text,
                          size: 48,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),

              // Circular progress
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, _) {
                          return CircularProgressIndicator(
                            value: _progressController.value,
                            strokeWidth: 4,
                            backgroundColor: tc.isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.05),
                            color: isLastStep ? tc.green : tc.primary,
                            strokeCap: StrokeCap.round,
                          );
                        },
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, _) {
                            return Text(
                              '${(_progressController.value * 100).round()}%',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: isLastStep ? tc.green : tc.text,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ЗАВЕРШЕНО',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: tc.textHint,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Status text with animation
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder:
                    (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  key: ValueKey('status_$_currentStatus'),
                  children: [
                    Text(
                      status.title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isLastStep ? tc.green : tc.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      status.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: tc.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Animated dots
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_statuses.length, (i) {
                      final isActive = i <= _currentStatus;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 24 : 8,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? (i == _currentStatus && isLastStep
                                  ? tc.green
                                  : tc.primary)
                              : (tc.isDark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.black.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingStatus {
  final IconData icon;
  final String title;
  final String subtitle;

  const _LoadingStatus({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
