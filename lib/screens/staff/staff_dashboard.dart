import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';
import '../../services/authentication_service.dart';
import '../settings/settings_screen.dart';
import '../common/communication_screen.dart';
import '../../app_theme.dart';
import 'dart:async';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  Map<String, dynamic>? _staffProfile;
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;
  bool _isCheckedIn = false;
  String? _lastCheckInTime;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final String staffId = SupabaseService.instance.client.auth.currentUser?.id ?? ""; 
    if (staffId.isEmpty) return;

    setState(() => _isLoading = true);
    
    try {
      final profile = await SupabaseService.instance.getStaffProfile(staffId);
      final tasks = await SupabaseService.instance.getTasks(staffId);
      final announcements = await SupabaseService.instance.getNotifications('staff');
      final attendance = await SupabaseService.instance.getStaffAttendanceHistory(staffId);
      
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final todayRecords = attendance.where((a) => a['date'] == today).toList();

      if (mounted) {
        setState(() {
          _staffProfile = profile;
          _tasks = tasks.where((t) => t['status'] != 'Completed').toList();
          _announcements = announcements;
          
          if (todayRecords.isNotEmpty) {
            _isCheckedIn = todayRecords.any((a) => a['status'] == 'Checked-In');
            _lastCheckInTime = todayRecords.where((a) => a['status'] == 'Checked-In').last['time'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCheckInOut() async {
    final String staffId = SupabaseService.instance.client.auth.currentUser?.id ?? "";
    final newStatus = _isCheckedIn ? 'Checked-Out' : 'Checked-In';
    
    try {
      await SupabaseService.instance.staffCheckInOut(staffId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Attendance Logged: $newStatus'), backgroundColor: _isCheckedIn ? Colors.orange : Colors.green),
        );
        _loadDashboardData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: _buildStaffDrawer(theme),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
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
                          _buildProfileCard(theme),
                          const SizedBox(height: 20),
                          _buildAttendancePanel(theme),
                          const SizedBox(height: 32),
                          _buildSectionHeader(theme, 'ACTIVE TASKS', Icons.assignment_turned_in_rounded),
                          _buildTasksSection(theme),
                          const SizedBox(height: 32),
                          _buildSectionHeader(theme, 'SCHOOL ANNOUNCEMENTS', Icons.campaign_rounded),
                          _buildAnnouncementsSection(theme),
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
      expandedHeight: 120.0,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Staff Portal', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, Colors.indigo.shade800]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            child: Text(_staffProfile?['name']?[0] ?? 'S', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.primaryColor)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_staffProfile?['name'] ?? 'Authorized Staff', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(_staffProfile?['role']?.toUpperCase() ?? 'STAFF', style: TextStyle(color: theme.primaryColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendancePanel(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: (_isCheckedIn ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (_isCheckedIn ? Colors.green : Colors.red).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(_isCheckedIn ? Icons.verified_user_rounded : Icons.gpp_maybe_rounded, color: _isCheckedIn ? Colors.green : Colors.red, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isCheckedIn ? 'ON DUTY' : 'OFF DUTY', style: TextStyle(fontWeight: FontWeight.w900, color: _isCheckedIn ? Colors.green : Colors.red)),
                if (_isCheckedIn) Text('Started at $_lastCheckInTime', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _handleCheckInOut,
            style: ElevatedButton.styleFrom(backgroundColor: _isCheckedIn ? Colors.red : Colors.green, foregroundColor: Colors.white),
            child: Text(_isCheckedIn ? 'CHECK OUT' : 'CHECK IN'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.primaryColor.withOpacity(0.5)),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.primaryColor.withOpacity(0.5), letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTasksSection(ThemeData theme) {
    if (_tasks.isEmpty) return _emptyState('All cloud-assigned tasks complete.');
    return Column(
      children: _tasks.map((t) => Card(
        child: ListTile(
          leading: const Icon(Icons.assignment_outlined, color: Colors.orange),
          title: Text(t['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Due: ${t['due_date']}'),
          trailing: const Icon(Icons.chevron_right),
        ),
      )).toList(),
    );
  }

  Widget _buildAnnouncementsSection(ThemeData theme) {
    if (_announcements.isEmpty) return _emptyState('No live notices for staff.');
    return Column(
      children: _announcements.take(3).map((n) => Card(
        child: ListTile(
          leading: const Icon(Icons.campaign, color: Colors.blue),
          title: Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(n['message'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      )).toList(),
    );
  }

  Widget _emptyState(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(child: Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 12))),
    );
  }

  Widget _buildStaffDrawer(ThemeData theme) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(decoration: BoxDecoration(color: theme.primaryColor), child: const Text('Staff Registry', style: TextStyle(color: Colors.white, fontSize: 24))),
          ListTile(leading: const Icon(Icons.settings), title: const Text('Control Center'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(role: 'Staff')))),
          ListTile(leading: const Icon(Icons.logout), title: const Text('End Session'), onTap: () => Navigator.pushReplacementNamed(context, '/login')),
        ],
      ),
    );
  }
}
