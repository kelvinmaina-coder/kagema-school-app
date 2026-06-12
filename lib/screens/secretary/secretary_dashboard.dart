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
      final stats = await SupabaseService.instance.getSecretaryStats();
      final appointments = await SupabaseService.instance.getAppointments();
      
      if (mounted) {
        setState(() {
          _stats = stats;
          _recentAppointments = List<Map<String, dynamic>>.from(appointments).take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: _currentIndex == 0 ? _buildHomeTab(theme) : _buildOperationsTab(theme),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.apps_rounded), label: 'Operations'),
        ],
      ),
    );
  }

  Widget _buildHomeTab(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          _buildAppBar(theme),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsGrid(theme),
                  const SizedBox(height: 32),
                  _buildRecentAppointments(theme),
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
      expandedHeight: 120,
      floating: true,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('Secretary Hub', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
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

  Widget _buildStatsGrid(ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _statCard(theme, 'Students', _stats['totalStudents'].toString(), Icons.people_rounded, Colors.blue),
        _statCard(theme, 'New Admits', _stats['newAdmissions'].toString(), Icons.person_add_rounded, Colors.green),
        _statCard(theme, 'Appointments', _stats['upcomingAppointments'].toString(), Icons.event_rounded, Colors.orange),
        _statCard(theme, 'Bulletins', _stats['announcements'].toString(), Icons.campaign_rounded, Colors.purple),
      ],
    );
  }

  Widget _statCard(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAppointments(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Upcoming Visits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(onPressed: () => setState(() => _currentIndex = 1), child: const Text('View All')),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading) const Center(child: CircularProgressIndicator())
        else if (_recentAppointments.isEmpty) const Text('No pending appointments')
        else ..._recentAppointments.map((appt) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline, size: 20)),
            title: Text(appt['visitor_name'] ?? 'Visitor', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(appt['title'] ?? 'General Meeting'),
            trailing: Text(appt['appointment_date'] != null ? appt['appointment_date'].toString().split('T')[0] : ''),
          ),
        )),
      ],
    );
  }

  Widget _buildOperationsTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      children: [
        _buildSectionLabel('ENROLLMENT & REGISTRY'),
        _operationTile(theme, 'Student Admission', 'Register new pupils', Icons.person_add_rounded, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRegistrationScreen()))),
        _operationTile(theme, 'Parent Directory', 'Guardian records & contacts', Icons.family_restroom_rounded, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentDirectoryScreen()))),
        const SizedBox(height: 24),
        _buildSectionLabel('OFFICE LOGISTICS'),
        _operationTile(theme, 'Visitors Log', 'Security & guest tracking', Icons.badge_rounded, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorsManagerScreen()))),
        _operationTile(theme, 'Appointments', 'Manage office meetings', Icons.event_available_rounded, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentManagementScreen()))),
        _operationTile(theme, 'Attendance Hub', 'Monitor daily presence', Icons.fact_check_rounded, Colors.amber, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceViewerScreen()))),
        const SizedBox(height: 24),
        _buildSectionLabel('ADMINISTRATION'),
        _operationTile(theme, 'Announcements', 'Post school bulletins', Icons.campaign_rounded, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunicationHubScreen()))),
        _operationTile(theme, 'Admin Reports', 'Registry & log exports', Icons.assignment_rounded, Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecretaryReportsScreen()))),
        const SizedBox(height: 80),
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
        subtitle: Text(sub, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
    );
  }
}
