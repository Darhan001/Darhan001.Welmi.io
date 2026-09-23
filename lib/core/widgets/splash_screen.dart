import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  final WidgetBuilder? onComplete;

  const SplashScreen({super.key, this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _dotController;
  late Animation<double> _dot1Animation;
  late Animation<double> _dot2Animation;
  late Animation<double> _dot3Animation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    // ВАЖНО: TweenSequence нельзя оборачивать в кривую с перелётом (easeOutBack
    // выдаёт значения > 1.0), т.к. TweenSequence.transform требует t из [0, 1]
    // — иначе assertion в debug-режиме (tween_sequence.dart).
    // Сам TweenSequence уже даёт эффект пружины: 0.6 -> 1.05 -> 1.0.
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.05), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 40),
    ]).animate(_scaleController);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _dotController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _dot1Animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _dotController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeInOut),
      ),
    );
    _dot2Animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _dotController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeInOut),
      ),
    );
    _dot3Animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _dotController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeInOut),
      ),
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor1 = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF9F7F2);
    final bgColor2 = isDark ? const Color(0xFF161616) : const Color(0xFFF5F0E8);
    final bgColor3 = isDark ? const Color(0xFF0F120F) : const Color(0xFFF0F5EA);

    final textColor = isDark ? AppColors.darkText : Colors.black87;
    final textSecondary = isDark ? AppColors.darkTextSecondary : Colors.black45;
    final textHint = isDark ? AppColors.darkTextHint : Colors.black26;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgColor1, bgColor2, bgColor3],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 140 * _pulseAnimation.value,
                    height: 140 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.iconGreen.withValues(alpha: isDark ? 0.15 : 0.3),
                          AppColors.iconGreen.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                        stops: const [0.3, 0.7, 1.0],
                      ),
                    ),
                    child: child,
                  );
                },
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.iconGreen.withValues(alpha: 0.12),
                      border: Border.all(
                        color: AppColors.iconGreen.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF75A47F),
                              Color(0xFF5A8A64),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.iconGreen.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'W',
                            style: GoogleFonts.notoSerif(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Welmi',
                style: GoogleFonts.notoSerif(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Твой путь к здоровью',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: textSecondary,
                  letterSpacing: 0.3,
                ),
              ),

              const Spacer(flex: 2),

              AnimatedBuilder(
                animation: _dotController,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDot(_dot1Animation, isDark),
                      const SizedBox(width: 6),
                      _buildDot(_dot2Animation, isDark),
                      const SizedBox(width: 6),
                      _buildDot(_dot3Animation, isDark),
                    ],
                  );
                },
              ),

              const SizedBox(height: 48),

              Column(
                children: [
                  Text(
                    'Welmi',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: textHint,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI-powered wellness',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: textHint,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(Animation<double> animation, bool isDark) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.iconGreen.withValues(
                alpha: 0.4 + animation.value * 0.4,
              ),
            ),
          ),
        );
      },
    );
  }
}
