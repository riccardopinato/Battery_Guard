import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'native_battery_service.dart';

class PremiumService {
  PremiumService({
    required this.platform,
    required this.onChanged,
  });

  final NativeBatteryService platform;
  final VoidCallback onChanged;

  static const productId = 'battery_guard_pro_lifetime';

  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool isPro = false;
  bool storeAvailable = false;
  bool loading = true;
  ProductDetails? product;
  String? error;

  String? get localizedPrice => product?.price;

  Future<void> initialize({required bool webPreview}) async {
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
        // Refresh non-consumable ownership from Google Play.
        await _iap.restorePurchases();
      }
    } catch (value) {
      error = value.toString();
    } finally {
      loading = false;
      onChanged();
    }
  }

  Future<bool> buy() async {
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
    } catch (value) {
      error = value.toString();
      onChanged();
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != productId) continue;

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
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
    onChanged();
  }

  void dispose() {
    _subscription?.cancel();
  }
}
