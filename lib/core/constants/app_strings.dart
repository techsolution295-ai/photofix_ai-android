/// Localization-ready user-facing strings (English first; Urdu-ready later).
class AppStrings {
  AppStrings._();

  static const String appName = 'PhotoFix AI';
  static const String tagline = 'Enhance. Restore. Upscale.';

  // Onboarding
  static const String onboardingTitle1 = 'Make Every Photo Better';
  static const String onboardingDesc1 =
      'Enhance your photos with powerful AI technology.';
  static const String onboardingTitle2 = 'Restore Old Memories';
  static const String onboardingDesc2 =
      'Bring blurry, damaged and old photos back to life.';
  static const String onboardingTitle3 = 'Upscale to HD';
  static const String onboardingDesc3 =
      'Create sharper and clearer high-resolution photos.';
  static const String skip = 'Skip';
  static const String next = 'Next';
  static const String getStarted = 'Get Started';

  // Home
  static const String heroTitle = 'Make Your Photos Better ✨';
  static const String heroDesc =
      'Enhance, restore and upscale your photos with AI.';
  static const String choosePhoto = 'Choose Photo';
  static const String takePhoto = 'Take Photo';
  static const String popularTools = 'Popular AI Tools';
  static const String freeRemaining = '{count} free enhancements remaining today';
  static const String dailyLimitReached = 'Daily limit reached';
  static const String watchAd = 'Watch Ad';
  static const String upgradeToPro = 'Upgrade to Pro';

  // Nav
  static const String home = 'Home';
  static const String aiTools = 'AI Tools';
  static const String profile = 'Profile';

  // Tools
  static const String enhance = 'AI Enhance';
  static const String enhanceDesc =
      'Improve sharpness, details, lighting and overall quality.';
  static const String upscale = 'AI Upscale';
  static const String upscaleDesc = 'Enlarge photos up to 4X with AI clarity.';
  static const String restore = 'Restore Photo';
  static const String restoreDesc =
      'Fix old photos, scratches, blur and face details.';
  static const String colorize = 'Colorize';
  static const String colorizeDesc =
      'Bring old black-and-white photos to life with realistic colors.';
  static const String denoise = 'Remove Noise';
  static const String denoiseDesc =
      'Reduce grain, digital noise and low-light noise.';
  static const String sharpen = 'Sharpen Photo';
  static const String sharpenDesc = 'Improve image sharpness and clarity.';

  // Processing
  static const String uploading = 'Uploading photo...';
  static const String preparingModel = 'Preparing AI model...';
  static const String enhancingDetails = 'Enhancing details...';
  static const String improvingQuality = 'Improving image quality...';
  static const String finalizing = 'Finalizing your photo...';
  static const String processingFailed =
      'Something went wrong while processing your photo. Please try again.';
  static const String tryAgain = 'Try Again';
  static const String offlineRequired =
      'Internet connection is required to process photos.';

  // Result
  static const String enhancementComplete = 'AI Enhancement Complete ✨';
  static const String saveToGallery = 'Save to Gallery';
  static const String share = 'Share';
  static const String enhanceAnother = 'Enhance Another';
  static const String goHome = 'Go Home';
  static const String savedSuccess = 'Photo saved successfully.';
  static const String saveFailed = 'Unable to save photo. Please try again.';

  // Limit
  static const String dailyLimitTitle = 'Daily limit reached';
  static const String dailyLimitBody =
      'You have used today\'s free AI enhancements.';
  static const String goPro = 'Go Pro';
  static const String adUnavailable =
      'Rewarded ad is currently unavailable.';

  // Premium
  static const String unlockPro = 'Unlock PhotoFix Pro 👑';
  static const String welcomePro = 'Welcome to PhotoFix Pro! 👑';
  static const String purchaseFailed = 'Purchase could not be completed.';
  static const String processingPurchase = 'Processing...';
  static const String bestValue = 'BEST VALUE';
  static const String monthly = 'MONTHLY';
  static const String yearly = 'YEARLY';
  static const String lifetime = 'LIFETIME';
  static const String priceMonthly = '\$2.99/month';
  static const String priceYearly = '\$19.99/year';
  static const String priceLifetime = '\$39.99 one-time';

  // History
  static const String history = 'History';
  static const String historyEmpty = 'No processed photos yet.';
  static const String historyEmptyHint =
      'Enhance your first photo to see it here.';
  static const String today = 'Today';
  static const String yesterday = 'Yesterday';
  static const String older = 'Older';
  static const String clearAll = 'Clear all';

  // Settings / Profile
  static const String settings = 'Settings';
  static const String darkMode = 'Dark Mode';
  static const String notifications = 'Notifications';
  static const String language = 'Language';
  static const String restorePurchases = 'Restore Purchases';
  static const String purchasesRestored = 'Purchases restored successfully.';
  static const String noPurchasesFound = 'No previous purchases found.';
  static const String helpFaq = 'Help & FAQ';
  static const String contactSupport = 'Contact Support';
  static const String rateApp = 'Rate App';
  static const String privacyPolicy = 'Privacy Policy';
  static const String termsOfUse = 'Terms of Use';
  static const String pro = 'PRO';

  // Errors
  static const String invalidImage =
      'This image cannot be processed. Please choose a JPG, PNG or WEBP file.';
  static const String imageTooLarge =
      'This image is too large. Please choose a smaller photo.';
  static const String cameraPermission =
      'Camera access is needed to take photos.';
  static const String openSettings = 'Open Settings';
  static const String genericError = 'Something went wrong. Please try again.';

  static String freeRemainingLabel(int count) =>
      '$count free enhancements remaining today';
}
