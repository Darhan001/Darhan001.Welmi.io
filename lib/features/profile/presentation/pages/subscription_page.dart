import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lumina/core/theme/app_tokens.dart';
import 'package:lumina/core/theme/theme_colors.dart';
import 'package:lumina/core/widgets/app_app_bar.dart';
import 'package:lumina/core/widgets/app_button.dart';
import 'package:lumina/core/widgets/ux_helpers.dart';
import 'package:lumina/features/profile/data/subscription_repository.dart';
import 'package:lumina/features/profile/domain/models/subscription_state.dart';
import 'package:lumina/features/profile/domain/services/subscription_service.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Текст ошибки подписки на языке приложения.
String subscriptionIssueMessage(AppLocalizations loc, SubscriptionIssue issue) {
  return switch (issue) {
    SubscriptionIssue.store => loc.subErrStore,
    SubscriptionIssue.storeUnavailableOnDevice =>
      loc.subErrStoreUnavailableDevice,
    SubscriptionIssue.storeUnavailable => loc.subErrStoreUnavailable,
    SubscriptionIssue.productsMissing => loc.subErrProductsMissing,
    SubscriptionIssue.productsLoad => loc.subErrProductsLoad,
    SubscriptionIssue.entitlement => loc.subErrEntitlement,
    SubscriptionIssue.planNotFound => loc.subErrPlanNotFound,
    SubscriptionIssue.signInToSubscribe => loc.subErrSignInToSubscribe,
    SubscriptionIssue.purchaseNotStarted => loc.subErrPurchaseNotStarted,
    SubscriptionIssue.purchaseStart => loc.subErrPurchaseStart,
    SubscriptionIssue.signInToRestore => loc.subErrSignInToRestore,
    SubscriptionIssue.restore => loc.subErrRestore,
    SubscriptionIssue.manageUnsupported => loc.subErrManageUnsupported,
    SubscriptionIssue.manageOpen => loc.subErrManageOpen,
    SubscriptionIssue.purchaseFailed => loc.subErrPurchaseFailed,
    SubscriptionIssue.verification => loc.subErrVerification,
  };
}

/// Текст уведомления экрана подписки на языке приложения.
String subscriptionNoticeMessage(
  AppLocalizations loc,
  SubscriptionNotice notice,
) {
  return switch (notice) {
    SubscriptionNotice.noActiveSubscription => loc.subNoticeNoActive,
    SubscriptionNotice.purchaseCancelled => loc.subNoticeCancelled,
    SubscriptionNotice.activated => loc.subNoticeActivated,
  };
}

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
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: AppAppBar(
                title: loc.welmiPremium,
                onBack: () => Navigator.maybePop(context),
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _subscription,
                builder: (context, _) => _buildContent(context, tc, loc),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeColors tc,
    AppLocalizations loc,
  ) {
    final state = _subscription.state;
    final selected = state.products[_selectedProductId];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroCard(subtitle: loc.subHeroSubtitle, title: loc.welmiPremium),
          const SizedBox(height: 18),
          _FeatureCard(
            title: loc.subInPremium,
            features: [
              loc.subFeatureScanner,
              loc.featureMealPlans,
              loc.subFeatureWorkouts,
              loc.subFeatureAnalytics,
              loc.subFeatureHealth,
              loc.subFeatureNoAds,
            ],
          ),
          const SizedBox(height: 18),
          if (state.isPremium) ...[
            _statusCard(tc, loc, state),
            const SizedBox(height: 12),
            AppButton(
              text: loc.subManage,
              icon: Icons.open_in_new_rounded,
              variant: AppButtonVariant.outline,
              onPressed: _subscription.openSubscriptionManagement,
            ),
          ] else ...[
            _plansCard(tc, loc, state),
            const SizedBox(height: 12),
            if (state.issue != null)
              _MessageCard(
                text: subscriptionIssueMessage(loc, state.issue!),
                isError: true,
              ),
            if (state.notice != null)
              _MessageCard(
                text: subscriptionNoticeMessage(loc, state.notice!),
                isError: false,
              ),
            const SizedBox(height: 8),
            AppButton(
              text: selected == null
                  ? loc.subOfferUnavailable
                  : loc.subContinuePrice(selected.price),
              size: AppButtonSize.lg,
              loading: state.phase == SubscriptionPhase.purchasing,
              onPressed: selected == null || state.isBusy
                  ? null
                  : () {
                      hapticTap();
                      _subscription.purchase(_selectedProductId);
                    },
            ),
          ],
          const SizedBox(height: 8),
          AppButton(
            text: loc.subRestore,
            variant: AppButtonVariant.text,
            loading: state.phase == SubscriptionPhase.restoring,
            onPressed: state.isBusy ? null : _subscription.restorePurchases,
          ),
          if (state.products.isEmpty && !state.isBusy && !state.isPremium)
            AppButton(
              text: loc.subRefreshOffers,
              icon: Icons.refresh_rounded,
              variant: AppButtonVariant.text,
              onPressed: _subscription.loadProducts,
            ),
          const SizedBox(height: 12),
          Text(
            loc.subTermsNote,
            textAlign: TextAlign.center,
            style: TextStyle(color: tc.textHint, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _plansCard(
    ThemeColors tc,
    AppLocalizations loc,
    SubscriptionState state,
  ) {
    final tokens = AppTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
      ),
      child: Column(
        children: [
          _planTile(
            tc,
            product: state.products[premiumMonthlyProductId],
            title: loc.subPlanMonth,
            productId: premiumMonthlyProductId,
          ),
          const SizedBox(height: 10),
          _planTile(
            tc,
            product: state.products[premiumYearlyProductId],
            title: loc.subPlanYear,
            productId: premiumYearlyProductId,
          ),
          if (state.phase == SubscriptionPhase.loading)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: LinearProgressIndicator(
                color: tc.greenDark,
                backgroundColor: tc.divider,
              ),
            ),
        ],
      ),
    );
  }

  Widget _planTile(
    ThemeColors tc, {
    required ProductDetails? product,
    required String title,
    required String productId,
  }) {
    final selected = _selectedProductId == productId;
    final accent = tc.isDark ? tc.success : tc.greenDark;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: () {
          hapticTap();
          setState(() => _selectedProductId = productId);
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: Duration(
            milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 180,
          ),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: selected ? tc.successBg : tc.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? tc.green : tc.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? accent : tc.textHint,
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
                        color: selected ? accent : tc.text,
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
                  color: selected ? accent : tc.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusCard(
    ThemeColors tc,
    AppLocalizations loc,
    SubscriptionState state,
  ) {
    final accent = tc.isDark ? tc.success : tc.greenDark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tc.successBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_rounded, color: accent, size: 25),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.subPremiumActive,
                  style: TextStyle(color: accent, fontWeight: FontWeight.w900),
                ),
                if (state.expiresAt != null)
                  Text(
                    loc.subValidUntil(
                      MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(state.expiresAt!.toLocal()),
                    ),
                    style: TextStyle(color: tc.textSecondary, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Шапка экрана: брендовый градиент одинаков в светлой и тёмной теме.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tc.greenDark, tc.green],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: tc.greenDark.withValues(alpha: tc.isDark ? 0.12 : 0.24),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, color: tc.textOnPrimary, size: 34),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: tc.textOnPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(color: tc.textOnPrimary.withValues(alpha: 0.86)),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.title, required this.features});

  final String title;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final tokens = AppTokens.of(context);
    final accent = tc.isDark ? tc.success : tc.greenDark;
    return Container(
      padding: tokens.cardPadding,
      decoration: BoxDecoration(
        color: tc.card,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: tc.text,
            ),
          ),
          const SizedBox(height: 15),
          for (final feature in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 19, color: accent),
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
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.text, required this.isError});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: isError ? tc.errorBg : tc.successBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.info_outline,
              size: 16,
              color: isError ? tc.error : tc.success,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isError ? tc.error : tc.text,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
