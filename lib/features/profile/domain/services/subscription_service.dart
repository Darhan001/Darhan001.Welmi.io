import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lumina/core/services/auth_service.dart';
import 'package:lumina/features/profile/data/subscription_repository.dart';
import 'package:lumina/features/profile/domain/models/subscription_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionService extends ChangeNotifier with WidgetsBindingObserver {
  SubscriptionService._();

  static final SubscriptionService instance = SubscriptionService._();

  // Создаём репозиторий лениво: на платформах без магазина покупок
  // (Windows/Linux) конструктор InAppPurchase может бросить исключение.
  late final SubscriptionRepository _repository = SubscriptionRepository();
  SubscriptionState _state = const SubscriptionState();
  SubscriptionState get state => _state;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  StreamSubscription? _authSubscription;
  bool _initialized = false;
  Completer<void>? _restoreCompleter;
  Timer? _entitlementRefreshTimer;
  Timer? _expiryTimer;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);

    // Любой шаг инициализации магазина может быть не поддержан платформой.
    // Раньше исключение оставляло phase = loading навсегда, и экран Premium
    // показывал бесконечную загрузку.
    try {
      _purchaseSubscription = InAppPurchase.instance.purchaseStream.listen(
        _onPurchasesUpdated,
        onError: (Object error) => _setError('Ошибка магазина: $error'),
      );
    } catch (error) {
      _setError('Магазин покупок недоступен на этом устройстве: $error');
    }

    try {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen((event) {
            if (event.session != null) {
              unawaited(refreshEntitlement());
            } else {
              _setState(
                _state.copyWith(
                  isPremium: false,
                  clearExpiration: true,
                  phase: SubscriptionPhase.ready,
                ),
              );
            }
          });
    } catch (error) {
      debugPrint('Subscription auth listener error: $error');
    }

    _startEntitlementRefreshTimer();
    await loadProducts();
    await refreshEntitlement();
  }

  Future<void> loadProducts() async {
    _setState(
      _state.copyWith(phase: SubscriptionPhase.loading, clearError: true),
    );
    try {
      final available = await _repository.isStoreAvailable().timeout(
        const Duration(seconds: 8),
      );
      if (!available) {
        _setState(
          _state.copyWith(
            phase: SubscriptionPhase.error,
            isStoreAvailable: false,
            errorMessage: 'Магазин покупок сейчас недоступен.',
          ),
        );
        return;
      }
      final response = await _repository.loadProducts().timeout(
        const Duration(seconds: 12),
      );
      final products = {
        for (final product in response.productDetails) product.id: product,
      };
      if (response.error != null) {
        throw StateError(response.error!.message);
      }
      final missing = premiumProductIds.difference(products.keys.toSet());
      _setState(
        _state.copyWith(
          phase: SubscriptionPhase.ready,
          products: products,
          isStoreAvailable: true,
          errorMessage: missing.isEmpty
              ? null
              : 'Не найдены товары: ${missing.join(', ')}. Проверьте Product ID в магазине.',
          clearError: missing.isEmpty,
        ),
      );
    } catch (error) {
      _setState(
        _state.copyWith(
          phase: SubscriptionPhase.error,
          errorMessage: 'Не удалось загрузить предложения магазина: $error',
        ),
      );
    }
  }

  Future<void> refreshEntitlement() async {
    final userId = AuthService().userId;
    if (userId == null) {
      _setState(
        _state.copyWith(
          isPremium: false,
          clearExpiration: true,
          phase: _state.isBusy ? _state.phase : SubscriptionPhase.ready,
        ),
      );
      return;
    }
    try {
      final entitlement = await _repository.loadEntitlement(userId).timeout(
        const Duration(seconds: 12),
      );
      _setState(
        _state.copyWith(
          isPremium: entitlement.isActive,
          expiresAt: entitlement.expiresAt,
          productId: entitlement.productId,
          clearExpiration: entitlement.expiresAt == null,
          phase: _state.isBusy ? _state.phase : SubscriptionPhase.ready,
        ),
      );
      _scheduleEntitlementRefresh(entitlement.expiresAt);
    } catch (error) {
      // Fail closed: do not grant Premium from a cached/local value.
      _setState(
        _state.copyWith(
          isPremium: false,
          clearExpiration: true,
          phase: SubscriptionPhase.error,
          errorMessage: 'Не удалось проверить статус Premium: $error',
        ),
      );
    }
  }

  Future<void> purchase(String productId) async {
    final product = _state.products[productId];
    if (product == null) {
      _setError('Тариф не найден в магазине.');
      return;
    }
    if (AuthService().userId == null) {
      _setError('Для оформления подписки войдите в аккаунт Welmi.');
      return;
    }
    _setState(
      _state.copyWith(
        phase: SubscriptionPhase.purchasing,
        clearError: true,
        clearNotice: true,
      ),
    );
    try {
      final started = await _repository.purchase(
        product,
        userId: AuthService().userId,
      );
      if (!started) {
        _setState(
          _state.copyWith(
            phase: SubscriptionPhase.error,
            errorMessage: 'Магазин не запустил покупку. Попробуйте ещё раз.',
          ),
        );
      }
    } catch (error) {
      _setError('Не удалось начать покупку: $error');
    }
  }

  Future<void> restorePurchases() async {
    if (AuthService().userId == null) {
      _setError('Войдите в Welmi, чтобы восстановить подписку.');
      return;
    }
    _setState(
      _state.copyWith(
        phase: SubscriptionPhase.restoring,
        clearError: true,
        clearNotice: true,
      ),
    );
    try {
      _restoreCompleter = Completer<void>();
      await _repository.restorePurchases(userId: AuthService().userId);
      await Future.any<void>([
        _restoreCompleter!.future,
        Future<void>.delayed(const Duration(seconds: 6)),
      ]);
      await refreshEntitlement();
      if (!_state.isPremium) {
        _setState(
          _state.copyWith(
            phase: SubscriptionPhase.ready,
            notice: 'Активная подписка не найдена.',
          ),
        );
      }
    } catch (error) {
      _setError('Не удалось восстановить покупки: $error');
    } finally {
      _restoreCompleter = null;
    }
  }

  Future<void> openSubscriptionManagement() async {
    final Uri uri;
    if (defaultTargetPlatform == TargetPlatform.android) {
      uri = Uri.parse(
        'https://play.google.com/store/account/subscriptions?sku=${_state.productId ?? premiumMonthlyProductId}&package=com.example.lumina',
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      uri = Uri.parse('https://apps.apple.com/account/subscriptions');
    } else {
      _setError(
        'Управлять подпиской можно на устройстве с App Store или Google Play.',
      );
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _setError('Не удалось открыть управление подпиской.');
    }
  }

  Future<void> _onPurchasesUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _setState(_state.copyWith(phase: SubscriptionPhase.purchasing));
          break;
        case PurchaseStatus.canceled:
          _setState(
            _state.copyWith(
              phase: SubscriptionPhase.cancelled,
              notice: 'Покупка отменена.',
            ),
          );
          await _completeIfNeeded(purchase);
          break;
        case PurchaseStatus.error:
          _setError(purchase.error?.message ?? 'Магазин не завершил покупку.');
          await _completeIfNeeded(purchase);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndRefresh(purchase);
          break;
      }
    }
  }

  Future<void> _verifyAndRefresh(PurchaseDetails purchase) async {
    try {
      if (!premiumProductIds.contains(purchase.productID)) {
        throw StateError('Неизвестный Product ID: ${purchase.productID}');
      }
      final verified = await _repository.verifyPurchase(purchase);
      if (!verified) {
        throw StateError('Магазин не подтвердил право на Premium.');
      }
      await refreshEntitlement();
      if (_state.isPremium) {
        _setState(
          _state.copyWith(
            phase: SubscriptionPhase.success,
            notice: 'Welmi Premium активирован.',
          ),
        );
      } else {
        throw StateError('Сервер ещё не обновил статус подписки.');
      }
    } catch (error) {
      _setError(
        'Покупка получена, но серверная проверка не завершилась: $error',
      );
    } finally {
      await _completeIfNeeded(purchase);
      if (purchase.status == PurchaseStatus.restored &&
          !(_restoreCompleter?.isCompleted ?? true)) {
        _restoreCompleter!.complete();
      }
    }
  }

  Future<void> _completeIfNeeded(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _repository.completePurchase(purchase);
    }
  }

  void _setError(String message) => _setState(
    _state.copyWith(
      phase: SubscriptionPhase.error,
      errorMessage: message,
      clearNotice: true,
    ),
  );

  void _setState(SubscriptionState state) {
    _state = state;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshEntitlement());
      _startEntitlementRefreshTimer();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _entitlementRefreshTimer?.cancel();
      _entitlementRefreshTimer = null;
    }
  }

  void _scheduleEntitlementRefresh(DateTime? expiresAt) {
    _expiryTimer?.cancel();
    if (expiresAt != null && expiresAt.isAfter(DateTime.now().toUtc())) {
      _expiryTimer = Timer(
        expiresAt.difference(DateTime.now().toUtc()),
        () => unawaited(refreshEntitlement()),
      );
    }
  }

  void _startEntitlementRefreshTimer() {
    _entitlementRefreshTimer?.cancel();
    _entitlementRefreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => unawaited(refreshEntitlement()),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _purchaseSubscription?.cancel();
    _authSubscription?.cancel();
    _entitlementRefreshTimer?.cancel();
    _expiryTimer?.cancel();
    super.dispose();
  }
}
