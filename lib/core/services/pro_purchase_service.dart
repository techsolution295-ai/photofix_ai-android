import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../config/app_config.dart';
import '../../presentation/providers/settings_provider.dart';
import 'ad_service.dart';
import 'app_open_ad_service.dart';

/// Play Billing for Weekly, Monthly, and Yearly Pro.
/// Pro is granted only after the store reports an active purchase.
class ProPurchaseService extends ChangeNotifier with WidgetsBindingObserver {
  ProPurchaseService(this._settings);

  static const Map<String, String> productIds = {
    'weekly': AppConfig.productWeekly,
    'monthly': AppConfig.productMonthly,
    'yearly': AppConfig.productYearly,
  };

  static const Map<String, String> basePlanIds = {
    'weekly': AppConfig.basePlanWeekly,
    'monthly': AppConfig.basePlanMonthly,
    'yearly': AppConfig.basePlanYearly,
  };

  final SettingsProvider _settings;
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Completer<void>? _restoreCompleter;
  Future<void>? _refreshTask;
  Future<void>? _loadTask;
  bool _syncInProgress = false;
  bool _restoreFoundActive = false;
  bool _started = false;

  List<ProductDetails> products = [];
  String? lastMessage;

  static const String missingPrice = '__';

  ProductDetails? productFor(String planId) {
    final id = productIds[planId];
    if (id == null) return null;
    final matches = [
      for (final product in products)
        if (product.id == id) product,
    ];
    if (matches.isEmpty) return null;

    final wantedBasePlan = basePlanIds[planId];
    GooglePlayProductDetails? fallback;
    for (final product in matches) {
      if (product is! GooglePlayProductDetails) continue;
      fallback ??= product;
      final offer = _offer(product);
      if (offer == null) continue;
      final phase = _pricedPhase(offer);
      if (phase == null) continue;
      if (wantedBasePlan != null && offer.basePlanId == wantedBasePlan) {
        return product;
      }
      fallback = product;
    }
    return fallback ?? matches.first;
  }

  /// Play's formatted price. Missing products stay as [missingPrice].
  String priceLabel(String planId) {
    final product = productFor(planId);
    if (product == null) return missingPrice;
    final phase = product is GooglePlayProductDetails
        ? _pricedPhase(_offer(product))
        : null;
    final label = (phase?.formattedPrice ?? product.price).trim();
    if (label.isEmpty || label == 'Free') return missingPrice;
    return label.replaceAll(RegExp(r'\.00(?!\d)'), '');
  }

  double? rawPrice(String planId) {
    final product = productFor(planId);
    if (product == null) return null;
    if (product is GooglePlayProductDetails) {
      final micros = _pricedPhase(_offer(product))?.priceAmountMicros;
      if (micros != null && micros > 0) return micros / 1000000.0;
    }
    return product.rawPrice > 0 ? product.rawPrice : null;
  }

  SubscriptionOfferDetailsWrapper? _offer(GooglePlayProductDetails product) {
    final index = product.subscriptionIndex;
    final offers = product.productDetails.subscriptionOfferDetails;
    if (index == null ||
        offers == null ||
        index < 0 ||
        index >= offers.length) {
      return null;
    }
    return offers[index];
  }

  PricingPhaseWrapper? _pricedPhase(SubscriptionOfferDetailsWrapper? offer) {
    final phases = offer?.pricingPhases;
    if (phases == null || phases.isEmpty) return null;
    for (final phase in phases.reversed) {
      if (phase.priceAmountMicros > 0 &&
          phase.recurrenceMode == RecurrenceMode.infiniteRecurring) {
        return phase;
      }
    }
    for (final phase in phases.reversed) {
      if (phase.priceAmountMicros > 0) return phase;
    }
    return null;
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (_) {
        if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
          _restoreCompleter!.complete();
        }
      },
    );
    await loadProducts();
    unawaited(refreshFromStore());
  }

  Future<void> loadProducts() {
    final existing = _loadTask;
    if (existing != null) return existing;
    final task = _loadProducts();
    _loadTask = task;
    return task.whenComplete(() {
      if (identical(_loadTask, task)) _loadTask = null;
    });
  }

  Future<void> _loadProducts() async {
    const pauses = [
      Duration.zero,
      Duration(milliseconds: 700),
      Duration(seconds: 2),
    ];
    Object? lastError;
    for (var attempt = 0; attempt < pauses.length; attempt++) {
      if (pauses[attempt] > Duration.zero) {
        await Future<void>.delayed(pauses[attempt]);
      }
      try {
        final available = await _iap.isAvailable();
        if (!available) {
          lastError = 'billing unavailable';
          continue;
        }
        final response = await _iap.queryProductDetails(
          productIds.values.toSet(),
        );
        final found = response.productDetails
            .map((product) => product.id)
            .toSet();
        if (kDebugMode) {
          debugPrint(
            'Pro prices attempt ${attempt + 1}: '
            'found=$found missing=${response.notFoundIDs} error=${response.error}',
          );
        }
        if (response.error != null) {
          lastError = response.error;
          continue;
        }
        if (found.containsAll(productIds.values)) {
          products = response.productDetails;
          notifyListeners();
          return;
        }
        if (response.productDetails.isNotEmpty) {
          products = response.productDetails;
          notifyListeners();
        }
        lastError = 'missing ${response.notFoundIDs.join(', ')}';
      } catch (error) {
        lastError = error;
        if (kDebugMode) debugPrint('Pro prices query failed: $error');
      }
    }
    if (products.isEmpty && lastError == 'billing unavailable') {
      lastMessage = 'Play Store billing is not available on this device.';
    }
    if (kDebugMode) debugPrint('Pro prices unavailable: $lastError');
    notifyListeners();
  }

  /// Returns false when checkout cannot open. A canceled sheet stays on the paywall.
  Future<bool> buy(String planId) async {
    lastMessage = null;
    final available = await _iap.isAvailable();
    if (!available) {
      lastMessage = 'Play Store billing is not available on this device.';
      notifyListeners();
      return false;
    }
    if (products.isEmpty) await loadProducts();
    final product = productFor(planId);
    if (product == null) {
      lastMessage =
          'This plan is not available in the Play Store yet. Add ${productIds[planId]} and try again.';
      notifyListeners();
      return false;
    }
    try {
      final started = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) {
        lastMessage = 'Could not open checkout. Please try again.';
        notifyListeners();
      }
      return started;
    } catch (error) {
      lastMessage = 'Could not open checkout. Please try again.';
      if (kDebugMode) debugPrint('Pro purchase failed: $error');
      notifyListeners();
      return false;
    }
  }

  Future<void> restore() => refreshFromStore();

  Future<void> refreshFromStore() {
    final existing = _refreshTask;
    if (existing != null) return existing;
    final task = _refreshFromStore();
    _refreshTask = task;
    return task.whenComplete(() {
      if (identical(_refreshTask, task)) _refreshTask = null;
    });
  }

  Future<void> _refreshFromStore() async {
    final available = await _iap.isAvailable();
    if (!available) return;
    _syncInProgress = true;
    try {
      final active = await _resolveActivePro();
      await _settings.setPremium(active);
      AdService.instance.syncWithPro(_settings.isPremium);
      if (_settings.isPremium) {
        AppOpenAdManager.instance.discard();
      } else {
        unawaited(AppOpenAdManager.instance.loadAd());
      }
    } finally {
      _syncInProgress = false;
    }
  }

  Future<bool> _resolveActivePro() async {
    if (Platform.isAndroid) return _queryActiveProAndroid();

    _restoreFoundActive = false;
    _restoreCompleter = Completer<void>();
    await _iap.restorePurchases();
    await _restoreCompleter!.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () {},
    );
    return _restoreFoundActive;
  }

  Future<bool> _queryActiveProAndroid() async {
    final addition =
        _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final response = await addition.queryPastPurchases();
    if (response.error != null) {
      if (kDebugMode) {
        debugPrint('Pro restore failed — keeping the current Pro state');
      }
      return _settings.isPremium;
    }
    return response.pastPurchases.any(_isActiveProPurchase);
  }

  bool _isActiveProPurchase(PurchaseDetails purchase) {
    if (!productIds.values.contains(purchase.productID)) return false;
    if (purchase.status == PurchaseStatus.pending ||
        purchase.status == PurchaseStatus.error ||
        purchase.status == PurchaseStatus.canceled) {
      return false;
    }
    if (Platform.isAndroid && purchase is GooglePlayPurchaseDetails) {
      return purchase.billingClientPurchase.purchaseState ==
          PurchaseStateWrapper.purchased;
    }
    return purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored;
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (!productIds.values.contains(purchase.productID)) continue;
      if (_isActiveProPurchase(purchase)) {
        if (_syncInProgress) {
          _restoreFoundActive = true;
        } else {
          await _settings.setPremium(true);
          AdService.instance.syncWithPro(true);
          AppOpenAdManager.instance.discard();
        }
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
    if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
      _restoreCompleter!.complete();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshFromStore());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _purchaseSub?.cancel();
    super.dispose();
  }
}
