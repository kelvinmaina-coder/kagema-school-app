import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'supabase_service.dart';
import '../app_theme.dart';
// Note: You would add ota_update: ^4.0.1 to your pubspec.yaml for the real installer
// import 'package:ota_update/ota_update.dart'; 

class UpdateService extends ChangeNotifier {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  String _currentVersion = "3.0.2";
  String _remoteVersion = "3.0.2";
  String _downloadUrl = "";
  bool _isChecking = false;
  bool _isMandatory = false;

  String get currentVersion => _currentVersion;
  String get remoteVersion => _remoteVersion;
  bool get isChecking => _isChecking;
  bool get isUpdateAvailable => _compareVersions(_currentVersion, _remoteVersion) < 0;

  Future<void> init() async {
    // 1. Get local version from the actual app package
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    _currentVersion = packageInfo.version;
    
    // 2. Load cached version if any
    final prefs = await SharedPreferences.getInstance();
    _currentVersion = prefs.getString('sys_version') ?? _currentVersion;
    
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

  /// REAL CLOUD CHECK: Fetches latest metadata from Supabase
  Future<void> silentCheck(BuildContext context) async {
    try {
      final config = await SupabaseService.instance.getLatestAppVersion();
      _remoteVersion = config['version'];
      _downloadUrl = config['url'];
      _isMandatory = config['is_mandatory'];

      if (!isUpdateAvailable) return;

      final prefs = await SharedPreferences.getInstance();
      final lastNotified = prefs.getString('update_notified_version');

      if (lastNotified != _remoteVersion) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSubtleNotification(context, config['changelog']);
        });
        await prefs.setString('update_notified_version', _remoteVersion);
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
  }

  void _showSubtleNotification(BuildContext context, String changelog) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "New OS Upgrade V$_remoteVersion Available",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                showUpdatePortal(context, changelog);
              },
              child: const Text("VIEW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        backgroundColor: Colors.indigo.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> manualCheck(BuildContext context) async {
    _isChecking = true;
    notifyListeners();
    
    final config = await SupabaseService.instance.getLatestAppVersion();
    _remoteVersion = config['version'];
    _downloadUrl = config['url'];
    
    _isChecking = false;
    notifyListeners();

    if (isUpdateAvailable) {
      showUpdatePortal(context, config['changelog']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Your Kagema OS is up to date with the latest school protocols."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void showUpdatePortal(BuildContext context, String changelog) {
    showGeneralDialog(
      context: context,
      barrierDismissible: !_isMandatory,
      barrierLabel: "Update",
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isUpdating = false;
            double progress = 0.0;
            String status = "Connecting to Kagema Cloud...";

            void startUpgrade() {
              setState(() => isUpdating = true);
              
              // REAL IMPLEMENTATION using OTA UPDATE
              /* 
              try {
                OtaUpdate().execute(_downloadUrl, destinationFilename: 'kagema_v$_remoteVersion.apk').listen((event) {
                  setState(() {
                    progress = double.parse(event.value!) / 100;
                    status = "Synchronizing: ${event.status.name}...";
                    if (event.status == OtaStatus.INSTALLING) {
                      _finalizeUpdate(context);
                    }
                  });
                });
              } catch (e) {
                setState(() => status = "Encryption Error: $e");
              }
              */

              // SIMULATED VISUALS FOR NOW
              Timer.periodic(const Duration(milliseconds: 50), (timer) {
                setState(() {
                  progress += 0.01;
                  if (progress >= 1.0) {
                    timer.cancel();
                    _finalizeUpdate(context);
                  }
                });
              });
            }

            return WillPopScope(
              onWillPop: () async => !_isMandatory,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAnimatedIcon(Theme.of(context), isUpdating),
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
                            Text(
                              changelog,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                            ),
                          const SizedBox(height: 40),
                          if (isUpdating)
                            _buildProgressBar(Theme.of(context), progress)
                          else
                            _buildActionButtons(context, startUpgrade, Theme.of(context)),
                        ],
                      ),
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
      width: 90, height: 90,
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(color: theme.primaryColor.withOpacity(0.1), width: 2),
      ),
      child: Center(
        child: active 
          ? CircularProgressIndicator(strokeWidth: 2)
          : Icon(Icons.rocket_launch_rounded, size: 45, color: theme.primaryColor),
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme, double val) {
    return Column(
      children: [
        LinearProgressIndicator(value: val, minHeight: 8),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text("INSTALL UPGRADE NOW", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        if (!_isMandatory) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("REMIND ME LATER", style: TextStyle(color: Colors.grey)),
          ),
        ]
      ],
    );
  }

  void _finalizeUpdate(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sys_version', _remoteVersion);
    if (context.mounted) Navigator.pop(context);
  }
}
