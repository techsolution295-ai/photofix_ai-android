import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/services/ad_service.dart';
import 'core/services/app_open_ad_service.dart';
import 'core/services/ai_service.dart';
import 'core/services/ai_service_factory.dart';
import 'core/services/analytics_service.dart';
import 'core/services/history_repository.dart';
import 'core/services/image_compression_service.dart';
import 'core/services/image_storage_service.dart';
import 'core/services/network_service.dart';
import 'core/services/openai_key_store.dart';
import 'core/services/photo_picker_service.dart';
import 'core/services/pro_purchase_service.dart';
import 'presentation/providers/ai_config_provider.dart';
import 'presentation/providers/ai_processing_provider.dart';
import 'presentation/providers/history_provider.dart';
import 'presentation/providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.isProduction) {
    AppConfig.assertProductionReady();
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFFF7F8FC),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final network = NetworkService();
  await network.init();

  final storage = ImageStorageService();
  final historyRepo = HistoryRepository(prefs, storage);
  final analytics = DebugAnalyticsService();
  final openAiKeys = OpenAiKeyStore(prefs);
  final aiService = AiServiceFactory.create(openAiKeys);

  final settingsProvider = SettingsProvider(prefs);
  final billing = ProPurchaseService(settingsProvider);
  AdService.instance.bind(isPro: () => settingsProvider.isPremium);
  try {
    await MobileAds.instance
        .initialize()
        .timeout(const Duration(seconds: 8));
  } catch (_) {}
  AdService.instance.initialize();
  if (!settingsProvider.isPremium) {
    unawaited(AppOpenAdManager.instance.loadAd());
  }
  unawaited(billing.start());

  final aiConfigProvider = AiConfigProvider(openAiKeys);
  final historyProvider = HistoryProvider(historyRepo);
  final processingProvider = AiProcessingProvider(
    aiService: aiService,
    network: network,
    compression: ImageCompressionService(),
    storage: storage,
    analytics: analytics,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AnalyticsService>.value(value: analytics),
        Provider<AiService>.value(value: aiService),
        Provider<PhotoPickerService>.value(value: PhotoPickerService()),
        Provider<ImageStorageService>.value(value: storage),
        Provider<ImageCompressionService>.value(
          value: ImageCompressionService(),
        ),
        Provider<NetworkService>.value(value: network),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: billing),
        ChangeNotifierProvider.value(value: aiConfigProvider),
        ChangeNotifierProvider.value(value: historyProvider),
        ChangeNotifierProvider.value(value: processingProvider),
      ],
      child: const PhotoFixApp(),
    ),
  );
}
