import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/supabase_service.dart';
import '../../services/authentication_service.dart';
import 'marks_entry.dart';
import 'attendance_module.dart';
import 'resources_screen.dart';
import 'timetable_viewer.dart';
import 'reports_generator.dart';
import 'homework_module.dart';
import 'student_progress_screen.dart';
import 'behavior_tracking_screen.dart';
import 'exam_manager_screen.dart';
import 'parent_contact_list.dart';
import 'co_curricular_screen.dart';
import 'lesson_planning_screen.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _currentIndex == 0 ? _buildHomeTab(theme, gemini) : _buildOperationsTab(theme, gemini),
      ) ?? (_currentIndex == 0 ? _buildHomeTab(theme, null) : _buildOperationsTab(theme, null)),
      bottomNavigationBar: _buildModernNavBar(theme, gemini),
    );
  }

  Widget _buildHomeTab(ThemeData theme, GeminiThemeExtension? gemini) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: CustomScrollView(
        slivers: [
          _buildHeroAppBar(theme, gemini, 'TEACHER HUB'),
          if (_errorMessage != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                    IconButton(icon: const Icon(Icons.refresh, color: Colors.red, size: 20), onPressed: _loadDashboardData),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildSummaryStats(theme, gemini),
                  const SizedBox(height: 32),
                  _buildSectionLabel('TODAY\'S LESSONS'),
                  _buildLessonsList(theme, gemini),
                  const SizedBox(height: 32),
                  _buildSectionLabel('QUICK CLASS ACTIONS'),
                  _buildQuickActions(theme, gemini),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsTab(ThemeData theme, GeminiThemeExtension? gemini) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 120),
      children: [
        _buildSectionLabel('ACADEMIC MANAGEMENT'),
        _operationTile(theme, 'Attendance Register', 'Daily student tracking', Icons.how_to_reg_rounded, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceModule(grade: selectedGrade, stream: selectedStream)))),
        _operationTile(theme, 'Marks & CBC Levels', 'Assessment entry', Icons.grade_rounded, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => MarksEntryScreen(grade: selectedGrade, stream: selectedStream, subject: 'Mathematics')))),
        _operationTile(theme, 'Exam Center', 'Schedule & manage tests', Icons.quiz_rounded, Colors.deepOrange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamManagerScreen()))),
        _operationTile(theme, 'Timetable', 'My teaching schedule', Icons.calendar_view_week_rounded, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimetableViewer()))),
        const SizedBox(height: 24),
        _buildSectionLabel('STUDENT SERVICES'),
        _operationTile(theme, 'Student Profiles', 'Detailed pupil information', Icons.badge_rounded, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentManagementScreen(role: 'teacher')))),
        _operationTile(theme, 'Progress Analysis', 'Performance trends', Icons.trending_up_rounded, Colors.cyan, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentProgressScreen()))),
        _operationTile(theme, 'Behavior Log', 'Incidents & discipline', Icons.gavel_rounded, Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BehaviorTrackingScreen()))),
        const SizedBox(height: 24),
        _buildSectionLabel('CLASSROOM RESOURCES'),
        _operationTile(theme, 'Homework Portal', 'Assign & review tasks', Icons.book_rounded, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => HomeworkModule(grade: selectedGrade, stream: selectedStream, subject: 'Mathematics')))),
        _operationTile(theme, 'Cloud Materials', 'Notes & digital files', Icons.cloud_upload_rounded, Colors.brown, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResourcesScreen()))),
        _operationTile(theme, 'Lesson Planning', 'Curriculum alignment', Icons.event_note_rounded, Colors.pink, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LessonPlanningScreen()))),
        const SizedBox(height: 24),
        _buildSectionLabel('COMMUNICATION & OTHERS'),
        _operationTile(theme, 'Parent Contacts', 'Call or message guardians', Icons.contact_phone_rounded, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ParentContactList(grade: selectedGrade, stream: selectedStream)))),
        _operationTile(theme, 'Co-Curricular', 'Clubs & sports activities', Icons.sports_soccer_rounded, Colors.amber, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoCurricularScreen()))),
        _operationTile(theme, 'Reports Gen', 'PDF Result slips & lists', Icons.picture_as_pdf_rounded, Colors.blueGrey, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsGeneratorScreen(grade: selectedGrade, stream: selectedStream)))),
      ],
    );
  }

  Widget _operationTile(ThemeData theme, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroAppBar(ThemeData theme, GeminiThemeExtension? gemini, String title) {
    return SliverAppBar(
      expandedHeight: 120.0,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2, color: Colors.white)),
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: gemini?.primaryGradient, 
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
            boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30, top: -10,
                child: Icon(Icons.school_rounded, size: 180, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStats(ThemeData theme, GeminiThemeExtension? gemini) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statItem('PUPILS', '${_stats['totalStudents'] ?? 0}', Colors.blue),
        _statItem('ATTENDANCE', '${(_stats['attendanceRate'] as num?)?.toStringAsFixed(1) ?? "0.0"}%', Colors.green),
        _statItem('TASKS', '${_stats['pendingAssignments'] ?? 0}', Colors.orange),
      ],
    );

    return gemini?.buildGlowContainer(
      borderRadius: 28,
      borderThickness: 2,
      backgroundColor: theme.cardColor.withOpacity(0.9),
      padding: const EdgeInsets.all(24),
      useAIBorder: true, // Apply AI Spectrum to main stats
      child: content,
    ) ?? Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.9), borderRadius: BorderRadius.circular(28)),
      child: content,
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildLessonsList(ThemeData theme, GeminiThemeExtension? gemini) {
    if (isLoading && _todayLessons.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_todayLessons.isEmpty) return Container(padding: const EdgeInsets.all(20), child: const Center(child: Text('No lessons for today.', style: TextStyle(color: Colors.grey, fontSize: 12))));
    
    return Column(
      children: _todayLessons.map((l) {
        final content = ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10), 
            decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle), 
            child: Icon(Icons.timer_outlined, color: theme.primaryColor, size: 20)
          ),
          title: Text(l['subject'] ?? 'Subject', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          subtitle: Text('${l['start_time']} - ${l['end_time']} | ${l['grade']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: theme.dividerColor.withOpacity(0.05)),
          ),
          child: content,
        );
      }).toList(),
    );
  }

  Widget _buildQuickActions(ThemeData theme, GeminiThemeExtension? gemini) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _quickCard(theme, gemini, 'ATTENDANCE', Icons.how_to_reg, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceModule(grade: selectedGrade, stream: selectedStream)))),
        _quickCard(theme, gemini, 'MARKS', Icons.grade, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => MarksEntryScreen(grade: selectedGrade, stream: selectedStream, subject: 'Mathematics')))),
      ],
    );
  }

  Widget _quickCard(ThemeData theme, GeminiThemeExtension? gemini, String title, IconData icon, Color color, VoidCallback onTap) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center, 
      children: [
        Icon(icon, color: color, size: 30), 
        const SizedBox(height: 10), 
        Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 10, letterSpacing: 1.5))
      ]
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: gemini?.buildGlowContainer(
        borderRadius: 24,
        borderThickness: 1.5,
        backgroundColor: color.withOpacity(0.08),
        padding: const EdgeInsets.all(12),
        useAIBorder: false, // Keep it simple here
        child: content,
      ) ?? Container(
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withOpacity(0.1))),
        child: content,
      ),
    );
  }

  Widget _buildModernNavBar(ThemeData theme, GeminiThemeExtension? gemini) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      height: 70,
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, spreadRadius: -10)],
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(0, Icons.home_rounded, 'Overview'),
          _navItem(1, Icons.grid_view_rounded, 'Operations'),
          _navItem(2, Icons.settings_rounded, 'Settings'),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        if (index == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(role: 'Teacher')));
          return;
        }
        setState(() => _currentIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected ? BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)) : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isSelected ? Theme.of(context).primaryColor : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12.0),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.blueGrey)),
    );
  }
}
