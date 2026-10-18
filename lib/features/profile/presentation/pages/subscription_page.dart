import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_app_bar.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/profile/data/subscription_repository.dart';
import 'package:lumina/features/profile/domain/models/subscription_state.dart';
import 'package:lumina/features/profile/domain/services/subscription_service.dart';

const _green = Color(0xFF75A47F);
const _greenDark = Color(0xFF4A8C5C);
const _greenSoft = Color(0xFFE8F3E5);

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final _subscription = SubscriptionService.instance;
  String _selectedProductId = premiumYearlyProductId;

  @override
  void initState() {
    super.initState();
    _subscription.refreshEntitlement();
    // Если товары ещё не загрузились (например, инициализация сервиса
    // прервалась), пробуем загрузить их при открытии экрана. У сервиса есть
    // таймауты, поэтому состояние loading не может зависнуть навсегда.
    final state = _subscription.state;
    if (state.products.isEmpty && state.phase != SubscriptionPhase.error) {
      _subscription.loadProducts();
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: AppAppBar(
                title: 'Welmi Premium',
                onBack: () => Navigator.maybePop(context),
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _subscription,
                builder: (context, _) => _buildContent(context, tc),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeColors tc) {
    final state = _subscription.state;
    final selected = state.products[_selectedProductId];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heroCard(),
          const SizedBox(height: 18),
          _featureCard(tc),
          const SizedBox(height: 18),
          if (state.isPremium) ...[
            _statusCard(tc, state),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _subscription.openSubscriptionManagement,
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Управлять подпиской'),
            ),
          ] else ...[
            _plansCard(tc, state),
            const SizedBox(height: 12),
            if (state.errorMessage != null)
              _messageCard(state.errorMessage!, isError: true),
            if (state.notice != null)
              _messageCard(state.notice!, isError: false),
            if (state.phase == SubscriptionPhase.success)
              _messageCard('Подписка активна.', isError: false),
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: selected == null || state.isBusy
                    ? null
                    : () {
                        hapticSuccess();
                        _subscription.purchase(_selectedProductId);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _greenDark,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _greenDark.withValues(alpha: .4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: state.phase == SubscriptionPhase.purchasing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        selected == null
                            ? 'Предложение недоступно'
                            : 'Продолжить · ${selected.price}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: state.isBusy ? null : _subscription.restorePurchases,
            child: const Text('Восстановить покупки'),
          ),
          if (state.products.isEmpty && !state.isBusy)
            Center(
              child: TextButton.icon(
                onPressed: _subscription.loadProducts,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Обновить предложения'),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Оплата и условия подписки показываются магазином перед подтверждением покупки. Управлять автопродлением можно в настройках магазина.',
            textAlign: TextAlign.center,
            style: TextStyle(color: tc.textHint, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
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
          color: _greenDark.withValues(alpha: .24),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 34),
        const SizedBox(height: 14),
        Text(
          'Welmi Premium',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Больше возможностей для заботы о себе',
          style: TextStyle(color: Colors.white.withValues(alpha: .86)),
        ),
      ],
    ),
  );

  Widget _featureCard(ThemeColors tc) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: tc.card,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'В Premium',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: tc.text,
          ),
        ),
        const SizedBox(height: 15),
        ...[
          'Умный сканер еды',
          'Персональные планы питания',
          'Планы тренировок от AI',
          'Подробная аналитика и замеры',
          'Синхронизация с Health Connect',
          'Без рекламы',
        ].map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 19,
                  color: _greenDark,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    feature,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tc.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _plansCard(ThemeColors tc, SubscriptionState state) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: tc.card,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        _planTile(
          tc,
          product: state.products[premiumMonthlyProductId],
          title: 'На месяц',
          productId: premiumMonthlyProductId,
        ),
        const SizedBox(height: 10),
        _planTile(
          tc,
          product: state.products[premiumYearlyProductId],
          title: 'На год',
          productId: premiumYearlyProductId,
        ),
        if (state.phase == SubscriptionPhase.loading)
          const Padding(
            padding: EdgeInsets.only(top: 14),
            child: LinearProgressIndicator(color: _greenDark),
          ),
      ],
    ),
  );

  Widget _planTile(
    ThemeColors tc, {
    required ProductDetails? product,
    required String title,
    required String productId,
  }) {
    final selected = _selectedProductId == productId;
    return InkWell(
      onTap: () => setState(() => _selectedProductId = productId),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected ? _greenSoft : tc.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _green : tc.divider.withValues(alpha: .4),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? _greenDark : tc.textHint,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: selected ? _greenDark : tc.text,
                    ),
                  ),
                  if (product != null)
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: tc.textHint),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              product?.price ?? '—',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: selected ? _greenDark : tc.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCard(ThemeColors tc, SubscriptionState state) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _greenSoft,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const Icon(Icons.verified_rounded, color: _greenDark, size: 25),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Premium активен',
                style: TextStyle(
                  color: _greenDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (state.expiresAt != null)
                Text(
                  'Действует до ${MaterialLocalizations.of(context).formatMediumDate(state.expiresAt!.toLocal())}',
                  style: TextStyle(color: tc.textSecondary, fontSize: 12),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _messageCard(String text, {required bool isError}) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: isError ? Colors.red.withValues(alpha: .08) : _greenSoft,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: isError ? Colors.red.shade700 : _greenDark,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
