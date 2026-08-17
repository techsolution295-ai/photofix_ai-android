import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// Resolves OpenAI API key from dart-define or user Settings (runtime).
/// Never hardcode secrets in source.
class OpenAiKeyStore {
  OpenAiKeyStore(this._prefs);

  final SharedPreferences _prefs;

  static const _prefsKey = 'openai_api_key';

  String? get dartDefineKey {
    final key = AppConfig.openAiApiKey.trim();
    return key.isEmpty ? null : key;
  }

  String? get runtimeKey {
    final key = _prefs.getString(_prefsKey)?.trim();
    return (key == null || key.isEmpty) ? null : key;
  }

  /// Runtime key wins (allows quick testing); else compile-time dart-define.
  String? get effectiveKey => runtimeKey ?? dartDefineKey;

  bool get hasKey => effectiveKey != null;

  Future<void> setRuntimeKey(String? key) async {
    final trimmed = key?.trim() ?? '';
    if (trimmed.isEmpty) {
      await _prefs.remove(_prefsKey);
    } else {
      await _prefs.setString(_prefsKey, trimmed);
    }
  }

  String get maskedKey {
    final key = effectiveKey;
    if (key == null) return '';
    if (key.length <= 8) return '••••';
    return '${key.substring(0, 3)}••••${key.substring(key.length - 4)}';
  }
}
