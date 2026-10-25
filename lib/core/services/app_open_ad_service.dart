import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_config.dart';
import 'ad_service.dart';

/// Splash app-open ad. Pro members never see it.
/// Failures never block splash navigation.
class AppOpenAdManager {
  AppOpenAdManager._();

  static final AppOpenAdManager instance = AppOpenAdManager._();

  AppOpenAd? _appOpenAd;
  bool _isShowing = false;
  bool _isLoading = false;
  Completer<bool>? _loadCompleter;
  DateTime? _nextAllowedLoadAt;

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
    if (!AppConfig.enableAppOpenAds || _isProUser) {
      discard();
      return Future.value(false);
    }
    if (_appOpenAd != null) return Future.value(true);
    if (_isLoading) return _loadCompleter?.future ?? Future.value(false);
    if (_loadCompleter != null) return _loadCompleter!.future;

    final nextAllowed = _nextAllowedLoadAt;
    if (nextAllowed != null && DateTime.now().isBefore(nextAllowed)) {
      return Future.value(false);
    }

    _loadCompleter = Completer<bool>();
    _isLoading = true;

    try {
      debugPrint('AppOpenAd: AdRequest');
      AppOpenAd.load(
        adUnitId: AdService.instance.appOpenAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            _isLoading = false;
            _nextAllowedLoadAt = null;
            debugPrint('AppOpenAd: loaded');
            _completeLoad(true);
          },
          onAdFailedToLoad: (error) {
            debugPrint('App open failed: $error');
            _isLoading = false;
            _nextAllowedLoadAt =
                DateTime.now().add(const Duration(seconds: 45));
            _completeLoad(false);
          },
        ),
      );
    } catch (error) {
      debugPrint('App open ad load error: $error');
      _isLoading = false;
      _nextAllowedLoadAt = DateTime.now().add(const Duration(seconds: 45));
      _completeLoad(false);
      return Future.value(false);
    }

    return _loadCompleter!.future;
  }

  void _completeLoad(bool value) {
    final completer = _loadCompleter;
    _loadCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(value);
    }
  }

  Future<bool> showAdIfAvailable({Duration? loadTimeout}) async {
    if (!AppConfig.enableAppOpenAds || _isProUser || _isShowing) {
      return false;
    }

    try {
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
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          if (kDebugMode) {
            debugPrint('App open ad failed to show: $error');
          }
          _disposeAd(ad);
          _isShowing = false;
          if (!completer.isCompleted) completer.complete();
        },
        onAdShowedFullScreenContent: (ad) {
          didShow = true;
        },
      );

      try {
        await _appOpenAd!.show();
      } on PlatformException catch (error) {
        if (kDebugMode) debugPrint('App open show error: $error');
        _disposeAd(_appOpenAd!);
        _isShowing = false;
        return false;
      }

      await completer.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          final ad = _appOpenAd;
          if (ad != null) _disposeAd(ad);
          _isShowing = false;
        },
      );
      return didShow;
    } catch (error) {
      if (kDebugMode) debugPrint('App open showAdIfAvailable error: $error');
      _isShowing = false;
      discard();
      return false;
    }
  }

  void _disposeAd(AppOpenAd ad) {
    ad.dispose();
    if (identical(_appOpenAd, ad)) {
      _appOpenAd = null;
    }
  }
}
