import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class UsageService {
  UsageService(this._prefs);

  final SharedPreferences _prefs;

  static const _countKey = 'usage_count';
  static const _dateKey = 'usage_date';
  static const _bonusKey = 'usage_bonus';

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void resetIfNewDay() {
    final stored = _prefs.getString(_dateKey);
    final today = _todayKey();
    if (stored != today) {
      _prefs.setString(_dateKey, today);
      _prefs.setInt(_countKey, 0);
      _prefs.setInt(_bonusKey, 0);
    }
  }

  int get usedToday {
    resetIfNewDay();
    return _prefs.getInt(_countKey) ?? 0;
  }

  int get bonusUses {
    resetIfNewDay();
    return _prefs.getInt(_bonusKey) ?? 0;
  }

  int getRemainingFreeUses({required bool isPro}) {
    if (isPro) return 9999;
    resetIfNewDay();
    final remaining = (AppConfig.freeDailyLimit + bonusUses) - usedToday;
    return remaining < 0 ? 0 : remaining;
  }

  bool canProcess({required bool isPro}) {
    if (isPro) return true;
    return getRemainingFreeUses(isPro: false) > 0;
  }

  Future<void> incrementUsage({required bool isPro}) async {
    if (isPro) return;
    resetIfNewDay();
    await _prefs.setInt(_countKey, usedToday + 1);
  }

  /// Grants exactly one additional free processing after a completed rewarded ad.
  Future<bool> grantRewardedUse() async {
    resetIfNewDay();
    // Prevent double-grant in the same millisecond session via a simple token.
    final last = _prefs.getInt('last_reward_ms') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - last < 1500) return false;
    await _prefs.setInt('last_reward_ms', now);
    await _prefs.setInt(_bonusKey, bonusUses + 1);
    return true;
  }
}
