import 'package:flutter/foundation.dart';

/// Analytics abstraction — swap implementation without touching UI.
abstract class AnalyticsService {
  Future<void> logEvent(String name, [Map<String, Object>? params]);
}

class DebugAnalyticsService implements AnalyticsService {
  @override
  Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    debugPrint('[analytics] $name ${params ?? {}}');
  }
}

class AnalyticsEvents {
  static const onboardingCompleted = 'onboarding_completed';
  static const photoSelected = 'photo_selected';
  static const enhancementStarted = 'enhancement_started';
  static const enhancementCompleted = 'enhancement_completed';
  static const enhancementFailed = 'enhancement_failed';
  static const upscaleStarted = 'upscale_started';
  static const restoreStarted = 'restore_started';
  static const colorizeStarted = 'colorize_started';
  static const rewardedAdCompleted = 'rewarded_ad_completed';
  static const premiumScreenOpened = 'premium_screen_opened';
  static const subscriptionStarted = 'subscription_started';
  static const lifetimePurchase = 'lifetime_purchase';
  static const resultSaved = 'result_saved';
  static const resultShared = 'result_shared';
}
