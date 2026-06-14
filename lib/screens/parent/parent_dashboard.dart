import 'package:flutter/material.dart';
import 'dart:async';
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
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBody: true,
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : IndexedStack(
              index: _selectedIndex,
              children: [
                _buildHomeTab(theme, gemini),
                const AnnouncementsScreen(),
                ChildListScreen(parentPhone: widget.parentPhone),
                const SettingsScreen(role: 'Parent'),
              ],
            ),
      ),
      bottomNavigationBar: _buildModernNavBar(theme, gemini),
    );
  }

  Widget _buildHomeTab(ThemeData theme, GeminiThemeExtension? gemini) {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: CustomScrollView(
        slivers: [
          _buildHeroAppBar(theme, gemini),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: children.isEmpty 
                ? _buildEmptyState()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChildSelector(theme, gemini),
                      const SizedBox(height: 32),
                      _buildSectionLabel(theme, 'SCHOOL PERFORMANCE'),
                      const SizedBox(height: 16),
                      _buildVitalsRow(theme, gemini),
                      const SizedBox(height: 32),
                      _buildSectionLabel(theme, 'ACADEMIC & SCHOOL SERVICES'),
                      const SizedBox(height: 16),
                      _buildServiceGrid(theme, gemini),
                      const SizedBox(height: 120),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsRow(ThemeData theme, GeminiThemeExtension? gemini) {
    return Row(
      children: [
        _vitalBox(theme, gemini, 'Attendance', '${_attendancePercent.toInt()}%', Colors.blue),
        const SizedBox(width: 12),
        _vitalBox(theme, gemini, 'Fee Balance', 'Ksh ${_feeBalance.toInt()}', _feeBalance > 0 ? Colors.red : Colors.green),
        const SizedBox(width: 12),
        _vitalBox(theme, gemini, 'Avg Score', '${_avgGrade.toInt()}%', Colors.orange),
      ],
    );
  }

  Widget _vitalBox(ThemeData theme, GeminiThemeExtension? gemini, String l, String v, Color c) {
    final content = Column(
      children: [
        Text(v, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: c)), 
        const SizedBox(height: 4), 
        Text(l, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1))
      ]
    );

    return Expanded(
      child: gemini?.buildGlowContainer(
        borderRadius: 20,
        borderThickness: 1,
        backgroundColor: theme.cardColor.withOpacity(0.9),
        padding: const EdgeInsets.symmetric(vertical: 20),
        useAIBorder: true, 
        child: content,
      ) ?? Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
        child: content,
      ),
    );
  }

  Widget _buildServiceGrid(ThemeData theme, GeminiThemeExtension? gemini) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _serviceCard(theme, gemini, 'Roll Call', Icons.event_available_rounded, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildAttendanceScreen(student: selectedChild!)))),
        _serviceCard(theme, gemini, 'Performance', Icons.auto_graph_rounded, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildPerformanceScreen(student: selectedChild!)))),
        _serviceCard(theme, gemini, 'Fee Portal', Icons.payments_rounded, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => FeesPaymentScreen(student: selectedChild!)))),
        _serviceCard(theme, gemini, 'Homework', Icons.assignment_rounded, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => HomeworkScreen(grade: selectedChild!.grade, stream: selectedChild!.stream)))),
        _serviceCard(theme, gemini, 'Timetable', Icons.calendar_view_week_rounded, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildTimetableScreen(student: selectedChild!)))),
        _serviceCard(theme, gemini, 'Library', Icons.local_library_rounded, Colors.blueGrey, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildLibraryScreen(student: selectedChild!)))),
        _serviceCard(theme, gemini, 'Conduct', Icons.gavel_rounded, Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildDisciplineScreen(student: selectedChild!)))),
        _serviceCard(theme, gemini, 'Calendar', Icons.event_note_rounded, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentCalendarScreen()))),
      ],
    );
  }

  Widget _serviceCard(ThemeData theme, GeminiThemeExtension? gemini, String title, IconData icon, Color color, VoidCallback onTap) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center, 
      children: [
        Icon(icon, color: color, size: 28), 
        const SizedBox(height: 10), 
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5))
      ]
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: gemini?.buildGlowContainer(
        borderRadius: 24,
        borderThickness: 1.5,
        backgroundColor: theme.cardColor.withOpacity(0.8),
        padding: const EdgeInsets.all(12),
        child: content,
      ) ?? Container(
        decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.9), borderRadius: BorderRadius.circular(24)),
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
          _navIcon(0, Icons.home_rounded, 'Home'),
          _navIcon(1, Icons.campaign_rounded, 'Notices'),
          _navIcon(2, Icons.people_rounded, 'Family'),
          _navIcon(3, Icons.person_rounded, 'Profile'),
        ],
      ),
    );
  }

  Widget _navIcon(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected ? BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)) : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey, size: 24), 
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isSelected ? Theme.of(context).primaryColor : Colors.grey))
          ]
        ),
      ),
    );
  }

  Widget _buildChildSelector(ThemeData theme, GeminiThemeExtension? gemini) {
    if (children.isEmpty) return const SizedBox.shrink();
    final content = Row(
      children: [
        CircleAvatar(radius: 18, backgroundColor: theme.primaryColor, child: Text(selectedChild?.name[0] ?? '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Student>(
              value: selectedChild,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: children.map((c) => DropdownMenuItem(value: c, child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)))).toList(),
              onChanged: (v) { if (v != null) { setState(() => selectedChild = v); _loadChildVitals(); } },
            ),
          ),
        ),
      ],
    );
    return gemini?.buildGlowContainer(borderRadius: 20, borderThickness: 1.5, backgroundColor: theme.cardColor.withOpacity(0.9), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: content) ?? Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20)), child: content);
  }

  Widget _buildHeroAppBar(ThemeData theme, GeminiThemeExtension? gemini) {
    return SliverAppBar(
      expandedHeight: 120.0, pinned: true, backgroundColor: Colors.transparent, elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('PARENT PORTAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2, color: Colors.white)),
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(gradient: gemini?.primaryGradient, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)), boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)]),
          child: Stack(children: [Positioned(left: -20, top: -10, child: Icon(Icons.family_restroom_rounded, size: 160, color: Colors.white.withOpacity(0.1)))]),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String text) {
    return Padding(padding: const EdgeInsets.only(left: 4), child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)));
  }

  Widget _buildEmptyState() {
    return Center(child: Column(children: [const SizedBox(height: 60), Icon(Icons.hub_rounded, size: 80, color: Colors.grey.withOpacity(0.3)), const SizedBox(height: 24), const Text('NO LINKED CHILDREN FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2, fontSize: 12)), const SizedBox(height: 8), const Text('Please link your child at the school office.', style: TextStyle(color: Colors.grey, fontSize: 11))]));
  }
}
