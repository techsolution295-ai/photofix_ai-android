import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_service.dart';

/// Splash app-open ad. Pro members never see it.
class AppOpenAdManager {
  AppOpenAdManager._();

  static final AppOpenAdManager instance = AppOpenAdManager._();

  AppOpenAd? _appOpenAd;
  bool _isShowing = false;
  bool _isLoading = false;
  Completer<bool>? _loadCompleter;

  bool get _isProUser => AdService.instance.isPro;

  void discard() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _isLoading = false;
    if (_loadCompleter != null && !_loadCompleter!.isCompleted) {
      _loadCompleter!.complete(false);
    }
    _loadCompleter = null;
  }

  Future<bool> loadAd() {
    if (_isProUser) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
      return Future.value(false);
    }
    if (_appOpenAd != null) return Future.value(true);
    if (_isLoading) return _loadCompleter?.future ?? Future.value(false);
    if (_loadCompleter != null) return _loadCompleter!.future;

    _loadCompleter = Completer<bool>();
    _isLoading = true;

    try {
      AppOpenAd.load(
        adUnitId: AdService.instance.appOpenAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            _isLoading = false;
            _loadCompleter?.complete(true);
            _loadCompleter = null;
          },
          onAdFailedToLoad: (error) {
            if (kDebugMode) debugPrint('App open ad failed to load: $error');
            _isLoading = false;
            _loadCompleter?.complete(false);
            _loadCompleter = null;
          },
        ),
      );
    } on PlatformException catch (error) {
      if (kDebugMode) debugPrint('App open ad load error: $error');
      _isLoading = false;
      _loadCompleter?.complete(false);
      _loadCompleter = null;
      return Future.value(false);
    }

    return _loadCompleter!.future;
  }

  Future<bool> showAdIfAvailable({Duration? loadTimeout}) async {
    if (_isProUser || _isShowing) return false;

    final loadFuture = loadAd();
    final loaded = loadTimeout == null
        ? await loadFuture
        : await loadFuture.timeout(loadTimeout, onTimeout: () => false);
    if (!loaded || _appOpenAd == null) return false;

    final completer = Completer<void>();
    var didShow = false;
    _isShowing = true;

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _disposeAd(ad);
        _isShowing = false;
        if (!completer.isCompleted) completer.complete();
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _disposeAd(ad);
        _isShowing = false;
        if (!completer.isCompleted) completer.complete();
        loadAd();
      },
      onAdShowedFullScreenContent: (ad) {
        didShow = true;
      },
    );

    _appOpenAd!.show();
    await completer.future;
    return didShow;
  }

  void _disposeAd(AppOpenAd ad) {
    ad.dispose();
    _appOpenAd = null;
  }
}
