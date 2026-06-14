import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/supabase_service.dart';
import '../settings/settings_screen.dart';
import 'student_registration.dart';
import '../common/parent_directory_screen.dart';
import 'appointment_management.dart';
import 'attendance_viewer.dart';
import 'secretary_reports.dart';
import 'visitors_manager.dart';
import '../admin/communication_hub_screen.dart';
import '../../app_theme.dart';

class SecretaryDashboard extends StatefulWidget {
  const SecretaryDashboard({super.key});

  @override
  State<SecretaryDashboard> createState() => _SecretaryDashboardState();
}

class _SecretaryDashboardState extends State<SecretaryDashboard> {
  int _currentIndex = 0;
  Map<String, dynamic> _stats = {
    'totalStudents': 0,
    'newAdmissions': 0,
    'upcomingAppointments': 0,
    'announcements': 0,
    'visitors_today': 0,
  };
  List<Map<String, dynamic>> _recentAppointments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        SupabaseService.instance.getSecretaryStats(),
        SupabaseService.instance.getAppointments(),
      ]);
      
      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, dynamic>;
          _recentAppointments = List<Map<String, dynamic>>.from(results[1] as List).take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Database Link Unstable. Swipe down to refresh.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    
    return Scaffold(
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _currentIndex == 0 ? _buildHomeTab(theme, gemini) : _buildOperationsTab(theme, gemini),
      ) ?? (_currentIndex == 0 ? _buildHomeTab(theme, null) : _buildOperationsTab(theme, null)),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          backgroundColor: theme.cardColor.withOpacity(0.95),
          indicatorColor: theme.primaryColor.withOpacity(0.2),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
            NavigationDestination(icon: Icon(Icons.apps_rounded), label: 'Operations'),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab(ThemeData theme, GeminiThemeExtension? gemini) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: theme.primaryColor,
      child: CustomScrollView(
        slivers: [
          _buildAppBar(theme),
          if (_error != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red.withOpacity(0.1))),
                child: Row(
                  children: [
                    const Icon(Icons.sync_problem_rounded, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsGrid(theme, gemini),
                  const SizedBox(height: 32),
                  _buildSectionLabel('LIVE APPOINTMENT STREAM'),
                  const SizedBox(height: 12),
                  _buildRecentAppointments(theme, gemini),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('Secretary Hub', 
          style: TextStyle(
            color: theme.colorScheme.onSurface, 
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontSize: 18,
          )
        ),
        centerTitle: false,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen(role: 'Secretary')),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(ThemeData theme, GeminiThemeExtension? gemini) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _statCard(theme, gemini, 'Total Students', _stats['totalStudents'].toString(), Icons.people_rounded, Colors.blue),
        _statCard(theme, gemini, 'Visitors Today', _stats['visitors_today'].toString(), Icons.badge_rounded, Colors.teal),
        _statCard(theme, gemini, 'Appointments', _stats['upcomingAppointments'].toString(), Icons.event_rounded, Colors.orange),
        _statCard(theme, gemini, 'Announcements', _stats['announcements'].toString(), Icons.campaign_rounded, Colors.purple),
      ],
    );
  }

  Widget _statCard(ThemeData theme, GeminiThemeExtension? gemini, String label, String value, IconData icon, Color color) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            Text(label.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 1)),
          ],
        ),
      ],
    );

    return gemini?.buildGlowContainer(
      borderRadius: 24,
      borderThickness: 1.5,
      backgroundColor: theme.cardColor.withOpacity(0.85),
      padding: const EdgeInsets.all(16),
      useAIBorder: label == 'Visitors Today', // Highlight active entry points
      child: content,
    ) ?? Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20)),
      child: content,
    );
  }

  Widget _buildRecentAppointments(ThemeData theme, GeminiThemeExtension? gemini) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_recentAppointments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.5), borderRadius: BorderRadius.circular(24)),
        child: const Center(child: Text('NO PENDING APPOINTMENTS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 10, letterSpacing: 2))),
      );
    }

    return Column(
      children: _recentAppointments.map((appt) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: gemini?.buildGlowContainer(
          borderRadius: 24,
          borderThickness: 1,
          backgroundColor: theme.cardColor.withOpacity(0.85),
          padding: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Icon(Icons.person_outline, size: 20, color: theme.primaryColor),
            ),
            title: Text(appt['visitor_name'] ?? 'Visitor', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            subtitle: Text(appt['title'] ?? 'General Meeting', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Text(
                appt['appointment_date'] != null ? appt['appointment_date'].toString().split('T')[0] : '',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.orange),
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildOperationsTab(ThemeData theme, GeminiThemeExtension? gemini) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 120),
      children: [
        _buildSectionLabel('ENROLLMENT & REGISTRY'),
        _operationTile(theme, 'Student Admission', 'Register new pupils', Icons.person_add_rounded, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRegistrationScreen()))),
        _operationTile(theme, 'Parent Directory', 'Guardian records & contacts', Icons.family_restroom_rounded, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentDirectoryScreen()))),
        const SizedBox(height: 32),
        _buildSectionLabel('OFFICE LOGISTICS'),
        _operationTile(theme, 'Visitors Log', 'Security & guest tracking', Icons.badge_rounded, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorsManagerScreen()))),
        _operationTile(theme, 'Appointments', 'Manage office meetings', Icons.event_available_rounded, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentManagementScreen()))),
        _operationTile(theme, 'Attendance Hub', 'Monitor daily presence', Icons.fact_check_rounded, Colors.amber, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceViewerScreen()))),
        const SizedBox(height: 32),
        _buildSectionLabel('ADMINISTRATION'),
        _operationTile(theme, 'Announcements', 'Post school bulletins', Icons.campaign_rounded, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunicationHubScreen()))),
        _operationTile(theme, 'Admin Reports', 'Registry & log exports', Icons.assignment_rounded, Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecretaryReportsScreen()))),
      ],
    );
  }

  Widget _operationTile(ThemeData theme, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(sub, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.dividerColor, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.blueGrey)),
    );
  }
}
