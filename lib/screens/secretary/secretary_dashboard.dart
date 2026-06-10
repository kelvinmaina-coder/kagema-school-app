import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/supabase_service.dart';
import '../settings/settings_screen.dart';
import 'student_registration.dart';
import 'parent_management.dart';
import 'appointment_management.dart';
import 'attendance_viewer.dart';
import 'secretary_reports.dart';
import 'visitors_manager.dart';
import '../../app_theme.dart';

class SecretaryDashboard extends StatefulWidget {
  const SecretaryDashboard({super.key});

  @override
  State<SecretaryDashboard> createState() => _SecretaryDashboardState();
}

class _SecretaryDashboardState extends State<SecretaryDashboard> {
  Map<String, dynamic> _stats = {
    'totalStudents': 0,
    'newAdmissions': 0,
    'upcomingAppointments': 0,
    'announcements': 0,
  };
  List<Map<String, dynamic>> _recentAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final stats = await SupabaseService.instance.getSecretaryStats();
      final appointments = await SupabaseService.instance.getAppointments();
      
      if (mounted) {
        setState(() {
          _stats = stats;
          _recentAppointments = List<Map<String, dynamic>>.from(appointments.take(3));
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Secretary Sync Error: $e");
      if (mounted) setState(() => _isLoading = false);
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
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  _buildHeroAppBar(theme),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildMetricsGrid(theme),
                          const SizedBox(height: 30),
                          _buildActionGrid(context, theme),
                          const SizedBox(height: 30),
                          _buildAppointmentSection(theme),
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

  Widget _buildHeroAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 140.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Registrar Portal', style: TextStyle(fontWeight: FontWeight.bold)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, Colors.indigo]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(ThemeData theme) {
    return Row(
      children: [
        _miniStatCard('Students', _stats['totalStudents'].toString(), Icons.people, Colors.blue),
        const SizedBox(width: 12),
        _miniStatCard('Appts', _stats['upcomingAppointments'].toString(), Icons.event, Colors.orange),
        const SizedBox(width: 12),
        _miniStatCard('Bulletins', _stats['announcements'].toString(), Icons.campaign, Colors.purple),
      ],
    );
  }

  Widget _miniStatCard(String label, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _actionBtn('Admission', Icons.person_add, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRegistrationScreen()))),
        _actionBtn('Visitors', Icons.badge, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorsManagerScreen()))),
        _actionBtn('Parents', Icons.family_restroom, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentManagementScreen()))),
        _actionBtn('Reports', Icons.assignment, Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecretaryReportsScreen()))),
      ],
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withOpacity(0.2))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('UPCOMING APPOINTMENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 12),
        ..._recentAppointments.map((a) => Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_today, size: 18),
            title: Text(a['visitor_name'] ?? 'Visitor'),
            subtitle: Text(a['appointment_date'] ?? 'No date'),
            trailing: const Icon(Icons.chevron_right),
          ),
        )),
      ],
    );
  }
}
