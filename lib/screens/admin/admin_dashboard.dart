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
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;

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
    final isMobile = context.sw < 600;
    final isTablet = context.sw >= 600 && context.sw < 1200;

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
                  horizontal: isMobile ? 16 : (isTablet ? 24 : 32),
                  vertical: isMobile ? 16 : 24
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null) _buildErrorBanner(dt),

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
                          '${greeter.greet('Admin')} 👋',
                          style: TextStyle(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: dt.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_statusInsights.isNotEmpty) ...[
                    _buildInsightSlider(dt, theme),
                    SizedBox(height: isMobile ? 24 : 40),
                  ],

                  _buildSectionHeader('GLOBAL VITALS', dt),
                  SizedBox(height: isMobile ? 12 : 20),
                  _buildSummaryStats(dt, theme),
                  SizedBox(height: isMobile ? 24 : 40),

                  _buildSectionHeader('COMMAND CENTER', dt),
                  SizedBox(height: isMobile ? 12 : 20),
                  _buildQuickActions(dt, theme),
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

  Widget _buildInsightSlider(DT dt, GeminiThemeExtension? theme) {
    final isMobile = context.sw < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('LIVE INSIGHTS', dt),
        SizedBox(height: isMobile ? 12 : 16),
        SizedBox(
          height: isMobile ? 120 : 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _statusInsights.length,
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 0),
            itemBuilder: (context, index) {
              final insight = _statusInsights[index];
              final color = insight['type'] == 'critical'
                  ? KagemaColors.parentRed
                  : (insight['type'] == 'success'
                  ? KagemaColors.teacherGreen
                  : RoleColors.of(_roleId));

              return SizedBox(
                width: isMobile ? 260 : 300,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: theme?.buildGlowContainer(
                    accentColor: color,
                    accentColor2: RoleColors.complement(_roleId),
                    borderRadius: 24,
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                                insight['type'] == 'critical'
                                    ? Icons.warning_rounded
                                    : Icons.tips_and_updates_rounded,
                                color: color,
                                size: isMobile ? 16 : 18
                            ),
                            const SizedBox(width: 10),
                            Text(
                                insight['title'].toString().toUpperCase(),
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: color,
                                    fontSize: isMobile ? 9 : 10,
                                    letterSpacing: 1
                                )
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 8 : 12),
                        Text(
                            insight['subtitle'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                                color: dt.textPrimary
                            )
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
    final isMobile = context.sw < 600;
    final roleColor = RoleColors.of(_roleId);

    final statsData = [
      {
        'label': 'STAFF',
        'value': '${stats['staff'] ?? 0}',
        'color': KagemaColors.teacherGreen,
        'icon': Icons.people_rounded,
      },
      {
        'label': 'FEES',
        'value': 'KSH ${stats['totalFees'] ?? 0}',
        'color': KagemaColors.staffSky,
        'icon': Icons.attach_money_rounded,
      },
      {
        'label': 'PARENTS',
        'value': '${stats['parents'] ?? 0}',
        'color': KagemaColors.accountantAmber,
        'icon': Icons.family_restroom_rounded,
      },
    ];

    return Row(
      children: statsData.map((stat) {
        final color = stat['color'] as Color;
        final value = stat['value'] as String;
        final label = stat['label'] as String;
        final icon = stat['icon'] as IconData;

        return Expanded(
          flex: 1,
          child: Padding(
            padding: EdgeInsets.only(right: isMobile ? 8 : 12),
            child: theme?.buildGlowContainer(
              accentColor: color,
              accentColor2: RoleColors.complement(_roleId),
              borderRadius: isMobile ? 16 : 24,
              padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 16 : 24,
                  horizontal: isMobile ? 8 : 12
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 6 : 10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: isMobile ? 16 : 22,
                    ),
                  ),
                  SizedBox(height: isMobile ? 6 : 10),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: color,
                      fontSize: isMobile ? 16 : 18,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isMobile ? 4 : 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isMobile ? 8 : 9,
                      fontWeight: FontWeight.w900,
                      color: dt.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: isMobile ? 6 : 10),
                    height: 2,
                    width: isMobile ? 20 : 30,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ) ?? const SizedBox.shrink(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActions(DT dt, GeminiThemeExtension? theme) {
    final isMobile = context.sw < 600;
    final roleColor = RoleColors.of(_roleId);

    final actions = [
      {
        'title': 'USER HUB',
        'icon': Icons.hub_rounded,
        'color': roleColor,
        'route': const UserManagementHub(),
      },
      {
        'title': 'NOTICE BOARD',
        'icon': Icons.campaign_rounded,
        'color': KagemaColors.secretaryViolet,
        'route': const CommunicationHubScreen(),
      },
    ];

    if (!isMobile) {
      actions.addAll([
        {
          'title': 'EXAMS',
          'icon': Icons.quiz_rounded,
          'color': KagemaColors.parentRed,
          'route': const ExamManagementScreen(),
        },
        {
          'title': 'ACADEMICS',
          'icon': Icons.auto_stories_rounded,
          'color': KagemaColors.staffSky,
          'route': const AcademicManagementScreen(),
        },
      ]);
    }

    return isMobile
        ? Column(
      children: [
        Row(
          children: actions.take(2).map((action) {
            return _actionCard(
              action['title'] as String,
              action['icon'] as IconData,
              action['color'] as Color,
              dt,
              theme,
                  () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => action['route'] as Widget)
              ),
            );
          }).toList(),
        ),
      ],
    )
        : GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: context.sw > 900 ? 4 : 2,
      crossAxisSpacing: isMobile ? 12 : 16,
      mainAxisSpacing: isMobile ? 12 : 16,
      childAspectRatio: isMobile ? 1.2 : 1.1,
      children: actions.map((action) {
        return _actionCard(
          action['title'] as String,
          action['icon'] as IconData,
          action['color'] as Color,
          dt,
          theme,
              () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => action['route'] as Widget)
          ),
        );
      }).toList(),
    );
  }

  Widget _actionCard(
      String title,
      IconData icon,
      Color accent,
      DT dt,
      GeminiThemeExtension? theme,
      VoidCallback onTap,
      ) {
    final isMobile = context.sw < 600;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: isMobile ? 8 : 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
          child: theme?.buildGlowContainer(
            accentColor: accent,
            accentColor2: RoleColors.complement(_roleId),
            borderRadius: isMobile ? 16 : 24,
            padding: EdgeInsets.symmetric(vertical: isMobile ? 20 : 32),
            child: Column(
              children: [
                RolePlasma(
                  color: accent,
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    decoration: BoxDecoration(
                      color: dt.roleSoftBg(accent),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: accent,
                      size: isMobile ? 24 : 32,
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: dt.textPrimary,
                    fontSize: isMobile ? 10 : 11,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Container(
                  height: 2,
                  width: isMobile ? 20 : 30,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
              _buildSectionHeader('REGISTRY & WORKFLOW', dt),
              SizedBox(height: isMobile ? 8 : 12),
              _opTile(
                'User Hub',
                'Enroll Students & Staff',
                Icons.people_alt_rounded,
                RoleColors.of(_roleId),
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserManagementHub())
                ),
              ),
              _opTile(
                'Task Manager',
                'Assign duties to staff',
                Icons.assignment_ind_rounded,
                KagemaColors.accountantAmber,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TaskManagementScreen())
                ),
              ),
              SizedBox(height: isMobile ? 16 : 24),
              _buildSectionHeader('ACADEMIC RECORDS', dt),
              SizedBox(height: isMobile ? 8 : 12),
              _opTile(
                'Exams & Grading',
                'Manage results',
                Icons.quiz_rounded,
                KagemaColors.parentRed,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExamManagementScreen())
                ),
              ),
              _opTile(
                'Academic Hub',
                'Classes & subjects',
                Icons.auto_stories_rounded,
                KagemaColors.staffSky,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AcademicManagementScreen())
                ),
              ),
              SizedBox(height: isMobile ? 16 : 24),
              _buildSectionHeader('LOGISTICS', dt),
              SizedBox(height: isMobile ? 8 : 12),
              _opTile(
                'Transport',
                'Routes & drivers',
                Icons.bus_alert_rounded,
                KagemaColors.secretaryViolet,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TransportManagementScreen())
                ),
              ),
              _opTile(
                'Library Center',
                'Lending records',
                Icons.local_library_rounded,
                dt.textSecondary,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LibraryManagementScreen())
                ),
              ),
              _opTile(
                'Conduct Logs',
                'Incident tracking',
                Icons.gavel_rounded,
                KagemaColors.parentRed,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DisciplineManagementScreen())
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
    final roleColor = RoleColors.of(_roleId);

    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      child: theme?.buildGlowContainer(
        accentColor: color,
        accentColor2: RoleColors.complement(_roleId),
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
      ),
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
            border: Border.all(
              color: dt.cardBorder,
              width: 1,
            ),
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
              MaterialPageRoute(builder: (_) => const SettingsScreen(role: 'Admin'))
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
                letterSpacing: 1,
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
        const SizedBox(width: 10),
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
        border: Border.all(
          color: KagemaColors.parentRed.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: KagemaColors.parentRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: KagemaColors.parentRed,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (!isMobile)
            IconButton(
              onPressed: _loadDashboardData,
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