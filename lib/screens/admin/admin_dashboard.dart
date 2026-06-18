import 'package:flutter/material.dart';
import 'dart:ui';
import '../../services/supabase_service.dart';
import '../settings/settings_screen.dart';
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
  List<Map<String, dynamic>> _statusInsights = [];
  bool isLoading = true;
  String? _errorMessage;

  final Color primaryAccent = const Color(0xFF1A237E); 
  final Color slateDark = const Color(0xFF0F172A);

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
          _statusInsights = results[1] as List<Map<String, dynamic>>;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { isLoading = false; _errorMessage = "SYSTEM SYNC PAUSED. SWIPE TO RETRY."; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gemini = theme.extension<GeminiThemeExtension>();
    final screenWidth = MediaQuery.of(context).size.width;

    // RESPONSIVE MAX WIDTH
    double maxWidth = screenWidth > 1200 ? 1100 : (screenWidth > 800 ? 800 : screenWidth);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0E12) : const Color(0xFFF4F7FA),
      body: gemini?.buildCreativeBackground(
        isDark: isDark,
        maxWidth: maxWidth,
        child: Stack(
          children: [
            _currentIndex == 0 ? _buildHomeTab(isDark, screenWidth) : _buildOperationsTab(isDark, screenWidth),
            _buildBottomNav(isDark, screenWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab(bool isDark, double screenWidth) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: primaryAccent,
      edgeOffset: 120,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildElegantHeader('SYSTEM MATRIX', Icons.admin_panel_settings_rounded),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth > 600 ? 32 : 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null) _buildErrorBanner(),
                  _buildInsightSlider(isDark),
                  const SizedBox(height: 40),
                  _buildSectionHeader('GLOBAL VITALS'),
                  const SizedBox(height: 20),
                  _buildSummaryStats(isDark, screenWidth),
                  const SizedBox(height: 40),
                  _buildSectionHeader('COMMAND CENTER'),
                  const SizedBox(height: 20),
                  _buildQuickActions(isDark, screenWidth),
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElegantHeader(String title, IconData icon) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: primaryAccent,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        title: Text(title, 
          style: const TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 18, 
            letterSpacing: 4, 
            color: Colors.white,
          )
        ),
        background: Stack(
          children: [
            Container(color: primaryAccent),
            Positioned(
              right: -20, top: -10,
              child: Icon(icon, size: 180, color: Colors.white.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightSlider(bool isDark) {
    if (_statusInsights.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('LIVE INSIGHTS'),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _statusInsights.length,
            itemBuilder: (context, index) {
              final insight = _statusInsights[index];
              final color = insight['type'] == 'critical' ? const Color(0xFFD32F2F) : (insight['type'] == 'success' ? const Color(0xFF2E7D32) : primaryAccent);
              
              return Container(
                width: 300,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: insight['type'] == 'critical' ? color.withOpacity(0.3) : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(insight['type'] == 'critical' ? Icons.warning_rounded : Icons.tips_and_updates_rounded, color: color, size: 18),
                        const SizedBox(width: 10),
                        Text(insight['title'].toString().toUpperCase(), 
                          style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 10, letterSpacing: 1)
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(insight['subtitle'] ?? '', 
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : slateDark)
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStats(bool isDark, double screenWidth) {
    // WRAP STATS ON SMALL SCREENS
    if (screenWidth < 400) {
      return Column(
        children: [
          Row(children: [
            _miniStat('STAFF', '${stats['staff'] ?? 0}', const Color(0xFF00796B), isDark),
            const SizedBox(width: 12),
            _miniStat('PARENTS', '${stats['parents'] ?? 0}', const Color(0xFFF57C00), isDark),
          ]),
          const SizedBox(height: 12),
          _miniStat('FEES', 'KSH ${stats['totalFees'] ?? 0}', const Color(0xFF2E7D32), isDark),
        ],
      );
    }

    return Row(
      children: [
        _miniStat('STAFF', '${stats['staff'] ?? 0}', const Color(0xFF00796B), isDark),
        const SizedBox(width: 12),
        _miniStat('FEES', 'KSH ${stats['totalFees'] ?? 0}', const Color(0xFF2E7D32), isDark),
        const SizedBox(width: 12),
        _miniStat('PARENTS', '${stats['parents'] ?? 0}', const Color(0xFFF57C00), isDark),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color, bool isDark) {
    return Expanded(
      flex: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1C2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
        ),
        child: Column(
          children: [
            Text(value, 
              style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 18)
            ), 
            const SizedBox(height: 6), 
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : Colors.black38, letterSpacing: 1.2))
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isDark, double screenWidth) {
    return Row(
      children: [
        _actionCard('USER HUB', Icons.hub_rounded, primaryAccent, isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementHub()))),
        const SizedBox(width: 16),
        _actionCard('NOTICE BOARD', Icons.campaign_rounded, const Color(0xFF7B1FA2), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunicationHubScreen()))),
      ],
    );
  }

  Widget _actionCard(String title, IconData icon, Color accent, bool isDark, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1C2E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: accent.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: accent, size: 32),
              ),
              const SizedBox(height: 16),
              Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white70 : slateDark, fontSize: 11, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOperationsTab(bool isDark, double screenWidth) {
    int crossAxisCount = screenWidth > 900 ? 2 : 1;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildElegantHeader('OPERATIONS', Icons.grid_view_rounded),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth > 600 ? 32 : 20, vertical: 24),
          sliver: crossAxisCount == 1 
            ? SliverList(
                delegate: SliverChildListDelegate([
                  _buildSectionHeader('REGISTRY & WORKFLOW'),
                  const SizedBox(height: 12),
                  _opTile('User Hub', 'Enroll Students & Staff', Icons.people_alt_rounded, primaryAccent, isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementHub()))),
                  _opTile('Task Manager', 'Assign duties to staff', Icons.assignment_ind_rounded, const Color(0xFFF57C00), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskManagementScreen()))),
                  const SizedBox(height: 24),
                  _buildSectionHeader('ACADEMIC RECORDS'),
                  const SizedBox(height: 12),
                  _opTile('Exams & Grading', 'Manage results', Icons.quiz_rounded, const Color(0xFFD32F2F), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamManagementScreen()))),
                  _opTile('Academic Hub', 'Classes & subjects', Icons.auto_stories_rounded, const Color(0xFF00ACC1), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AcademicManagementScreen()))),
                  const SizedBox(height: 24),
                  _buildSectionHeader('LOGISTICS'),
                  const SizedBox(height: 12),
                  _opTile('Transport', 'Routes & drivers', Icons.bus_alert_rounded, const Color(0xFF7B1FA2), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransportManagementScreen()))),
                  _opTile('Library Center', 'Lending records', Icons.local_library_rounded, const Color(0xFF546E7A), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryManagementScreen()))),
                  _opTile('Conduct Logs', 'Incident tracking', Icons.gavel_rounded, const Color(0xFFC2185B), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DisciplineManagementScreen()))),
                  const SizedBox(height: 140),
                ]),
              )
            : SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 90,
                ),
                delegate: SliverChildListDelegate([
                   _opTile('User Hub', 'Enroll Users', Icons.people_alt_rounded, primaryAccent, isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementHub()))),
                   _opTile('Task Manager', 'Assign duties', Icons.assignment_ind_rounded, const Color(0xFFF57C00), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskManagementScreen()))),
                   _opTile('Exams & Grading', 'Manage results', Icons.quiz_rounded, const Color(0xFFD32F2F), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamManagementScreen()))),
                   _opTile('Academic Hub', 'Classes', Icons.auto_stories_rounded, const Color(0xFF00ACC1), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AcademicManagementScreen()))),
                   _opTile('Transport', 'Routes', Icons.bus_alert_rounded, const Color(0xFF7B1FA2), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransportManagementScreen()))),
                   _opTile('Library', 'Lending', Icons.local_library_rounded, const Color(0xFF546E7A), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryManagementScreen()))),
                   _opTile('Conduct Logs', 'Incidents', Icons.gavel_rounded, const Color(0xFFC2185B), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DisciplineManagementScreen()))),
                ]),
              ),
        ),
      ],
    );
  }

  Widget _opTile(String title, String sub, IconData icon, Color color, bool isDark, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? const Color(0xFF1A1C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? Colors.white : slateDark)),
                      const SizedBox(height: 2),
                      Text(sub.toUpperCase(), style: TextStyle(fontSize: 9, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white12 : Colors.black12, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(bool isDark, double screenWidth) {
    double navWidth = screenWidth > 800 ? 500 : screenWidth - 40;

    return Positioned(
      bottom: 25, left: 0, right: 0,
      child: Center(
        child: Container(
          width: navWidth,
          height: 70,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1C2E).withOpacity(0.95) : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))],
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(0, Icons.dashboard_rounded, 'MATRIX'),
              _navItem(1, Icons.grid_view_rounded, 'SERVICES'),
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
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(role: 'Admin')));
          return;
        }
        setState(() => _currentIndex = index);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? primaryAccent : Colors.grey.withOpacity(0.5), size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isSelected ? primaryAccent : Colors.grey.withOpacity(0.5), letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: primaryAccent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.5, color: Color(0xFF475569))),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFFCDD2))),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFD32F2F)),
          const SizedBox(width: 12),
          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 11, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}
