import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
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
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // RESPONSIVE ENGINE:
    double maxWidth = screenWidth > 1000 ? 800 : (screenWidth > 600 ? 600 : screenWidth);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(theme, gemini),
      body: gemini?.buildCreativeBackground(
        isDark: isDark,
        maxWidth: maxWidth, // CENTERED AND CONSTRAINED FOR DESKTOP
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth > 600 ? 40 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(theme, auth, gemini, isDark),
                    const SizedBox(height: 40),
                    
                    _buildSectionHeader('SYSTEM INFRASTRUCTURE'),
                    _buildSettingsGroup(theme, gemini, isDark, [
                      _buildUpdateTile(theme, updates, gemini, isDark),
                      _buildActionTile(
                        theme, isDark,
                        'Purge Local Cache',
                        'Optimize performance & reset UI',
                        Icons.cleaning_services_rounded,
                        const Color(0xFF00B0FF),
                        () => _showClearCacheDialog(settings),
                      ),
                    ]),
                    const SizedBox(height: 32),

                    _buildSectionHeader('USER PREFERENCES'),
                    _buildSettingsGroup(theme, gemini, isDark, [
                      _buildToggleTile(
                        theme, isDark,
                        'Neural Notifications',
                        'Real-time cloud alerts',
                        Icons.notifications_active_rounded,
                        const Color(0xFFFFAB40),
                        settings.notificationsEnabled,
                        (v) => settings.setNotifications(v),
                      ),
                      _buildActionTile(
                        theme, isDark,
                        'Interface Theme',
                        settings.themeMode == ThemeMode.dark ? 'Dark Mode Active' : 'Light Mode Active',
                        Icons.palette_rounded,
                        const Color(0xFF7C4DFF),
                        () => _showAppearanceDialog(settings),
                      ),
                      _buildActionTile(
                        theme, isDark,
                        'Language Node',
                        settings.language,
                        Icons.translate_rounded,
                        const Color(0xFF00E676),
                        () => _showLanguageDialog(settings),
                      ),
                    ]),
                    const SizedBox(height: 32),

                    _buildSectionHeader('SECURITY PROTOCOLS'),
                    _buildSettingsGroup(theme, gemini, isDark, [
                      _buildActionTile(
                        theme, isDark,
                        'Identity Sync',
                        auth.currentUserName.toUpperCase(),
                        Icons.badge_rounded,
                        const Color(0xFF2979FF),
                        () => _showEditNameDialog(auth),
                      ),
                      _buildActionTile(
                        theme, isDark,
                        'Access Credentials',
                        'Modify your encrypted password',
                        Icons.lock_person_rounded,
                        const Color(0xFFFF3D00),
                        () => _showPasswordDialog(auth),
                      ),
                    ]),
                    const SizedBox(height: 32),

                    _buildSectionHeader('DANGER ZONE'),
                    _buildSettingsGroup(theme, gemini, isDark, [
                      _buildActionTile(
                        theme, isDark,
                        'System Factory Reset',
                        'Wipe all local session data',
                        Icons.auto_delete_rounded,
                        const Color(0xFFD50000),
                        () => _showFactoryResetDialog(settings),
                      ),
                    ]),

                    const SizedBox(height: 48),
                    _buildLogoutButton(theme, auth, gemini, isDark),
                    const SizedBox(height: 32),
                    _buildAppInfo(settings, isDark),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ) ?? const SizedBox(),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, GeminiThemeExtension? gemini) {
    return AppBar(
      title: const Text('CONTROL CENTER', 
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 4, color: Colors.white, shadows: [Shadow(color: Colors.black45, blurRadius: 10)])
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(decoration: BoxDecoration(gradient: gemini?.primaryGradient)),
            Positioned(
              right: -20, top: -10,
              child: Icon(Icons.settings_suggest_rounded, size: 140, color: Colors.white.withOpacity(0.12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, AuthenticationService auth, GeminiThemeExtension? gemini, bool isDark) {
    final profileContent = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: theme.primaryColor, width: 2.5)),
          child: CircleAvatar(
            radius: 32,
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            child: Text(auth.currentUserName.isNotEmpty ? auth.currentUserName[0].toUpperCase() : '?', 
              style: TextStyle(fontSize: 26, color: theme.primaryColor, fontWeight: FontWeight.w900)
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(auth.currentUserName.toUpperCase(), 
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : const Color(0xFF1E293B))
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(widget.role.toUpperCase(), 
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: theme.primaryColor, letterSpacing: 2)
                ),
              ),
              const SizedBox(height: 6),
              Text(auth.currentUserPhone ?? 'NODE VERIFIED', 
                style: TextStyle(fontSize: 10, color: isDark ? Colors.white24 : const Color(0xFF64748B), fontWeight: FontWeight.w900, letterSpacing: 1)
              ),
            ],
          ),
        ),
      ],
    );

    return gemini?.buildGlowContainer(
      borderRadius: 30,
      borderThickness: 2,
      backgroundColor: isDark ? const Color(0xF21A1C22) : Colors.white,
      padding: const EdgeInsets.all(24),
      useAIBorder: true,
      child: profileContent,
    ) ?? Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xF21A1C22) : Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: profileContent,
    );
  }

  Widget _buildUpdateTile(ThemeData theme, UpdateService updates, GeminiThemeExtension? gemini, bool isDark) {
    return ListenableBuilder(
      listenable: updates,
      builder: (context, _) {
        bool hasUpdate = updates.isUpdateAvailable;
        final color = hasUpdate ? const Color(0xFF2979FF) : const Color(0xFF00E676);
        
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(hasUpdate ? Icons.system_update_rounded : Icons.verified_user_rounded, color: color, size: 22),
          ),
          title: Text(hasUpdate ? 'System Upgrade Available' : 'Infrastructure Synced', 
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1E293B))
          ),
          subtitle: Text(hasUpdate ? 'Patch V${updates.remoteVersion} Ready' : 'System running V${updates.currentVersion}', 
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : const Color(0xFF64748B), letterSpacing: 0.5)
          ),
          trailing: hasUpdate ? Container(
            decoration: BoxDecoration(
              gradient: gemini?.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton(
              onPressed: () => updates.showUpdatePortal(context), 
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('SYNC', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10))
            ),
          ) : null,
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Container(width: 4, height: 12, decoration: BoxDecoration(color: const Color(0xFF475569), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF334155), letterSpacing: 3)),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(ThemeData theme, GeminiThemeExtension? gemini, bool isDark, List<Widget> tiles) {
    final content = Column(children: tiles);
    return gemini?.buildGlowContainer(
      borderRadius: 28,
      borderThickness: 1.2,
      backgroundColor: isDark ? const Color(0xF21A1C22) : Colors.white,
      padding: EdgeInsets.zero,
      child: content,
    ) ?? Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xF21A1C22) : Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: content,
    );
  }

  Widget _buildActionTile(ThemeData theme, bool isDark, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1E293B))),
      subtitle: Text(sub, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : const Color(0xFF64748B))),
      trailing: Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
      onTap: onTap,
    );
  }

  Widget _buildToggleTile(ThemeData theme, bool isDark, String title, String sub, IconData icon, Color color, bool val, Function(bool) onChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1E293B))),
      subtitle: Text(sub, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : const Color(0xFF64748B))),
      trailing: Switch.adaptive(value: val, activeColor: theme.primaryColor, onChanged: onChanged),
    );
  }

  Widget _buildLogoutButton(ThemeData theme, AuthenticationService auth, GeminiThemeExtension? gemini, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _confirmLogout(auth),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFFFF3D00).withOpacity(0.05),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFFF3D00).withOpacity(0.2)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.power_settings_new_rounded, color: Color(0xFFFF3D00), size: 22),
              SizedBox(width: 12),
              Text('TERMINATE SESSION', style: TextStyle(color: Color(0xFFFF3D00), fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfo(AppSettings settings, bool isDark) {
    return Center(
      child: Column(
        children: [
          Text('KAGEMA INTELLIGENT SYSTEMS', 
            style: TextStyle(fontSize: 8, color: isDark ? Colors.white12 : Colors.black12, fontWeight: FontWeight.w900, letterSpacing: 2)
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(6)),
            child: Text('CORE v${settings.appVersion} [ENCRYPTED]', 
              style: TextStyle(fontSize: 8, color: isDark ? Colors.white24 : Colors.black26, fontWeight: FontWeight.bold, letterSpacing: 1)
            ),
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
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(32), 
              child: Text('ENVIRONMENT MODE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3))
            ),
            ListTile(
              leading: const Icon(Icons.wb_sunny_rounded, color: Color(0xFFFFD600)),
              title: const Text('CRYSTAL LIGHT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              onTap: () { settings.setThemeMode(ThemeMode.light); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.nightlight_round, color: Color(0xFF7C4DFF)),
              title: const Text('OLED DARK', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              onTap: () { settings.setThemeMode(ThemeMode.dark); Navigator.pop(context); },
            ),
            const SizedBox(height: 40),
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
              padding: EdgeInsets.all(32), 
              child: Text('LANGUAGE NODE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3))
            ),
            ListTile(title: const Text('ENGLISH (GLOBAL)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)), onTap: () { settings.setLanguage('English'); Navigator.pop(context); }),
            ListTile(title: const Text('KISWAHILI (REGIONAL)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)), onTap: () { settings.setLanguage('Kiswahili'); Navigator.pop(context); }),
            const SizedBox(height: 40),
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
        title: const Text('IDENTITY SYNC', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        content: TextField(
          controller: ctrl, 
          decoration: const InputDecoration(labelText: 'Display Name', border: OutlineInputBorder()),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ABORT')),
          ElevatedButton(onPressed: () async { await auth.updateName(ctrl.text); Navigator.pop(context); }, child: const Text('SYNC')),
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
        title: const Text('ACCESS KEY SYNC', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldP, obscureText: true, decoration: const InputDecoration(labelText: 'Current Secret')),
            const SizedBox(height: 16),
            TextField(controller: newP, obscureText: true, decoration: const InputDecoration(labelText: 'New Secret')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ABORT')),
          ElevatedButton(onPressed: () async { await auth.changePassword(oldP.text, newP.text); Navigator.pop(context); }, child: const Text('APPLY')),
        ],
      ),
    );
  }

  void _showClearCacheDialog(AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('PURGE CACHE?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Optimize system performance by clearing temporary UI states.'),
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
        title: const Text('CRITICAL WIPE?', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFF3D00))),
        content: const Text('This will erase all local session data and disconnect this node from the system.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ABORT')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3D00)),
            onPressed: () async { 
              await settings.factoryReset(); 
              Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false); 
            }, 
            child: const Text('EXECUTE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
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
        title: const Text('LOGOUT?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('End the current secure session?'),
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
