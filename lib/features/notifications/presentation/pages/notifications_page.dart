import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/app_colors.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<Map<String, dynamic>> _recentNotifications = [
    {
      'icon': Icons.water_drop,
      'color': const Color(0xFF4A8C5C),
      'title': 'Пора выпить воды!',
      'subtitle': 'Вы выпили 60% от дневной нормы',
      'time': '15 мин назад',
      'read': false,
    },
    {
      'icon': Icons.restaurant,
      'color': Colors.orange,
      'title': 'Время обеда',
      'subtitle': 'Не забудьте записать приём пищи',
      'time': '2 часа назад',
      'read': false,
    },
    {
      'icon': Icons.trending_down,
      'color': const Color(0xFF75A47F),
      'title': 'Новый результат!',
      'subtitle': 'Ваш вес снизился на 0.4 кг',
      'time': '1 день назад',
      'read': true,
    },
    {
      'icon': Icons.auto_awesome,
      'color': Colors.amber,
      'title': 'Мотивация дня',
      'subtitle': 'Маленькие шаги ведут к большим результатам',
      'time': '2 дня назад',
      'read': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : Colors.black;
    final primaryGreen = isDark ? AppColors.iconGreenDark : AppColors.iconGreen;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_back, size: 22, color: textColor),
                    ),
                  ),
                  Text(
                    'Уведомления',
                    style: GoogleFonts.notoSerif(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Входящие',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            for (var n in _recentNotifications) {
                              n['read'] = true;
                            }
                          });
                        },
                        child: Text(
                          'Прочитать всё',
                          style: TextStyle(
                            fontSize: 12,
                            color: primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(_recentNotifications.length, (i) {
                    final notif = _recentNotifications[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildNotificationItem(
                        context,
                        notif['icon'] as IconData,
                        notif['color'] as Color,
                        notif['title'] as String,
                        notif['subtitle'] as String,
                        notif['time'] as String,
                        notif['read'] as bool,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    IconData icon,
    Color color,
    String title,
    String subtitle,
    String time,
    bool read,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkText : Colors.black;
    final textSecondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final timeColor = isDark ? AppColors.darkTextHint : AppColors.textHint;
    final primaryGreen = isDark ? AppColors.iconGreenDark : AppColors.iconGreen;

    final unreadBg = isDark 
        ? primaryGreen.withValues(alpha: 0.1) 
        : const Color(0xFFE8F3E5).withValues(alpha: 0.4);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: read ? cardColor : unreadBg,
        borderRadius: BorderRadius.circular(20),
        border: read
            ? null
            : Border.all(
                color: primaryGreen.withValues(alpha: 0.15),
                width: 1,
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: read ? FontWeight.w600 : FontWeight.w800,
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                    if (!read) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 10,
              color: timeColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
