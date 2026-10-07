import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config/monetization_config.dart';
import '../core/core.dart';
import 'analytics_service.dart';
import 'storage_service.dart';

/// What the shop shows for one pack.
@immutable
class PackOffer {
  const PackOffer({required this.pack, required this.price, required this.available});
  final Pack pack;

  /// Store-formatted price, e.g. "£1.99". Empty if the store didn't return it.
  final String price;

  /// False when the store doesn't know this product (not created yet, or
  /// billing unavailable).
  final bool available;
}

/// In-app purchases. All packs are non-consumable. Ownership is cached
/// locally so cosmetics and Remove Ads work offline.
abstract class IapService {
  ValueListenable<Set<Pack>> get owned;
  ValueListenable<Map<Pack, PackOffer>> get offers;

  /// Human-readable status for the shop ("PURCHASE PENDING", errors...).
  ValueListenable<String?> get message;

  Future<void> init();
  Future<void> buy(Pack pack);
  Future<void> restore();
  void dispose();
}

/// Shared ownership bookkeeping for both implementations.
mixin _Ownership {
  StorageService get storage;
  AnalyticsService get analytics;
  ValueNotifier<Set<Pack>> get ownedNotifier;

  Future<void> grant(Pack pack, {required bool isNewPurchase}) async {
    if (ownedNotifier.value.contains(pack)) return;
    ownedNotifier.value = {...ownedNotifier.value, pack};
    await storage.setOwnedPacks(ownedNotifier.value);
    if (isNewPurchase) {
      await analytics.log(Events.iapPurchase(pack, productId: MonetizationConfig.productIds[pack]!));
    }
  }
}

class StoreIapService with _Ownership implements IapService {
  StoreIapService({required this.storage, required this.analytics})
      : ownedNotifier = ValueNotifier(storage.ownedPacks);

  @override
  final StorageService storage;
  @override
  final AnalyticsService analytics;
  @override
  final ValueNotifier<Set<Pack>> ownedNotifier;

  final _offers = ValueNotifier<Map<Pack, PackOffer>>({});
  final _message = ValueNotifier<String?>(null);
  final Map<Pack, ProductDetails> _products = {};
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final InAppPurchase _iap = InAppPurchase.instance;

  @override
  ValueListenable<Set<Pack>> get owned => ownedNotifier;
  @override
  ValueListenable<Map<Pack, PackOffer>> get offers => _offers;
  @override
  ValueListenable<String?> get message => _message;

  @override
  Future<void> init() async {
    // Listen before anything else so purchases completed while the app was
    // closed are delivered.
    _sub = _iap.purchaseStream.listen(_onPurchases, onError: (Object e) {
      _message.value = 'STORE ERROR';
      debugPrint('[iap] stream error: $e');
    });
    if (!await _iap.isAvailable()) {
      _message.value = 'STORE UNAVAILABLE';
      _offers.value = {
        for (final p in Pack.values) p: PackOffer(pack: p, price: '', available: false),
      };
      return;
    }
    final response = await _iap.queryProductDetails(MonetizationConfig.productIds.values.toSet());
    for (final d in response.productDetails) {
      final pack = MonetizationConfig.packForProduct(d.id);
      if (pack != null) _products[pack] = d;
    }
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('[iap] products not found in store: ${response.notFoundIDs}');
    }
    _offers.value = {
      for (final p in Pack.values)
        p: PackOffer(pack: p, price: _products[p]?.price ?? '', available: _products.containsKey(p)),
    };
  }

  @override
  Future<void> buy(Pack pack) async {
    final details = _products[pack];
    if (details == null) {
      _message.value = 'NOT AVAILABLE YET';
      return;
    }
    _message.value = null;
    await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: details));
  }

  @override
  Future<void> restore() async {
    _message.value = 'RESTORING...';
    await _iap.restorePurchases();
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      final pack = MonetizationConfig.packForProduct(p.productID);
      switch (p.status) {
        case PurchaseStatus.pending:
          _message.value = 'PURCHASE PENDING';
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // NOTE: no server-side receipt validation. Fine for cosmetics and
          // Remove Ads; add it (e.g. a Cloud Function) if that changes.
          if (pack != null) {
            await grant(pack, isNewPurchase: p.status == PurchaseStatus.purchased);
          }
          _message.value = p.status == PurchaseStatus.restored ? 'PURCHASES RESTORED' : 'THANK YOU!';
        case PurchaseStatus.error:
          _message.value = 'PURCHASE FAILED';
          debugPrint('[iap] error: ${p.error}');
        case PurchaseStatus.canceled:
          _message.value = null;
      }
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
  }

  @override
  void dispose() => _sub?.cancel();
}

/// A pretend store: purchases succeed instantly. Used on web, in tests, and
/// on devices with `--dart-define=FAKE_STORE=true` (to try the shop before
/// products exist in Play Console / App Store Connect).
class FakeIapService with _Ownership implements IapService {
  FakeIapService({required this.storage, required this.analytics})
      : ownedNotifier = ValueNotifier(storage.ownedPacks);

  @override
  final StorageService storage;
  @override
  final AnalyticsService analytics;
  @override
  final ValueNotifier<Set<Pack>> ownedNotifier;

  final _offers = ValueNotifier<Map<Pack, PackOffer>>({});
  final _message = ValueNotifier<String?>(null);

  static const prices = {
    Pack.removeAds: '£2.99',
    Pack.skins: '£1.99',
    Pack.trails: '£1.99',
    Pack.themes: '£1.99',
  };

  @override
  ValueListenable<Set<Pack>> get owned => ownedNotifier;
  @override
  ValueListenable<Map<Pack, PackOffer>> get offers => _offers;
  @override
  ValueListenable<String?> get message => _message;

  @override
  Future<void> init() async {
    _offers.value = {
      for (final p in Pack.values) p: PackOffer(pack: p, price: prices[p]!, available: true),
    };
  }

  @override
  Future<void> buy(Pack pack) async {
    await grant(pack, isNewPurchase: true);
    _message.value = 'THANK YOU! (TEST STORE)';
  }

  @override
  Future<void> restore() async => _message.value = 'PURCHASES RESTORED';

  @override
  void dispose() {}
}
