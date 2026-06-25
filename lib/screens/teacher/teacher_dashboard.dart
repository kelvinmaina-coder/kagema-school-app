import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/supabase_service.dart';
import '../../services/authentication_service.dart';
import 'marks_entry.dart';
import 'attendance_module.dart';
import 'timetable_viewer.dart';
import 'student_progress_screen.dart';
import 'behavior_tracking_screen.dart';
import 'exam_manager_screen.dart';
import '../common/student_management_screen.dart';
import '../settings/settings_screen.dart';
import '../../app_theme.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentIndex = 0;
  late String teacherId;
  late String teacherName;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _todayLessons = [];
  bool isLoading = true;
  String? _errorMessage;

  String selectedGrade = 'Grade 1';
  String selectedStream = 'North';

  final String _roleId = 'teacher';

  @override
  void initState() {
    super.initState();
    final auth = AuthenticationService();
    teacherId = auth.currentUserPhone ?? "teacher";
    teacherName = auth.currentUserName;
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        SupabaseService.instance.getTeacherDashboardStats(teacherId, selectedGrade, selectedStream),
        SupabaseService.instance.getTeacherSchedule(teacherId),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, dynamic>;
          _todayLessons = results[1] as List<Map<String, dynamic>>;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Teacher Sync Error: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          _errorMessage = "Cloud Sync Error. Swipe down to refresh.";
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

    return Scaffold(
      backgroundColor: dt.pageBg,
      body: theme?.buildCreativeBackground(
        isDark: context.isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
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
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildHomeTab(DT dt, GeminiThemeExtension? theme) {
    final roleColor = RoleColors.of(_roleId);
    final greeter = TimeGreeter.now;
    final isMobile = context.sw < 600;
    final isTablet = context.sw >= 600 && context.sw < 1200;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: roleColor,
      edgeOffset: 120,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildPremiumHeader(greeter.greet(teacherName.split(' ')[0]), Icons.hub_rounded, dt),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : (isTablet ? 24 : 40),
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
                          '${greeter.greet(teacherName.split(' ')[0])} ðŸ‘‹',
                          style: TextStyle(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: dt.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildSummaryMetrics(dt, theme),
                  SizedBox(height: isMobile ? 24 : 40),
                  _buildSectionHeader('DAILY SCHEDULE', dt),
                  SizedBox(height: isMobile ? 12 : 20),
                  _buildLessonsList(dt, theme),
                  SizedBox(height: isMobile ? 24 : 40),
                  _buildSectionHeader('PRIORITY ACTIONS', dt),
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

  Widget _buildSummaryMetrics(DT dt, GeminiThemeExtension? theme) {
    final roleColor = RoleColors.of(_roleId);
    final isMobile = context.sw < 600;

    return theme?.buildGlowContainer(
      accentColor: roleColor,
      accentColor2: RoleColors.complement(_roleId),
      borderRadius: isMobile ? 28 : 45,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 20 : 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _metricItem('PUPILS', '${_stats['totalStudents'] ?? 0}', KagemaColors.azure, dt, isMobile),
          _vDivider(dt),
          _metricItem('ATTENDANCE', '${(_stats['attendanceRate'] as num?)?.toStringAsFixed(0) ?? "0"}%', KagemaColors.teacherGreen, dt, isMobile),
          _vDivider(dt),
          _metricItem('TASKS', '${_stats['pendingAssignments'] ?? 0}', KagemaColors.accountantAmber, dt, isMobile),
        ],
      ),
    ) ?? const SizedBox.shrink();
  }

  Widget _metricItem(String label, String value, Color color, DT dt, bool isMobile) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 4 : 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            label == 'PUPILS' ? Icons.people_rounded :
            label == 'ATTENDANCE' ? Icons.calendar_today_rounded :
            Icons.assignment_rounded,
            color: color,
            size: isMobile ? 16 : 20,
          ),
        ),
        SizedBox(height: isMobile ? 4 : 6),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: isMobile ? 22 : 26,
            color: color,
            letterSpacing: -1,
          ),
        ),
        SizedBox(height: isMobile ? 2 : 6),
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
    );
  }

  Widget _vDivider(DT dt) => Container(width: 1, height: 35, color: dt.divider);

  Widget _buildLessonsList(DT dt, GeminiThemeExtension? theme) {
    final isMobile = context.sw < 600;

    if (isLoading && _todayLessons.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(
            color: RoleColors.of(_roleId),
          ),
        ),
      );
    }

    if (_todayLessons.isEmpty) {
      return theme?.buildGlowContainer(
        accentColor: RoleColors.of(_roleId),
        borderRadius: isMobile ? 24 : 40,
        padding: EdgeInsets.all(isMobile ? 30 : 50),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: isMobile ? 36 : 50,
              color: dt.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'NO LESSONS SCHEDULED',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: dt.textMuted,
                fontSize: isMobile ? 9 : 10,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ) ?? const SizedBox.shrink();
    }

    return Column(
      children: _todayLessons.map((l) => _buildLessonTile(l, dt, theme)).toList(),
    );
  }

  Widget _buildLessonTile(Map<String, dynamic> l, DT dt, GeminiThemeExtension? theme) {
    final roleColor = RoleColors.of(_roleId);
    final isMobile = context.sw < 600;

    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      child: theme?.buildGlowContainer(
        accentColor: roleColor,
        borderRadius: isMobile ? 20 : 30,
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: isMobile ? 8 : 12,
          ),
          leading: Container(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            decoration: BoxDecoration(
              color: dt.roleSoftBg(roleColor),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.timer_rounded,
              color: roleColor,
              size: isMobile ? 18 : 22,
            ),
          ),
          title: Text(
            l['subject']?.toString().toUpperCase() ?? 'SUBJECT',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: isMobile ? 13 : 14,
              color: dt.textPrimary,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${l['start_time']} - ${l['end_time']} | ${l['grade']}',
              style: TextStyle(
                fontSize: isMobile ? 9 : 10,
                fontWeight: FontWeight.w800,
                color: dt.textSecondary,
              ),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: roleColor.withOpacity(0.2)),
            ),
            child: Text(
              'NOW',
              style: TextStyle(
                fontSize: isMobile ? 7 : 8,
                fontWeight: FontWeight.w800,
                color: roleColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildQuickActions(DT dt, GeminiThemeExtension? theme) {
    final isMobile = context.sw < 600;

    final actions = [
      {
        'title': 'ROLL CALL',
        'icon': Icons.how_to_reg_rounded,
        'color': KagemaColors.teacherGreen,
        'route': AttendanceModule(initialGrade: selectedGrade, initialStream: selectedStream),
      },
      {
        'title': 'MARKS ENTRY',
        'icon': Icons.grade_rounded,
        'color': KagemaColors.accountantAmber,
        'route': MarksEntryScreen(grade: selectedGrade, stream: selectedStream, subject: 'Mathematics'),
      },
    ];

    if (!isMobile) {
      actions.addAll([
        {
          'title': 'EXAM CONTROL',
          'icon': Icons.quiz_rounded,
          'color': KagemaColors.parentRed,
          'route': const ExamManagerScreen(),
        },
        {
          'title': 'TIMETABLE',
          'icon': Icons.calendar_view_week_rounded,
          'color': KagemaColors.secretaryViolet,
          'route': const TimetableViewer(),
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
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
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

  Widget _actionCard(String title, IconData icon, Color accent, DT dt, GeminiThemeExtension? theme, VoidCallback onTap) {
    final isMobile = context.sw < 600;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: isMobile ? 8 : 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isMobile ? 24 : 40),
          child: theme?.buildGlowContainer(
            accentColor: accent,
            accentColor2: RoleColors.complement(_roleId),
            borderRadius: isMobile ? 24 : 40,
            padding: EdgeInsets.symmetric(vertical: isMobile ? 24 : 35),
            child: Column(
              children: [
                RolePlasma(
                  color: accent,
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 14 : 18),
                    decoration: BoxDecoration(
                      color: dt.roleSoftBg(accent),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: accent,
                      size: isMobile ? 28 : 35,
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 18),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: dt.textPrimary,
                    fontSize: isMobile ? 9 : 10,
                    letterSpacing: 1.5,
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
          ) ?? const SizedBox.shrink(),
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
            horizontal: isMobile ? 16 : (context.sw < 900 ? 24 : 40),
            vertical: isMobile ? 16 : 24,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionHeader('ACADEMIC MANAGEMENT', dt),
              SizedBox(height: isMobile ? 12 : 16),
              _opTile(
                'Attendance Register',
                'Daily student tracking',
                Icons.how_to_reg_rounded,
                KagemaColors.teacherGreen,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AttendanceModule(initialGrade: selectedGrade, initialStream: selectedStream))
                ),
              ),
              _opTile(
                'Marks & Assessments',
                'CBC entry & scoring',
                Icons.grade_rounded,
                KagemaColors.accountantAmber,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MarksEntryScreen(grade: selectedGrade, stream: selectedStream, subject: 'Mathematics'))
                ),
              ),
              _opTile(
                'Exam Control',
                'Manage tests',
                Icons.quiz_rounded,
                KagemaColors.parentRed,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExamManagerScreen())
                ),
              ),
              _opTile(
                'My Timetable',
                'Teaching schedule',
                Icons.calendar_view_week_rounded,
                KagemaColors.secretaryViolet,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TimetableViewer())
                ),
              ),
              SizedBox(height: isMobile ? 20 : 32),
              _buildSectionHeader('STUDENT ECOSYSTEM', dt),
              SizedBox(height: isMobile ? 12 : 16),
              _opTile(
                'Pupil Profiles',
                'Bio & parent details',
                Icons.badge_rounded,
                KagemaColors.staffSky,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentManagementScreen(role: 'teacher'))
                ),
              ),
              _opTile(
                'Progress Analytics',
                'Performance trends',
                Icons.trending_up_rounded,
                KagemaColors.secretaryViolet,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentProgressScreen())
                ),
              ),
              _opTile(
                'Behavior Logs',
                'Discipline logs',
                Icons.gavel_rounded,
                KagemaColors.parentRed,
                dt,
                theme,
                    () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BehaviorTrackingScreen())
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
      padding: EdgeInsets.only(bottom: isMobile ? 10 : 16),
      child: theme?.buildGlowContainer(
        accentColor: color,
        borderRadius: isMobile ? 20 : 30,
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isMobile ? 20 : 30),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
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
                SizedBox(width: isMobile ? 12 : 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          fontSize: isMobile ? 8 : 8.5,
                          color: dt.textMuted,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: dt.iconInactive,
                  size: isMobile ? 20 : 24,
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

    final screenWidth = MediaQuery.of(context).size.width;
    double navWidth = context.fluid(screenWidth - 48, 500);
    double navHeight = isMobile ? 60 : 80;

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
            borderRadius: BorderRadius.circular(isMobile ? 28 : 40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: dt.cardBorder, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(0, Icons.grid_view_rounded, 'HUB', dt),
              _navItem(1, Icons.explore_rounded, 'TOOLS', dt),
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
              MaterialPageRoute(builder: (_) => const SettingsScreen(role: 'Teacher'))
          );
          return;
        }
        setState(() => _currentIndex = index);
      },
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 20,
          vertical: isMobile ? 4 : 0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : dt.iconInactive,
              size: isMobile ? 24 : 28,
            ),
            SizedBox(height: isMobile ? 4 : 6),
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 8 : 9,
                fontWeight: FontWeight.w900,
                color: isSelected ? activeColor : dt.iconInactive,
                letterSpacing: 2,
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
            fontSize: isMobile ? 9 : 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
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
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: dt.roleSoftBg(KagemaColors.parentRed),
        borderRadius: BorderRadius.circular(isMobile ? 20 : 30),
        border: Border.all(color: KagemaColors.parentRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: KagemaColors.parentRed, size: isMobile ? 18 : 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: KagemaColors.parentRed,
                fontSize: isMobile ? 10 : 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (!isMobile)
            IconButton(
              onPressed: _loadDashboardData,
              icon: Icon(Icons.refresh_rounded, color: KagemaColors.parentRed),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              iconSize: isMobile ? 18 : 22,
            ),
        ],
      ),
    );
  }
}