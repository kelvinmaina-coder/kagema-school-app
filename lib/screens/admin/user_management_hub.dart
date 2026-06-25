import 'package:flutter/material.dart';
import '../../app_theme.dart';
import 'staff_registration_screen.dart';
import 'parent_registration_screen.dart';
import '../secretary/student_registration.dart';

class UserManagementHub extends StatelessWidget {
  const UserManagementHub({super.key});

  final String _roleId = 'admin';

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final roleColor = RoleColors.of(_roleId);
    final compColor = RoleColors.complement(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: const Text('USER ECOSYSTEM', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 4, color: Colors.white)
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
            gradient: RoleColors.gradient(_roleId, dark: context.isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.manage_accounts_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ),
      ),
      body: theme?.buildCreativeBackground(
        isDark: context.isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: context.isDark,
          child: Padding(
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                _buildHeader(dt),
                const SizedBox(height: 40),
                _buildSectionLabel('REGISTRATION CENTERS', dt),
                const SizedBox(height: 16),
                _hubTile(
                  context, dt, theme,
                  'Student Admissions', 'Enroll new pupils to registry',
                  Icons.person_add_rounded, KagemaColors.staffSky,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRegistrationScreen())),
                ),
                _hubTile(
                  context, dt, theme,
                  'Staff Onboarding', 'Manage educator & support profiles',
                  Icons.badge_rounded, KagemaColors.teacherGreen,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffRegistrationScreen())),
                ),
                _hubTile(
                  context, dt, theme,
                  'Guardian Nexus', 'Register parent accounts',
                  Icons.family_restroom_rounded, KagemaColors.accountantAmber,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentRegistrationScreen())),
                ),
                const SizedBox(height: 140),
              ],
            ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildHeader(DT dt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CENTRAL REGISTRY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: RoleColors.of(_roleId), letterSpacing: 3)),
        const SizedBox(height: 8),
        Text('Manage the identities within the school ecosystem.', 
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: dt.textSecondary, height: 1.4)
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String title, DT dt) {
    return Row(
      children: [
        Container(width: 4, height: 14, decoration: BoxDecoration(color: RoleColors.of(_roleId), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: dt.textMuted)),
      ],
    );
  }

  Widget _hubTile(BuildContext context, DT dt, GeminiThemeExtension? theme, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: theme?.buildGlowContainer(
        accentColor: color,
        borderRadius: 30,
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                RolePlasma(
                  color: color,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: dt.roleSoftBg(color), shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 28),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: dt.textPrimary)),
                      const SizedBox(height: 4),
                      Text(sub.toUpperCase(), style: TextStyle(fontSize: 9, color: dt.textMuted, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: dt.iconInactive, size: 28),
              ],
            ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }
}
