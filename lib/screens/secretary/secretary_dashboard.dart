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
import '../common/communication_screen.dart';
import '../common/document_management.dart';
import '../../app_theme.dart';

class SecretaryDashboard extends StatefulWidget {
  const SecretaryDashboard({super.key});

  @override
  State<SecretaryDashboard> createState() => _SecretaryDashboardState();
}

class _SecretaryDashboardState extends State<SecretaryDashboard> {
  StreamSubscription? _notifSubscription;
  Map<String, dynamic> _stats = {
    'totalStudents': 0,
    'newAdmissions': 0,
    'upcomingAppointments': 0,
    'announcements': 0,
  };
  List<Map<String, dynamic>> _recentAppointments = [];
  List<Map<String, dynamic>> _recentAnnouncements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _notifSubscription = SupabaseService.instance.notificationStream.listen((data) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final stats = await SupabaseService.instance.getSecretaryStats();
      final appointments = await SupabaseService.instance.getAppointments();
      final announcements = await SupabaseService.instance.getNotifications('All');
      
      if (mounted) {
        setState(() {
          _stats = stats;
          _recentAppointments = appointments.take(3).toList();
          _recentAnnouncements = announcements.take(3).toList();
        });
      }
    } catch (e) {
      debugPrint("SecretaryDashboard Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    super.dispose();
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
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildHeroAppBar(theme, gemini),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildMetricsGrid(theme),
                          const SizedBox(height: 32),
                          _buildSectionLabel(theme, 'QUICK OPERATIONS'),
                          const SizedBox(height: 16),
                          _buildActionMosaic(theme),
                          const SizedBox(height: 32),
                          _buildSectionLabel(theme, 'UPCOMING APPOINTMENTS'),
                          const SizedBox(height: 16),
                          _buildRecentAppointments(theme),
                          const SizedBox(height: 32),
                          _buildSectionLabel(theme, 'LATEST ANNOUNCEMENTS'),
                          const SizedBox(height: 16),
                          _buildRecentAnnouncements(theme),
                          const SizedBox(height: 32),
                          _buildSectionLabel(theme, 'OFFICE CHANNELS'),
                          const SizedBox(height: 16),
                          _buildWorkflowCard(theme, 'Communication Center', 'Broadcast to parents or teachers.', Icons.campaign_rounded, Colors.orange, () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunicationScreen(senderRole: 'Secretary', senderId: 'SEC01')));
                          }),
                          const SizedBox(height: 12),
                          _buildWorkflowCard(theme, 'Digital Filing', 'Access letters, forms & archives.', Icons.description_rounded, Colors.purple, () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentManagementScreen(role: 'Secretary')));
                          }),
                          const SizedBox(height: 40),
                          _buildCreativeSignOut(theme),
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

  Widget _buildHeroAppBar(ThemeData theme, GeminiThemeExtension? gemini) {
    return SliverAppBar(
      expandedHeight: 160.0,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OFFICE OF THE REGISTRAR', style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            Text('Secretary Portal', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.white)),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: gemini?.primaryGradient ?? LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)]),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white, size: 18)),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(role: 'Secretary'))),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildMetricsGrid(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            _metricCard(theme, 'Total Pupils', '${_stats['totalStudents'] ?? 0}', Icons.groups_rounded, Colors.blue),
            const SizedBox(width: 16),
            _metricCard(theme, 'New Admits', '${_stats['newAdmissions'] ?? 0}', Icons.person_add_alt_1_rounded, Colors.green),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _metricCard(theme, 'Pending Appts', '${_stats['upcomingAppointments'] ?? 0}', Icons.event_available_rounded, Colors.orange),
            const SizedBox(width: 16),
            _metricCard(theme, 'Bulletins', '${_stats['announcements'] ?? 0}', Icons.campaign_rounded, Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _metricCard(ThemeData theme, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String text) {
    return Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.primaryColor.withOpacity(0.5), letterSpacing: 2));
  }

  Widget _buildActionMosaic(ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _mosaicCard(theme, 'Enroll Student', Icons.person_add_rounded, Colors.indigo, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRegistrationScreen())).then((_) => _loadData());
        }),
        _mosaicCard(theme, 'Parent Links', Icons.family_restroom_rounded, Colors.blue, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentManagementScreen()));
        }),
        _mosaicCard(theme, 'Appointments', Icons.calendar_month_rounded, Colors.teal, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentManagementScreen())).then((_) => _loadData());
        }),
        _mosaicCard(theme, 'Visitors', Icons.badge_rounded, Colors.green, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorsManagerScreen()));
        }),
        _mosaicCard(theme, 'Attendance', Icons.fact_check_rounded, Colors.amber, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceViewerScreen()));
        }),
        _mosaicCard(theme, 'Gen Reports', Icons.assessment_rounded, Colors.redAccent, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SecretaryReportsScreen()));
        }),
      ],
    );
  }

  Widget _mosaicCard(ThemeData theme, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.7),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAppointments(ThemeData theme) {
    if (_recentAppointments.isEmpty) return const Center(child: Text('No upcoming appointments', style: TextStyle(color: Colors.grey, fontSize: 12)));
    return Column(
      children: _recentAppointments.map((a) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          dense: true,
          title: Text(a['visitor_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${a['appointment_date'] ?? ""}'),
        ),
      )).toList(),
    );
  }

  Widget _buildRecentAnnouncements(ThemeData theme) {
    if (_recentAnnouncements.isEmpty) return const Center(child: Text('No announcements yet', style: TextStyle(color: Colors.grey, fontSize: 12)));
    return Column(
      children: _recentAnnouncements.map((n) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          dense: true,
          title: Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(n['message'] ?? '', maxLines: 1),
        ),
      )).toList(),
    );
  }

  Widget _buildWorkflowCard(ThemeData theme, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 11)),
    );
  }

  Widget _buildCreativeSignOut(ThemeData theme) {
    return InkWell(
      onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
      child: const Center(
        child: Text('LOGOUT OFFICE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
      ),
    );
  }
}
