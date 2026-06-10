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
import '../common/student_management_screen.dart';
import '../settings/settings_screen.dart';
import '../../app_theme.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  late String teacherId;
  late String teacherName;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _todayLessons = [];
  List<Map<String, dynamic>> _announcements = [];
  bool isLoading = true;
  StreamSubscription? _notifSub;

  String selectedGrade = 'Grade 1';
  String selectedStream = 'North';

  @override
  void initState() {
    super.initState();
    final auth = AuthenticationService();
    teacherId = auth.currentUserPhone ?? "teacher";
    teacherName = auth.currentUserName;
    _loadDashboardData();
    _setupNotifications();
  }

  void _setupNotifications() {
    _notifSub = SupabaseService.instance.notificationStream.listen((data) {
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    
    try {
      // Fetch all data from Supabase Cloud
      final stats = await SupabaseService.instance.getTeacherDashboardStats(teacherId, selectedGrade, selectedStream);
      final schedule = await SupabaseService.instance.getTeacherSchedule(teacherId);
      final announcements = await SupabaseService.instance.getNotifications('Teacher');
      
      if (mounted) {
        setState(() {
          _stats = stats;
          _todayLessons = schedule;
          _announcements = announcements;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Cloud Sync Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: _buildTeacherDrawer(context, theme),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: CustomScrollView(
                slivers: [
                  _buildHeroAppBar(theme, gemini),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildSummaryStats(theme),
                          const SizedBox(height: 30),
                          _buildSectionLabel(theme, 'TODAY\'S LESSONS'),
                          _buildLessonsList(),
                          const SizedBox(height: 30),
                          _buildSectionLabel(theme, 'CLASSROOM MANAGEMENT'),
                          const SizedBox(height: 16),
                          _buildActionMosaic(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildHeroAppBar(ThemeData theme, GeminiThemeExtension? gemini) {
    return SliverAppBar(
      expandedHeight: 120.0,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('Welcome, $teacherName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        background: Container(
          decoration: BoxDecoration(
            gradient: gemini?.primaryGradient ?? const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStats(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem('Pupils', _stats['totalStudents']?.toString() ?? '0', Colors.blue),
          _statItem('Attendance', '${(_stats['attendanceRate'] as num?)?.toStringAsFixed(1) ?? "0.0"}%', Colors.green),
          _statItem('Tasks', _stats['pendingAssignments']?.toString() ?? '0', Colors.orange),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildLessonsList() {
    if (_todayLessons.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('Schedule is clear.'));
    return Column(
      children: _todayLessons.map((l) => Card(
        child: ListTile(
          leading: const Icon(Icons.timer),
          title: Text(l['subject'] ?? 'Lesson'),
          subtitle: Text('${l['time_slot'] ?? ''} - ${l['grade'] ?? ''}'),
        ),
      )).toList(),
    );
  }

  Widget _buildActionMosaic() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _toolItem('Attendance', Icons.how_to_reg, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceModule(grade: selectedGrade, stream: selectedStream)))),
        _toolItem('Marks', Icons.grade, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => MarksEntryScreen(grade: selectedGrade, stream: selectedStream, subject: 'Mathematics')))),
        _toolItem('Students', Icons.people, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentManagementScreen(role: 'teacher')))),
        _toolItem('Homework', Icons.book, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => HomeworkModule(grade: selectedGrade, stream: selectedStream, subject: 'Mathematics')))),
        _toolItem('Resources', Icons.cloud_upload, Colors.brown, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResourcesScreen()))),
        _toolItem('Reports', Icons.assessment, Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsGeneratorScreen(grade: selectedGrade, stream: selectedStream)))),
      ],
    );
  }

  Widget _toolItem(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }

  Widget _buildTeacherDrawer(BuildContext context, ThemeData theme) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(decoration: BoxDecoration(color: theme.primaryColor), child: const Text('Kagema School', style: TextStyle(color: Colors.white, fontSize: 20))),
          ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(role: 'teacher')))),
          ListTile(leading: const Icon(Icons.logout), title: const Text('Logout'), onTap: () => Navigator.pushReplacementNamed(context, '/login')),
        ],
      ),
    );
  }
}
