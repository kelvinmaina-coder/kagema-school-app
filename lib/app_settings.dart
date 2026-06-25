import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal();

  // Core App State
  ThemeMode _themeMode = ThemeMode.light;
  bool _notificationsEnabled = true;
  String _language = 'English';
  bool _biometricAuth = false;
  final String _appVersion = "3.1.0 (Production)";

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  String get language => _language;
  bool get biometricAuth => _biometricAuth;
  String get appVersion => _appVersion;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _notificationsEnabled = prefs.getBool('notifications') ?? true;
    _language = prefs.getString('language') ?? 'English';
    _biometricAuth = prefs.getBool('biometric') ?? false;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', mode == ThemeMode.dark);
    notifyListeners();
  }

  Future<void> setNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', enabled);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    notifyListeners();
  }

  Future<void> setBiometric(bool enabled) async {
    _biometricAuth = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric', enabled);
    notifyListeners();
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    // Keep login session but clear UI preferences
    await prefs.remove('isDark');
    await prefs.remove('notifications');
    await loadSettings();
  }

  Future<void> factoryReset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Wipes EVERYTHING including auth tokens
    await loadSettings();
  }
}
