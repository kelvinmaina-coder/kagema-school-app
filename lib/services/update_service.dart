import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';

class UpdateService extends ChangeNotifier {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  String _currentVersion = "3.0.2";
  final String _remoteVersion = "3.1.0"; // Simulated remote version
  bool _isChecking = false;

  String get currentVersion => _currentVersion;
  String get remoteVersion => _remoteVersion;
  bool get isChecking => _isChecking;
  bool get isUpdateAvailable => _compareVersions(_currentVersion, _remoteVersion) < 0;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentVersion = prefs.getString('sys_version') ?? "3.0.2";
    notifyListeners();
  }

  int _compareVersions(String current, String remote) {
    try {
      List<int> currParts = current.split('.').map(int.parse).toList();
      List<int> remParts = remote.split('.').map(int.parse).toList();
      for (int i = 0; i < currParts.length; i++) {
        if (remParts[i] > currParts[i]) return -1;
        if (remParts[i] < currParts[i]) return 1;
      }
    } catch (e) {
      debugPrint("Version comparison error: $e");
    }
    return 0;
  }

  /// Silently notifies the user if an update is available via a subtle SnackBar
  Future<void> silentCheck(BuildContext context) async {
    if (!isUpdateAvailable) return;

    final prefs = await SharedPreferences.getInstance();
    final lastNotified = prefs.getString('update_notified_version');

    // Only notify once per new version to avoid nagging
    if (lastNotified != _remoteVersion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSubtleNotification(context);
      });
      await prefs.setString('update_notified_version', _remoteVersion);
    }
  }

  /// Compatibility method for existing calls in main.dart
  void checkAndPromptUpdate(BuildContext context) {
    silentCheck(context);
  }

  void _showSubtleNotification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Intelligence Upgrade Available (V3.1.0)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                showUpdatePortal(context);
              },
              child: const Text("VIEW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        backgroundColor: Colors.indigo.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Triggered manually from Settings
  Future<void> manualCheck(BuildContext context) async {
    _isChecking = true;
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 2)); // Simulate network check
    
    _isChecking = false;
    notifyListeners();

    if (isUpdateAvailable) {
      showUpdatePortal(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Your Kagema OS is up to date with the latest school protocols."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void showUpdatePortal(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Update",
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isUpdating = false;
            double progress = 0.0;
            String status = "Initializing synchronization...";

            void startUpgrade() {
              setState(() => isUpdating = true);
              Timer.periodic(const Duration(milliseconds: 40), (timer) {
                setState(() {
                  if (progress < 0.3) {
                    status = "Downloading V$_remoteVersion Core...";
                    progress += 0.01;
                  } else if (progress < 0.7) {
                    status = "Patching Glowing UI Components...";
                    progress += 0.015;
                  } else if (progress < 0.9) {
                    status = "Optimizing Performance Engines...";
                    progress += 0.008;
                  } else {
                    status = "Finalizing Secure Handshake...";
                    progress += 0.005;
                  }

                  if (progress >= 1.0) {
                    timer.cancel();
                    _finalizeUpdate(context);
                  }
                });
              });
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Material(
                  color: Colors.transparent,
                  child: gemini?.buildGlowContainer(
                    backgroundColor: theme.cardColor,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAnimatedIcon(theme, isUpdating),
                        const SizedBox(height: 24),
                        Text(
                          isUpdating ? "SYNCHRONIZING..." : "SYSTEM UPGRADE READY",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.blueGrey),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isUpdating ? status : "Intelligence Patch V$_remoteVersion",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        if (!isUpdating)
                          const Text(
                            "This update includes enhanced glowing effects, faster report generation, and security optimizations for the 2024 academic year.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                          ),
                        const SizedBox(height: 40),
                        if (isUpdating)
                          _buildProgressBar(theme, progress)
                        else
                          _buildActionButtons(context, startUpgrade, theme),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnimatedIcon(ThemeData theme, bool active) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(color: theme.primaryColor.withOpacity(0.1), width: 2),
      ),
      child: Center(
        child: active 
          ? CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor))
          : Icon(Icons.rocket_launch_rounded, size: 45, color: theme.primaryColor),
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme, double val) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: val,
            minHeight: 8,
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
          ),
        ),
        const SizedBox(height: 12),
        Text("${(val * 100).toInt()}% SYNCHRONIZED", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, VoidCallback onUpdate, ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: onUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 8,
              shadowColor: theme.primaryColor.withOpacity(0.4),
            ),
            child: const Text("INSTALL UPGRADE NOW", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("REMIND ME LATER", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _finalizeUpdate(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sys_version', _remoteVersion);
    
    if (context.mounted) {
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ System Synchronized to V$_remoteVersion. Restarting environment..."),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Simulate App Restart by pushing back to splash
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      });
    }
  }

  /// Creative Dialog to ask for Notification permissions on first install/start
  void promptNotificationPermission(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasAsked = prefs.getBool('notif_permission_asked') ?? false;
    
    if (hasAsked) return;

    if (!context.mounted) return;
    
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: gemini?.buildGlowContainer(
          backgroundColor: theme.cardColor,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.notifications_active_rounded, color: Colors.amber, size: 40),
              ),
              const SizedBox(height: 24),
              const Text("Enable Intelligence Alerts?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                "Stay synchronized with school events, fee reminders, and academic results in real-time.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await prefs.setBool('notif_permission_asked', true);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Intelligence alerts enabled!")));
                  },
                  child: const Text("ALLOW NOTIFICATIONS", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await prefs.setBool('notif_permission_asked', true);
                },
                child: const Text("NOT NOW", style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
