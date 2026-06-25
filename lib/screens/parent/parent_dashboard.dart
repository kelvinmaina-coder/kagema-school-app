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
                horizontal: context.fluid(20, 40), 
                vertical: 32
              ),
              child: children.isEmpty 
                ? _buildEmptyState(dt)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24, left: 4),
                        child: Text(greeter.tailline.toUpperCase(), 
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2.5)
                        ),
                      ),
                      _buildChildSelector(dt),
                      const SizedBox(height: 40),
                      _buildSectionLabel('INTELLIGENT INSIGHTS', dt),
                      const SizedBox(height: 16),
                      _buildVitalsRow(dt, theme, screenWidth),
                      const SizedBox(height: 40),
                      _buildSectionLabel('STUDENT SERVICES', dt),
                      const SizedBox(height: 16),
                      _buildServiceGrid(dt, theme, screenWidth),
                      const SizedBox(height: 140),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsRow(DT dt, GeminiThemeExtension? theme, double screenWidth) {
    if (screenWidth < 360) {
       return Column(
         children: [
           Row(children: [
             _vitalBox(dt, theme, 'ATTENDANCE', '${_attendancePercent.toInt()}%', KagemaColors.azure, true),
             const SizedBox(width: 12),
             _vitalBox(dt, theme, 'AVG SCORE', '${_avgGrade.toInt()}%', KagemaColors.accountantAmber, false),
           ]),
           const SizedBox(height: 12),
           _vitalBox(dt, theme, 'FEES DUE', 'KSH ${_feeBalance.toInt()}', _feeBalance > 0 ? KagemaColors.parentRed : KagemaColors.teacherGreen, false),
         ],
       );
    }
    
    return Row(
      children: [
        _vitalBox(dt, theme, 'ATTENDANCE', '${_attendancePercent.toInt()}%', KagemaColors.azure, true),
        const SizedBox(width: 12),
        _vitalBox(dt, theme, 'FEES DUE', 'KSH ${_feeBalance.toInt()}', _feeBalance > 0 ? KagemaColors.parentRed : KagemaColors.teacherGreen, false),
        const SizedBox(width: 12),
        _vitalBox(dt, theme, 'AVG SCORE', '${_avgGrade.toInt()}%', KagemaColors.accountantAmber, false),
      ],
    );
  }

  Widget _vitalBox(DT dt, GeminiThemeExtension? theme, String label, String value, Color color, bool useAIBorder) {
    return Expanded(
      flex: 1,
      child: theme?.buildGlowContainer(
        accentColor: color,
        accentColor2: RoleColors.complement(_roleId),
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        useAIBorder: useAIBorder, 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, 
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)
            ), 
            const SizedBox(height: 6), 
            Text(label, 
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 1.5)
            )
          ]
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildServiceGrid(DT dt, GeminiThemeExtension? theme, double screenWidth) {
    int crossAxisCount = context.isTablet || context.isDesktop ? 4 : 2;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _serviceCard(dt, theme, 'ROLL CALL', Icons.event_available_rounded, KagemaColors.azure, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildAttendanceScreen(student: selectedChild!)))),
        _serviceCard(dt, theme, 'PERFORMANCE', Icons.auto_graph_rounded, KagemaColors.accountantAmber, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildPerformanceScreen(student: selectedChild!)))),
        _serviceCard(dt, theme, 'FEE PORTAL', Icons.account_balance_wallet_rounded, KagemaColors.teacherGreen, () => Navigator.push(context, MaterialPageRoute(builder: (_) => FeesPaymentScreen(student: selectedChild!)))),
        _serviceCard(dt, theme, 'HOMEWORK', Icons.assignment_rounded, KagemaColors.secretaryViolet, () => Navigator.push(context, MaterialPageRoute(builder: (_) => HomeworkScreen(grade: selectedChild!.grade, stream: selectedChild!.stream)))),
        _serviceCard(dt, theme, 'TIMETABLE', Icons.calendar_view_week_rounded, KagemaColors.staffSky, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildTimetableScreen(student: selectedChild!)))),
        _serviceCard(dt, theme, 'LIBRARY', Icons.local_library_rounded, dt.textSecondary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildLibraryScreen(student: selectedChild!)))),
        _serviceCard(dt, theme, 'CONDUCT', Icons.gavel_rounded, KagemaColors.parentRed, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildDisciplineScreen(student: selectedChild!)))),
        _serviceCard(dt, theme, 'CALENDAR', Icons.event_note_rounded, KagemaColors.electric, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentCalendarScreen()))),
      ],
    );
  }

  Widget _serviceCard(DT dt, GeminiThemeExtension? theme, String title, IconData icon, Color color, VoidCallback onTap) {
    return theme?.buildGlowContainer(
      accentColor: color,
      borderRadius: 28,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: dt.roleSoftBg(color),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ), 
            const SizedBox(height: 12), 
            Text(title, 
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1.5, color: dt.textPrimary)
            )
          ]
        ),
      ),
    ) ?? const SizedBox.shrink();
  }

  Widget _buildModernNavBar(DT dt, double screenWidth) {
    double navWidth = context.fluid(context.sw - 40, 500);

    return Center(
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 25),
        width: navWidth,
        height: 75,
        decoration: BoxDecoration(
          color: dt.cardBg.withOpacity(0.95), 
          borderRadius: BorderRadius.circular(30), 
          border: Border.all(color: dt.cardBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10))
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
    
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          AnimatedContainer(
            duration: KagemaMotion.normal,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? dt.roleSoftBg(color) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 26),
          ), 
          const SizedBox(height: 4),
          Text(label, 
            style: TextStyle(
              fontSize: 8, 
              fontWeight: FontWeight.w900, 
              color: color,
              letterSpacing: 1
            )
          )
        ]
      ),
    );
  }

  Widget _buildChildSelector(DT dt) {
    if (children.isEmpty) return const SizedBox.shrink();
    final roleColor = RoleColors.of(_roleId);

    return LiquidGlassCard(
      accentColor: roleColor,
      borderRadius: 30, 
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4), 
      useAIBorder: true,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: roleColor, width: 2),
            ),
            child: CircleAvatar(
              radius: 18, 
              backgroundColor: dt.roleSoftBg(roleColor), 
              child: Text(selectedChild?.name[0].toUpperCase() ?? '?',
                style: TextStyle(color: roleColor, fontWeight: FontWeight.bold)
              )
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Student>(
                value: selectedChild,
                isExpanded: true,
                dropdownColor: dt.cardBg,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: roleColor),
                items: children.map((c) => DropdownMenuItem(
                  value: c, 
                  child: Text(c.name.toUpperCase(), 
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: dt.textPrimary, letterSpacing: 1)
                  )
                )).toList(),
                onChanged: (v) { if (v != null) { setState(() => selectedChild = v); _loadChildVitals(); } },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroAppBar(DT dt) {
    final roleColor = RoleColors.of(_roleId);
    return SliverAppBar(
      expandedHeight: 140.0, 
      pinned: true, 
      backgroundColor: roleColor, 
      elevation: 0,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text('PARENT PORTAL', 
          style: const TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 16, 
            letterSpacing: 4, 
            color: Colors.white,
          )
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: roleColor),
            Positioned(
              right: -30, 
              bottom: -20, 
              child: Icon(Icons.hub_rounded, size: 180, color: Colors.white.withOpacity(0.05))
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, DT dt) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: RoleColors.of(_roleId), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(text, 
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textSecondary, letterSpacing: 3)
        ),
      ],
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 80), 
          Icon(Icons.diversity_3_rounded, size: 80, color: dt.iconInactive), 
          const SizedBox(height: 24), 
          Text('NO LINKED STUDENTS', 
            style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 3, fontSize: 13)
          ), 
          const SizedBox(height: 8), 
          Text('Link your account at the school office.', 
            style: TextStyle(color: dt.textMuted, fontSize: 11, fontWeight: FontWeight.bold)
          ),
        ]
      )
    );
  }
}
