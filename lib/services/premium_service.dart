import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'native_battery_service.dart';
import 'store_entitlement_reconciler.dart';

class PremiumService {
  PremiumService({
    required this.platform,
    required this.onChanged,
  });

  final NativeBatteryService platform;
  final VoidCallback onChanged;

  static const productId = 'battery_guard_pro_lifetime';

  static const bool _forcePremiumTest = bool.fromEnvironment(
    'BATTERY_GUARD_FORCE_PRO_TEST',
    defaultValue: false,
  );

  static const bool _allowLocalProTest = bool.fromEnvironment(
    'BATTERY_GUARD_ALLOW_LOCAL_PRO_TEST',
    defaultValue: false,
  );

  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool isPro = false;
  bool storeAvailable = false;
  bool loading = true;
  bool storeOwnershipReconciled = false;
  ProductDetails? product;
  String? error;

  String? get localizedPrice => product?.price;

  bool get localTestUnlockAvailable =>
      _allowLocalProTest &&
      !isPro &&
      (!storeAvailable || product == null);

  bool get canUnlock =>
      !loading &&
      ((storeAvailable && product != null) || localTestUnlockAvailable);

  Future<void> initialize({required bool webPreview}) async {
    if (_forcePremiumTest) {
      isPro = true;
      storeAvailable = false;
      loading = false;
      product = null;
      error = null;
      onChanged();
      return;
    }

    if (webPreview) {
      isPro = true;
      storeAvailable = false;
      loading = false;
      onChanged();
      return;
    }

    isPro = await platform.getProEntitlement();

    _subscription ??= _iap.purchaseStream.listen(
      _handlePurchases,
      onError: (Object value) {
        error = value.toString();
        loading = false;
        onChanged();
      },
    );

    try {
      storeAvailable = await _iap.isAvailable();
      if (storeAvailable) {
        final response = await _iap.queryProductDetails({productId});
        if (response.error != null) {
          error = response.error!.message;
        }
        if (response.productDetails.isNotEmpty) {
          product = response.productDetails.first;
        }
        await _reconcileStoreOwnership();
      }
    } catch (value) {
      error = value.toString();
    } finally {
      loading = false;
      onChanged();
    }
  }

  Future<bool> buy() async {
    if (localTestUnlockAvailable) {
      error = null;
      isPro = true;
      await platform.setProEntitlement(true);
      onChanged();
      return true;
    }

    final details = product;
    if (!storeAvailable || details == null) return false;

    error = null;
    onChanged();
    try {
      return await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
      );
    } catch (value) {
      error = value.toString();
      onChanged();
      return false;
    }
  }

  Future<void> restore() async {
    if (!storeAvailable) return;
    error = null;
    onChanged();
    try {
      await _iap.restorePurchases();
      await _reconcileStoreOwnership();
    } catch (value) {
      error = value.toString();
      onChanged();
    }
  }

  Future<void> _reconcileStoreOwnership() async {
    // INTERNAL sideload builds deliberately use a local entitlement and must
    // never have it revoked by an unavailable Play Store.
    if (_allowLocalProTest || _forcePremiumTest || !storeAvailable) return;

    final owned = await reconcileStoreOwnership(
      iap: _iap,
      productId: productId,
    );
    if (owned == null) return;

    storeOwnershipReconciled = true;
    isPro = owned;
    await platform.setProEntitlement(owned);
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != productId) continue;

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // This client-side check is integrity hygiene, not trusted purchase
          // verification. Production remains blocked until a secure backend
          // validates the Google Play purchase token.
          if (purchase.verificationData.serverVerificationData.trim().isEmpty) {
            error = 'Purchase verification data unavailable';
            break;
          }
          isPro = true;
          error = null;
          await platform.setProEntitlement(true);
          break;
        case PurchaseStatus.error:
          error = purchase.error?.message ?? 'Purchase failed';
          break;
        case PurchaseStatus.canceled:
          break;
        case PurchaseStatus.pending:
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }

    if (storeAvailable && !_allowLocalProTest && !_forcePremiumTest) {
      await _reconcileStoreOwnership();
    }
    onChanged();
  }

  void dispose() {
    _subscription?.cancel();
  }
}
