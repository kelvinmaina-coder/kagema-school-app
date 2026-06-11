import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../settings/settings_screen.dart';
import '../common/student_management_screen.dart';
import '../common/staff_management.dart';
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
import '../../app_theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  
  // Unified Data State
  Map<String, dynamic> stats = {};
  List<Map<String, dynamic>> _insights = [];
  List<Map<String, dynamic>> _classStats = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIntelligenceData();
  }

  Future<void> _loadIntelligenceData() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait<dynamic>([
        SupabaseService.instance.getDashboardSummary(),
        SupabaseService.instance.getClassStatistics(),
        SupabaseService.instance.getActionableInsights(),
      ]);

      if (mounted) {
        setState(() {
          stats = results[0] as Map<String, dynamic>;
          _classStats = results[1] as List<Map<String, dynamic>>;
          _insights = results[2] as List<Map<String, dynamic>>;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
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
        child: _currentIndex == 0 ? _buildHomeTab(theme, gemini) : _buildOperationsTab(theme),
      ),
      bottomNavigationBar: _buildModernNavBar(theme),
    );
  }

  Widget _buildHomeTab(ThemeData theme, GeminiThemeExtension? gemini) {
    return RefreshIndicator(
      onRefresh: _loadIntelligenceData,
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
                  _buildIntelligencePanel(theme, gemini),
                  const SizedBox(height: 30),
                  _buildSummaryStats(theme),
                  const SizedBox(height: 30),
                  _buildSectionLabel(theme, 'CORE DIRECTORY'),
                  _buildQuickActions(theme),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntelligencePanel(ThemeData theme, GeminiThemeExtension? gemini) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(theme, 'SCHOOL INTELLIGENCE'),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _insights.length,
            itemBuilder: (context, index) {
              final insight = _insights[index];
              final color = insight['type'] == 'critical' ? Colors.red : (insight['type'] == 'success' ? Colors.green : Colors.blue);
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: color.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(insight['type'] == 'critical' ? Icons.warning_rounded : Icons.tips_and_updates_rounded, color: color, size: 18),
                        const SizedBox(width: 8),
                        Text(insight['title'], style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(insight['msg'], style: const TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOperationsTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      children: [
        _buildSectionLabel(theme, 'ACADEMICS & EXAMS'),
        _operationTile(theme, 'Exam Center', 'Manage assessments & grades', Icons.quiz_rounded, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamManagementScreen()))),
        _operationTile(theme, 'Academic Structures', 'Curriculum & subjects', Icons.auto_stories_rounded, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AcademicManagementScreen()))),
        const SizedBox(height: 24),
        _buildSectionLabel(theme, 'LOGISTICS'),
        _operationTile(theme, 'Bus Fleet', 'Routes & drivers', Icons.bus_alert_rounded, Colors.deepPurple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransportManagementScreen()))),
        _operationTile(theme, 'Asset Register', 'Inventory & stock control', Icons.inventory_2_rounded, Colors.brown, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryManagerScreen()))),
        const SizedBox(height: 24),
        _buildSectionLabel(theme, 'ADMINISTRATION'),
        _operationTile(theme, 'Global Bulletins', 'Cloud announcements', Icons.campaign_rounded, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunicationHubScreen()))),
        _operationTile(theme, 'HR & Payroll', 'Staff leave & treasury', Icons.badge_rounded, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HRManagementScreen()))),
      ],
    );
  }

  Widget _operationTile(ThemeData theme, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        onTap: onTap,
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
      ),
    );
  }

  Widget _buildModernNavBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 70,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(0, Icons.dashboard_rounded, 'Overview'),
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
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(role: 'Admin')));
          return;
        }
        setState(() => _currentIndex = index);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey, size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isSelected ? Theme.of(context).primaryColor : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _quickCard(theme, 'PUPILS', Icons.school, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentManagementScreen(role: 'Admin')))),
        _quickCard(theme, 'TREASURY', Icons.account_balance, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeeManagementScreen()))),
      ],
    );
  }

  Widget _quickCard(ThemeData theme, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withOpacity(0.1))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 30), const SizedBox(height: 8), Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 10, letterSpacing: 1))]),
      ),
    );
  }

  Widget _buildSummaryStats(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _miniStat('STAFF', '${stats['staff'] ?? 0}', Colors.teal),
        _miniStat('REVENUE', 'Ksh ${stats['totalFees'] ?? 0}', Colors.green),
        _miniStat('TASKS', '3', Colors.orange),
      ],
    );
  }

  Widget _miniStat(String l, String v, Color c) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Theme.of(context).cardColor.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
        child: Column(children: [Text(v, style: TextStyle(fontWeight: FontWeight.w900, color: c, fontSize: 16)), Text(l, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey))]),
      ),
    );
  }

  Widget _buildHeroAppBar(ThemeData theme, GeminiThemeExtension? gemini) {
    return SliverAppBar(
      expandedHeight: 100.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('ADMIN CONTROL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1, color: Colors.white)),
        background: Container(decoration: BoxDecoration(gradient: gemini?.primaryGradient, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)))),
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.grey)),
    );
  }

  Widget _buildAdminDrawer(BuildContext context, ThemeData theme) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(decoration: BoxDecoration(color: theme.primaryColor), child: const Center(child: Text('KAGEMA OS', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)))),
          const Spacer(),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Logout Session'), onTap: () => Navigator.pushReplacementNamed(context, '/login')),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
