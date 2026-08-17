import 'package:flutter_test/flutter_test.dart';
import 'package:photofix_ai/core/services/entitlement_service.dart';
import 'package:photofix_ai/domain/models/models.dart';
import 'package:photofix_ai/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsProvider', () {
    test('persists theme and onboarding', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsProvider(prefs);

      expect(settings.onboardingDone, isFalse);
      await settings.completeOnboarding();
      expect(settings.onboardingDone, isTrue);

      await settings.setTheme(ThemeModeOption.dark);
      expect(settings.themeOption, ThemeModeOption.dark);

      final reloaded = SettingsProvider(prefs);
      expect(reloaded.onboardingDone, isTrue);
      expect(reloaded.themeOption, ThemeModeOption.dark);
    });
  });

  group('Premium checks', () {
    test('isProUser centralizes entitlement', () async {
      SharedPreferences.setMockInitialValues({});
      final service =
          EntitlementService(await SharedPreferences.getInstance());
      expect(service.isProUser(), isFalse);
      await service.setEntitlement(EntitlementType.proYearly);
      expect(service.isProUser(), isTrue);
    });
  });
}
