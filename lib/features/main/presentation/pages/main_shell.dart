import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina/core/theme/app_colors.dart';
import 'package:lumina/core/theme/theme_provider.dart';
import 'package:lumina/features/home/presentation/pages/home_page.dart';
import 'package:lumina/features/diary/presentation/pages/diary_page.dart';
import 'package:lumina/features/scanner/presentation/pages/scanner_page.dart';
import 'package:lumina/features/progress/presentation/pages/progress_page.dart';
import 'package:lumina/features/profile/presentation/pages/profile_page.dart';
import 'package:lumina/l10n/app_localizations.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = <Widget>[
    const HomePage(),
    const DiaryPage(),
    const ProgressPage(),
    const ProfilePage(),
  ];

  void _onTap(int index) {
    if (_currentIndex != index) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = ThemeProvider.isDark(context);
    final navBg = isDark
        ? AppColors.darkCard.withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.85);
    final navBorder = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.2);
    final navShadow = isDark
        ? Colors.transparent
        : Colors.black.withValues(alpha: 0.08);

    return Scaffold(
      extendBody: true,
      body: _currentIndex == 2
          // Сканер — вкладка. Пока Premium тестируется, сканер еды открыт
          // без подписки (PremiumAccessGate вернём, когда подписка заработает).
          // После добавления в дневник возвращаемся на вкладку «Дневник»
          // (index 1) через колбэк, а не Navigator.pop.
          ? ScannerPage(onAddToDiary: () => _onTap(1))
          : IndexedStack(
              index: _currentIndex < 2 ? _currentIndex : _currentIndex - 1,
              children: _pages,
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          height: 72,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: navBg,
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(color: navBorder, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: navShadow,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      0,
                      Icons.home_rounded,
                      Icons.home_outlined,
                      loc.navHome,
                    ),
                    // Дневник питания: раньше была иконка закладки, не связанная с разделом.
                    _buildNavItem(
                      1,
                      Icons.menu_book_rounded,
                      Icons.menu_book_outlined,
                      loc.diaryTitle,
                    ),
                    _buildCenterItem(loc.navScanner),
                    _buildNavItem(
                      3,
                      Icons.insert_chart_rounded,
                      Icons.insert_chart_outlined_rounded,
                      loc.progressTitle,
                    ),
                    _buildNavItem(
                      4,
                      Icons.person_rounded,
                      Icons.person_outline_rounded,
                      loc.navProfile,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData selectedIcon,
    IconData unselectedIcon,
    String label,
  ) {
    final isDark = ThemeProvider.isDark(context);
    bool isSelected = _currentIndex == index;
    final activeColor = isDark ? AppColors.iconGreenDark : Colors.black;
    // Black26 давал контраст ниже 2:1 на светлом фоне — иконки неактивных
    // разделов было трудно различить. Black45 ≈ 3.6:1 — порог для иконок.
    final inactiveColor = isDark ? AppColors.darkTextHint : Colors.black45;
    final animate = !MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: () => _onTap(index),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: Duration(milliseconds: animate ? 300 : 0),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? selectedIcon : unselectedIcon,
                    color: isSelected ? activeColor : inactiveColor,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: Duration(milliseconds: animate ? 300 : 0),
                  height: 4,
                  width: isSelected ? 4 : 0,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterItem(String label) {
    final isDark = ThemeProvider.isDark(context);
    bool isSelected = _currentIndex == 2;
    final btnColor = isDark ? AppColors.iconGreenDark : Colors.black;
    final shadowColor = Colors.black.withValues(alpha: isDark ? 0.5 : 0.3);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: () => _onTap(2),
          child: AnimatedScale(
            scale: isSelected ? 1.1 : 1.0,
            duration: Duration(
              milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 200,
            ),
            child: Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: btnColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
