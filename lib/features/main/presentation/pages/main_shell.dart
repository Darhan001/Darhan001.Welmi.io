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

  static const List<Widget> _pages = <Widget>[
    HomePage(),
    DiaryPage(),
    ProgressPage(),
    ProfilePage(),
  ];

  /// Вкладки, которые пользователь уже открывал. Остальные не строятся:
  /// раньше все четыре раздела создавались при запуске и одновременно
  /// грузили свои данные, хотя виден был только первый.
  final Set<int> _visited = {0};

  /// Последняя вкладка-раздел: она остаётся выбранной в стеке под сканером.
  int _lastTab = 0;

  /// Позиция вкладки нижней панели в IndexedStack (сканер в нём не лежит).
  static int _stackIndex(int navIndex) =>
      navIndex < 2 ? navIndex : navIndex - 1;

  void _onTap(int index) {
    if (_currentIndex != index) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentIndex = index;
        if (index != 2) {
          _lastTab = index;
          _visited.add(_stackIndex(index));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = ThemeProvider.isDark(context);
    final navBg = isDark
        ? AppColors.darkCard.withValues(alpha: 0.97)
        : Colors.white.withValues(alpha: 0.96);
    final navBorder = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.2);
    final navShadow = isDark
        ? Colors.transparent
        : Colors.black.withValues(alpha: 0.08);

    // Системная «Назад» с любой вкладки сначала возвращает на главную и
    // только с неё закрывает приложение — привычное поведение Android.
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onTap(0);
      },
      child: _buildScaffold(loc, navBg, navBorder, navShadow),
    );
  }

  Widget _buildScaffold(
    AppLocalizations loc,
    Color navBg,
    Color navBorder,
    Color navShadow,
  ) {
    return Scaffold(
      extendBody: true,
      // Разделы остаются в дереве и под сканером: раньше при открытии
      // сканера они уничтожались, а после возврата заново грузили данные и
      // теряли прокрутку. Offstage не рисует их, TickerMode ставит их
      // анимации на паузу. Сам сканер живёт только пока открыт (камера).
      body: Stack(
        fit: StackFit.expand,
        children: [
          Offstage(
            offstage: _currentIndex == 2,
            child: TickerMode(
              enabled: _currentIndex != 2,
              child: IndexedStack(
                index: _stackIndex(
                  _currentIndex == 2 ? _lastTab : _currentIndex,
                ),
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    _visited.contains(i) ? _pages[i] : const SizedBox.shrink(),
                ],
              ),
            ),
          ),
          // Пока Premium тестируется, сканер еды открыт без подписки
          // (PremiumAccessGate вернём, когда подписка заработает). После
          // добавления в дневник переходим на вкладку «Дневник» колбэком.
          if (_currentIndex == 2) ScannerPage(onAddToDiary: () => _onTap(1)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          height: 72,
          // Раньше под панелью было размытие (BackdropFilter). Оно
          // пересчитывается на каждом кадре прокрутки и на слабых телефонах
          // давало рывки; почти непрозрачный фон выглядит так же, а панель
          // в своём слое не перерисовывается вместе со списком.
          child: RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(35),
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
          // Выбранная вкладка — на мягкой подложке: её видно сразу, в том
          // числе тем, кто плохо различает оттенки иконок.
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
            child: AnimatedContainer(
              duration: Duration(milliseconds: animate ? 260 : 0),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: activeColor.withValues(
                  alpha: isSelected ? (isDark ? 0.18 : 0.08) : 0,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: animate ? 200 : 0),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  isSelected ? selectedIcon : unselectedIcon,
                  key: ValueKey(isSelected),
                  color: isSelected ? activeColor : inactiveColor,
                  size: 26,
                ),
              ),
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
