import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../services/authentication_service.dart';
import '../../services/database_service.dart';
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
import '../common/communication_screen.dart';
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

  String? selectedGrade;
  String? selectedStream;
  List<String> myClasses = [];
  List<String> myStreams = [];

  @override
  void initState() {
    super.initState();
    final auth = AuthenticationService();
    // FIX: Using currentUserPhone from Auth service which supports bypass login
    teacherId = auth.currentUserPhone ?? "teacher";
    teacherName = auth.currentUserName;
    
    _loadTeacherProfile();
    _setupNotifications();
  }

  Future<void> _loadTeacherProfile() async {
    try {
      // Try local DB first (for bypass login consistency)
      final profile = await DatabaseService.instance.getStaffProfile(teacherId);

      if (profile != null && mounted) {
        String classesStr = profile['assignedClasses'] ?? '';
        List<String> parts = classesStr.split(',').where((e) => e.isNotEmpty).toList();
        if (parts.isNotEmpty) {
          setState(() {
            // Assuming format "Grade 1 North"
            myClasses = parts.map((e) {
              List<String> words = e.split(' ');
              return words.length >= 2 ? "${words[0]} ${words[1]}" : e;
            }).toSet().toList();
            
            myStreams = parts.map((e) => e.split(' ').last).toSet().toList();
            selectedGrade = myClasses.first;
            selectedStream = myStreams.first;
          });
        }
      }
      
      if (selectedGrade == null) {
        selectedGrade = 'Grade 1';
        selectedStream = 'North';
      }

      _loadDashboardData();
    } catch (e) {
      debugPrint("Profile load error: $e");
      if (mounted) {
        selectedGrade = 'Grade 1';
        selectedStream = 'North';
        _loadDashboardData();
      }
    }
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
      // 1. Fetch Teacher Stats (Cloud with fallback)
      final stats = await SupabaseService.instance.getTeacherDashboardStats(teacherId, selectedGrade!, selectedStream!);
      
      // 2. Fetch Schedule (Local for now to ensure speed)
      final schedule = await DatabaseService.instance.getTeacherSchedule(teacherId);
      
      // 3. Fetch Announcements
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
      debugPrint("TeacherDashboard Error: $e");
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
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildHeroAppBar(theme, gemini),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildClassSelector(theme),
                          const SizedBox(height: 20),
                          _buildSummaryStats(theme),
                          const SizedBox(height: 30),
                          _buildSectionLabel(theme, 'TODAY\'S LESSONS'),
                          const SizedBox(height: 12),
                          _buildLessonsList(theme),
                          const SizedBox(height: 30),
                          _buildSectionLabel(theme, 'SCHOOL ANNOUNCEMENTS'),
                          const SizedBox(height: 12),
                          _buildAnnouncementsList(theme),
                          const SizedBox(height: 30),
                          _buildSectionLabel(theme, 'CLASSROOM MANAGEMENT'),
                          const SizedBox(height: 16),
                          _buildActionMosaic(theme),
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
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Educator Hub', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        background: Container(
          decoration: BoxDecoration(
            gradient: gemini?.primaryGradient ?? LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)]),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
        ),
      ),
    );
  }

  Widget _buildClassSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.class_outlined, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedGrade,
                isExpanded: true,
                items: (myClasses.isEmpty ? ['Grade 1'] : myClasses).map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                onChanged: (v) {
                  setState(() => selectedGrade = v);
                  _loadDashboardData();
                },
              ),
            ),
          ),
          const VerticalDivider(),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedStream,
                isExpanded: true,
                items: (myStreams.isEmpty ? ['North'] : myStreams).map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                onChanged: (v) {
                  setState(() => selectedStream = v);
                  _loadDashboardData();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem('My Pupils', _stats['totalStudents']?.toString() ?? '0', Colors.blue),
          _statItem('Attendance', '${(_stats['attendanceRate'] as num?)?.toStringAsFixed(1) ?? "0.0"}%', Colors.green),
          _statItem('Pending', _stats['pendingAssignments']?.toString() ?? '0', Colors.orange),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLessonsList(ThemeData theme) {
    if (_todayLessons.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No lessons in schedule', style: TextStyle(color: Colors.grey, fontSize: 12))));
    return Column(
      children: _todayLessons.map((l) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.timer_outlined, color: Colors.blue),
          title: Text(l['subject'] ?? 'Duty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text('${l['time'] ?? ''} • ${l['grade'] ?? ''} ${l['stream'] ?? ''}'),
        ),
      )).toList(),
    );
  }

  Widget _buildAnnouncementsList(ThemeData theme) {
    if (_announcements.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No active announcements', style: TextStyle(color: Colors.grey, fontSize: 12))));
    return Column(
      children: _announcements.take(2).map((n) => Card(
        color: Colors.orange.withOpacity(0.05),
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.campaign, color: Colors.orange, size: 20),
          title: Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: Text(n['message'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      )).toList(),
    );
  }

  Widget _buildActionMosaic(ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        _toolItem('Mark Attendance', Icons.how_to_reg, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceModule(grade: selectedGrade!, stream: selectedStream!)))),
        _toolItem('Enter Results', Icons.grade, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => MarksEntryScreen(grade: selectedGrade!, stream: selectedStream!, subject: 'Mathematics')))),
        _toolItem('Pupil List', Icons.people_alt, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentManagementScreen(role: 'teacher', initialGrade: selectedGrade, initialStream: selectedStream)))),
        _toolItem('Assign Homework', Icons.assignment_add, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => HomeworkModule(grade: selectedGrade!, stream: selectedStream!, subject: 'Mathematics')))),
        _toolItem('Materials', Icons.upload_file, Colors.brown, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResourcesScreen()))),
        _toolItem('Reports', Icons.analytics, Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsGeneratorScreen(grade: selectedGrade!, stream: selectedStream!)))),
        _toolItem('Timetable', Icons.calendar_today, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimetableViewer()))),
        _toolItem('Progress', Icons.trending_up, Colors.cyan, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentProgressScreen()))),
        _toolItem('Behavior', Icons.gavel, Colors.blueGrey, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BehaviorTrackingScreen()))),
      ],
    );
  }

  Widget _toolItem(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String text) {
    return Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.primaryColor.withOpacity(0.5), letterSpacing: 1.5));
  }

  Widget _buildTeacherDrawer(BuildContext context, ThemeData theme) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(decoration: BoxDecoration(color: theme.primaryColor), child: const Text('Educator Portal', style: TextStyle(color: Colors.white, fontSize: 24))),
          ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(role: 'teacher')))),
          ListTile(leading: const Icon(Icons.logout), title: const Text('Logout'), onTap: () => Navigator.pushReplacementNamed(context, '/login')),
        ],
      ),
    );
  }
}
