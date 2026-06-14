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
      appBar: _buildAppBar(theme, gemini),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(theme, auth, gemini),
                    const SizedBox(height: 32),
                    
                    _buildSectionHeader('SYSTEM INFRASTRUCTURE'),
                    _buildSettingsGroup(theme, gemini, [
                      _buildUpdateTile(theme, updates, gemini),
                      _buildActionTile(
                        theme,
                        'Purge System Cache',
                        'Clear UI state and temporary data',
                        Icons.cleaning_services_rounded,
                        Colors.blueGrey,
                        () => _showClearCacheDialog(settings),
                      ),
                    ]),
                    const SizedBox(height: 32),

                    _buildSectionHeader('ENVIRONMENT PREFERENCES'),
                    _buildSettingsGroup(theme, gemini, [
                      _buildToggleTile(
                        theme,
                        'Intelligence Alerts',
                        'Real-time cloud notifications',
                        Icons.notifications_active_rounded,
                        Colors.orange,
                        settings.notificationsEnabled,
                        (v) => settings.setNotifications(v),
                      ),
                      _buildActionTile(
                        theme,
                        'Appearance Mode',
                        settings.themeMode == ThemeMode.dark ? 'Neural Dark' : 'Neural Light',
                        Icons.palette_rounded,
                        Colors.blue,
                        () => _showAppearanceDialog(settings),
                      ),
                      _buildActionTile(
                        theme,
                        'System Language',
                        settings.language,
                        Icons.translate_rounded,
                        Colors.teal,
                        () => _showLanguageDialog(settings),
                      ),
                    ]),
                    const SizedBox(height: 32),

                    _buildSectionHeader('SECURITY PROTOCOLS'),
                    _buildSettingsGroup(theme, gemini, [
                      _buildActionTile(
                        theme,
                        'Update Identity',
                        auth.currentUserName,
                        Icons.badge_rounded,
                        Colors.green,
                        () => _showEditNameDialog(auth),
                      ),
                      _buildActionTile(
                        theme,
                        'Encrypted Password',
                        'Update your neural access key',
                        Icons.lock_person_rounded,
                        Colors.redAccent,
                        () => _showPasswordDialog(auth),
                      ),
                    ]),
                    const SizedBox(height: 32),

                    _buildSectionHeader('CORE RECOVERY'),
                    _buildSettingsGroup(theme, gemini, [
                      _buildActionTile(
                        theme,
                        'Factory Data Reset',
                        'Wipe all local session metadata',
                        Icons.auto_delete_rounded,
                        Colors.red,
                        () => _showFactoryResetDialog(settings),
                      ),
                    ]),

                    const SizedBox(height: 48),
                    _buildLogoutButton(theme, auth, gemini),
                    const SizedBox(height: 32),
                    _buildAppInfo(settings),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, GeminiThemeExtension? gemini) {
    return AppBar(
      title: const Text('CONTROL CENTER', 
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2, color: Colors.white)
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.primaryColor, Colors.indigo.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20, top: -10,
              child: Icon(Icons.settings_suggest_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, AuthenticationService auth, GeminiThemeExtension? gemini) {
    final content = Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: theme.primaryColor.withOpacity(0.1),
          child: Text(auth.currentUserName[0].toUpperCase(), 
            style: TextStyle(fontSize: 28, color: theme.primaryColor, fontWeight: FontWeight.w900)
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(auth.currentUserName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 4),
              Text(widget.role.toUpperCase(), 
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.primaryColor, letterSpacing: 2)
              ),
              Text(auth.currentUserPhone ?? 'CLOUD IDENTITY VERIFIED', 
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)
              ),
            ],
          ),
        ),
      ],
    );

    return gemini?.buildGlowContainer(
      borderRadius: 28,
      borderThickness: 2,
      backgroundColor: theme.cardColor.withOpacity(0.9),
      padding: const EdgeInsets.all(24),
      child: content,
    ) ?? Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(28)),
      child: content,
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
            decoration: BoxDecoration(color: (hasUpdate ? Colors.blue : Colors.green).withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(hasUpdate ? Icons.system_update_rounded : Icons.verified_user_rounded, color: hasUpdate ? Colors.blue : Colors.green, size: 20),
          ),
          title: Text(hasUpdate ? 'Upgrade Available' : 'System Synchronized', 
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)
          ),
          subtitle: Text(hasUpdate ? 'Intelligence Patch V${updates.remoteVersion} is ready' : 'Neural Core V${updates.currentVersion}', 
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)
          ),
          trailing: hasUpdate ? ElevatedButton(
            onPressed: () => updates.showUpdatePortal(context), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('SYNC', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10))
          ) : null,
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2.5)),
    );
  }

  Widget _buildSettingsGroup(ThemeData theme, GeminiThemeExtension? gemini, List<Widget> tiles) {
    return gemini?.buildGlowContainer(
      borderRadius: 30,
      borderThickness: 1,
      backgroundColor: theme.cardColor.withOpacity(0.85),
      padding: EdgeInsets.zero,
      child: Column(children: tiles),
    ) ?? Container(
      decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.9), borderRadius: BorderRadius.circular(28)),
      child: Column(children: tiles),
    );
  }

  Widget _buildActionTile(ThemeData theme, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildToggleTile(ThemeData theme, String title, String sub, IconData icon, Color color, bool val, Function(bool) onChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
      trailing: Switch.adaptive(value: val, activeColor: theme.primaryColor, onChanged: onChanged),
    );
  }

  Widget _buildLogoutButton(ThemeData theme, AuthenticationService auth, GeminiThemeExtension? gemini) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.power_settings_new_rounded, color: Colors.red, size: 20),
        const SizedBox(width: 12),
        const Text('TERMINATE NEURAL SESSION', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13)),
      ],
    );

    return InkWell(
      onTap: () => _confirmLogout(auth),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: content,
      ),
    );
  }

  Widget _buildAppInfo(AppSettings settings) {
    return Center(
      child: Column(
        children: [
          const Text('KAGEMA COMPREHENSIVE INTELLIGENCE SYSTEM', 
            style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 1.5)
          ),
          const SizedBox(height: 4),
          Text('QUANTUM CORE v${settings.appVersion}', 
            style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }

  void _showAppearanceDialog(AppSettings settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(24), 
              child: Text('Neural Environment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1))
            ),
            ListTile(
              leading: const Icon(Icons.wb_sunny_rounded, color: Colors.orange),
              title: const Text('Neural Light', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () { settings.setThemeMode(ThemeMode.light); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.nightlight_round, color: Colors.indigo),
              title: const Text('Neural Dark', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () { settings.setThemeMode(ThemeMode.dark); Navigator.pop(context); },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(AppSettings settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(24), 
              child: Text('Linguistic Matrix', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))
            ),
            ListTile(title: const Text('English (Global Standard)', style: TextStyle(fontWeight: FontWeight.bold)), onTap: () { settings.setLanguage('English'); Navigator.pop(context); }),
            ListTile(title: const Text('Kiswahili (Regional Adapt)', style: TextStyle(fontWeight: FontWeight.bold)), onTap: () { settings.setLanguage('Kiswahili'); Navigator.pop(context); }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(AuthenticationService auth) {
    final ctrl = TextEditingController(text: auth.currentUserName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Modify Identity', style: TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(
          controller: ctrl, 
          decoration: const InputDecoration(labelText: 'Full Display Name', border: OutlineInputBorder()),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () async { await auth.updateName(ctrl.text); Navigator.pop(context); }, child: const Text('UPDATE')),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Neural Key Update', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldP, obscureText: true, decoration: const InputDecoration(labelText: 'Current Secret Key')),
            const SizedBox(height: 16),
            TextField(controller: newP, obscureText: true, decoration: const InputDecoration(labelText: 'New Quantum Key')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () async { await auth.changePassword(oldP.text, newP.text); Navigator.pop(context); }, child: const Text('RE-ENCRYPT')),
        ],
      ),
    );
  }

  void _showClearCacheDialog(AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Purge System Cache?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('This will reset your local UI preferences. Neural cloud data remains secure.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('STAY')),
          ElevatedButton(onPressed: () async { await settings.clearCache(); Navigator.pop(context); }, child: const Text('PURGE')),
        ],
      ),
    );
  }

  void _showFactoryResetDialog(AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('TOTAL SYSTEM RESET?', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red)),
        content: const Text('Critical Warning: This wipes all local session metadata. You will be ejected from the neural net.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ABORT')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async { 
              await settings.factoryReset(); 
              Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false); 
            }, 
            child: const Text('EXECUTE WIPE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(AuthenticationService auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Logout Session?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Terminate the current encrypted handshake?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('STAY CONNECTED')),
          ElevatedButton(
            onPressed: () { 
              auth.logout(); 
              Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false); 
            }, 
            child: const Text('DISCONNECT'),
          ),
        ],
      ),
    );
  }
}
