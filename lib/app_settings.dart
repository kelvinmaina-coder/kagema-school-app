import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String notificationsKey = 'notifications';
  
  // Theme Management (Shared across all roles)
  static Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(themeKey, mode.index);
  }
  
  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(themeKey) ?? 0;
    return ThemeMode.values[index];
  }
  
  // Language Management
  static Future<void> setLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(languageKey, langCode);
  }
  
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(languageKey) ?? 'en';
  }
  
  // Notifications
  static Future<void> setNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notificationsKey, enabled);
  }
  
  static Future<bool> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(notificationsKey) ?? true;
  }
  
  // Shared Settings Method (All roles use this)
  static List<Map<String, dynamic>> getSharedSettings() {
    return [
      {'title': 'Account', 'icon': Icons.person, 'type': 'profile'},
      {'title': 'Security', 'icon': Icons.security, 'type': 'security'},
      {'title': 'Notifications', 'icon': Icons.notifications, 'type': 'notifications'},
      {'title': 'Appearance', 'icon': Icons.palette, 'type': 'appearance'},
      {'title': 'Language', 'icon': Icons.language, 'type': 'language'},
      {'title': 'Help & Support', 'icon': Icons.help, 'type': 'help'},
      {'title': 'About', 'icon': Icons.info, 'type': 'about'},
      {'title': 'Logout', 'icon': Icons.logout, 'type': 'logout'},
    ];
  }
}
