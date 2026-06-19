import 'package:flutter/material.dart';
import 'dart:ui';
import '../../services/supabase_service.dart';
import '../settings/settings_screen.dart';
import 'inventory_manager.dart';
import 'fee_management_screen.dart';
import 'communication_hub_screen.dart';
import 'transport_management_screen.dart';
import 'exam_management_screen.dart';
import 'library_management_screen.dart';
import 'reports_module_screen.dart';
import 'academic_management.dart';
import 'hr_management_screen.dart';
import 'discipline_management_screen.dart';
import 'extracurricular_management_screen.dart';
import 'attendance_admin_screen.dart';
import 'user_management_hub.dart';
import 'task_management_screen.dart';
import '../../app_theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  Map<String, dynamic> stats = {};
  List<Map<String, dynamic>> _statusInsights = [];
  bool isLoading = true;
  String? _errorMessage;

  final String _roleId = 'admin';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() { isLoading = true; _errorMessage = null; });
    try {
      final results = await Future.wait<dynamic>([
        SupabaseService.instance.getDashboardSummary(),
        SupabaseService.instance.getActionableInsights(),
      ]);
      if (mounted) {
        setState(() {
          stats = results[0] as Map<String, dynamic>;
          _statusInsights = results[1] as List<Map<String, dynamic>>;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { isLoading = false; _errorMessage = "SYSTEM SYNC PAUSED. SWIPE TO RETRY."; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final roleColor = RoleColors.of(_roleId);
    final compColor = RoleColors.complement(_roleId);
    final screenWidth = context.sw;

    double maxWidth = screenWidth > 1200 ? 1100 : (screenWidth > 800 ? 800 : screenWidth);

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
      onRefresh: _loadDashboardData,
      color: RoleColors.of(_roleId),
      edgeOffset: 120,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildPremiumHeader(greeter.greet('Admin'), Icons.admin_panel_settings_rounded, dt),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.fluid(20, 32), 
                vertical: 24
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null) _buildErrorBanner(dt),
                  
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24, left: 4),
                    child: Text(greeter.tailline.toUpperCase(), 
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2.5)
                    ),
                  ),

                  _buildInsightSlider(dt, theme),
                  const SizedBox(height: 40),
                  _buildSectionHeader('GLOBAL VITALS', dt),
                  const SizedBox(height: 20),
                  _buildSummaryStats(dt, theme),
                  const SizedBox(height: 40),
                  _buildSectionHeader('COMMAND CENTER', dt),
                  const SizedBox(height: 20),
                  _buildQuickActions(dt, theme),
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

  Widget _buildInsightSlider(DT dt, GeminiThemeExtension? theme) {
    if (_statusInsights.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('LIVE INSIGHTS', dt),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _statusInsights.length,
            itemBuilder: (context, index) {
              final insight = _statusInsights[index];
              final color = insight['type'] == 'critical' ? KagemaColors.parentRed : (insight['type'] == 'success' ? KagemaColors.teacherGreen : RoleColors.of(_roleId));
              
              return SizedBox(
                width: 300,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: theme?.buildGlowContainer(
                    accentColor: color,
                    accentColor2: RoleColors.complement(_roleId),
                    borderRadius: 24,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(insight['type'] == 'critical' ? Icons.warning_rounded : Icons.tips_and_updates_rounded, color: color, size: 18),
                            const SizedBox(width: 10),
                            Text(insight['title'].toString().toUpperCase(), 
                              style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 10, letterSpacing: 1)
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(insight['subtitle'] ?? '', 
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w600, color: dt.textPrimary)
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStats(DT dt, GeminiThemeExtension? theme) {
    return Row(
      children: [
        _miniStat('STAFF', '${stats['staff'] ?? 0}', KagemaColors.teacherGreen, dt, theme),
        const SizedBox(width: 12),
        _miniStat('FEES', 'KSH ${stats['totalFees'] ?? 0}', KagemaColors.staffSky, dt, theme),
        const SizedBox(width: 12),
        _miniStat('PARENTS', '${stats['parents'] ?? 0}', KagemaColors.accountantAmber, dt, theme),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color, DT dt, GeminiThemeExtension? theme) {
    return Expanded(
      flex: 1,
      child: theme?.buildGlowContainer(
        accentColor: color,
        accentColor2: RoleColors.complement(_roleId),
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        child: Column(
          children: [
            Text(value, 
              style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 18)
            ), 
            const SizedBox(height: 6), 
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 1.2))
          ],
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildQuickActions(DT dt, GeminiThemeExtension? theme) {
    return Row(
      children: [
        _actionCard('USER HUB', Icons.hub_rounded, RoleColors.of(_roleId), dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementHub()))),
        const SizedBox(width: 16),
        _actionCard('NOTICE BOARD', Icons.campaign_rounded, KagemaColors.secretaryViolet, dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunicationHubScreen()))),
      ],
    );
  }

  Widget _actionCard(String title, IconData icon, Color accent, DT dt, GeminiThemeExtension? theme, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: theme?.buildGlowContainer(
          accentColor: accent,
          accentColor2: RoleColors.complement(_roleId),
          borderRadius: 24,
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              RolePlasma(
                color: accent,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: dt.roleSoftBg(accent), shape: BoxShape.circle),
                  child: Icon(icon, color: accent, size: 32),
                ),
              ),
              const SizedBox(height: 16),
              Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: dt.textPrimary, fontSize: 11, letterSpacing: 1)),
            ],
          ),
        ),
      ),
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
              _buildSectionHeader('REGISTRY & WORKFLOW', dt),
              const SizedBox(height: 12),
              _opTile('User Hub', 'Enroll Students & Staff', Icons.people_alt_rounded, RoleColors.of(_roleId), dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementHub()))),
              _opTile('Task Manager', 'Assign duties to staff', Icons.assignment_ind_rounded, KagemaColors.accountantAmber, dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskManagementScreen()))),
              const SizedBox(height: 24),
              _buildSectionHeader('ACADEMIC RECORDS', dt),
              const SizedBox(height: 12),
              _opTile('Exams & Grading', 'Manage results', Icons.quiz_rounded, KagemaColors.parentRed, dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamManagementScreen()))),
              _opTile('Academic Hub', 'Classes & subjects', Icons.auto_stories_rounded, KagemaColors.staffSky, dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AcademicManagementScreen()))),
              const SizedBox(height: 24),
              _buildSectionHeader('LOGISTICS', dt),
              const SizedBox(height: 12),
              _opTile('Transport', 'Routes & drivers', Icons.bus_alert_rounded, KagemaColors.secretaryViolet, dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransportManagementScreen()))),
              _opTile('Library Center', 'Lending records', Icons.local_library_rounded, dt.textSecondary, dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryManagementScreen()))),
              _opTile('Conduct Logs', 'Incident tracking', Icons.gavel_rounded, KagemaColors.parentRed, dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DisciplineManagementScreen()))),
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
        accentColor2: RoleColors.complement(_roleId),
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
      ),
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
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(role: 'Admin')));
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
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isSelected ? activeColor : dt.iconInactive, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, DT dt) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: RoleColors.of(_roleId), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
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
          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: KagemaColors.parentRed, fontSize: 11, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}
