import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/supabase_service.dart';
import '../settings/settings_screen.dart';
import 'student_registration.dart';
import '../common/parent_directory_screen.dart';
import 'appointment_management.dart';
import 'attendance_viewer.dart';
import 'secretary_reports.dart';
import 'visitors_manager.dart';
import '../admin/communication_hub_screen.dart';
import '../../app_theme.dart';

class SecretaryDashboard extends StatefulWidget {
  const SecretaryDashboard({super.key});

  @override
  State<SecretaryDashboard> createState() => _SecretaryDashboardState();
}

class _SecretaryDashboardState extends State<SecretaryDashboard> with TickerProviderStateMixin {
  int _currentIndex = 0;
  Map<String, dynamic> _stats = {
    'totalStudents': 0,
    'newAdmissions': 0,
    'upcomingAppointments': 0,
    'announcements': 0,
    'visitors_today': 0,
  };
  List<Map<String, dynamic>> _recentAppointments = [];
  bool _isLoading = true;
  String? _error;

  final String _roleId = 'secretary';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        SupabaseService.instance.getSecretaryStats(),
        SupabaseService.instance.getAppointments(),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, dynamic>;
          _recentAppointments = List<Map<String, dynamic>>.from(results[1] as List).take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "LINK UNSTABLE. SWIPE DOWN.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final roleColor = RoleColors.of(_roleId);
    final compColor = RoleColors.complement(_roleId);
    final screenWidth = context.sw;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;

    double maxWidth = screenWidth > 1200 ? 1100 : (screenWidth > 800 ? 850 : screenWidth);

    return Scaffold(
      backgroundColor: dt.pageBg,
      body: theme?.buildCreativeBackground(
        isDark: context.isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: RoleAuraLayer(
              roleColor: roleColor,
              isDark: context.isDark,
              child: Stack(
                children: [
                  _currentIndex == 0 ? _buildHomeTab(dt, theme) : _buildOperationsTab(dt, theme),
                  _buildBottomNav(dt),
                ],
              ),
            ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildHomeTab(DT dt, GeminiThemeExtension? theme) {
    final greeter = TimeGreeter.now;
    final isMobile = context.sw < 600;
    final isTablet = context.sw >= 600 && context.sw < 1200;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: RoleColors.of(_roleId),
      edgeOffset: 120,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildPremiumHeader(greeter.greet('Secretary'), Icons.assignment_ind_rounded, dt),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : (isTablet ? 24 : 32),
                  vertical: isMobile ? 16 : 24
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null) _buildErrorBanner(dt),

                  Padding(
                    padding: EdgeInsets.only(bottom: isMobile ? 16 : 24, left: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeter.tailline.toUpperCase(),
                          style: TextStyle(
                              fontSize: isMobile ? 8 : 9,
                              fontWeight: FontWeight.w900,
                              color: dt.textMuted,
                              letterSpacing: 2.5
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${greeter.greet('Secretary')} ðŸ‘‹',
                          style: TextStyle(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: dt.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildSectionHeader('SYSTEM VITALS', dt),
                  SizedBox(height: isMobile ? 12 : 20),
                  _buildStatsGrid(dt, theme),
                  SizedBox(height: isMobile ? 24 : 40),
                  _buildSectionHeader('PRIORITY LOGS', dt),
                  SizedBox(height: isMobile ? 12 : 20),
                  _buildRecentAppointments(dt, theme),
                  SizedBox(height: isMobile ? 80 : 140),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(String title, IconData icon, DT dt) {
    final roleColor = RoleColors.of(_roleId);
    final isMobile = context.sw < 600;

    return SliverAppBar(
      expandedHeight: isMobile ? 100 : 140,
      pinned: true,
      elevation: 0,
      backgroundColor: roleColor,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isMobile ? 14 : 16,
                  letterSpacing: 4,
                  color: Colors.white,
                )
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: isMobile ? 30 : 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(1),
              ),
            )
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: roleColor),
            Center(
              child: Opacity(
                opacity: 0.08,
                child: Icon(icon, size: isMobile ? 120 : 200, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(DT dt, GeminiThemeExtension? theme) {
    final isMobile = context.sw < 600;
    final roleColor = RoleColors.of(_roleId);

    int crossAxisCount = isMobile ? 2 : (context.sw > 900 ? 4 : 3);

    final statsData = [
      {'label': 'STUDENTS', 'value': _stats['totalStudents'].toString(), 'icon': Icons.people_rounded, 'color': KagemaColors.staffSky},
      {'label': 'VISITORS', 'value': _stats['visitors_today'].toString(), 'icon': Icons.badge_rounded, 'color': KagemaColors.teacherGreen},
      {'label': 'APPOINTMENTS', 'value': _stats['upcomingAppointments'].toString(), 'icon': Icons.event_rounded, 'color': KagemaColors.accountantAmber},
      {'label': 'BULLETINS', 'value': _stats['announcements'].toString(), 'icon': Icons.campaign_rounded, 'color': KagemaColors.secretaryViolet},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: isMobile ? 12 : 16,
      crossAxisSpacing: isMobile ? 12 : 16,
      childAspectRatio: isMobile ? 1.2 : 1.3,
      children: statsData.map((stat) {
        return _statCard(
          dt,
          theme,
          stat['label'] as String,
          stat['value'] as String,
          stat['icon'] as IconData,
          stat['color'] as Color,
          isMobile,
        );
      }).toList(),
    );
  }

  Widget _statCard(DT dt, GeminiThemeExtension? theme, String label, String value, IconData icon, Color color, bool isMobile) {
    final roleColor = RoleColors.of(_roleId);

    return theme?.buildGlowContainer(
      accentColor: color,
      accentColor2: RoleColors.complement(_roleId),
      borderRadius: isMobile ? 20 : 28,
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RolePlasma(
            color: color,
            child: Container(
              padding: EdgeInsets.all(isMobile ? 6 : 8),
              decoration: BoxDecoration(
                color: dt.roleSoftBg(color),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: isMobile ? 16 : 20,
              ),
            ),
          ),
          SizedBox(height: isMobile ? 4 : 0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.w900,
                  color: dt.textPrimary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 7 : 8,
                  fontWeight: FontWeight.w900,
                  color: dt.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
              // Indicator bar
              Container(
                margin: EdgeInsets.only(top: isMobile ? 4 : 6),
                height: 2,
                width: isMobile ? 15 : 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ],
      ),
    ) ?? const SizedBox.shrink();
  }

  Widget _buildRecentAppointments(DT dt, GeminiThemeExtension? theme) {
    final isMobile = context.sw < 600;
    final roleColor = RoleColors.of(_roleId);

    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(
            color: roleColor,
          ),
        ),
      );
    }

    if (_recentAppointments.isEmpty) {
      return theme?.buildGlowContainer(
        accentColor: roleColor,
        borderRadius: isMobile ? 16 : 24,
        padding: EdgeInsets.all(isMobile ? 40 : 60),
        child: Column(
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: isMobile ? 40 : 60,
              color: dt.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'NO PENDING APPOINTMENTS',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: dt.textMuted,
                fontSize: isMobile ? 9 : 10,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ) ?? const SizedBox.shrink();
    }

    return Column(
      children: _recentAppointments.map((appt) => _buildAppointmentTile(appt, dt, theme)).toList(),
    );
  }

  Widget _buildAppointmentTile(Map<String, dynamic> appt, DT dt, GeminiThemeExtension? theme) {
    final roleColor = RoleColors.of(_roleId);
    final isMobile = context.sw < 600;

    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      child: theme?.buildGlowContainer(
        accentColor: roleColor,
        borderRadius: isMobile ? 16 : 24,
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 20,
            vertical: isMobile ? 4 : 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: roleColor.withOpacity(0.3), width: 1.5),
            ),
            child: CircleAvatar(
              radius: isMobile ? 18 : 20,
              backgroundColor: dt.roleSoftBg(roleColor),
              child: Text(
                (appt['visitor_name'] ?? 'V')[0].toString().toUpperCase(),
                style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.w900,
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
            ),
          ),
          title: Text(
            appt['visitor_name'] ?? 'Visitor',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: isMobile ? 13 : 14,
              color: dt.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            appt['title']?.toString().toUpperCase() ?? 'GENERAL MEETING',
            style: TextStyle(
              fontSize: isMobile ? 8 : 9,
              fontWeight: FontWeight.w800,
              color: roleColor.withOpacity(0.6),
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 6 : 10,
                  vertical: isMobile ? 3 : 5,
                ),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: roleColor.withOpacity(0.2)),
                ),
                child: Text(
                  'PENDING',
                  style: TextStyle(
                    fontSize: isMobile ? 7 : 8,
                    fontWeight: FontWeight.w800,
                    color: roleColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: dt.iconInactive,
                size: isMobile ? 18 : 20,
              ),
            ],
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildOperationsTab(DT dt, GeminiThemeExtension? theme) {
    final isMobile = context.sw < 600;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildPremiumHeader('OPERATIONS', Icons.grid_view_rounded, dt),
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : (context.sw < 900 ? 24 : 32),
            vertical: isMobile ? 16 : 24,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionHeader('REGISTRY CONTROL', dt),
              SizedBox(height: isMobile ? 8 : 12),
              _opTile(
                'Student Admission',
                'Enroll new pupils',
                Icons.person_add_rounded,
                KagemaColors.staffSky,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentRegistrationScreen())
                ),
              ),
              _opTile(
                'Parent Directory',
                'Contact database',
                Icons.family_restroom_rounded,
                KagemaColors.teacherGreen,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ParentDirectoryScreen())
                ),
              ),
              SizedBox(height: isMobile ? 16 : 24),
              _buildSectionHeader('LOGISTICS & SECURITY', dt),
              SizedBox(height: isMobile ? 8 : 12),
              _opTile(
                'Visitors Manager',
                'Gate tracking',
                Icons.badge_rounded,
                KagemaColors.staffSky,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VisitorsManagerScreen())
                ),
              ),
              _opTile(
                'Office Schedule',
                'Appointments',
                Icons.event_available_rounded,
                KagemaColors.accountantAmber,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AppointmentManagementScreen())
                ),
              ),
              _opTile(
                'Attendance Hub',
                'Monitoring',
                Icons.fact_check_rounded,
                KagemaColors.teacherGreen,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AttendanceViewerScreen())
                ),
              ),
              SizedBox(height: isMobile ? 16 : 24),
              _buildSectionHeader('COMMUNICATIONS', dt),
              SizedBox(height: isMobile ? 8 : 12),
              _opTile(
                'Official Bulletins',
                'Broadcasts',
                Icons.campaign_rounded,
                KagemaColors.secretaryViolet,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CommunicationHubScreen())
                ),
              ),
              _opTile(
                'System Reports',
                'Data export',
                Icons.assignment_rounded,
                KagemaColors.parentRed,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SecretaryReportsScreen())
                ),
              ),
              const SizedBox(height: 140),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _opTile(
      String title,
      String sub,
      IconData icon,
      Color color,
      DT dt,
      GeminiThemeExtension? theme,
      VoidCallback onTap,
      ) {
    final isMobile = context.sw < 600;

    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      child: theme?.buildGlowContainer(
        accentColor: color,
        borderRadius: isMobile ? 16 : 20,
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                  decoration: BoxDecoration(
                    color: dt.roleSoftBg(color),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isMobile ? 18 : 20,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isMobile ? 13 : 14,
                          color: dt.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sub.toUpperCase(),
                        style: TextStyle(
                          fontSize: isMobile ? 8 : 9,
                          color: dt.textMuted,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: dt.iconInactive,
                  size: isMobile ? 18 : 20,
                ),
              ],
            ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildBottomNav(DT dt) {
    final isMobile = context.sw < 600;
    final roleColor = RoleColors.of(_roleId);

    double navWidth = context.fluid(context.sw - 40, 500);
    double navHeight = isMobile ? 60 : 70;

    return Positioned(
      bottom: isMobile ? 16 : 25,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: navWidth,
          height: navHeight,
          decoration: BoxDecoration(
            color: dt.cardBg.withOpacity(0.95),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: dt.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(0, Icons.dashboard_rounded, 'MATRIX', dt),
              _navItem(1, Icons.grid_view_rounded, 'SERVICES', dt),
              _navItem(2, Icons.settings_rounded, 'SETUP', dt),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, DT dt) {
    bool isSelected = _currentIndex == index;
    final activeColor = RoleColors.of(_roleId);
    final isMobile = context.sw < 600;

    return GestureDetector(
      onTap: () {
        if (index == 2) {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen(role: 'Secretary'))
          );
          return;
        }
        setState(() => _currentIndex = index);
      },
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 12,
          vertical: isMobile ? 4 : 0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : dt.iconInactive,
              size: isMobile ? 22 : 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 8 : 9,
                fontWeight: FontWeight.w900,
                color: isSelected ? activeColor : dt.iconInactive,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, DT dt) {
    final roleColor = RoleColors.of(_roleId);
    final isMobile = context.sw < 600;

    return Row(
      children: [
        Container(
          width: 4,
          height: isMobile ? 14 : 16,
          decoration: BoxDecoration(
            color: roleColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: isMobile ? 10 : 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
            color: dt.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(DT dt) {
    final isMobile = context.sw < 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: dt.roleSoftBg(KagemaColors.parentRed),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        border: Border.all(color: KagemaColors.parentRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: KagemaColors.parentRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: KagemaColors.parentRed,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (!isMobile)
            IconButton(
              onPressed: _loadData,
              icon: Icon(Icons.refresh_rounded, color: KagemaColors.parentRed),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              iconSize: 20,
            ),
        ],
      ),
    );
  }
}