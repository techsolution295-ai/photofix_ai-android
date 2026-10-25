import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_config.dart';

/// Banner and interstitial ads.
/// Debug builds use Google test units. Release builds use live AdMob units.
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  static const _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const _testAppOpenId = 'ca-app-pub-3940256099942544/9257395921';

  String get bannerAdUnitId =>
      kDebugMode ? _testBannerId : AppConfig.bannerAdUnitId;

  String get interstitialAdUnitId =>
      kDebugMode ? _testInterstitialId : AppConfig.interstitialAdUnitId;

  String get appOpenAdUnitId =>
      kDebugMode ? _testAppOpenId : AppConfig.appOpenAdUnitId;

  bool get isPro => _isPro();

  bool get usingLiveAds => !kDebugMode;

  bool Function() _isPro = () => false;

  InterstitialAd? _interstitialAd;
  bool _isLoadingInterstitial = false;
  bool _isShowingInterstitial = false;
  bool _started = false;
  DateTime? _nextInterstitialLoadAt;
  DateTime? _lastInterstitialShownAt;

  void bind({required bool Function() isPro}) {
    _isPro = isPro;
  }

  void initialize() {
    if (_started) return;
    _started = true;
    debugPrint(
      'AdService: ready (${usingLiveAds ? 'live' : 'test'} units)',
    );
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
    final nextAllowed = _nextInterstitialLoadAt;
    if (nextAllowed != null && DateTime.now().isBefore(nextAllowed)) return;

    _isLoadingInterstitial = true;
    debugPrint('AdService: AdRequest interstitial');
    try {
      InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isLoadingInterstitial = false;
            _nextInterstitialLoadAt = null;
            debugPrint('AdService: interstitial loaded');
          },
          onAdFailedToLoad: (error) {
            _isLoadingInterstitial = false;
            _nextInterstitialLoadAt =
                DateTime.now().add(const Duration(seconds: 45));
            debugPrint('Interstitial failed: $error');
          },
        ),
      );
    } catch (error) {
      _isLoadingInterstitial = false;
      _nextInterstitialLoadAt =
          DateTime.now().add(const Duration(seconds: 45));
      debugPrint('Interstitial load error: $error');
    }
  }

  bool get _interstitialCooldownActive {
    final last = _lastInterstitialShownAt;
    if (last == null) return false;
    final wait = Duration(minutes: AppConfig.interstitialCooldownMinutes);
    return DateTime.now().isBefore(last.add(wait));
  }

  /// Tool opens. Pro members skip the ad and continue.
  Future<void> showSelectInterstitialThen(
    Future<void> Function() action,
  ) async {
    if (_isPro() || _isShowingInterstitial || _interstitialCooldownActive) {
      await action();
      return;
    }

    if (_interstitialAd == null) {
      _loadInterstitial();
      final deadline = DateTime.now().add(const Duration(seconds: 3));
      while (_interstitialAd == null &&
          _isLoadingInterstitial &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }

    final ad = _interstitialAd;
    if (ad == null) {
      await action();
      return;
    }

    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shown) {
        shown.dispose();
        if (identical(_interstitialAd, shown)) {
          _interstitialAd = null;
        }
        _isShowingInterstitial = false;
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (shown, error) {
        debugPrint('Interstitial show failed: $error');
        shown.dispose();
        if (identical(_interstitialAd, shown)) {
          _interstitialAd = null;
        }
        _isShowingInterstitial = false;
        if (!completer.isCompleted) completer.complete();
      },
    );

    _interstitialAd = null;
    _isShowingInterstitial = true;
    try {
      await ad.show();
      _lastInterstitialShownAt = DateTime.now();
      await completer.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          _isShowingInterstitial = false;
        },
      );
    } catch (error) {
      debugPrint('Interstitial show error: $error');
      ad.dispose();
      _isShowingInterstitial = false;
    }

    try {
      await action();
    } finally {
      if (!_isLoadingInterstitial) _loadInterstitial();
    }
  }
}
