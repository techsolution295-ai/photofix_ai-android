import 'package:flutter_test/flutter_test.dart';
import 'package:photofix_ai/core/config/app_config.dart';
import 'package:photofix_ai/core/services/usage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UsageService', () {
    late UsageService usage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      usage = UsageService(prefs);
    });

    test('starts with full daily free uses', () {
      expect(
        usage.getRemainingFreeUses(isPro: false),
        AppConfig.freeDailyLimit,
      );
      expect(usage.canProcess(isPro: false), isTrue);
    });

    test('decrements after incrementUsage', () async {
      await usage.incrementUsage(isPro: false);
      expect(
        usage.getRemainingFreeUses(isPro: false),
        AppConfig.freeDailyLimit - 1,
      );
    });

    test('pro users are never limited', () async {
      for (var i = 0; i < 10; i++) {
        await usage.incrementUsage(isPro: true);
      }
      expect(usage.canProcess(isPro: true), isTrue);
    });

    test('rewarded ad grants exactly one extra use', () async {
      for (var i = 0; i < AppConfig.freeDailyLimit; i++) {
        await usage.incrementUsage(isPro: false);
      }
      expect(usage.canProcess(isPro: false), isFalse);

      final granted = await usage.grantRewardedUse();
      expect(granted, isTrue);
      expect(usage.getRemainingFreeUses(isPro: false), 1);
      expect(usage.canProcess(isPro: false), isTrue);
    });

    test('prevents duplicate reward grants within short window', () async {
      final first = await usage.grantRewardedUse();
      final second = await usage.grantRewardedUse();
      expect(first, isTrue);
      expect(second, isFalse);
    });

    test('resets on new calendar day', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('usage_date', '2000-01-01');
      await prefs.setInt('usage_count', 3);
      await prefs.setInt('usage_bonus', 2);

      usage.resetIfNewDay();
      expect(usage.usedToday, 0);
      expect(usage.bonusUses, 0);
      expect(
        usage.getRemainingFreeUses(isPro: false),
        AppConfig.freeDailyLimit,
      );
    });
  });
}
