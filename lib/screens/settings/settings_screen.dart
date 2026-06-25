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

  double responsiveValue(double small, double medium, double large) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return small;
    if (width < 600) return medium;
    return large;
  }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final isDark = context.isDark;
    final settings = Provider.of<AppSettings>(context);
    final auth = Provider.of<AuthenticationService>(context);
    final updates = Provider.of<UpdateService>(context);

    // âœ… ROLE-BASED COLORS - Each role gets its own color
    final roleColor = RoleColors.of(widget.role);
    final compColor = RoleColors.complement(widget.role);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: _buildAppBar(theme, roleColor, isDark, isSmallScreen),
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
                padding: EdgeInsets.symmetric(horizontal: context.fluid(12, 40)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(dt, auth, theme, roleColor, isSmallScreen),
                    SizedBox(height: responsiveValue(24, 32, 40)),

                    _buildSectionHeader('SYSTEM INFRASTRUCTURE', dt, roleColor, isSmallScreen),
                    _buildSettingsGroup(dt, theme, roleColor, [
                      _buildUpdateTile(dt, updates, theme, roleColor, isSmallScreen),
                      _buildActionTile(
                        dt,
                        'Purge Local Cache',
                        'Optimize performance & reset UI',
                        Icons.cleaning_services_rounded,
                        KagemaColors.staffSky,
                            () => _showClearCacheDialog(settings),
                        roleColor,
                        isSmallScreen,
                      ),
                    ], isSmallScreen),
                    SizedBox(height: responsiveValue(20, 28, 32)),

                    _buildSectionHeader('USER PREFERENCES', dt, roleColor, isSmallScreen),
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
                        isSmallScreen,
                      ),
                      _buildActionTile(
                        dt,
                        'Interface Theme',
                        settings.themeMode == ThemeMode.dark ? 'Dark Mode Active' : 'Light Mode Active',
                        Icons.palette_rounded,
                        KagemaColors.secretaryViolet,
                            () => _showAppearanceDialog(settings),
                        roleColor,
                        isSmallScreen,
                      ),
                      _buildActionTile(
                        dt,
                        'Language Node',
                        settings.language,
                        Icons.translate_rounded,
                        KagemaColors.teacherGreen,
                            () => _showLanguageDialog(settings),
                        roleColor,
                        isSmallScreen,
                      ),
                    ], isSmallScreen),
                    SizedBox(height: responsiveValue(20, 28, 32)),

                    _buildSectionHeader('SECURITY PROTOCOLS', dt, roleColor, isSmallScreen),
                    _buildSettingsGroup(dt, theme, roleColor, [
                      _buildActionTile(
                        dt,
                        'Identity Sync',
                        auth.currentUserName.toUpperCase(),
                        Icons.badge_rounded,
                        KagemaColors.azure,
                            () => _showEditNameDialog(auth),
                        roleColor,
                        isSmallScreen,
                      ),
                      _buildActionTile(
                        dt,
                        'Access Credentials',
                        'Modify your encrypted password',
                        Icons.lock_person_rounded,
                        KagemaColors.parentRed,
                            () => _showPasswordDialog(auth),
                        roleColor,
                        isSmallScreen,
                      ),
                    ], isSmallScreen),
                    SizedBox(height: responsiveValue(20, 28, 32)),

                    _buildSectionHeader('DANGER ZONE', dt, roleColor, isSmallScreen),
                    _buildSettingsGroup(dt, theme, roleColor, [
                      _buildActionTile(
                        dt,
                        'System Factory Reset',
                        'Wipe all local session data',
                        Icons.auto_delete_rounded,
                        KagemaColors.parentRed,
                            () => _showFactoryResetDialog(settings),
                        roleColor,
                        isSmallScreen,
                      ),
                    ], isSmallScreen),

                    SizedBox(height: responsiveValue(32, 40, 48)),
                    _buildLogoutButton(dt, auth, isSmallScreen, roleColor),
                    SizedBox(height: responsiveValue(20, 28, 32)),
                    _buildAppInfo(settings, dt, isSmallScreen, roleColor),
                    SizedBox(height: responsiveValue(60, 80, 120)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  // âœ… UPDATED: AppBar with role color
  PreferredSizeWidget _buildAppBar(GeminiThemeExtension? theme, Color roleColor, bool isDark, bool isSmallScreen) {
    return AppBar(
      title: Text(
          isSmallScreen ? 'CTRL CTR' : 'CONTROL CENTER',
          style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: isSmallScreen ? 12 : 16,
              letterSpacing: isSmallScreen ? 2 : 4,
              color: Colors.white,
              shadows: const [Shadow(color: Colors.black45, blurRadius: 10)]
          )
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
            colors: [roleColor, roleColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -20, top: -10,
              child: Icon(Icons.settings_suggest_rounded, size: isSmallScreen ? 80 : 140, color: Colors.white.withOpacity(0.12)),
            ),
          ],
        ),
      ),
    );
  }

  // âœ… UPDATED: Profile header with role color
  Widget _buildProfileHeader(DT dt, AuthenticationService auth, GeminiThemeExtension? theme, Color roleColor, bool isSmallScreen) {
    final Color textColor = dt.dark ? Colors.white : dt.textPrimary;
    final Color subTextColor = dt.dark ? Colors.white.withOpacity(0.6) : dt.textMuted;

    String nodeId = auth.currentUserId?.substring(0, 8).toUpperCase() ?? 'SYS-04B';

    final avatarSize = isSmallScreen ? 56.0 : 78.0;
    final paddingSize = isSmallScreen ? 16.0 : 24.0;

    return theme?.buildGlowContainer(
      accentColor: roleColor,
      borderRadius: 30,
      padding: EdgeInsets.zero,
      useAIBorder: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          splashColor: roleColor.withOpacity(0.15),
          highlightColor: roleColor.withOpacity(0.05),
          onTap: () => _showProfileDetailsSheet(dt, auth, roleColor, nodeId),
          child: Container(
            padding: EdgeInsets.all(paddingSize),
            decoration: BoxDecoration(
              color: dt.dark ? Colors.transparent : dt.cardBg.withOpacity(0.4),
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
                            width: avatarSize + 8,
                            height: avatarSize + 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: roleColor.withOpacity(0.35),
                                width: isSmallScreen ? 1.5 : 2,
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
                              border: Border.all(color: roleColor.withOpacity(0.6), width: isSmallScreen ? 2 : 2.5),
                            ),
                            child: CircleAvatar(
                              radius: isSmallScreen ? 24 : 32,
                              backgroundColor: roleColor.withOpacity(0.18),
                              child: Text(
                                  auth.currentUserName.isNotEmpty ? auth.currentUserName[0].toUpperCase() : '?',
                                  style: TextStyle(
                                      fontSize: isSmallScreen ? 20 : 26,
                                      color: roleColor,
                                      fontWeight: FontWeight.w900
                                  )
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 20),
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
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: isSmallScreen ? 14 : 18,
                                      color: textColor,
                                      letterSpacing: 0.5
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.expand_more_rounded, size: isSmallScreen ? 14 : 18, color: roleColor.withOpacity(0.7)),
                            ],
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 6),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 10, vertical: isSmallScreen ? 2 : 4),
                            decoration: BoxDecoration(
                                color: roleColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: roleColor.withOpacity(0.25), width: 0.8)
                            ),
                            child: Text(
                                widget.role.toUpperCase(),
                                style: TextStyle(
                                    fontSize: isSmallScreen ? 7 : 9,
                                    fontWeight: FontWeight.w900,
                                    color: roleColor,
                                    letterSpacing: isSmallScreen ? 1 : 2
                                )
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 8),
                          Text(
                              auth.currentUserPhone ?? auth.currentUserEmail ?? 'NODE VERIFIED',
                              style: TextStyle(
                                  fontSize: isSmallScreen ? 8 : 10,
                                  color: subTextColor,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: isSmallScreen ? 0.5 : 1
                              )
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isSmallScreen ? 12 : 20),
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                  decoration: BoxDecoration(
                    color: dt.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: roleColor.withOpacity(0.1), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDatabaseMetaItem(Icons.dns_rounded, 'NODE ID', nodeId, roleColor, dt, isSmallScreen),
                      Container(width: 1, height: isSmallScreen ? 16 : 24, color: roleColor.withOpacity(0.15)),
                      _buildDatabaseMetaItem(Icons.security_rounded, 'CLEARANCE', 'LEVEL ${widget.role.toUpperCase() == 'ADMIN' ? '5' : '2'}', roleColor, dt, isSmallScreen),
                      Container(width: 1, height: isSmallScreen ? 16 : 24, color: roleColor.withOpacity(0.15)),
                      _buildDatabaseMetaItem(Icons.cloud_done_rounded, 'STATUS', auth.isOffline ? 'OFFLINE' : 'CONNECTED', roleColor, dt, isSmallScreen),
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

  // âœ… UPDATED: Profile details with role color
  void _showProfileDetailsSheet(DT dt, AuthenticationService auth, Color roleColor, String nodeId) {
    String userEmail = auth.currentUserEmail ?? 'node_admin@kagema.io';
    String userName = auth.currentUserName.isNotEmpty ? auth.currentUserName : 'AUTHORIZED USER';
    final isSmallScreen = MediaQuery.of(context).size.width < 400;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: dt.pageBg.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
            border: Border.all(color: roleColor.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(color: roleColor.withOpacity(0.15), blurRadius: 30, spreadRadius: 5),
            ],
          ),
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: dt.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),

              Container(
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                child: Row(
                  children: [
                    Container(
                      width: isSmallScreen ? 50 : 64,
                      height: isSmallScreen ? 50 : 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [roleColor, roleColor.withOpacity(0.6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: roleColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 22 : 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 14 : 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName.toUpperCase(),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 18,
                              fontWeight: FontWeight.w900,
                              color: dt.textPrimary,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: isSmallScreen ? 2 : 4),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 8 : 12,
                                  vertical: isSmallScreen ? 2 : 4,
                                ),
                                decoration: BoxDecoration(
                                  color: roleColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  widget.role.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 8 : 10,
                                    fontWeight: FontWeight.w800,
                                    color: roleColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 6 : 10),
                              Icon(
                                Icons.circle,
                                size: isSmallScreen ? 6 : 8,
                                color: auth.isOffline ? KagemaColors.parentRed : KagemaColors.teacherGreen,
                              ),
                              Text(
                                auth.isOffline ? 'OFFLINE' : 'ACTIVE',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 8 : 10,
                                  fontWeight: FontWeight.w700,
                                  color: auth.isOffline ? KagemaColors.parentRed : KagemaColors.teacherGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                height: 1,
                margin: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
                color: roleColor.withOpacity(0.08),
              ),

              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildProfileDetailRow(
                        Icons.face_rounded,
                        'Name',
                        userName.toUpperCase(),
                        dt,
                        roleColor,
                        isSmallScreen,
                      ),
                      _buildProfileDetailRow(
                        Icons.alternate_email_rounded,
                        'Email',
                        userEmail,
                        dt,
                        roleColor,
                        isSmallScreen,
                      ),
                      _buildProfileDetailRow(
                        Icons.phone_android_rounded,
                        'Phone',
                        auth.currentUserPhone ?? 'NO RECORDED PHONE',
                        dt,
                        roleColor,
                        isSmallScreen,
                      ),
                      _buildProfileDetailRow(
                        Icons.gavel_rounded,
                        'Role',
                        widget.role.toUpperCase(),
                        dt,
                        roleColor,
                        isSmallScreen,
                      ),
                      _buildProfileDetailRow(
                        Icons.offline_bolt_rounded,
                        'Status',
                        auth.isOffline ? 'OFFLINE' : 'ACTIVE',
                        dt,
                        KagemaColors.teacherGreen,
                        isSmallScreen,
                        isStatus: true,
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),
                    ],
                  ),
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(top: isSmallScreen ? 8 : 12),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: roleColor,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, isSmallScreen ? 44 : 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'DISMISS NODE PROFILE',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: isSmallScreen ? 1 : 1.5,
                        fontSize: isSmallScreen ? 11 : 13,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String label, String value, DT dt, Color roleColor, bool isSmallScreen, {bool isStatus = false}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 8),
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: isSmallScreen ? 10 : 14),
      decoration: BoxDecoration(
        color: dt.cardBg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dt.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            decoration: BoxDecoration(color: roleColor.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: roleColor, size: isSmallScreen ? 14 : 18),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Text(
            '$label:',
            style: TextStyle(
                fontSize: isSmallScreen ? 10 : 12,
                fontWeight: FontWeight.w900,
                color: dt.textMuted,
                letterSpacing: 0.5
            ),
          ),
          const Spacer(),
          isStatus
              ? Container(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 10, vertical: isSmallScreen ? 2 : 4),
            decoration: BoxDecoration(color: roleColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
            child: Text(
                value,
                style: TextStyle(
                    fontSize: isSmallScreen ? 9 : 11,
                    fontWeight: FontWeight.w900,
                    color: roleColor,
                    letterSpacing: 1
                )
            ),
          )
              : Text(
            value,
            style: TextStyle(
                fontSize: isSmallScreen ? 11 : 13,
                fontWeight: FontWeight.w900,
                color: dt.textPrimary
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseMetaItem(IconData icon, String label, String value, Color roleColor, DT dt, bool isSmallScreen) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: isSmallScreen ? 10 : 12, color: roleColor),
            SizedBox(width: isSmallScreen ? 2 : 4),
            Text(
                label,
                style: TextStyle(
                    fontSize: isSmallScreen ? 6 : 8,
                    fontWeight: FontWeight.w900,
                    color: dt.textMuted,
                    letterSpacing: 0.5
                )
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 1 : 2),
        Text(
            value,
            style: TextStyle(
                fontSize: isSmallScreen ? 8 : 10,
                fontWeight: FontWeight.w900,
                color: dt.dark ? Colors.white : dt.textPrimary
            )
        ),
      ],
    );
  }

  Widget _buildUpdateTile(DT dt, UpdateService updates, GeminiThemeExtension? theme, Color roleColor, bool isSmallScreen) {
    return ListenableBuilder(
      listenable: updates,
      builder: (context, _) {
        bool hasUpdate = updates.isUpdateAvailable;
        final color = hasUpdate ? KagemaColors.azure : KagemaColors.teacherGreen;

        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: roleColor.withOpacity(0.08),
                width: 1.0,
              ),
            ),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 20, vertical: isSmallScreen ? 4 : 8),
            leading: Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
              decoration: BoxDecoration(color: dt.roleSoftBg(color), shape: BoxShape.circle),
              child: Icon(hasUpdate ? Icons.system_update_rounded : Icons.verified_user_rounded, color: color, size: isSmallScreen ? 18 : 22),
            ),
            title: Text(
                hasUpdate ? 'System Upgrade Available' : 'Infrastructure Synced',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: isSmallScreen ? 12 : 14,
                    color: dt.textPrimary
                )
            ),
            subtitle: Text(
                hasUpdate ? 'Patch V${updates.remoteVersion} Ready' : 'System running V${updates.currentVersion}',
                style: TextStyle(
                    fontSize: isSmallScreen ? 8 : 10,
                    fontWeight: FontWeight.w900,
                    color: dt.textMuted,
                    letterSpacing: 0.5
                )
            ),
            trailing: hasUpdate ? Container(
              decoration: BoxDecoration(
                gradient: theme?.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                  onPressed: () => updates.showUpdatePortal(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12, vertical: isSmallScreen ? 4 : 8),
                  ),
                  child: Text(
                      'SYNC',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isSmallScreen ? 8 : 10
                      )
                  )
              ),
            ) : null,
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, DT dt, Color roleColor, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.only(left: 4, bottom: isSmallScreen ? 8 : 12),
      child: Row(
        children: [
          Container(width: 4, height: isSmallScreen ? 8 : 12, decoration: BoxDecoration(color: roleColor, borderRadius: BorderRadius.circular(2))),
          SizedBox(width: isSmallScreen ? 4 : 8),
          Text(
              title,
              style: TextStyle(
                  fontSize: isSmallScreen ? 8 : 10,
                  fontWeight: FontWeight.w900,
                  color: dt.textSecondary,
                  letterSpacing: isSmallScreen ? 2 : 3
              )
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(DT dt, GeminiThemeExtension? theme, Color roleColor, List<Widget> tiles, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: dt.cardBg.withOpacity(0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: roleColor.withOpacity(0.22),
          width: isSmallScreen ? 1.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: roleColor.withOpacity(0.08),
            blurRadius: isSmallScreen ? 10 : 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(dt.dark ? 0.2 : 0.04),
            blurRadius: isSmallScreen ? 8 : 15,
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

  Widget _buildActionTile(DT dt, String title, String sub, IconData icon, Color color, VoidCallback onTap, Color roleColor, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: roleColor.withOpacity(0.08),
            width: 1.0,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 20, vertical: isSmallScreen ? 2 : 6),
        leading: Container(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
          decoration: BoxDecoration(color: dt.roleSoftBg(color), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: isSmallScreen ? 18 : 22),
        ),
        title: Text(
            title,
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: isSmallScreen ? 12 : 14,
                color: dt.textPrimary
            )
        ),
        subtitle: Text(
          sub,
          style: TextStyle(
              fontSize: isSmallScreen ? 8 : 10,
              fontWeight: FontWeight.w900,
              color: dt.textMuted
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(Icons.chevron_right_rounded, size: isSmallScreen ? 16 : 20, color: dt.iconInactive),
        onTap: onTap,
        dense: isSmallScreen,
      ),
    );
  }

  Widget _buildToggleTile(DT dt, String title, String sub, IconData icon, Color color, bool val, Function(bool) onChanged, Color roleColor, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: roleColor.withOpacity(0.08),
            width: 1.0,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 20, vertical: isSmallScreen ? 2 : 6),
        leading: Container(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
          decoration: BoxDecoration(color: dt.roleSoftBg(color), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: isSmallScreen ? 18 : 22),
        ),
        title: Text(
            title,
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: isSmallScreen ? 12 : 14,
                color: dt.textPrimary
            )
        ),
        subtitle: Text(
            sub,
            style: TextStyle(
                fontSize: isSmallScreen ? 8 : 10,
                fontWeight: FontWeight.w900,
                color: dt.textMuted
            )
        ),
        trailing: Switch.adaptive(
          value: val,
          activeColor: roleColor,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        dense: isSmallScreen,
      ),
    );
  }

  // âœ… UPDATED: Logout button with role color
  Widget _buildLogoutButton(DT dt, AuthenticationService auth, bool isSmallScreen, Color roleColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _confirmLogout(auth, dt, roleColor),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 14 : 22),
          decoration: BoxDecoration(
            color: KagemaColors.parentRed.withOpacity(0.05),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: KagemaColors.parentRed.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.power_settings_new_rounded, color: KagemaColors.parentRed, size: isSmallScreen ? 18 : 22),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Text(
                  'TERMINATE SESSION',
                  style: TextStyle(
                      color: KagemaColors.parentRed,
                      fontWeight: FontWeight.w900,
                      letterSpacing: isSmallScreen ? 1 : 2,
                      fontSize: isSmallScreen ? 10 : 12
                  )
              ),
            ],
          ),
        ),
      ),
    );
  }

  // âœ… UPDATED: App info with role color
  Widget _buildAppInfo(AppSettings settings, DT dt, bool isSmallScreen, Color roleColor) {
    return Center(
      child: Column(
        children: [
          Text(
              'KAGEMA INTELLIGENT SYSTEMS',
              style: TextStyle(
                  fontSize: isSmallScreen ? 6 : 8,
                  color: dt.textMuted.withOpacity(0.5),
                  fontWeight: FontWeight.w900,
                  letterSpacing: isSmallScreen ? 1 : 2
              )
          ),
          SizedBox(height: isSmallScreen ? 4 : 6),
          Container(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 10, vertical: isSmallScreen ? 2 : 4),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: roleColor.withOpacity(0.1)),
            ),
            child: Text(
                'CORE v${settings.appVersion} [ENCRYPTED]',
                style: TextStyle(
                    fontSize: isSmallScreen ? 6 : 8,
                    color: roleColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: isSmallScreen ? 0.5 : 1
                )
            ),
          ),
        ],
      ),
    );
  }

  void _showAppearanceDialog(AppSettings settings) {
    final dt = context.dt;
    final isSmallScreen = MediaQuery.of(context).size.width < 400;
    final roleColor = RoleColors.of(widget.role);

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
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: roleColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                          'ENVIRONMENT MODE',
                          style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: isSmallScreen ? 2 : 3
                          )
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: roleColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: KagemaColors.accountantAmber.withOpacity(0.15),
                child: Icon(Icons.wb_sunny_rounded, color: KagemaColors.accountantAmber, size: 20),
              ),
              title: Text(
                  'CRYSTAL LIGHT',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: isSmallScreen ? 12 : 14
                  )
              ),
              onTap: () { settings.setThemeMode(ThemeMode.light); Navigator.pop(context); },
            ),
            ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: KagemaColors.secretaryViolet.withOpacity(0.15),
                child: Icon(Icons.nightlight_round, color: KagemaColors.secretaryViolet, size: 20),
              ),
              title: Text(
                  'OLED DARK',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: isSmallScreen ? 12 : 14
                  )
              ),
              onTap: () { settings.setThemeMode(ThemeMode.dark); Navigator.pop(context); },
            ),
            SizedBox(height: isSmallScreen ? 20 : 40),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(AppSettings settings) {
    final dt = context.dt;
    final isSmallScreen = MediaQuery.of(context).size.width < 400;
    final roleColor = RoleColors.of(widget.role);

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
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: roleColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                      'LANGUAGE NODE',
                      style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: isSmallScreen ? 2 : 3
                      )
                  ),
                ],
              ),
            ),
            ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: roleColor.withOpacity(0.1),
                  child: Text('EN', style: TextStyle(color: roleColor, fontWeight: FontWeight.w900, fontSize: 12)),
                ),
                title: Text(
                    'ENGLISH (GLOBAL)',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: isSmallScreen ? 12 : 14
                    )
                ),
                onTap: () { settings.setLanguage('English'); Navigator.pop(context); }
            ),
            ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: roleColor.withOpacity(0.1),
                  child: Text('SW', style: TextStyle(color: roleColor, fontWeight: FontWeight.w900, fontSize: 12)),
                ),
                title: Text(
                    'KISWAHILI (REGIONAL)',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: isSmallScreen ? 12 : 14
                    )
                ),
                onTap: () { settings.setLanguage('Kiswahili'); Navigator.pop(context); }
            ),
            SizedBox(height: isSmallScreen ? 20 : 40),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(AuthenticationService auth) {
    final dt = context.dt;
    final isSmallScreen = MediaQuery.of(context).size.width < 400;
    final roleColor = RoleColors.of(widget.role);
    final ctrl = TextEditingController(text: auth.currentUserName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dt.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: roleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
                'IDENTITY SYNC',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: dt.textPrimary,
                  fontSize: isSmallScreen ? 16 : 20,
                )
            ),
          ],
        ),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: 'Display Name',
            labelStyle: TextStyle(color: roleColor),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: roleColor),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: dt.textPrimary,
            fontSize: isSmallScreen ? 14 : 16,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                  'ABORT',
                  style: TextStyle(
                    color: dt.textMuted,
                    fontSize: isSmallScreen ? 12 : 14,
                  )
              )
          ),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: roleColor),
              onPressed: () async { await auth.updateName(ctrl.text); Navigator.pop(context); },
              child: Text(
                  'SYNC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 12 : 14,
                  )
              )
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog(AuthenticationService auth) {
    final dt = context.dt;
    final isSmallScreen = MediaQuery.of(context).size.width < 400;
    final roleColor = RoleColors.of(widget.role);
    final oldP = TextEditingController();
    final newP = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dt.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: roleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
                'ACCESS KEY SYNC',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: dt.textPrimary,
                  fontSize: isSmallScreen ? 16 : 20,
                )
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldP,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Secret',
                labelStyle: TextStyle(color: roleColor),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: roleColor),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 16),
            TextField(
              controller: newP,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Secret',
                labelStyle: TextStyle(color: roleColor),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: roleColor),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                  'ABORT',
                  style: TextStyle(
                    color: dt.textMuted,
                    fontSize: isSmallScreen ? 12 : 14,
                  )
              )
          ),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: roleColor),
              onPressed: () async { await auth.changePassword(oldP.text, newP.text); Navigator.pop(context); },
              child: Text(
                  'APPLY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 12 : 14,
                  )
              )
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(AppSettings settings) {
    final dt = context.dt;
    final isSmallScreen = MediaQuery.of(context).size.width < 400;
    final roleColor = RoleColors.of(widget.role);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dt.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: roleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
                'PURGE CACHE?',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: dt.textPrimary,
                  fontSize: isSmallScreen ? 16 : 20,
                )
            ),
          ],
        ),
        content: Text(
            'Optimize system performance by clearing temporary UI states.',
            style: TextStyle(
              color: dt.textSecondary,
              fontSize: isSmallScreen ? 12 : 14,
            )
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                  'STAY',
                  style: TextStyle(
                    color: dt.textMuted,
                    fontSize: isSmallScreen ? 12 : 14,
                  )
              )
          ),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: roleColor),
              onPressed: () async { await settings.clearCache(); Navigator.pop(context); },
              child: Text(
                  'PURGE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 12 : 14,
                  )
              )
          ),
        ],
      ),
    );
  }

  void _showFactoryResetDialog(AppSettings settings) {
    final dt = context.dt;
    final isSmallScreen = MediaQuery.of(context).size.width < 400;
    final roleColor = RoleColors.of(widget.role);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dt.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: KagemaColors.parentRed,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
                'CRITICAL WIPE?',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: KagemaColors.parentRed,
                  fontSize: isSmallScreen ? 16 : 20,
                )
            ),
          ],
        ),
        content: Text(
            'This will erase all local session data and disconnect this node from the system.',
            style: TextStyle(
              color: dt.textSecondary,
              fontSize: isSmallScreen ? 12 : 14,
            )
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                  'ABORT',
                  style: TextStyle(
                    color: dt.textMuted,
                    fontSize: isSmallScreen ? 12 : 14,
                  )
              )
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: KagemaColors.parentRed),
            onPressed: () async {
              await settings.factoryReset();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
            },
            child: Text(
                'EXECUTE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: isSmallScreen ? 12 : 14,
                )
            ),
          ),
        ],
      ),
    );
  }

  // âœ… UPDATED: Logout dialog with role color
  void _confirmLogout(AuthenticationService auth, DT dt, Color roleColor) {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dt.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: roleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
                'LOGOUT?',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: dt.textPrimary,
                  fontSize: isSmallScreen ? 16 : 20,
                )
            ),
          ],
        ),
        content: Text(
            'End the current secure session?',
            style: TextStyle(
              color: dt.textSecondary,
              fontSize: isSmallScreen ? 12 : 14,
            )
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                  'STAY',
                  style: TextStyle(
                    color: dt.textMuted,
                    fontSize: isSmallScreen ? 12 : 14,
                  )
              )
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: roleColor),
            onPressed: () {
              auth.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
            },
            child: Text(
                'LOGOUT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 12 : 14,
                )
            ),
          ),
        ],
      ),
    );
  }
}