import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';
import '../../services/authentication_service.dart';
import '../../models/school_models.dart';
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
  List<Map<String, dynamic>> _schedule = [];
  bool _isLoading = true;
  bool _isCheckedIn = false;
  String? _lastCheckInTime;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final auth = Provider.of<AuthenticationService>(context, listen: false);
    // In Supabase, the ID is usually a UUID from auth.uid()
    final String staffId = SupabaseService.instance.client.auth.currentUser?.id ?? ""; 
    
    setState(() => _isLoading = true);
    
    try {
      final profile = await SupabaseService.instance.getStaffProfile(staffId);
      final tasks = await SupabaseService.instance.getTasks(staffId);
      final announcements = await SupabaseService.instance.getNotifications('staff');
      final schedule = await SupabaseService.instance.getTeacherSchedule(staffId); 
      final attendance = await SupabaseService.instance.getStaffAttendanceHistory(staffId);
      
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final todayRecords = attendance.where((a) => a['date'] == today).toList();

      if (mounted) {
        setState(() {
          _staffProfile = profile;
          _tasks = tasks.where((t) => t['status'] != 'Completed').toList();
          _announcements = announcements;
          _schedule = schedule;
          
          if (todayRecords.isNotEmpty) {
            _isCheckedIn = todayRecords.first['status'] == 'Checked-In';
            _lastCheckInTime = todayRecords.first['time'];
          } else {
            _isCheckedIn = false;
            _lastCheckInTime = null;
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("StaffDashboard Error: $e");
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
          SnackBar(
            content: Text('Attendance Logged: $newStatus'),
            backgroundColor: _isCheckedIn ? Colors.orange : Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
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
                physics: const BouncingScrollPhysics(),
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
                          _buildSectionHeader(theme, 'WORK SCHEDULE', Icons.calendar_today_rounded),
                          const SizedBox(height: 12),
                          _buildScheduleSection(theme),
                          const SizedBox(height: 32),
                          _buildSectionHeader(theme, 'ACTIVE TASKS', Icons.assignment_turned_in_rounded),
                          const SizedBox(height: 12),
                          _buildTasksSection(theme),
                          const SizedBox(height: 32),
                          _buildSectionHeader(theme, 'SCHOOL ANNOUNCEMENTS', Icons.campaign_rounded),
                          const SizedBox(height: 12),
                          _buildAnnouncementsSection(theme),
                          const SizedBox(height: 40),
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
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Staff Dashboard', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        background: Container(
          decoration: BoxDecoration(
            gradient: gemini?.primaryGradient ?? LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)]),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            child: _staffProfile?['photo_url'] != null 
              ? ClipRRect(borderRadius: BorderRadius.circular(35), child: Image.network(_staffProfile!['photo_url'], fit: BoxFit.cover))
              : Icon(Icons.person, size: 40, color: theme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_staffProfile?['name'] ?? 'Authorized Staff', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_staffProfile?['role']?.toUpperCase() ?? 'STAFF', style: TextStyle(color: theme.primaryColor, fontSize: 10, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 4),
                Text(_staffProfile?['email'] ?? 'staff@school.edu', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(role: 'Staff'))),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendancePanel(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isCheckedIn ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (_isCheckedIn ? Colors.green : Colors.red).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(_isCheckedIn ? Icons.check_circle_rounded : Icons.cancel_rounded, color: _isCheckedIn ? Colors.green : Colors.red, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isCheckedIn ? 'Status: ON DUTY' : 'Status: OFF DUTY', style: TextStyle(fontWeight: FontWeight.w900, color: _isCheckedIn ? Colors.green : Colors.red)),
                Text(_isCheckedIn ? 'Checked in today at $_lastCheckInTime' : 'Please check in to start your shift', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _handleCheckInOut,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCheckedIn ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: Text(_isCheckedIn ? 'CHECK OUT' : 'CHECK IN'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.primaryColor.withOpacity(0.5)),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: theme.primaryColor.withOpacity(0.5), letterSpacing: 1.2)),
      ],
    );
  }

  Widget _buildScheduleSection(ThemeData theme) {
    if (_schedule.isEmpty) return _emptyState('No scheduled duties found.');
    return Column(
      children: _schedule.map((s) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.access_time, color: Colors.indigo),
          title: Text(s['subject'] ?? 'Duty'),
          subtitle: Text('${s['day']} • ${s['time_slot']}'),
          trailing: Text(s['room'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      )).toList(),
    );
  }

  Widget _buildTasksSection(ThemeData theme) {
    if (_tasks.isEmpty) return _emptyState('All tasks completed! Good job.');
    return Column(
      children: _tasks.map((t) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.assignment_outlined, color: Colors.orange),
          title: Text(t['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Deadline: ${t['due_date']}'),
          trailing: IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: () async {
              await SupabaseService.instance.updateTaskStatus(t['task_id'], 'Completed');
              _loadDashboardData();
            },
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildAnnouncementsSection(ThemeData theme) {
    if (_announcements.isEmpty) return _emptyState('No recent announcements.');
    return Column(
      children: _announcements.take(3).map((n) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.campaign, color: Colors.blue),
          title: Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(n['message'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      )).toList(),
    );
  }

  Widget _emptyState(String msg) {
    return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 12))));
  }

  Widget _buildStaffDrawer(ThemeData theme) {
    final String staffId = SupabaseService.instance.client.auth.currentUser?.id ?? "";
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(radius: 30, child: Icon(Icons.person)),
                const SizedBox(height: 12),
                Text(_staffProfile?['name'] ?? 'Authorized Staff', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(_staffProfile?['role'] ?? 'Staff', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          ListTile(leading: const Icon(Icons.dashboard), title: const Text('Main Dashboard'), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.person), title: const Text('My Profile'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(role: 'Staff')))),
          ListTile(leading: const Icon(Icons.history), title: const Text('Attendance History'), onTap: _showAttendanceHistory),
          ListTile(leading: const Icon(Icons.time_to_leave), title: const Text('Leave Requests'), onTap: _showLeaveManagement),
          ListTile(leading: const Icon(Icons.message), title: const Text('Messages'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CommunicationScreen(senderRole: 'Staff', senderId: staffId)))),
          const Divider(),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Logout'), onTap: () {
            Provider.of<AuthenticationService>(context, listen: false).logout();
            Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
          }),
        ],
      ),
    );
  }

  void _showAttendanceHistory() async {
    final String staffId = SupabaseService.instance.client.auth.currentUser?.id ?? "";
    final history = await SupabaseService.instance.getStaffAttendanceHistory(staffId);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Attendance History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final h = history[index];
                  return ListTile(
                    leading: Icon(h['status'] == 'Checked-In' ? Icons.login : Icons.logout, color: h['status'] == 'Checked-In' ? Colors.green : Colors.red),
                    title: Text(h['date']),
                    subtitle: Text('${h['status']} at ${h['time']}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaveManagement() async {
    final String staffId = SupabaseService.instance.client.auth.currentUser?.id ?? "";
    final history = await SupabaseService.instance.getLeaveHistory(staffId);
    if (!mounted) return;
    
    final reasonController = TextEditingController();
    final startController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('Leave Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'Reason for leave')),
              TextField(
                controller: startController, 
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Start Date', suffixIcon: Icon(Icons.calendar_month)),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)));
                  if (d != null) setModalState(() => startController.text = DateFormat('yyyy-MM-dd').format(d));
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (reasonController.text.isNotEmpty && startController.text.isNotEmpty) {
                      await SupabaseService.instance.insertLeaveRequest({
                        'staff_id': staffId,
                        'reason': reasonController.text,
                        'start_date': startController.text,
                        'end_date': startController.text,
                        'status': 'Pending',
                      });
                      Navigator.pop(context);
                      _showLeaveManagement();
                    }
                  },
                  child: const Text('SUBMIT REQUEST'),
                ),
              ),
              const Divider(height: 40),
              const Text('Recent Requests', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final l = history[index];
                    return ListTile(
                      title: Text(l['reason']),
                      subtitle: Text('Status: ${l['status']} • Date: ${l['start_date']}'),
                      trailing: Icon(l['status'] == 'Approved' ? Icons.check_circle : Icons.pending, color: l['status'] == 'Approved' ? Colors.green : Colors.orange),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
