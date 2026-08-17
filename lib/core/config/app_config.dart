/// Central configuration. Prefer `--dart-define` for production values.
///
/// Example:
/// ```
/// flutter run \
///   --dart-define=OPENAI_API_KEY=sk-... \
///   --dart-define=USE_MOCK_AI=false \
///   --dart-define=ENVIRONMENT=development
/// ```
class AppConfig {
  AppConfig._();

  static const String appName = 'PhotoFix AI';
  static const String appTagline = 'Enhance. Restore. Upscale.';
  static const String packageName = 'com.appstudio.photofix.ai';

  /// Development | production
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  /// Your own backend (optional). Used when OpenAI key is not set.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// OpenAI secret key — prefer dart-define or Settings screen.
  /// Never commit real keys to git.
  static const String openAiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  /// GPT Image model for /v1/images/edits
  static const String openAiImageModel = String.fromEnvironment(
    'OPENAI_IMAGE_MODEL',
    defaultValue: 'gpt-image-1.5',
  );

  /// When true, uses local mock adjustments for UI testing only.
  /// Default false — real OpenAI / backend is preferred.
  static const bool useMockAi = bool.fromEnvironment(
    'USE_MOCK_AI',
    defaultValue: false,
  );

  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://sites.google.com/view/app-bounties/home',
  );

  static const String termsUrl = String.fromEnvironment(
    'TERMS_URL',
    defaultValue: 'https://sites.google.com/view/appbounties/home',
  );

  static const String supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'supportmateen@gmail.com',
  );

  static String get supportEmailUri => 'mailto:$supportEmail';

  // --- Google Play product IDs ---
  static const String productMonthly = String.fromEnvironment(
    'PRODUCT_MONTHLY',
    defaultValue: 'photofix_pro_monthly',
  );
  static const String productYearly = String.fromEnvironment(
    'PRODUCT_YEARLY',
    defaultValue: 'photofix_pro_yearly',
  );
  static const String productLifetime = String.fromEnvironment(
    'PRODUCT_LIFETIME',
    defaultValue: 'photofix_lifetime',
  );

  // --- AdMob (defaults = Google test IDs) ---
  static const String admobAppId = String.fromEnvironment(
    'ADMOB_APP_ID',
    defaultValue: 'ca-app-pub-3940256099942544~3347511713',
  );
  static const String bannerAdUnitId = String.fromEnvironment(
    'ADMOB_BANNER_ID',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111',
  );
  static const String interstitialAdUnitId = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ID',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712',
  );
  static const String rewardedAdUnitId = String.fromEnvironment(
    'ADMOB_REWARDED_ID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
  );
  static const bool enableAppOpenAds = bool.fromEnvironment(
    'ENABLE_APP_OPEN_ADS',
    defaultValue: false,
  );

  static const int freeDailyLimit = 3;
  static const int freeHistoryLimit = 10;
  static const int interstitialCooldownMinutes = 3;
  static const int maxUploadBytes = 15 * 1024 * 1024;
  static const int maxImageDimension = 4096;

  static bool get isProduction => environment == 'production';

  static bool get hasApiConfigured => apiBaseUrl.trim().isNotEmpty;

  static bool get hasOpenAiKeyConfigured => openAiApiKey.trim().isNotEmpty;

  /// Production must never silently mock AI results.
  static bool get shouldUseMockAi {
    if (isProduction) return false;
    return useMockAi;
  }

  static void assertProductionReady() {
    if (!isProduction) return;
    if (useMockAi) {
      throw StateError('USE_MOCK_AI must be false in production.');
    }
    // Local on-device AI is always available — cloud keys are optional.
  }
}
