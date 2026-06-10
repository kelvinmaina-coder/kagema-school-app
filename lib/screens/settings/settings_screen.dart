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
    final updates = UpdateService();
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
                    _buildProfileSection(theme, auth, gemini),
                    const SizedBox(height: 32),
                    
                    _buildSectionHeader(theme, 'SYSTEM UPGRADE'),
                    _buildSettingsGroup(theme, [
                      _buildUpdateTile(theme, updates, gemini),
                    ]),
                    const SizedBox(height: 32),

                    _buildSectionHeader(theme, 'PREFERENCES'),
                    _buildSettingsGroup(theme, [
                      _buildToggleTile(
                        theme,
                        'Intelligence Notifications',
                        'Sync with real-time school alerts',
                        Icons.notifications_active_outlined,
                        Colors.orange,
                        settings.notificationsEnabled,
                        (v) => settings.setNotifications(v),
                      ),
                      _buildActionTile(
                        theme,
                        'Theme Appearance',
                        settings.themeMode == ThemeMode.dark ? 'Dark Mode' : 'Light Mode',
                        Icons.palette_outlined,
                        Colors.blue,
                        () => _showAppearanceDialog(settings),
                      ),
                    ]),
                    const SizedBox(height: 32),

                    _buildSectionHeader(theme, 'SECURITY & ACCOUNT'),
                    _buildSettingsGroup(theme, [
                      _buildActionTile(
                        theme,
                        'Update Profile Name',
                        auth.currentUserName,
                        Icons.badge_outlined,
                        Colors.green,
                        () => _showEditNameDialog(auth),
                      ),
                      _buildActionTile(
                        theme,
                        'Change Security Password',
                        'Last updated 3 months ago',
                        Icons.lock_reset_rounded,
                        Colors.redAccent,
                        () => _showPasswordDialog(auth),
                      ),
                    ]),
                    const SizedBox(height: 40),
                    _buildLogoutButton(theme, auth),
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
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text('Intelligence Settings', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5, color: Colors.white)),
        background: Container(
          decoration: BoxDecoration(
            gradient: gemini?.primaryGradient ?? LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)]),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(ThemeData theme, AuthenticationService auth, GeminiThemeExtension? gemini) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            child: Text(
              auth.currentUserName[0].toUpperCase(),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.primaryColor),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auth.currentUserName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 4),
                Text(widget.role.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.primaryColor, letterSpacing: 1)),
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
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (hasUpdate ? Colors.blue : Colors.blueGrey).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(hasUpdate ? Icons.system_update_rounded : Icons.check_circle_outline, color: hasUpdate ? Colors.blue : Colors.blueGrey, size: 20),
          ),
          title: Text(hasUpdate ? 'Upgrade System' : 'System Version', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          subtitle: Text(hasUpdate ? 'V${updates.remoteVersion} is ready to install' : 'Kagema OS V${updates.currentVersion} (Stable)', style: const TextStyle(fontSize: 12)),
          trailing: updates.isChecking 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : hasUpdate 
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(gradient: gemini?.glowingBorderGradient, borderRadius: BorderRadius.circular(12)),
                  child: const Text('SYNC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                )
              : TextButton(
                  onPressed: () => updates.manualCheck(context),
                  child: const Text('CHECK', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
          onTap: hasUpdate ? () => updates.showUpdatePortal(context) : null,
        );
      },
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.primaryColor.withOpacity(0.5), letterSpacing: 2)),
    );
  }

  Widget _buildSettingsGroup(ThemeData theme, List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(children: tiles),
    );
  }

  Widget _buildActionTile(ThemeData theme, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildToggleTile(ThemeData theme, String title, String subtitle, IconData icon, Color color, bool value, Function(bool) onChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Switch.adaptive(value: value, activeColor: theme.primaryColor, onChanged: onChanged),
    );
  }

  Widget _buildLogoutButton(ThemeData theme, AuthenticationService auth) {
    return InkWell(
      onTap: () => _confirmLogout(auth),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.red.withOpacity(0.15))),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.power_settings_new_rounded, color: Colors.red, size: 20),
            const SizedBox(width: 12),
            Text('TERMINATE ACTIVE SESSION', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  void _showAppearanceDialog(AppSettings settings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Appearance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.wb_sunny_rounded, color: Colors.orange),
              title: const Text('Light Mode'),
              trailing: settings.themeMode == ThemeMode.light ? const Icon(Icons.check_circle, color: Colors.green) : null,
              onTap: () { settings.setThemeMode(ThemeMode.light); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.nightlight_round, color: Colors.indigo),
              title: const Text('Dark Mode'),
              trailing: settings.themeMode == ThemeMode.dark ? const Icon(Icons.check_circle, color: Colors.green) : null,
              onTap: () { settings.setThemeMode(ThemeMode.dark); Navigator.pop(context); },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(AuthenticationService auth) {
    final nameCtrl = TextEditingController(text: auth.currentUserName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Update Display Name', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isNotEmpty) {
                    await auth.updateName(nameCtrl.text);
                    Navigator.pop(context);
                  }
                },
                child: const Text('SAVE CHANGES'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showPasswordDialog(AuthenticationService auth) {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Security Update', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            TextField(controller: oldPass, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
            const SizedBox(height: 12),
            TextField(controller: newPass, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  final success = await auth.changePassword(oldPass.text, newPass.text);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Password updated!' : 'Wrong password'), backgroundColor: success ? Colors.green : Colors.red));
                },
                child: const Text('UPDATE PASSWORD'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(AuthenticationService auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () { auth.logout(); Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false); }, child: const Text('LOGOUT')),
        ],
      ),
    );
  }
}
