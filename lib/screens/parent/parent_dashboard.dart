import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../settings/settings_screen.dart';
import 'fees_payment.dart';
import 'child_performance_screen.dart';
import 'child_attendance_viewers.dart';
import 'homework_screen.dart';
import 'child_list_screen.dart';
import 'announcements_screen.dart';
import 'child_discipline_screen.dart';
import 'child_timetable_screen.dart';
import 'child_library_screen.dart';
import 'parent_calendar_screen.dart';
import '../../app_theme.dart';

class ParentDashboard extends StatefulWidget {
  final String parentPhone;
  const ParentDashboard({super.key, required this.parentPhone});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _selectedIndex = 0;
  List<Student> children = [];
  Student? selectedChild;
  bool isLoading = true;

  double _attendancePercent = 0.0;
  double _avgGrade = 0.0;
  double _feeBalance = 0.0;

  final String _roleId = 'parent';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final childMaps = await SupabaseService.instance.getParentChildren(widget.parentPhone);
      if (mounted) {
        setState(() {
          children = childMaps.map((m) => Student.fromMap(m)).toList();
          if (children.isNotEmpty) { selectedChild ??= children[0]; }
        });
        if (selectedChild != null) await _loadChildVitals();
      }
    } catch (e) {
      debugPrint("Parent Sync Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadChildVitals() async {
    if (selectedChild == null) return;
    try {
      final results = await Future.wait<dynamic>([
        SupabaseService.instance.getStudentMarks(selectedChild!.studentId),
        SupabaseService.instance.getChildAttendance(selectedChild!.studentId),
        SupabaseService.instance.getStudentBalance(selectedChild!.studentId, selectedChild!.grade),
      ]);
      if (mounted) {
        setState(() {
          final marks = results[0] as List<Map<String, dynamic>>;
          final att = results[1] as List<Map<String, dynamic>>;
          final balanceData = results[2] as Map<String, dynamic>;
          _avgGrade = marks.isEmpty ? 0.0 : marks.fold(0.0, (sum, m) => sum + (m['score'] ?? 0)) / marks.length;
          _attendancePercent = att.isEmpty ? 0.0 : (att.where((a) => a['status'] == 'Present').length / att.length) * 100;
          _feeBalance = (balanceData['balance'] ?? 0.0).toDouble();
        });
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final isDark = context.isDark;
    final screenWidth = context.sw;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final roleColor = RoleColors.of(_roleId);
    final compColor = RoleColors.complement(_roleId);

    double maxWidth = screenWidth > 1200 ? 1000 : (screenWidth > 800 ? 800 : screenWidth);

    return Scaffold(
      extendBody: true,
      backgroundColor: dt.pageBg,
      body: theme?.buildCreativeBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: RoleAuraLayer(
              roleColor: roleColor,
              isDark: isDark,
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: roleColor, strokeWidth: 3))
                  : IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildHomeTab(dt, theme, screenWidth),
                  const AnnouncementsScreen(),
                  ChildListScreen(parentPhone: widget.parentPhone),
                  const SettingsScreen(role: 'Parent'),
                ],
              ),
            ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
      bottomNavigationBar: _buildModernNavBar(dt, screenWidth),
    );
  }

  Widget _buildHomeTab(DT dt, GeminiThemeExtension? theme, double screenWidth) {
    final greeter = TimeGreeter.now;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: RoleColors.of(_roleId),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeroAppBar(dt),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : (isTablet ? 24 : 40),
                  vertical: isMobile ? 16 : 32
              ),
              child: children.isEmpty
                  ? _buildEmptyState(dt)
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          '${greeter.greet('Parent')} ðŸ‘‹',
                          style: TextStyle(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: dt.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildChildSelector(dt),
                  SizedBox(height: isMobile ? 24 : 40),
                  _buildSectionLabel('INTELLIGENT INSIGHTS', dt),
                  SizedBox(height: isMobile ? 12 : 16),
                  _buildVitalsRow(dt, theme, screenWidth),
                  SizedBox(height: isMobile ? 24 : 40),
                  _buildSectionLabel('STUDENT SERVICES', dt),
                  SizedBox(height: isMobile ? 12 : 16),
                  _buildServiceGrid(dt, theme, screenWidth),
                  SizedBox(height: isMobile ? 80 : 140),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsRow(DT dt, GeminiThemeExtension? theme, double screenWidth) {
    final isMobile = screenWidth < 600;
    final roleColor = RoleColors.of(_roleId);

    if (screenWidth < 360) {
      return Column(
        children: [
          Row(children: [
            _vitalBox(dt, theme, 'ATTENDANCE', '${_attendancePercent.toInt()}%', KagemaColors.azure, true, isMobile),
            const SizedBox(width: 12),
            _vitalBox(dt, theme, 'AVG SCORE', '${_avgGrade.toInt()}%', KagemaColors.accountantAmber, false, isMobile),
          ]),
          const SizedBox(height: 12),
          _vitalBox(dt, theme, 'FEES DUE', 'KSH ${_feeBalance.toInt()}', _feeBalance > 0 ? KagemaColors.parentRed : KagemaColors.teacherGreen, false, isMobile),
        ],
      );
    }

    return Row(
      children: [
        _vitalBox(dt, theme, 'ATTENDANCE', '${_attendancePercent.toInt()}%', KagemaColors.azure, true, isMobile),
        SizedBox(width: isMobile ? 8 : 12),
        _vitalBox(dt, theme, 'FEES DUE', 'KSH ${_feeBalance.toInt()}', _feeBalance > 0 ? KagemaColors.parentRed : KagemaColors.teacherGreen, false, isMobile),
        SizedBox(width: isMobile ? 8 : 12),
        _vitalBox(dt, theme, 'AVG SCORE', '${_avgGrade.toInt()}%', KagemaColors.accountantAmber, false, isMobile),
      ],
    );
  }

  Widget _vitalBox(DT dt, GeminiThemeExtension? theme, String label, String value, Color color, bool useAIBorder, bool isMobile) {
    final roleColor = RoleColors.of(_roleId);

    return Expanded(
      flex: 1,
      child: theme?.buildGlowContainer(
        accentColor: color,
        accentColor2: RoleColors.complement(_roleId),
        borderRadius: isMobile ? 16 : 24,
        padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 24, horizontal: isMobile ? 6 : 8),
        useAIBorder: useAIBorder,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Small icon indicator
              Container(
                padding: EdgeInsets.all(isMobile ? 4 : 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  label == 'ATTENDANCE' ? Icons.calendar_today_rounded :
                  label == 'FEES DUE' ? Icons.attach_money_rounded :
                  Icons.grade_rounded,
                  color: color,
                  size: isMobile ? 14 : 18,
                ),
              ),
              SizedBox(height: isMobile ? 4 : 6),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isMobile ? 16 : 18,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isMobile ? 2 : 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 7 : 8,
                  fontWeight: FontWeight.w900,
                  color: dt.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
              // Indicator bar
              Container(
                margin: EdgeInsets.only(top: isMobile ? 4 : 8),
                height: 2,
                width: isMobile ? 20 : 30,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ]
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildServiceGrid(DT dt, GeminiThemeExtension? theme, double screenWidth) {
    final isMobile = screenWidth < 600;
    final roleColor = RoleColors.of(_roleId);

    int crossAxisCount = isMobile ? 2 : (screenWidth > 900 ? 4 : 3);

    final services = [
      {'title': 'ROLL CALL', 'icon': Icons.event_available_rounded, 'color': KagemaColors.azure, 'route': ChildAttendanceScreen(student: selectedChild!)},
      {'title': 'PERFORMANCE', 'icon': Icons.auto_graph_rounded, 'color': KagemaColors.accountantAmber, 'route': ChildPerformanceScreen(student: selectedChild!)},
      {'title': 'FEE PORTAL', 'icon': Icons.account_balance_wallet_rounded, 'color': KagemaColors.teacherGreen, 'route': FeesPaymentScreen(student: selectedChild!)},
      {'title': 'HOMEWORK', 'icon': Icons.assignment_rounded, 'color': KagemaColors.secretaryViolet, 'route': HomeworkScreen(grade: selectedChild!.grade, stream: selectedChild!.stream)},
      {'title': 'TIMETABLE', 'icon': Icons.calendar_view_week_rounded, 'color': KagemaColors.staffSky, 'route': ChildTimetableScreen(student: selectedChild!)},
      {'title': 'LIBRARY', 'icon': Icons.local_library_rounded, 'color': dt.textSecondary, 'route': ChildLibraryScreen(student: selectedChild!)},
      {'title': 'CONDUCT', 'icon': Icons.gavel_rounded, 'color': KagemaColors.parentRed, 'route': ChildDisciplineScreen(student: selectedChild!)},
      {'title': 'CALENDAR', 'icon': Icons.event_note_rounded, 'color': KagemaColors.electric, 'route': const ParentCalendarScreen()},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: isMobile ? 12 : 16,
      mainAxisSpacing: isMobile ? 12 : 16,
      childAspectRatio: isMobile ? 1.2 : 1.4,
      children: services.map((service) {
        return _serviceCard(
          dt,
          theme,
          service['title'] as String,
          service['icon'] as IconData,
          service['color'] as Color,
              () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => service['route'] as Widget)
          ),
          isMobile,
        );
      }).toList(),
    );
  }

  Widget _serviceCard(DT dt, GeminiThemeExtension? theme, String title, IconData icon, Color color, VoidCallback onTap, bool isMobile) {
    final roleColor = RoleColors.of(_roleId);

    return theme?.buildGlowContainer(
      accentColor: color,
      borderRadius: isMobile ? 20 : 28,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isMobile ? 20 : 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                size: isMobile ? 20 : 24,
              ),
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: isMobile ? 8 : 9,
                letterSpacing: 1.5,
                color: dt.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: isMobile ? 15 : 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    ) ?? const SizedBox.shrink();
  }

  Widget _buildModernNavBar(DT dt, double screenWidth) {
    final isMobile = screenWidth < 600;
    final roleColor = RoleColors.of(_roleId);

    double navWidth = context.fluid(context.sw - 40, 500);
    double navHeight = isMobile ? 60 : 75;

    return Center(
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 25),
        width: navWidth,
        height: navHeight,
        decoration: BoxDecoration(
          color: dt.cardBg.withOpacity(0.95),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: dt.cardBorder),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10)
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navIcon(0, Icons.grid_view_rounded, 'HUB', dt),
            _navIcon(1, Icons.campaign_rounded, 'ALERTS', dt),
            _navIcon(2, Icons.family_restroom_rounded, 'FAMILY', dt),
            _navIcon(3, Icons.person_rounded, 'PROFILE', dt),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(int index, IconData icon, String label, DT dt) {
    bool isSelected = _selectedIndex == index;
    final color = isSelected ? RoleColors.of(_roleId) : dt.iconInactive;
    final isMobile = context.sw < 600;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 12,
          vertical: isMobile ? 4 : 0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: KagemaMotion.normal,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 18,
                vertical: isMobile ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: isSelected ? dt.roleSoftBg(color) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: color,
                size: isMobile ? 22 : 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 7 : 8,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildSelector(DT dt) {
    if (children.isEmpty) return const SizedBox.shrink();
    final roleColor = RoleColors.of(_roleId);
    final isMobile = context.sw < 600;

    return LiquidGlassCard(
      accentColor: roleColor,
      borderRadius: isMobile ? 20 : 30,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: isMobile ? 6 : 4),
      useAIBorder: true,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: roleColor, width: 2),
            ),
            child: CircleAvatar(
              radius: isMobile ? 16 : 18,
              backgroundColor: dt.roleSoftBg(roleColor),
              child: Text(
                selectedChild?.name[0].toUpperCase() ?? '?',
                style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Student>(
                value: selectedChild,
                isExpanded: true,
                dropdownColor: dt.cardBg,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: roleColor,
                  size: isMobile ? 20 : 24,
                ),
                items: children.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(
                    c.name.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: isMobile ? 12 : 13,
                      color: dt.textPrimary,
                      letterSpacing: 1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                )).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => selectedChild = v);
                    _loadChildVitals();
                  }
                },
              ),
            ),
          ),
          // Indicator pill
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 12,
              vertical: isMobile ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: roleColor.withOpacity(0.2)),
            ),
            child: Text(
              'ACTIVE',
              style: TextStyle(
                fontSize: isMobile ? 7 : 8,
                fontWeight: FontWeight.w900,
                color: roleColor,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroAppBar(DT dt) {
    final roleColor = RoleColors.of(_roleId);
    final isMobile = context.sw < 600;

    return SliverAppBar(
      expandedHeight: isMobile ? 100 : 140.0,
      pinned: true,
      backgroundColor: roleColor,
      elevation: 0,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
                'PARENT PORTAL',
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
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: roleColor),
            Positioned(
              right: -30,
              bottom: -20,
              child: Icon(
                Icons.hub_rounded,
                size: isMobile ? 120 : 180,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, DT dt) {
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
          text,
          style: TextStyle(
            fontSize: isMobile ? 9 : 10,
            fontWeight: FontWeight.w900,
            color: dt.textSecondary,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(DT dt) {
    final roleColor = RoleColors.of(_roleId);
    final isMobile = context.sw < 600;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.diversity_3_rounded,
            size: isMobile ? 60 : 80,
            color: dt.iconInactive,
          ),
          const SizedBox(height: 24),
          Text(
            'NO LINKED STUDENTS',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: dt.textMuted,
              letterSpacing: 3,
              fontSize: isMobile ? 11 : 13,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 0),
            child: Text(
              'Link your account at the school office.',
              style: TextStyle(
                color: dt.textMuted,
                fontSize: isMobile ? 10 : 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: isMobile ? 8 : 12,
            ),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: roleColor.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.support_agent_rounded, color: roleColor, size: isMobile ? 16 : 20),
                const SizedBox(width: 8),
                Text(
                  'CONTACT ADMIN',
                  style: TextStyle(
                    fontSize: isMobile ? 9 : 10,
                    fontWeight: FontWeight.w900,
                    color: roleColor,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}