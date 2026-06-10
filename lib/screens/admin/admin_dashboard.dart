import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../settings/settings_screen.dart';
import '../common/student_management_screen.dart';
import '../common/staff_management.dart';
import 'inventory_manager.dart';
import 'fee_management_screen.dart';
import 'attendance_admin_screen.dart';
import 'communication_hub_screen.dart';
import 'transport_management_screen.dart';
import 'exam_management_screen.dart';
import 'library_management_screen.dart';
import 'reports_module_screen.dart';
import '../../app_theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic> stats = {};
  List<Map<String, dynamic>> _recentActivity = [];
  List<Map<String, dynamic>> _classStats = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    
    try {
      // FIXED: Added explicit Future typing to avoid List<dynamic> inference error
      final results = await Future.wait<dynamic>([
        SupabaseService.instance.getDashboardSummary(),
        SupabaseService.instance.getClassStatistics(),
        SupabaseService.instance.getRecentActivity(),
      ]);

      if (mounted) {
        setState(() {
          stats = results[0] as Map<String, dynamic>;
          _classStats = results[1] as List<Map<String, dynamic>>;
          _recentActivity = results[2] as List<Map<String, dynamic>>;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("AdminDashboard Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: _buildAdminDrawer(context, theme),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllData,
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
                          const SizedBox(height: 24),
                          _buildClassStats(theme),
                          const SizedBox(height: 30),
                          _buildSectionLabel(theme, 'CORE MANAGEMENT'),
                          const SizedBox(height: 16),
                          _buildMainActionsGrid(theme),
                          const SizedBox(height: 30),
                          _buildSectionLabel(theme, 'SCHOOL OPERATIONS'),
                          const SizedBox(height: 16),
                          _buildSecondaryActionsGrid(theme),
                          const SizedBox(height: 30),
                          _buildSectionLabel(theme, 'RECENT ACTIVITY'),
                          const SizedBox(height: 16),
                          _buildActivityFeed(theme),
                          const SizedBox(height: 60),
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

  Widget _buildSummaryStats(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _miniStat('Students', (stats['students'] ?? 0).toString(), Colors.blue),
          _miniStat('Teachers', (stats['teachers'] ?? 0).toString(), Colors.orange),
          _miniStat('Staff', (stats['staff'] ?? 0).toString(), Colors.teal),
          _miniStat('Parents', (stats['parents'] ?? 0).toString(), Colors.purple),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildClassStats(ThemeData theme) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _classStats.length,
        itemBuilder: (context, index) {
          final c = _classStats[index];
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(c['grade'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Text('${c['student_count'] ?? 0}', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w900, fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityFeed(ThemeData theme) {
    return Column(
      children: _recentActivity.map((log) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(_getLogIcon(log['type']), color: theme.primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(log['subtitle'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getLogIcon(String? type) {
    switch (type) {
      case 'Enrollment': return Icons.person_add;
      case 'Finance': return Icons.payments;
      case 'Event': return Icons.event;
      default: return Icons.info;
    }
  }

  Widget _buildMainActionsGrid(ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _actionCard(theme, 'Students', Icons.school, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentManagementScreen(role: 'Admin')))),
        _actionCard(theme, 'Staff', Icons.badge, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffManagementScreen(role: 'Admin')))),
        _actionCard(theme, 'Fees', Icons.account_balance, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeeManagementScreen()))),
        _actionCard(theme, 'Exams', Icons.auto_stories, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamManagementScreen()))),
      ],
    );
  }

  Widget _buildSecondaryActionsGrid(ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        _miniActionCard(theme, 'Inventory', Icons.inventory_2, Colors.brown, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryManagerScreen()))),
        _miniActionCard(theme, 'Transport', Icons.bus_alert, Colors.deepPurple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransportManagementScreen()))),
        _miniActionCard(theme, 'Library', Icons.local_library, Colors.blueGrey, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryManagementScreen()))),
        _miniActionCard(theme, 'Messages', Icons.message, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunicationHubScreen()))),
        _miniActionCard(theme, 'Attendance', Icons.how_to_reg, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceAdminScreen()))),
        _miniActionCard(theme, 'Reports', Icons.assessment, Colors.cyan, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsModuleScreen()))),
      ],
    );
  }

  Widget _actionCard(ThemeData theme, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.8), borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withOpacity(0.1))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 36, color: color), const SizedBox(height: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13))]),
      ),
    );
  }

  Widget _miniActionCard(ThemeData theme, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 24, color: color), const SizedBox(height: 6), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10))]),
      ),
    );
  }

  Widget _buildHeroAppBar(ThemeData theme, GeminiThemeExtension? gemini) {
    return SliverAppBar(
      expandedHeight: 120.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        background: Container(decoration: BoxDecoration(gradient: gemini?.primaryGradient, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)))),
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String text) {
    return Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: theme.primaryColor.withOpacity(0.5), letterSpacing: 1.5));
  }

  Widget _buildAdminDrawer(BuildContext context, ThemeData theme) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(decoration: BoxDecoration(color: theme.primaryColor), child: const Text('Admin Portal', style: TextStyle(color: Colors.white, fontSize: 24))),
          ListTile(leading: const Icon(Icons.settings), title: const Text('System Settings'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(role: 'Admin')))),
          ListTile(leading: const Icon(Icons.logout), title: const Text('Sign Out'), onTap: () => Navigator.pushReplacementNamed(context, '/login')),
        ],
      ),
    );
  }
}
