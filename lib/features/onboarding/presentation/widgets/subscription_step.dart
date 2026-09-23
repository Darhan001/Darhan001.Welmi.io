import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/theme_colors.dart';

class SubscriptionStep extends StatelessWidget {
  final VoidCallback? onSubscribe;
  final VoidCallback? onClose;

  const SubscriptionStep({
    super.key,
    this.onSubscribe,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: onClose,
              icon: Icon(Icons.close, color: tc.textHint),
            ),
          ),
          Text(
            'Открой все\nвозможности',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSerif(
                fontSize: 28, fontWeight: FontWeight.w900, color: tc.text),
          ),
          const SizedBox(height: 12),
          Text(
            'Попробуй бесплатно 7 дней.\nОтмена в любой момент.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: tc.textSecondary, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 40),
          _buildFeatureRow('Умный сканер еды и продуктов', tc),
          _buildFeatureRow('Персональные планы питания', tc),
          _buildFeatureRow('Подробная аналитика макросов', tc),
          _buildFeatureRow('Никакой рекламы', tc),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: tc.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: tc.card,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: tc.shadow(0.05),
                            blurRadius: 10)
                      ],
                    ),
                    child: Text(
                      'Месяц',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, color: tc.text),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('Год',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: tc.textSecondary)),
                      Text('-60%',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.red.withValues(alpha: 0.6),
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onSubscribe,
            style: ElevatedButton.styleFrom(
              backgroundColor: tc.primary,
              foregroundColor: tc.textOnPrimary,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Начать бесплатный период',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Text(
            'Оплата спишется автоматически за 24 часа до конца пробного периода. Отмените в настройках, если не желаете продлевать. Условия и политика конфиденциальности.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: tc.textHint, height: 1.3),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text, ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(Icons.check_circle,
              color: tc.isDark ? tc.green.withValues(alpha: 0.3) : const Color(0xFFE8F3E5),
              size: 24),
          const SizedBox(width: 12),
          Text(text,
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: tc.text)),
        ],
      ),
    );
  }
}
