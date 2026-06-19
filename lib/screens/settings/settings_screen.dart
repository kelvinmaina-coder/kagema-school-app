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

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _cyberRotationController;

  @override
  void initState() {
    super.initState();
    _cyberRotationController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _cyberRotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final isDark = context.isDark;
    final settings = Provider.of<AppSettings>(context);
    final auth = Provider.of<AuthenticationService>(context);
    final updates = Provider.of<UpdateService>(context);
    final roleColor = RoleColors.of(widget.role);
    final compColor = RoleColors.complement(widget.role);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: _buildAppBar(theme, roleColor, isDark),
      body: theme?.buildCreativeBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.fluid(20, 40)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(dt, auth, theme, roleColor),
                    const SizedBox(height: 40),

                    _buildSectionHeader('SYSTEM INFRASTRUCTURE', dt, roleColor),
                    _buildSettingsGroup(dt, theme, roleColor, [
                      _buildUpdateTile(dt, updates, theme, roleColor),
                      _buildActionTile(
                        dt,
                        'Purge Local Cache',
                        'Optimize performance & reset UI',
                        Icons.cleaning_services_rounded,
                        KagemaColors.staffSky,
                            () => _showClearCacheDialog(settings),
                        roleColor,
                      ),
                    ]),
                    const SizedBox(height: 32),

                    _buildSectionHeader('USER PREFERENCES', dt, roleColor),
                    _buildSettingsGroup(dt, theme, roleColor, [
                      _buildToggleTile(
                        dt,
                        'Neural Notifications',
                        'Real-time cloud alerts',
                        Icons.notifications_active_rounded,
                        KagemaColors.accountantAmber,
                        settings.notificationsEnabled,
                            (v) => settings.setNotifications(v),
                        roleColor,
                      ),
                      _buildActionTile(
                        dt,
                        'Interface Theme',
                        settings.themeMode == ThemeMode.dark ? 'Dark Mode Active' : 'Light Mode Active',
                        Icons.palette_rounded,
                        KagemaColors.secretaryViolet,
                            () => _showAppearanceDialog(settings),
                        roleColor,
                      ),
                      _buildActionTile(
                        dt,
                        'Language Node',
                        settings.language,
                        Icons.translate_rounded,
                        KagemaColors.teacherGreen,
                            () => _showLanguageDialog(settings),
                        roleColor,
                      ),
                    ]),
                    const SizedBox(height: 32),

                    _buildSectionHeader('SECURITY PROTOCOLS', dt, roleColor),
                    _buildSettingsGroup(dt, theme, roleColor, [
                      _buildActionTile(
                        dt,
                        'Identity Sync',
                        auth.currentUserName.toUpperCase(),
                        Icons.badge_rounded,
                        KagemaColors.azure,
                            () => _showEditNameDialog(auth),
                        roleColor,
                      ),
                      _buildActionTile(
                        dt,
                        'Access Credentials',
                        'Modify your encrypted password',
                        Icons.lock_person_rounded,
                        KagemaColors.parentRed,
                            () => _showPasswordDialog(auth),
                        roleColor,
                      ),
                    ]),
                    const SizedBox(height: 32),

                    _buildSectionHeader('DANGER ZONE', dt, roleColor),
                    _buildSettingsGroup(dt, theme, roleColor, [
                      _buildActionTile(
                        dt,
                        'System Factory Reset',
                        'Wipe all local session data',
                        Icons.auto_delete_rounded,
                        KagemaColors.parentRed,
                            () => _showFactoryResetDialog(settings),
                        roleColor,
                      ),
                    ]),

                    const SizedBox(height: 48),
                    _buildLogoutButton(dt, auth),
                    const SizedBox(height: 32),
                    _buildAppInfo(settings, dt),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  PreferredSizeWidget _buildAppBar(GeminiThemeExtension? theme, Color roleColor, bool isDark) {
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
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: theme?.primaryGradient,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -20, top: -10,
              child: Icon(Icons.settings_suggest_rounded, size: 140, color: Colors.white.withValues(alpha: 0.12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(DT dt, AuthenticationService auth, GeminiThemeExtension? theme, Color roleColor) {
    final Color textColor = dt.dark ? Colors.white : dt.textPrimary;
    final Color subTextColor = dt.dark ? Colors.white.withValues(alpha: 0.6) : dt.textMuted;

    String nodeId = 'SYS-04B';
    try {
      dynamic dynamicAuth = auth;
      String? parsedId = dynamicAuth.userId ?? dynamicAuth.uid;
      if (parsedId != null && parsedId.isNotEmpty) {
        nodeId = parsedId.substring(0, parsedId.length > 8 ? 8 : parsedId.length).toUpperCase();
      }
    } catch (_) {}

    return theme?.buildGlowContainer(
      accentColor: roleColor,
      borderRadius: 30,
      padding: EdgeInsets.zero,
      useAIBorder: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          splashColor: roleColor.withValues(alpha: 0.15),
          highlightColor: roleColor.withValues(alpha: 0.05),
          onTap: () => _showProfileDetailsSheet(dt, auth, roleColor, nodeId),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: dt.dark ? Colors.transparent : dt.cardBg.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        RotationTransition(
                          turns: _cyberRotationController,
                          child: Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: roleColor.withValues(alpha: 0.35),
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                            ),
                          ),
                        ),
                        RolePlasma(
                          color: roleColor,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: roleColor.withValues(alpha: 0.6), width: 2.5),
                            ),
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: roleColor.withValues(alpha: 0.18),
                              child: Text(
                                  auth.currentUserName.isNotEmpty ? auth.currentUserName[0].toUpperCase() : '?',
                                  style: TextStyle(fontSize: 26, color: roleColor, fontWeight: FontWeight.w900)
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                    auth.currentUserName.toUpperCase(),
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor, letterSpacing: 0.5)
                                ),
                              ),
                              Icon(Icons.expand_more_rounded, size: 18, color: roleColor.withValues(alpha: 0.7)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: roleColor.withValues(alpha: 0.25), width: 0.8)
                            ),
                            child: Text(
                                widget.role.toUpperCase(),
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: roleColor, letterSpacing: 2)
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                              auth.currentUserPhone ?? 'NODE VERIFIED',
                              style: TextStyle(fontSize: 10, color: subTextColor, fontWeight: FontWeight.w900, letterSpacing: 1)
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: dt.dark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: roleColor.withValues(alpha: 0.1), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDatabaseMetaItem(Icons.dns_rounded, 'NODE ID', nodeId, roleColor, dt),
                      Container(width: 1, height: 24, color: roleColor.withValues(alpha: 0.15)),
                      _buildDatabaseMetaItem(Icons.security_rounded, 'CLEARANCE', 'LEVEL ${widget.role == 'ADMIN' ? '5' : '2'}', roleColor, dt),
                      Container(width: 1, height: 24, color: roleColor.withValues(alpha: 0.15)),
                      _buildDatabaseMetaItem(Icons.cloud_done_rounded, 'STATUS', 'CONNECTED', roleColor, dt),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ) ?? const SizedBox.shrink();
  }

  void _showProfileDetailsSheet(DT dt, AuthenticationService auth, Color roleColor, String nodeId) {
    String userEmail = 'NOT DETECTED';
    try {
      dynamic dynamicAuth = auth;
      userEmail = dynamicAuth.currentUserEmail ?? dynamicAuth.email ?? 'node_admin@kagema.io';
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
              color: dt.pageBg.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
              border: Border.all(color: roleColor.withValues(alpha: 0.2), width: 1.5),
              boxShadow: [
                BoxShadow(color: roleColor.withValues(alpha: 0.15), blurRadius: 30, spreadRadius: 5)
              ]
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50, height: 5,
                decoration: BoxDecoration(color: dt.textMuted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2.5)),
              ),
              const SizedBox(height: 24),
              Text(
                'PROFILE OVERVIEW',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: roleColor, letterSpacing: 4),
              ),
              const SizedBox(height: 24),

              _buildProfileDetailRow(Icons.face_rounded, 'Name', auth.currentUserName.toUpperCase(), dt, roleColor),
              _buildProfileDetailRow(Icons.alternate_email_rounded, 'Email', userEmail, dt, roleColor),
              _buildProfileDetailRow(Icons.phone_android_rounded, 'Phone', auth.currentUserPhone ?? 'NO RECORDED PHONE', dt, roleColor),
              _buildProfileDetailRow(Icons.gavel_rounded, 'Role', widget.role.toUpperCase(), dt, roleColor),
              _buildProfileDetailRow(Icons.offline_bolt_rounded, 'Status', 'ACTIVE', dt, KagemaColors.teacherGreen, isStatus: true),

              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: roleColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('DISMISS NODE PROFILE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String label, String value, DT dt, Color roleColor, {bool isStatus = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: dt.cardBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dt.dark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: roleColor, size: 18),
          ),
          const SizedBox(width: 16),
          Text(
            '$label:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 0.5),
          ),
          const Spacer(),
          isStatus
              ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: roleColor, letterSpacing: 1)),
          )
              : Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: dt.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseMetaItem(IconData icon, String label, String value, Color roleColor, DT dt) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: roleColor),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.dark ? Colors.white : dt.textPrimary)),
      ],
    );
  }

  Widget _buildUpdateTile(DT dt, UpdateService updates, GeminiThemeExtension? theme, Color roleColor) {
    return ListenableBuilder(
      listenable: updates,
      builder: (context, _) {
        bool hasUpdate = updates.isUpdateAvailable;
        final color = hasUpdate ? KagemaColors.azure : KagemaColors.teacherGreen;

        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: roleColor.withValues(alpha: 0.08),
                width: 1.0,
              ),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: dt.roleSoftBg(color), shape: BoxShape.circle),
              child: Icon(hasUpdate ? Icons.system_update_rounded : Icons.verified_user_rounded, color: color, size: 22),
            ),
            title: Text(hasUpdate ? 'System Upgrade Available' : 'Infrastructure Synced',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary)
            ),
            subtitle: Text(hasUpdate ? 'Patch V${updates.remoteVersion} Ready' : 'System running V${updates.currentVersion}',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 0.5)
            ),
            trailing: hasUpdate ? Container(
              decoration: BoxDecoration(
                gradient: theme?.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                  onPressed: () => updates.showUpdatePortal(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('SYNC', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10))
              ),
            ) : null,
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, DT dt, Color roleColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Container(width: 4, height: 12, decoration: BoxDecoration(color: roleColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textSecondary, letterSpacing: 3)),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(DT dt, GeminiThemeExtension? theme, Color roleColor, List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: dt.cardBg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: roleColor.withValues(alpha: 0.22),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: roleColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: dt.dark ? 0.2 : 0.04),
            blurRadius: 15,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Column(
          children: tiles,
        ),
      ),
    );
  }

  Widget _buildActionTile(DT dt, String title, String sub, IconData icon, Color color, VoidCallback onTap, Color roleColor) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: roleColor.withValues(alpha: 0.08),
            width: 1.0,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: dt.roleSoftBg(color), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary)),
        subtitle: Text(sub, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted)),
        trailing: Icon(Icons.chevron_right_rounded, size: 20, color: dt.iconInactive),
        onTap: onTap,
      ),
    );
  }

  Widget _buildToggleTile(DT dt, String title, String sub, IconData icon, Color color, bool val, Function(bool) onChanged, Color roleColor) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: roleColor.withValues(alpha: 0.08),
            width: 1.0,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: dt.roleSoftBg(color), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary)),
        subtitle: Text(sub, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted)),
        trailing: Switch.adaptive(value: val, activeColor: roleColor, onChanged: onChanged),
      ),
    );
  }

  Widget _buildLogoutButton(DT dt, AuthenticationService auth) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _confirmLogout(auth, dt),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: KagemaColors.parentRed.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: KagemaColors.parentRed.withValues(alpha: 0.2)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.power_settings_new_rounded, color: KagemaColors.parentRed, size: 22),
              SizedBox(width: 12),
              Text('TERMINATE SESSION', style: TextStyle(color: KagemaColors.parentRed, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfo(AppSettings settings, DT dt) {
    return Center(
      child: Column(
        children: [
          Text('KAGEMA INTELLIGENT SYSTEMS',
              style: TextStyle(fontSize: 8, color: dt.textMuted.withValues(alpha: 0.5), fontWeight: FontWeight.w900, letterSpacing: 2)
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: dt.roleSoftBg(dt.textMuted), borderRadius: BorderRadius.circular(6)),
            child: Text('CORE v${settings.appVersion} [ENCRYPTED]',
                style: TextStyle(fontSize: 8, color: dt.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)
            ),
          ),
        ],
      ),
    );
  }

  void _showAppearanceDialog(AppSettings settings) {
    final dt = context.dt;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: dt.pageBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
          border: Border.all(color: dt.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
                padding: EdgeInsets.all(32),
                child: Text('ENVIRONMENT MODE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3))
            ),
            ListTile(
              leading: const Icon(Icons.wb_sunny_rounded, color: KagemaColors.accountantAmber),
              title: const Text('CRYSTAL LIGHT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              onTap: () { settings.setThemeMode(ThemeMode.light); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.nightlight_round, color: KagemaColors.secretaryViolet),
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
    final dt = context.dt;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: dt.pageBg,
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
    final dt = context.dt;
    final ctrl = TextEditingController(text: auth.currentUserName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dt.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('IDENTITY SYNC', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, color: dt.textPrimary)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Display Name'),
          style: TextStyle(fontWeight: FontWeight.w900, color: dt.textPrimary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('ABORT', style: TextStyle(color: dt.textMuted))),
          ElevatedButton(onPressed: () async { await auth.updateName(ctrl.text); Navigator.pop(context); }, child: const Text('SYNC')),
        ],
      ),
    );
  }

  void _showPasswordDialog(AuthenticationService auth) {
    final dt = context.dt;
    final oldP = TextEditingController();
    final newP = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dt.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('ACCESS KEY SYNC', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldP, obscureText: true, decoration: const InputDecoration(labelText: 'Current Secret')),
            const SizedBox(height: 16),
            TextField(controller: newP, obscureText: true, decoration: const InputDecoration(labelText: 'New Secret')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('ABORT', style: TextStyle(color: dt.textMuted))),
          ElevatedButton(onPressed: () async { await auth.changePassword(oldP.text, newP.text); Navigator.pop(context); }, child: const Text('APPLY')),
        ],
      ),
    );
  }

  void _showClearCacheDialog(AppSettings settings) {
    final dt = context.dt;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dt.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('PURGE CACHE?', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textPrimary)),
        content: Text('Optimize system performance by clearing temporary UI states.', style: TextStyle(color: dt.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('STAY', style: TextStyle(color: dt.textMuted))),
          ElevatedButton(onPressed: () async { await settings.clearCache(); Navigator.pop(context); }, child: const Text('PURGE')),
        ],
      ),
    );
  }

  void _showFactoryResetDialog(AppSettings settings) {
    final dt = context.dt;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dt.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('CRITICAL WIPE?', style: TextStyle(fontWeight: FontWeight.w900, color: KagemaColors.parentRed)),
        content: Text('This will erase all local session data and disconnect this node from the system.', style: TextStyle(color: dt.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('ABORT', style: TextStyle(color: dt.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: KagemaColors.parentRed),
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

  void _confirmLogout(AuthenticationService auth, DT dt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dt.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('LOGOUT?', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textPrimary)),
        content: Text('End the current secure session?', style: TextStyle(color: dt.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('STAY', style: TextStyle(color: dt.textMuted))),
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