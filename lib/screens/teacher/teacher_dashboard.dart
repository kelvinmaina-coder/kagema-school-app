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
                horizontal: context.fluid(20, 40), 
                vertical: 24
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null) _buildErrorBanner(dt),
                  
                  // Interactive Greeting Tailline
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24, left: 4),
                    child: Text(greeter.tailline.toUpperCase(), 
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2.5)
                    ),
                  ),

                  _buildSummaryMetrics(dt, theme),
                  const SizedBox(height: 40),
                  _buildSectionHeader('DAILY SCHEDULE', dt),
                  const SizedBox(height: 20),
                  _buildLessonsList(dt, theme),
                  const SizedBox(height: 40),
                  _buildSectionHeader('PRIORITY ACTIONS', dt),
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

  Widget _buildSummaryMetrics(DT dt, GeminiThemeExtension? theme) {
    return theme?.buildGlowContainer(
      accentColor: RoleColors.of(_roleId),
      accentColor2: RoleColors.complement(_roleId),
      borderRadius: 45,
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _metricItem('PUPILS', '${_stats['totalStudents'] ?? 0}', KagemaColors.azure, dt),
          _vDivider(dt),
          _metricItem('ATTENDANCE', '${(_stats['attendanceRate'] as num?)?.toStringAsFixed(0) ?? "0"}%', KagemaColors.teacherGreen, dt),
          _vDivider(dt),
          _metricItem('TASKS', '${_stats['pendingAssignments'] ?? 0}', KagemaColors.accountantAmber, dt),
        ],
      ),
    ) ?? const SizedBox.shrink();
  }

  Widget _metricItem(String label, String value, Color color, DT dt) {
    return Column(
      children: [
        Text(value, 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: color, letterSpacing: -1)
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _vDivider(DT dt) => Container(width: 1, height: 35, color: dt.divider);

  Widget _buildLessonsList(DT dt, GeminiThemeExtension? theme) {
    if (isLoading && _todayLessons.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_todayLessons.isEmpty) {
      return theme?.buildGlowContainer(
        accentColor: RoleColors.of(_roleId),
        borderRadius: 40,
        padding: const EdgeInsets.all(50),
        child: Center(child: Text('NO LESSONS SCHEDULED', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, fontSize: 10, letterSpacing: 2))),
      ) ?? const SizedBox.shrink();
    }
    
    return Column(
      children: _todayLessons.map((l) => _buildLessonTile(l, dt, theme)).toList(),
    );
  }

  Widget _buildLessonTile(Map<String, dynamic> l, DT dt, GeminiThemeExtension? theme) {
    final roleColor = RoleColors.of(_roleId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: theme?.buildGlowContainer(
        accentColor: roleColor,
        borderRadius: 30,
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          leading: Container(
            padding: const EdgeInsets.all(12), 
            decoration: BoxDecoration(color: dt.roleSoftBg(roleColor), shape: BoxShape.circle), 
            child: Icon(Icons.timer_rounded, color: roleColor, size: 22)
          ),
          title: Text(l['subject']?.toString().toUpperCase() ?? 'SUBJECT', 
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary, letterSpacing: 0.5)
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('${l['start_time']} - ${l['end_time']} | ${l['grade']}', 
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: dt.textSecondary)
            ),
          ),
          trailing: Icon(Icons.chevron_right_rounded, size: 24, color: dt.iconInactive),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildQuickActions(DT dt, GeminiThemeExtension? theme) {
    return Row(
      children: [
        _actionCard('ROLL CALL', Icons.how_to_reg_rounded, KagemaColors.teacherGreen, dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceModule(initialGrade: selectedGrade, initialStream: selectedStream)))),
        const SizedBox(width: 20),
        _actionCard('MARKS ENTRY', Icons.grade_rounded, KagemaColors.accountantAmber, dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => MarksEntryScreen(grade: selectedGrade, stream: selectedStream, subject: 'Mathematics')))),
      ],
    );
  }

  Widget _actionCard(String title, IconData icon, Color accent, DT dt, GeminiThemeExtension? theme, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: theme?.buildGlowContainer(
          accentColor: accent,
          accentColor2: RoleColors.complement(_roleId),
          borderRadius: 40,
          padding: const EdgeInsets.symmetric(vertical: 35),
          child: Column(
            children: [
              RolePlasma(
                color: accent,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: dt.roleSoftBg(accent), shape: BoxShape.circle),
                  child: Icon(icon, color: accent, size: 35),
                ),
              ),
              const SizedBox(height: 18),
              Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: dt.textPrimary, fontSize: 10, letterSpacing: 1.5)),
            ],
          ),
        ) ?? const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildOperationsTab(DT dt, GeminiThemeExtension? theme) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildPremiumHeader('OPERATIONS', Icons.grid_view_rounded, dt),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: context.fluid(20, 40), vertical: 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionHeader('ACADEMIC MANAGEMENT', dt),
              const SizedBox(height: 16),
              _opTile('Attendance Register', 'Daily student tracking', Icons.how_to_reg_rounded, KagemaColors.teacherGreen, dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceModule(initialGrade: selectedGrade, initialStream: selectedStream)))),
              _opTile('Marks & Assessments', 'CBC entry & scoring', Icons.grade_rounded, KagemaColors.accountantAmber, dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => MarksEntryScreen(grade: selectedGrade, stream: selectedStream, subject: 'Mathematics')))),
              _opTile('Exam Control', 'Manage tests', Icons.quiz_rounded, KagemaColors.parentRed, dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamManagerScreen()))),
              _opTile('My Timetable', 'Teaching schedule', Icons.calendar_view_week_rounded, KagemaColors.secretaryViolet, dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimetableViewer()))),
              const SizedBox(height: 32),
              _buildSectionHeader('STUDENT ECOSYSTEM', dt),
              const SizedBox(height: 16),
              _opTile('Pupil Profiles', 'Bio & parent details', Icons.badge_rounded, KagemaColors.staffSky, dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentManagementScreen(role: 'teacher')))),
              _opTile('Progress Analytics', 'Performance trends', Icons.trending_up_rounded, KagemaColors.secretaryViolet, dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentProgressScreen()))),
              _opTile('Behavior Logs', 'Discipline logs', Icons.gavel_rounded, KagemaColors.parentRed, dt, theme, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BehaviorTrackingScreen()))),
              const SizedBox(height: 140),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _opTile(String title, String sub, IconData icon, Color color, DT dt, GeminiThemeExtension? theme, VoidCallback onTap) {
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
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: dt.roleSoftBg(color), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary)),
                      const SizedBox(height: 2),
                      Text(sub.toUpperCase(), style: TextStyle(fontSize: 8.5, color: dt.textMuted, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: dt.iconInactive, size: 24),
              ],
            ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildBottomNav(DT dt) {
    final screenWidth = MediaQuery.of(context).size.width;
    double navWidth = context.fluid(screenWidth - 48, 500);

    return Positioned(
      bottom: 25, left: 0, right: 0,
      child: Center(
        child: Container(
          width: navWidth,
          height: 80,
          decoration: BoxDecoration(
            color: dt.cardBg.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 10)),
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
    return GestureDetector(
      onTap: () {
        if (index == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(role: 'Teacher')));
          return;
        }
        setState(() => _currentIndex = index);
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? activeColor : dt.iconInactive, size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isSelected ? activeColor : dt.iconInactive, letterSpacing: 2)),
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
        Text(
          title,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 3, color: dt.textSecondary),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(DT dt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dt.roleSoftBg(KagemaColors.parentRed), 
        borderRadius: BorderRadius.circular(30), 
        border: Border.all(color: KagemaColors.parentRed.withValues(alpha: 0.3))
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: KagemaColors.parentRed),
          const SizedBox(width: 16),
          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: KagemaColors.parentRed, fontSize: 11, fontWeight: FontWeight.w900))),
          IconButton(icon: const Icon(Icons.refresh_rounded, color: KagemaColors.parentRed, size: 22), onPressed: _loadDashboardData),
        ],
      ),
    );
  }
}
