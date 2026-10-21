import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../core/services/ad_service.dart';
import '../providers/settings_provider.dart';

/// Anchored banner. Hidden for Pro members.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  static const double _height = 56;
  static const _retryInterval = Duration(seconds: 30);

  BannerAd? _bannerAd;
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

  void _loadBanner() {
    if (_isLoading || _bannerAd != null) return;
    if (context.read<SettingsProvider>().isPremium) return;
    _isLoading = true;
    final ad = BannerAd(
      adUnitId: AdService.instance.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loaded) {
          if (!mounted) {
            loaded.dispose();
            return;
          }
          setState(() {
            _bannerAd = loaded as BannerAd;
            _isLoading = false;
          });
        },
        onAdFailedToLoad: (failed, error) {
          failed.dispose();
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

    return Material(
      color: Colors.white,
      child: Container(
        height: _height,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE8EAF2))),
        ),
        alignment: Alignment.center,
        child: _bannerAd == null
            ? const SizedBox.shrink()
            : SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
      ),
    );
  }
}
