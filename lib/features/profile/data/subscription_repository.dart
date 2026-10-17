import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const premiumMonthlyProductId = 'welmi_premium_monthly';
const premiumYearlyProductId = 'welmi_premium_yearly';
const premiumProductIds = <String>{
  premiumMonthlyProductId,
  premiumYearlyProductId,
};

class SubscriptionEntitlement {
  const SubscriptionEntitlement({
    this.isActive = false,
    this.expiresAt,
    this.productId,
  });

  final bool isActive;
  final DateTime? expiresAt;
  final String? productId;
}

class SubscriptionRepository {
  SubscriptionRepository({InAppPurchase? store, SupabaseClient? client})
    : _store = store ?? InAppPurchase.instance,
      _client = client ?? Supabase.instance.client;

  final InAppPurchase _store;
  final SupabaseClient _client;

  Future<bool> isStoreAvailable() => _store.isAvailable();

  Future<ProductDetailsResponse> loadProducts() =>
      _store.queryProductDetails(premiumProductIds);

  Future<bool> purchase(ProductDetails product, {String? userId}) {
    if (defaultTargetPlatform == TargetPlatform.android &&
        product is GooglePlayProductDetails) {
      final param = GooglePlayPurchaseParam(
        productDetails: product,
        offerToken: product.offerToken,
        obfuscatedProfileId: userId,
      );
      return _store.buyNonConsumable(purchaseParam: param);
    }

    return _store.buyNonConsumable(
      purchaseParam: PurchaseParam(
        productDetails: product,
        applicationUserName: userId,
      ),
    );
  }

  Future<void> restorePurchases({String? userId}) =>
      _store.restorePurchases(applicationUserName: userId);

  Future<void> completePurchase(PurchaseDetails purchase) =>
      _store.completePurchase(purchase);

  Future<SubscriptionEntitlement> loadEntitlement(String userId) async {
    final row = await _client
        .from('subscription_entitlements')
        .select('status, expires_at, product_id')
        .eq('user_id', userId)
        .maybeSingle();

    if (row == null) return const SubscriptionEntitlement();
    final expiresAt = row['expires_at'] == null
        ? null
        : DateTime.tryParse(row['expires_at'] as String)?.toUtc();
    final activeStatus =
        row['status'] == 'active' || row['status'] == 'in_grace_period';
    final active =
        activeStatus &&
        expiresAt != null &&
        expiresAt.isAfter(DateTime.now().toUtc());
    return SubscriptionEntitlement(
      isActive: active,
      expiresAt: expiresAt,
      productId: row['product_id'] as String?,
    );
  }

  /// Requests verification from a trusted Edge Function. The client never
  /// writes entitlement rows and never treats a local receipt as proof.
  Future<bool> verifyPurchase(PurchaseDetails purchase) async {
    final response = await _client.functions.invoke(
      'verify-subscription',
      body: {
        'productId': purchase.productID,
        'transactionId': purchase.purchaseID,
        'serverVerificationData':
            purchase.verificationData.serverVerificationData,
        'platform': _platformName,
      },
    );
    if (response.status < 200 || response.status >= 300) {
      throw StateError('Проверка покупки не прошла (${response.status}).');
    }
    final data = response.data;
    if (data is! Map || data['verified'] != true) return false;
    return true;
  }

  String get _platformName {
    if (kIsWeb) return 'unsupported';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'unsupported';
  }
}
