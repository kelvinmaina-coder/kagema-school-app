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
                horizontal: context.fluid(20, 32), 
                vertical: 24
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null) _buildErrorBanner(dt),
                  
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24, left: 4),
                    child: Text(greeter.tailline.toUpperCase(), 
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2.5)
                    ),
                  ),

                  _buildSectionHeader('SYSTEM VITALS', dt),
                  const SizedBox(height: 20),
                  _buildStatsGrid(dt, theme),
                  const SizedBox(height: 40),
                  _buildSectionHeader('PRIORITY LOGS', dt),
                  const SizedBox(height: 20),
                  _buildRecentAppointments(dt, theme),
                  const SizedBox(height: 140),
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
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      backgroundColor: roleColor,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(title, 
              style: const TextStyle(
                fontWeight: FontWeight.w900, 
                fontSize: 16, 
                letterSpacing: 4, 
                color: Colors.white,
              )
            ),
            const SizedBox(height: 4),
            Container(
              height: 2, width: 40,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(1)),
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
                child: Icon(icon, size: 200, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(DT dt, GeminiThemeExtension? theme) {
    int crossAxisCount = context.isTablet || context.isDesktop ? 4 : 2;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _statCard('STUDENTS', _stats['totalStudents'].toString(), Icons.people_rounded, KagemaColors.staffSky, dt, theme),
        _statCard('VISITORS', _stats['visitors_today'].toString(), Icons.badge_rounded, KagemaColors.teacherGreen, dt, theme),
        _statCard('APPOINTMENTS', _stats['upcomingAppointments'].toString(), Icons.event_rounded, KagemaColors.accountantAmber, dt, theme),
        _statCard('BULLETINS', _stats['announcements'].toString(), Icons.campaign_rounded, KagemaColors.secretaryViolet, dt, theme),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, DT dt, GeminiThemeExtension? theme) {
    return theme?.buildGlowContainer(
      accentColor: color,
      accentColor2: RoleColors.complement(_roleId),
      borderRadius: 28,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RolePlasma(
            color: color,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: dt.roleSoftBg(color),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, 
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: dt.textPrimary, letterSpacing: -1)
              ),
              Text(label, 
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 1.5)
              ),
            ],
          ),
        ],
      ),
    ) ?? const SizedBox.shrink();
  }

  Widget _buildRecentAppointments(DT dt, GeminiThemeExtension? theme) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_recentAppointments.isEmpty) {
      return theme?.buildGlowContainer(
        accentColor: RoleColors.of(_roleId),
        borderRadius: 24,
        padding: const EdgeInsets.all(60),
        child: Center(child: Text('NO PENDING APPOINTMENTS', style: TextStyle(fontWeight: FontWeight.w800, color: dt.textMuted, fontSize: 10, letterSpacing: 1.5))),
      ) ?? const SizedBox.shrink();
    }

    return Column(
      children: _recentAppointments.map((appt) => _buildAppointmentTile(appt, dt, theme)).toList(),
    );
  }

  Widget _buildAppointmentTile(Map<String, dynamic> appt, DT dt, GeminiThemeExtension? theme) {
    final roleColor = RoleColors.of(_roleId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: theme?.buildGlowContainer(
        accentColor: roleColor,
        borderRadius: 24,
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: roleColor.withValues(alpha: 0.3), width: 1.5)),
            child: CircleAvatar(
              backgroundColor: dt.roleSoftBg(roleColor),
              child: Text((appt['visitor_name'] ?? 'V')[0].toString().toUpperCase(), 
                style: TextStyle(color: roleColor, fontWeight: FontWeight.w900)
              ),
            ),
          ),
          title: Text(appt['visitor_name'] ?? 'Visitor', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary)),
          subtitle: Text(appt['title']?.toString().toUpperCase() ?? 'GENERAL MEETING', 
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: roleColor.withValues(alpha: 0.6), letterSpacing: 0.5)
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: dt.iconInactive, size: 20),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildOperationsTab(DT dt, GeminiThemeExtension? theme) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildPremiumHeader('OPERATIONS', Icons.grid_view_rounded, dt),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: context.fluid(20, 32), vertical: 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionHeader('REGISTRY CONTROL', dt),
              const SizedBox(height: 12),
              _opTile('Student Admission', 'Enroll new pupils', Icons.person_add_rounded, KagemaColors.staffSky, dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRegistrationScreen()))),
              _opTile('Parent Directory', 'Contact database', Icons.family_restroom_rounded, KagemaColors.teacherGreen, dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentDirectoryScreen()))),
              const SizedBox(height: 24),
              _buildSectionHeader('LOGISTICS & SECURITY', dt),
              const SizedBox(height: 12),
              _opTile('Visitors Manager', 'Gate tracking', Icons.badge_rounded, KagemaColors.staffSky, dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorsManagerScreen()))),
              _opTile('Office Schedule', 'Appointments', Icons.event_available_rounded, KagemaColors.accountantAmber, dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentManagementScreen()))),
              _opTile('Attendance Hub', 'Monitoring', Icons.fact_check_rounded, KagemaColors.teacherGreen, dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceViewerScreen()))),
              const SizedBox(height: 24),
              _buildSectionHeader('COMMUNICATIONS', dt),
              const SizedBox(height: 12),
              _opTile('Official Bulletins', 'Broadcasts', Icons.campaign_rounded, KagemaColors.secretaryViolet, dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunicationHubScreen()))),
              _opTile('System Reports', 'Data export', Icons.assignment_rounded, KagemaColors.parentRed, dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecretaryReportsScreen()))),
              const SizedBox(height: 140),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _opTile(String title, String sub, IconData icon, Color color, DT dt, GeminiThemeExtension? theme, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: theme?.buildGlowContainer(
        accentColor: color,
        borderRadius: 20,
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: dt.roleSoftBg(color), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary)),
                      const SizedBox(height: 2),
                      Text(sub.toUpperCase(), style: TextStyle(fontSize: 9, color: dt.textMuted, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: dt.iconInactive, size: 20),
              ],
            ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildBottomNav(DT dt) {
    double navWidth = context.fluid(context.sw - 40, 500);

    return Positioned(
      bottom: 25, left: 0, right: 0,
      child: Center(
        child: Container(
          width: navWidth,
          height: 70,
          decoration: BoxDecoration(
            color: dt.cardBg.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10))],
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
    return GestureDetector(
      onTap: () {
        if (index == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(role: 'Secretary')));
          return;
        }
        setState(() => _currentIndex = index);
      },
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? activeColor : dt.iconInactive, size: 26),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isSelected ? activeColor : dt.iconInactive, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, DT dt) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: RoleColors.of(_roleId), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.5, color: dt.textSecondary)),
      ],
    );
  }

  Widget _buildErrorBanner(DT dt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: dt.roleSoftBg(KagemaColors.parentRed), borderRadius: BorderRadius.circular(20), border: Border.all(color: KagemaColors.parentRed.withValues(alpha: 0.3))),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: KagemaColors.parentRed),
          const SizedBox(width: 12),
          Expanded(child: Text(_error!, style: const TextStyle(color: KagemaColors.parentRed, fontSize: 11, fontWeight: FontWeight.w800))),
          IconButton(icon: const Icon(Icons.refresh_rounded, color: KagemaColors.parentRed, size: 20), onPressed: _loadData),
        ],
      ),
    );
  }
}
