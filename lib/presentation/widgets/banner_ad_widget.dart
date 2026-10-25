import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../core/services/ad_service.dart';
import '../providers/settings_provider.dart';

/// Anchored adaptive banner. Hidden for Pro members.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  static const _retryInterval = Duration(seconds: 45);

  BannerAd? _bannerAd;
  double _bannerHeight = 56;
  bool _isLoading = false;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadBanner();
      _retryTimer = Timer.periodic(_retryInterval, (_) {
        if (!mounted || _bannerAd != null) return;
        _loadBanner();
      });
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadBanner() async {
    if (_isLoading || _bannerAd != null) return;
    if (context.read<SettingsProvider>().isPremium) return;
    _isLoading = true;

    final width = MediaQuery.sizeOf(context).width.truncate();
    AdSize size = AdSize.banner;
    try {
      final adaptive = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        width,
      );
      if (adaptive != null) size = adaptive;
    } catch (_) {}

    if (!mounted) {
      _isLoading = false;
      return;
    }

    final ad = BannerAd(
      adUnitId: AdService.instance.bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loaded) {
          if (!mounted) {
            loaded.dispose();
            return;
          }
          setState(() {
            _bannerAd = loaded as BannerAd;
            _bannerHeight = size.height.toDouble();
            _isLoading = false;
          });
        },
        onAdFailedToLoad: (failed, error) {
          failed.dispose();
          debugPrint('Banner failed: $error');
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _isLoading = false;
          });
        },
      ),
    );
    ad.load();
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<SettingsProvider>().isPremium;
    if (isPro) {
      final ad = _bannerAd;
      if (ad != null) {
        _bannerAd = null;
        WidgetsBinding.instance.addPostFrameCallback((_) => ad.dispose());
      }
      return const SizedBox.shrink();
    }

    if (_bannerAd == null) return const SizedBox.shrink();

    return Material(
      color: Colors.white,
      child: Container(
        width: double.infinity,
        height: _bannerHeight,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE8EAF2))),
        ),
        alignment: Alignment.center,
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
