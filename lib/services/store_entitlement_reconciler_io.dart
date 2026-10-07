import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

Future<bool?> reconcileStoreOwnership({
  required InAppPurchase iap,
  required String productId,
}) async {
  if (!Platform.isAndroid) return null;

  try {
    final addition =
        iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final response = await addition.queryPastPurchases();
    if (response.error != null) return null;

    return response.pastPurchases.any(
      (purchase) =>
          purchase.productID == productId &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored),
    );
  } catch (_) {
    // Unknown is safer than revoking entitlement on a transient store error.
    return null;
  }
}
