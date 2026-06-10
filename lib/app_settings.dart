import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal();

  // Storage Keys
  static const String themeModeKey = 'theme_mode';
  static const String pushNotificationsKey = 'push_notifications';
  static const String languageKey = 'language';

  // State with Defaults (Light Mode is Default)
  ThemeMode _themeMode = ThemeMode.light;
  bool _pushNotifications = true;
  String _language = 'en';

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _pushNotifications;
  String get language => _language;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to index 1 (Light Mode)
    int themeIndex = prefs.getInt(themeModeKey) ?? 1;
    _themeMode = ThemeMode.values[themeIndex];
    _pushNotifications = prefs.getBool(pushNotificationsKey) ?? true;
    _language = prefs.getString(languageKey) ?? 'en';
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(themeModeKey, mode.index);
    notifyListeners();
  }

  Future<void> setNotifications(bool enabled) async {
    _pushNotifications = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(pushNotificationsKey, enabled);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(languageKey, lang);
    notifyListeners();
  }

  // Shared settings list used by the UI
  static List<Map<String, dynamic>> getSharedSettings() {
    return [
      {'title': 'Profile', 'icon': Icons.person_outline, 'type': 'profile'},
      {'title': 'Account & Security', 'icon': Icons.security_outlined, 'type': 'security'},
      {'title': 'Appearance', 'icon': Icons.palette_outlined, 'type': 'appearance'},
      {'title': 'Notifications', 'icon': Icons.notifications_none_outlined, 'type': 'notifications'},
      {'title': 'Language', 'icon': Icons.language_outlined, 'type': 'language'},
      {'title': 'Help & Support', 'icon': Icons.help_outline, 'type': 'help'},
      {'title': 'About', 'icon': Icons.info_outline, 'type': 'about'},
      {'title': 'Logout', 'icon': Icons.logout_rounded, 'type': 'logout'},
    ];
  }
}
