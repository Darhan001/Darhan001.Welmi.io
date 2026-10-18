import 'package:flutter/material.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/features/profile/domain/services/subscription_service.dart';
import 'package:lumina/features/profile/presentation/pages/subscription_page.dart';

/// Keeps premium-only surfaces locked unless Supabase confirms an active
/// store-verified entitlement. No local preference can unlock this widget.
class PremiumAccessGate extends StatelessWidget {
  const PremiumAccessGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: SubscriptionService.instance,
    builder: (context, _) {
      if (SubscriptionService.instance.state.isPremium) return child;
      final tc = ThemeColors.of(context);
      return Scaffold(
        backgroundColor: tc.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    size: 48,
                    color: Color(0xFF4A8C5C),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Эта функция доступна в Welmi Premium',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: tc.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Статус проверяется по подтверждённой подписке магазина.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: tc.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SubscriptionPage(),
                      ),
                    ),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Посмотреть Premium'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
