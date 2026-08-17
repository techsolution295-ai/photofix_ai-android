import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/models.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;

  static const _themeKey = 'theme_mode';
  static const _notifKey = 'notifications_enabled';
  static const _onboardingKey = 'onboarding_done';
  static const _langKey = 'language';

  ThemeModeOption _theme = ThemeModeOption.system;
  bool _notifications = true;
  bool _onboardingDone = false;
  String _language = 'en';

  ThemeModeOption get themeOption => _theme;
  bool get notificationsEnabled => _notifications;
  bool get onboardingDone => _onboardingDone;
  String get language => _language;

  ThemeMode get themeMode {
    switch (_theme) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
        return ThemeMode.system;
    }
  }

  void _load() {
    final t = _prefs.getString(_themeKey);
    _theme = switch (t) {
      'light' => ThemeModeOption.light,
      'dark' => ThemeModeOption.dark,
      _ => ThemeModeOption.system,
    };
    _notifications = _prefs.getBool(_notifKey) ?? true;
    _onboardingDone = _prefs.getBool(_onboardingKey) ?? false;
    _language = _prefs.getString(_langKey) ?? 'en';
  }

  Future<void> setTheme(ThemeModeOption option) async {
    _theme = option;
    await _prefs.setString(_themeKey, option.name);
    notifyListeners();
  }

  Future<void> setNotifications(bool enabled) async {
    _notifications = enabled;
    await _prefs.setBool(_notifKey, enabled);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _onboardingDone = true;
    await _prefs.setBool(_onboardingKey, true);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _language = code;
    await _prefs.setString(_langKey, code);
    notifyListeners();
  }
}
