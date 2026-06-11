import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_settings.dart';
import '../../services/authentication_service.dart';
import '../../services/update_service.dart';
import '../../app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final String role;
  const SettingsScreen({super.key, required this.role});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Provider.of<AppSettings>(context);
    final auth = Provider.of<AuthenticationService>(context);
    final updates = Provider.of<UpdateService>(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(theme, gemini),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(theme, auth),
                    const SizedBox(height: 32),
                    
                    _buildSectionHeader('SYSTEM INFRASTRUCTURE'),
                    _buildSettingsGroup(theme, [
                      _buildUpdateTile(theme, updates, gemini),
                      _buildActionTile(
                        theme,
                        'Clear System Cache',
                        'Reset UI preferences and temp data',
                        Icons.cleaning_services_rounded,
                        Colors.grey,
                        () => _showClearCacheDialog(settings),
                      ),
                    ]),
                    const SizedBox(height: 32),

                    _buildSectionHeader('ENVIRONMENT PREFERENCES'),
                    _buildSettingsGroup(theme, [
                      _buildToggleTile(
                        theme,
                        'Intelligence Alerts',
                        'Real-time cloud notifications',
                        Icons.notifications_active_outlined,
                        Colors.orange,
                        settings.notificationsEnabled,
                        (v) => settings.setNotifications(v),
                      ),
                      _buildActionTile(
                        theme,
                        'Display Mode',
                        settings.themeMode == ThemeMode.dark ? 'Dark Environment' : 'Light Environment',
                        Icons.palette_outlined,
                        Colors.blue,
                        () => _showAppearanceDialog(settings),
                      ),
                      _buildActionTile(
                        theme,
                        'System Language',
                        settings.language,
                        Icons.language_rounded,
                        Colors.teal,
                        () => _showLanguageDialog(settings),
                      ),
                    ]),
                    const SizedBox(height: 32),

                    _buildSectionHeader('SECURITY & CREDENTIALS'),
                    _buildSettingsGroup(theme, [
                      _buildActionTile(
                        theme,
                        'Modify Identity Name',
                        auth.currentUserName,
                        Icons.badge_outlined,
                        Colors.green,
                        () => _showEditNameDialog(auth),
                      ),
                      _buildActionTile(
                        theme,
                        'Reset Cloud Password',
                        'Update your encrypted access key',
                        Icons.lock_reset_rounded,
                        Colors.redAccent,
                        () => _showPasswordDialog(auth),
                      ),
                    ]),
                    const SizedBox(height: 32),

                    _buildSectionHeader('DANGER ZONE'),
                    _buildSettingsGroup(theme, [
                      _buildActionTile(
                        theme,
                        'Factory Data Reset',
                        'Wipe all local session data',
                        Icons.delete_forever_rounded,
                        Colors.red,
                        () => _showFactoryResetDialog(settings),
                      ),
                    ]),

                    const SizedBox(height: 40),
                    _buildLogoutButton(theme, auth),
                    const SizedBox(height: 24),
                    _buildAppInfo(settings),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, GeminiThemeExtension? gemini) {
    return SliverAppBar(
      expandedHeight: 140.0,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Control Center', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
        background: Container(
          decoration: BoxDecoration(
            gradient: gemini?.primaryGradient ?? LinearGradient(colors: [theme.primaryColor, Colors.black87]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme, AuthenticationService auth) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            child: Text(auth.currentUserName[0].toUpperCase(), style: TextStyle(fontSize: 28, color: theme.primaryColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auth.currentUserName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                Text(widget.role.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.primaryColor, letterSpacing: 1.5)),
                Text(auth.currentUserPhone ?? 'No identifier', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateTile(ThemeData theme, UpdateService updates, GeminiThemeExtension? gemini) {
    return ListenableBuilder(
      listenable: updates,
      builder: (context, _) {
        bool hasUpdate = updates.isUpdateAvailable;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Icon(hasUpdate ? Icons.system_update_rounded : Icons.verified_user_rounded, color: hasUpdate ? Colors.blue : Colors.green),
          title: Text(hasUpdate ? 'Upgrade Available' : 'System Up to Date', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          subtitle: Text(hasUpdate ? 'V${updates.remoteVersion} is ready' : 'Kagema OS V${updates.currentVersion}'),
          trailing: hasUpdate ? ElevatedButton(onPressed: () => updates.showUpdatePortal(context), child: const Text('SYNC')) : null,
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
    );
  }

  Widget _buildSettingsGroup(ThemeData theme, List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(children: tiles),
    );
  }

  Widget _buildActionTile(ThemeData theme, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
      onTap: onTap,
    );
  }

  Widget _buildToggleTile(ThemeData theme, String title, String sub, IconData icon, Color color, bool val, Function(bool) onChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: Switch.adaptive(value: val, activeColor: theme.primaryColor, onChanged: onChanged),
    );
  }

  Widget _buildLogoutButton(ThemeData theme, AuthenticationService auth) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(auth),
        icon: const Icon(Icons.logout_rounded, color: Colors.red),
        label: const Text('TERMINATE SESSION', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: const EdgeInsets.all(16)),
      ),
    );
  }

  Widget _buildAppInfo(AppSettings settings) {
    return Center(
      child: Column(
        children: [
          const Text('KAGEMA COMPREHENSIVE SCHOOL MANAGEMENT SYSTEM', style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text('CORE ENGINE VERSION ${settings.appVersion}', style: const TextStyle(fontSize: 8, color: Colors.grey)),
        ],
      ),
    );
  }

  // --- DIALOGS ---

  void _showAppearanceDialog(AppSettings settings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(padding: EdgeInsets.all(20), child: Text('Theme Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ListTile(
            leading: const Icon(Icons.wb_sunny_rounded, color: Colors.orange),
            title: const Text('Light Mode'),
            onTap: () { settings.setThemeMode(ThemeMode.light); Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.nightlight_round, color: Colors.indigo),
            title: const Text('Dark Mode'),
            onTap: () { settings.setThemeMode(ThemeMode.dark); Navigator.pop(context); },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showLanguageDialog(AppSettings settings) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(padding: EdgeInsets.all(20), child: Text('Select Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ListTile(title: const Text('English (Production Default)'), onTap: () { settings.setLanguage('English'); Navigator.pop(context); }),
          ListTile(title: const Text('Kiswahili (Kenya Localized)'), onTap: () { settings.setLanguage('Kiswahili'); Navigator.pop(context); }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showEditNameDialog(AuthenticationService auth) {
    final ctrl = TextEditingController(text: auth.currentUserName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Identity'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Full Display Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () async { await auth.updateName(ctrl.text); Navigator.pop(context); }, child: const Text('SAVE')),
        ],
      ),
    );
  }

  void _showPasswordDialog(AuthenticationService auth) {
    final oldP = TextEditingController();
    final newP = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Key Update'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldP, obscureText: true, decoration: const InputDecoration(labelText: 'Current Key')),
            TextField(controller: newP, obscureText: true, decoration: const InputDecoration(labelText: 'New Secret Key')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () async { await auth.changePassword(oldP.text, newP.text); Navigator.pop(context); }, child: const Text('UPDATE')),
        ],
      ),
    );
  }

  void _showClearCacheDialog(AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purge System Cache?'),
        content: const Text('This will reset your UI preferences. Cloud data remains untouched.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () async { await settings.clearCache(); Navigator.pop(context); }, child: const Text('PURGE')),
        ],
      ),
    );
  }

  void _showFactoryResetDialog(AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('TOTAL FACTORY RESET?'),
        content: const Text('Warning: This wipes all local session data. You will be logged out.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async { 
              await settings.factoryReset(); 
              Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false); 
            }, 
            child: const Text('RESET SYSTEM', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(AuthenticationService auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Terminate the current encrypted session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('STAY')),
          ElevatedButton(
            onPressed: () { 
              auth.logout(); 
              Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false); 
            }, 
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );
  }
}
