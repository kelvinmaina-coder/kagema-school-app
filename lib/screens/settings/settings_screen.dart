import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../app_settings.dart';

class SettingsScreen extends StatefulWidget {
  final String role;
  const SettingsScreen({super.key, required this.role});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _notificationsEnabled = await AppSettings.getNotifications();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('${widget.role} Settings'),
        backgroundColor: AppTheme.primaryTeal,
      ),
      body: ListView(
        children: [
          // Profile Section
          _buildSectionHeader('PROFILE'),
          _buildSettingsCard([
            _buildSettingTile(
              title: 'My Profile',
              icon: Icons.person,
              onTap: () => _showMessage('Edit Profile'),
            ),
            _buildDivider(),
            _buildSettingTile(
              title: 'Change Password',
              icon: Icons.lock,
              onTap: () => _showMessage('Change Password'),
            ),
          ]),
          
          const SizedBox(height: 20),
          
          // Preferences Section (Shared by ALL roles)
          _buildSectionHeader('PREFERENCES'),
          _buildSettingsCard([
            _buildSwitchTile(
              title: 'Push Notifications',
              icon: Icons.notifications,
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                AppSettings.setNotifications(value);
              },
            ),
            _buildDivider(),
            _buildSettingTile(
              title: 'Language',
              icon: Icons.language,
              trailing: _selectedLanguage,
              onTap: () => _selectLanguage(),
            ),
            _buildDivider(),
            _buildSettingTile(
              title: 'Theme Mode',
              icon: Icons.dark_mode,
              trailing: 'Light',
              onTap: () => _showMessage('Theme Settings'),
            ),
          ]),
          
          const SizedBox(height: 20),
          
          // Support Section
          _buildSectionHeader('SUPPORT'),
          _buildSettingsCard([
            _buildSettingTile(
              title: 'Help Center',
              icon: Icons.help,
              onTap: () => _showMessage('Help Center'),
            ),
            _buildDivider(),
            _buildSettingTile(
              title: 'About Kagema School',
              icon: Icons.info,
              onTap: () => _showMessage('Version 1.0.0'),
            ),
          ]),
          
          const SizedBox(height: 20),
          
          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('LOGOUT'),
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile({required String title, required IconData icon, String? trailing, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryTeal),
      title: Text(title, style: const TextStyle(color: AppTheme.primaryDark)),
      trailing: trailing != null ? Text(trailing, style: const TextStyle(color: Colors.grey)) : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({required String title, required IconData icon, required bool value, required Function(bool) onChanged}) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryTeal),
      title: Text(title, style: const TextStyle(color: AppTheme.primaryDark)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: AppTheme.primaryTeal),
    );
  }

  Widget _buildDivider() => Divider(height: 1, thickness: 1, color: Colors.grey[200]);

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _selectLanguage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('English'), onTap: () { setState(() => _selectedLanguage = 'English'); Navigator.pop(context); }),
            ListTile(title: const Text('Swahili'), onTap: () { setState(() => _selectedLanguage = 'Swahili'); Navigator.pop(context); }),
          ],
        ),
      ),
    );
  }
}
