import 'package:in_app_purchase/in_app_purchase.dart';

/// Причина ошибки подписки. Текст для пользователя строит экран из
/// локализации; технические детали уходят только в лог.
enum SubscriptionIssue {
  store,
  storeUnavailableOnDevice,
  storeUnavailable,
  productsMissing,
  productsLoad,
  entitlement,
  planNotFound,
  signInToSubscribe,
  purchaseNotStarted,
  purchaseStart,
  signInToRestore,
  restore,
  manageUnsupported,
  manageOpen,
  purchaseFailed,
  verification,
}

/// Информационное сообщение экрана подписки (не ошибка).
enum SubscriptionNotice { noActiveSubscription, purchaseCancelled, activated }

enum SubscriptionPhase {
  loading,
  ready,
  purchasing,
  restoring,
  success,
  cancelled,
  error,
}

class SubscriptionState {
  const SubscriptionState({
    // Экран подписки открывается сразу в рабочем состоянии. Фаза loading
    // выставляется только на время реальной загрузки товаров, иначе
    // индикатор мог крутиться бесконечно (если магазин не инициализировался).
    this.phase = SubscriptionPhase.ready,
    this.products = const {},
    this.isStoreAvailable = false,
    this.isPremium = false,
    this.productId,
    this.expiresAt,
    this.issue,
    this.notice,
  });

  final SubscriptionPhase phase;
  final Map<String, ProductDetails> products;
  final bool isStoreAvailable;
  final bool isPremium;
  final String? productId;
  final DateTime? expiresAt;
  final SubscriptionIssue? issue;
  final SubscriptionNotice? notice;

  bool get isBusy =>
      phase == SubscriptionPhase.loading ||
      phase == SubscriptionPhase.purchasing ||
      phase == SubscriptionPhase.restoring;

  SubscriptionState copyWith({
    SubscriptionPhase? phase,
    Map<String, ProductDetails>? products,
    bool? isStoreAvailable,
    bool? isPremium,
    String? productId,
    DateTime? expiresAt,
    bool clearExpiration = false,
    SubscriptionIssue? issue,
    bool clearError = false,
    SubscriptionNotice? notice,
    bool clearNotice = false,
  }) => SubscriptionState(
    phase: phase ?? this.phase,
    products: products ?? this.products,
    isStoreAvailable: isStoreAvailable ?? this.isStoreAvailable,
    isPremium: isPremium ?? this.isPremium,
    productId: productId ?? this.productId,
    expiresAt: clearExpiration ? null : expiresAt ?? this.expiresAt,
    issue: clearError ? null : issue ?? this.issue,
    notice: clearNotice ? null : notice ?? this.notice,
  );
}
