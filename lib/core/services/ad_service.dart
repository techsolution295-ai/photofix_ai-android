import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Banner and interstitial ads.
/// Debug builds use Google's test units. Release builds use the live units.
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  static const _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const _testAppOpenId = 'ca-app-pub-3940256099942544/9257395921';
  static const _productionBannerId = 'ca-app-pub-8476267163759140/2887318448';
  static const _productionInterstitialId =
      'ca-app-pub-8476267163759140/3534930569';
  static const _productionAppOpenId = 'ca-app-pub-8476267163759140/8550708668';

  String get bannerAdUnitId => kDebugMode ? _testBannerId : _productionBannerId;

  String get interstitialAdUnitId =>
      kDebugMode ? _testInterstitialId : _productionInterstitialId;

  String get appOpenAdUnitId =>
      kDebugMode ? _testAppOpenId : _productionAppOpenId;

  bool get isPro => _isPro();

  bool Function() _isPro = () => false;

  InterstitialAd? _interstitialAd;
  bool _isLoadingInterstitial = false;
  bool _isShowingInterstitial = false;
  bool _started = false;

  void bind({required bool Function() isPro}) {
    _isPro = isPro;
  }

  void initialize() {
    if (_started) return;
    _started = true;
    syncWithPro(isPro);
  }

  /// Drops a loaded interstitial for Pro members and loads one when Pro ends.
  void syncWithPro(bool isPro) {
    if (isPro) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _isLoadingInterstitial = false;
      return;
    }
    _loadInterstitial();
  }

  void _loadInterstitial() {
    if (_isPro()) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
      return;
    }
    if (_interstitialAd != null || _isLoadingInterstitial) return;
    _isLoadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoadingInterstitial = false;
        },
        onAdFailedToLoad: (error) {
          _isLoadingInterstitial = false;
          if (kDebugMode) {
            debugPrint('Interstitial failed to load: $error');
          }
        },
      ),
    );
  }

  /// Tool opens. Pro members skip the ad and continue.
  Future<void> showSelectInterstitialThen(
    Future<void> Function() action,
  ) async {
    if (_isPro() || _isShowingInterstitial) {
      await action();
      return;
    }

    if (_interstitialAd == null) {
      _loadInterstitial();
      final deadline = DateTime.now().add(const Duration(seconds: 4));
      while (_interstitialAd == null && DateTime.now().isBefore(deadline)) {
        if (!_isLoadingInterstitial) _loadInterstitial();
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }

    final ad = _interstitialAd;
    if (ad == null) {
      await action();
      _loadInterstitial();
      return;
    }

    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _isShowingInterstitial = false;
        if (!completer.isCompleted) completer.complete();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _isShowingInterstitial = false;
        if (!completer.isCompleted) completer.complete();
        _loadInterstitial();
      },
    );

    _interstitialAd = null;
    _isShowingInterstitial = true;
    ad.show();
    await completer.future;
    try {
      await action();
    } finally {
      if (!_isLoadingInterstitial) _loadInterstitial();
    }
  }
}
