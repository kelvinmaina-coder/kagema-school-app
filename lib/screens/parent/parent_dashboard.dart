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
    setState(() => isLoading = true);
    try {
      final childMaps = await SupabaseService.instance.getParentChildren(widget.parentPhone);
      if (mounted) {
        setState(() {
          children = childMaps.map((m) => Student.fromMap(m)).toList();
          if (children.isNotEmpty) {
            selectedChild ??= children[0];
          }
        });
        if (selectedChild != null) await _loadChildVitals();
      }
    } catch (e) {
      debugPrint("Parent Dashboard Error: $e");
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
          _feeBalance = balanceData['balance'] ?? 0.0;
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
          ? const Center(child: CircularProgressIndicator())
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
      bottomNavigationBar: _buildModernNavBar(theme),
    );
  }

  Widget _buildHomeTab(ThemeData theme, GeminiThemeExtension? gemini) {
    return CustomScrollView(
      slivers: [
        _buildHeroAppBar(theme, gemini),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChildSelector(theme),
                const SizedBox(height: 24),
                _buildSectionLabel(theme, 'REAL-TIME VITALS'),
                const SizedBox(height: 16),
                _buildVitalsRow(theme),
                const SizedBox(height: 32),
                _buildSectionLabel(theme, 'ACADEMIC SERVICES'),
                const SizedBox(height: 16),
                _buildServiceGrid(theme),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVitalsRow(ThemeData theme) {
    return Row(
      children: [
        _vitalBox(theme, 'Attendance', '${_attendancePercent.toInt()}%', Colors.blue),
        const SizedBox(width: 12),
        _vitalBox(theme, 'Fee Balance', 'Ksh ${_feeBalance.toInt()}', _feeBalance > 0 ? Colors.red : Colors.green),
        const SizedBox(width: 12),
        _vitalBox(theme, 'Avg Score', '${_avgGrade.toInt()}%', Colors.orange),
      ],
    );
  }

  Widget _vitalBox(ThemeData theme, String l, String v, Color c) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.9), borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withOpacity(0.2))),
        child: Column(children: [Text(v, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: c)), const SizedBox(height: 4), Text(l, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))]),
      ),
    );
  }

  Widget _buildServiceGrid(ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _serviceCard(theme, 'Attendance', Icons.event_available_rounded, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildAttendanceScreen(student: selectedChild!)))),
        _serviceCard(theme, 'Performance', Icons.auto_graph_rounded, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildPerformanceScreen(student: selectedChild!)))),
        _serviceCard(theme, 'Fee Portal', Icons.payments_rounded, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => FeesPaymentScreen(student: selectedChild!)))),
        _serviceCard(theme, 'Homework', Icons.assignment_rounded, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => HomeworkScreen(grade: selectedChild!.grade, stream: selectedChild!.stream)))),
      ],
    );
  }

  Widget _serviceCard(ThemeData theme, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withOpacity(0.1))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 28), const SizedBox(height: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))]),
      ),
    );
  }

  Widget _buildModernNavBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 70,
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)]),
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
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey, size: 26), Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Theme.of(context).primaryColor : Colors.grey))]),
    );
  }

  Widget _buildChildSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: theme.primaryColor, child: Text(selectedChild?.name[0] ?? '?', style: const TextStyle(color: Colors.white))),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Student>(
                value: selectedChild,
                isExpanded: true,
                items: children.map((c) => DropdownMenuItem(value: c, child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                onChanged: (v) { if (v != null) { setState(() => selectedChild = v); _loadChildVitals(); } },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroAppBar(ThemeData theme, GeminiThemeExtension? gemini) {
    return SliverAppBar(
      expandedHeight: 120.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('PARENT PORTAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1, color: Colors.white)),
        background: Container(decoration: BoxDecoration(gradient: gemini?.primaryGradient, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)))),
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String text) {
    return Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 1.5));
  }
}
