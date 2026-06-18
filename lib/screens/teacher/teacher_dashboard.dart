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

  // Role Theme Color - Premium Deep Orange
  final Color primaryAccent = const Color(0xFFFF5722); 
  final Color slateDark = const Color(0xFF1E293B);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gemini = Theme.of(context).extension<GeminiThemeExtension>();
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F8),
      body: gemini?.buildCreativeBackground(
        isDark: isDark,
        maxWidth: screenWidth,
        child: Stack(
          children: [
            _currentIndex == 0 ? _buildHomeTab(screenWidth) : _buildOperationsTab(screenWidth),
            _buildBottomNav(screenWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab(double screenWidth) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: primaryAccent,
      edgeOffset: 120,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildPremiumHeader('TEACHER HUB', Icons.hub_rounded),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null) _buildErrorBanner(),
                  _buildSummaryMetrics(),
                  const SizedBox(height: 40),
                  _buildSectionHeader('DAILY SCHEDULE'),
                  const SizedBox(height: 20),
                  _buildLessonsList(),
                  const SizedBox(height: 40),
                  _buildSectionHeader('PRIORITY ACTIONS'),
                  const SizedBox(height: 20),
                  _buildQuickActions(),
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(String title, IconData icon) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFFF1F3F8),
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
                color: Color(0xFF1E293B),
              )
            ),
            const SizedBox(height: 4),
            Container(
              height: 2, width: 40,
              decoration: BoxDecoration(color: primaryAccent, borderRadius: BorderRadius.circular(1)),
            )
          ],
        ),
        background: Center(
          child: Opacity(
            opacity: 0.03,
            child: Icon(icon, size: 200, color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryMetrics() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(45),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 40, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _metricItem('PUPILS', '${_stats['totalStudents'] ?? 0}', const Color(0xFF2563EB)),
          _vDivider(),
          _metricItem('ATTENDANCE', '${(_stats['attendanceRate'] as num?)?.toStringAsFixed(0) ?? "0"}%', const Color(0xFF10B981)),
          _vDivider(),
          _metricItem('TASKS', '${_stats['pendingAssignments'] ?? 0}', const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _metricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: color, letterSpacing: -1)
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.5)),
      ],
    );
  }

  Widget _vDivider() => Container(width: 1, height: 35, color: const Color(0xFFE2E8F0));

  Widget _buildLessonsList() {
    if (isLoading && _todayLessons.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_todayLessons.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(50),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(child: Text('NO LESSONS SCHEDULED', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), fontSize: 10, letterSpacing: 2))),
      );
    }
    
    return Column(
      children: _todayLessons.map((l) => _buildLessonTile(l)).toList(),
    );
  }

  Widget _buildLessonTile(Map<String, dynamic> l) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12), 
          decoration: BoxDecoration(color: primaryAccent.withValues(alpha: 0.08), shape: BoxShape.circle), 
          child: Icon(Icons.timer_rounded, color: primaryAccent, size: 22)
        ),
        title: Text(l['subject']?.toString().toUpperCase() ?? 'SUBJECT', 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B), letterSpacing: 0.5)
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${l['start_time']} - ${l['end_time']} | ${l['grade']}', 
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B))
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 24, color: Color(0xFFE2E8F0)),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _actionCard('ROLL CALL', Icons.how_to_reg_rounded, const Color(0xFF10B981), () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceModule(initialGrade: selectedGrade, initialStream: selectedStream)))),
        const SizedBox(width: 20),
        _actionCard('MARKS ENTRY', Icons.grade_rounded, const Color(0xFFF59E0B), () => Navigator.push(context, MaterialPageRoute(builder: (_) => MarksEntryScreen(grade: selectedGrade, stream: selectedStream, subject: 'Mathematics')))),
      ],
    );
  }

  Widget _actionCard(String title, IconData icon, Color accent, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 35),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: Icon(icon, color: accent, size: 35),
              ),
              const SizedBox(height: 18),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 10, letterSpacing: 1.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOperationsTab(double screenWidth) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildPremiumHeader('OPERATIONS', Icons.grid_view_rounded),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionHeader('ACADEMIC MANAGEMENT'),
              const SizedBox(height: 16),
              _opTile('Attendance Register', 'Daily student tracking', Icons.how_to_reg_rounded, const Color(0xFF10B981), () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceModule(initialGrade: selectedGrade, initialStream: selectedStream)))),
              _opTile('Marks & Assessments', 'CBC entry & scoring', Icons.grade_rounded, const Color(0xFFF59E0B), () => Navigator.push(context, MaterialPageRoute(builder: (_) => MarksEntryScreen(grade: selectedGrade, stream: selectedStream, subject: 'Mathematics')))),
              _opTile('Exam Control', 'Manage tests', Icons.quiz_rounded, const Color(0xFFEF4444), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamManagerScreen()))),
              _opTile('My Timetable', 'Teaching schedule', Icons.calendar_view_week_rounded, const Color(0xFF6366F1), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimetableViewer()))),
              const SizedBox(height: 32),
              _buildSectionHeader('STUDENT ECOSYSTEM'),
              const SizedBox(height: 16),
              _opTile('Pupil Profiles', 'Bio & parent details', Icons.badge_rounded, const Color(0xFF0EA5E9), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentManagementScreen(role: 'teacher')))),
              _opTile('Progress Analytics', 'Performance trends', Icons.trending_up_rounded, const Color(0xFF8B5CF6), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentProgressScreen()))),
              _opTile('Behavior Logs', 'Discipline logs', Icons.gavel_rounded, const Color(0xFFD946EF), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BehaviorTrackingScreen()))),
              const SizedBox(height: 140),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _opTile(String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 5)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B))),
                    const SizedBox(height: 2),
                    Text(sub.toUpperCase(), style: const TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFE2E8F0), size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(double screenWidth) {
    return Positioned(
      bottom: 25, left: 0, right: 0,
      child: Center(
        child: Container(
          width: screenWidth - 48,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 10)),
            ],
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(0, Icons.grid_view_rounded, 'HUB'),
              _navItem(1, Icons.explore_rounded, 'TOOLS'),
              _navItem(2, Icons.settings_rounded, 'SETUP'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
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
            Icon(icon, color: isSelected ? primaryAccent : const Color(0xFF94A3B8), size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isSelected ? primaryAccent : const Color(0xFF94A3B8), letterSpacing: 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: primaryAccent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 3, color: Color(0xFF475569)),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBE8), 
        borderRadius: BorderRadius.circular(30), 
        border: Border.all(color: const Color(0xFFFFCCBC))
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFD84315)),
          const SizedBox(width: 16),
          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFBF360C), fontSize: 11, fontWeight: FontWeight.w900))),
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Color(0xFFD84315), size: 22), onPressed: _loadDashboardData),
        ],
      ),
    );
  }
}
