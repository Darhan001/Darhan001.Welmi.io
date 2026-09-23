import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_app_bar.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';

const _green = Color(0xFF75A47F);
const _greenDark = Color(0xFF4A8C5C);
const _greenSoft = Color(0xFFE8F3E5);

/// Отдельный экран подписки PRO.
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  bool _yearly = true;

  final List<String> _features = [
    'Умный сканер еды',
    'Персональные планы питания',
    'Планы тренировок от AI',
    'Подробная аналитика и замеры',
    'Синхронизация с Health Connect',
    'Без рекламы',
  ];

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: AppAppBar(title: 'Подписка PRO', onBack: () => Navigator.maybePop(context)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Промо-карточка ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_greenDark, _green],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: _greenDark.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.star_rounded,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(height: 16),
                          Text('Welmi PRO',
                              style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('Открой все возможности Welmi',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.85))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Преимущества ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: tc.card,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Что входит в PRO',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: tc.text)),
                          const SizedBox(height: 16),
                          ..._features.map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: _greenSoft,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check_rounded,
                                        size: 14, color: _greenDark),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(f,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: tc.text)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Планы ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: tc.card,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          _planTile(
                            tc,
                            title: 'Месяц',
                            price: '199 сом',
                            period: 'в месяц',
                            selected: !_yearly,
                            onTap: () => setState(() => _yearly = false),
                          ),
                          const SizedBox(height: 10),
                          _planTile(
                            tc,
                            title: 'Год',
                            price: '1 490 сом',
                            period: '≈ 124 сом/мес',
                            selected: _yearly,
                            badge: '−38%',
                            onTap: () => setState(() => _yearly = true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Кнопка оформления ──
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          hapticSuccess();
                          showWelmiSnackbar(
                            context,
                            'Оплата появится после релиза в App Store / Google Play',
                            icon: Icons.star_rounded,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _greenDark,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text(
                          _yearly ? 'Оформить на год' : 'Оформить на месяц',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _greenSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Текущий статус: активация после релиза',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _greenDark)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planTile(
    ThemeColors tc, {
    required String title,
    required String price,
    required String period,
    required bool selected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? _greenSoft : tc.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _green : tc.divider.withValues(alpha: 0.4),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: selected ? _greenDark : tc.textHint, width: 2),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      size: 15, color: _greenDark)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: selected ? _greenDark : tc.text)),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _greenDark,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(badge,
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ),
            Text(price,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: selected ? _greenDark : tc.text)),
            const SizedBox(width: 4),
            Text(period,
                style: TextStyle(fontSize: 10, color: selected ? _greenDark.withValues(alpha: 0.7) : tc.textHint)),
          ],
        ),
      ),
    );
  }
}
