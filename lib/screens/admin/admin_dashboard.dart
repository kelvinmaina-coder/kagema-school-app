import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../settings/settings_screen.dart';
import '../common/student_management_screen.dart';
import 'inventory_manager.dart';
import 'fee_management_screen.dart';
import 'communication_hub_screen.dart';
import 'transport_management_screen.dart';
import 'exam_management_screen.dart';
import 'library_management_screen.dart';
import 'reports_module_screen.dart';
import 'academic_management.dart';
import 'hr_management_screen.dart';
import 'discipline_management_screen.dart';
import 'extracurricular_management_screen.dart';
import 'attendance_admin_screen.dart';
import 'user_management_hub.dart';
import 'task_management_screen.dart';
import '../../app_theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  Map<String, dynamic> stats = {};
  List<Map<String, dynamic>> _insights = [];
  bool isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() { isLoading = true; _errorMessage = null; });
    try {
      final results = await Future.wait<dynamic>([
        SupabaseService.instance.getDashboardSummary(),
        SupabaseService.instance.getActionableInsights(),
      ]);
      if (mounted) {
        setState(() {
          stats = results[0] as Map<String, dynamic>;
          _insights = results[1] as List<Map<String, dynamic>>;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { isLoading = false; _errorMessage = "Sync Failed. Retrying..."; });
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
      ),
      bottomNavigationBar: _buildModernNavBar(theme, gemini),
    );
  }

  Widget _buildHomeTab(ThemeData theme, GeminiThemeExtension? gemini) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: CustomScrollView(
        slivers: [
          _buildHeroAppBar(theme, gemini),
          if (_errorMessage != null) SliverToBoxAdapter(child: _buildErrorPanel(_errorMessage!)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildInsightsPanel(theme, gemini),
                  const SizedBox(height: 32),
                  _buildSummaryStats(theme, gemini),
                  const SizedBox(height: 32),
                  _buildSectionLabel(theme, 'QUICK ACCESS'),
                  _buildQuickActions(theme, gemini),
                  const SizedBox(height: 120),
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
        _buildSectionLabel(theme, 'REGISTRY & WORKFLOW'),
        _operationTile(theme, 'User Registry', 'Enroll Students, Staff & Parents', Icons.people_alt_rounded, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementHub()))),
        _operationTile(theme, 'Task Manager', 'Assign duties to faculty', Icons.assignment_ind_rounded, Colors.deepOrange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskManagementScreen()))),
        const SizedBox(height: 32),
        _buildSectionLabel(theme, 'ACADEMIC RECORDS'),
        _operationTile(theme, 'Exams & Grading', 'Schedule assessments & grades', Icons.quiz_rounded, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamManagementScreen()))),
        _operationTile(theme, 'Academic Hub', 'Classes & subjects management', Icons.auto_stories_rounded, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AcademicManagementScreen()))),
        _operationTile(theme, 'Activities', 'Manage Clubs & Sports', Icons.sports_basketball_rounded, Colors.pink, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExtracurricularManagementScreen()))),
        const SizedBox(height: 32),
        _buildSectionLabel(theme, 'LOGISTICS & ADMIN'),
        _operationTile(theme, 'Transport', 'Routes & drivers management', Icons.bus_alert_rounded, Colors.deepPurple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransportManagementScreen()))),
        _operationTile(theme, 'Library Center', 'Lending records & history', Icons.local_library_rounded, Colors.blueGrey, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryManagementScreen()))),
        _operationTile(theme, 'HR & Payroll', 'Staff leave & salary management', Icons.badge_rounded, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HRManagementScreen()))),
        _operationTile(theme, 'Discipline Records', 'Behavioral incidents & logs', Icons.gavel_rounded, Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DisciplineManagementScreen()))),
        _operationTile(theme, 'Business Reports', 'Analytics & system reports', Icons.insights_rounded, Colors.cyan, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsModuleScreen()))),
      ],
    );
  }

  Widget _operationTile(ThemeData theme, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.9), borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.dividerColor.withOpacity(0.05))),
          child: Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 22)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)), Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))])), const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey)]),
        ),
      ),
    );
  }

  Widget _buildSummaryStats(ThemeData theme, GeminiThemeExtension? gemini) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _miniStat(theme, gemini, 'STAFF', '${stats['staff'] ?? 0}', Colors.teal),
        _miniStat(theme, gemini, 'FEES PAID', 'Ksh ${stats['totalFees'] ?? 0}', Colors.green),
        _miniStat(theme, gemini, 'PARENTS', '${stats['parents'] ?? 0}', Colors.orange),
      ],
    );
  }

  Widget _miniStat(ThemeData theme, GeminiThemeExtension? gemini, String l, String v, Color c) {
    final content = Column(children: [Text(v, style: TextStyle(fontWeight: FontWeight.w900, color: c, fontSize: 18)), const SizedBox(height: 2), Text(l, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1))]);
    return Expanded(child: Container(margin: const EdgeInsets.only(right: 8), child: gemini?.buildGlowContainer(borderRadius: 20, borderThickness: 1, backgroundColor: theme.cardColor.withOpacity(0.7), padding: const EdgeInsets.symmetric(vertical: 16), child: content) ?? Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.6), borderRadius: BorderRadius.circular(20)), child: content)));
  }

  Widget _buildInsightsPanel(ThemeData theme, GeminiThemeExtension? gemini) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildSectionLabel(theme, 'SYSTEM INSIGHTS'), const SizedBox(height: 12), SizedBox(height: 150, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _insights.length, itemBuilder: (context, index) { final insight = _insights[index]; final color = insight['type'] == 'critical' ? Colors.red : (insight['type'] == 'success' ? Colors.green : Colors.blue); return Container(width: 280, margin: const EdgeInsets.only(right: 16), child: gemini?.buildGlowContainer(borderRadius: 24, borderThickness: 1.5, backgroundColor: theme.cardColor.withOpacity(0.8), padding: const EdgeInsets.all(20), useAIBorder: insight['type'] == 'critical', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(insight['type'] == 'critical' ? Icons.warning_rounded : Icons.tips_and_updates_rounded, color: color, size: 16), const SizedBox(width: 10), Text(insight['title'], style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 12, letterSpacing: 0.5))]), const SizedBox(height: 12), Text(insight['subtitle'] ?? '', style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w600))]))); }))]);
  }

  Widget _buildModernNavBar(ThemeData theme, GeminiThemeExtension? gemini) { return Container(margin: const EdgeInsets.fromLTRB(20, 0, 20, 20), height: 70, decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.95), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, spreadRadius: -10)], border: Border.all(color: theme.dividerColor.withOpacity(0.05))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_navItem(0, Icons.dashboard_rounded, 'Dashboard'), _navItem(1, Icons.grid_view_rounded, 'Services'), _navItem(2, Icons.settings_rounded, 'Settings')])); }
  Widget _navItem(int index, IconData icon, String label) { bool isSelected = _currentIndex == index; return InkWell(onTap: () { if (index == 2) { Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(role: 'Admin'))); return; } setState(() => _currentIndex = index); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: isSelected ? BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)) : null, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey, size: 24), const SizedBox(height: 2), Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isSelected ? Theme.of(context).primaryColor : Colors.grey))]))); }
  Widget _buildQuickActions(ThemeData theme, GeminiThemeExtension? gemini) { return GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.5, children: [_quickCard(theme, gemini, 'USERS HUB', Icons.hub_rounded, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementHub()))), _quickCard(theme, gemini, 'NOTICE BOARD', Icons.campaign_rounded, Colors.pink, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunicationHubScreen())))]); }
  Widget _quickCard(ThemeData theme, GeminiThemeExtension? gemini, String title, IconData icon, Color color, VoidCallback onTap) { final content = Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 30), const SizedBox(height: 10), Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 10, letterSpacing: 1.5))]); return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(24), child: gemini?.buildGlowContainer(borderRadius: 24, borderThickness: 1.2, backgroundColor: color.withOpacity(0.08), padding: const EdgeInsets.all(12), child: content)); }
  Widget _buildHeroAppBar(ThemeData theme, GeminiThemeExtension? gemini) { return SliverAppBar(expandedHeight: 120.0, pinned: true, backgroundColor: Colors.transparent, elevation: 0, flexibleSpace: FlexibleSpaceBar(title: const Text('ADMINISTRATION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2, color: Colors.white)), centerTitle: true, background: Container(decoration: BoxDecoration(gradient: gemini?.primaryGradient, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)), boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)]), child: Stack(children: [Positioned(right: -20, top: -20, child: Icon(Icons.shield_rounded, size: 150, color: Colors.white.withOpacity(0.1)))])))); }
  Widget _buildSectionLabel(ThemeData theme, String text) { return Padding(padding: const EdgeInsets.only(left: 4, bottom: 12.0), child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.blueGrey))); }
  Widget _buildErrorPanel(String msg) { return Container(margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.withOpacity(0.1))), child: Row(children: [const Icon(Icons.sync_problem_rounded, color: Colors.red), const SizedBox(width: 12), Expanded(child: Text(msg, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold))), IconButton(icon: const Icon(Icons.refresh, color: Colors.red, size: 20), onPressed: _loadDashboardData)])); }
}
