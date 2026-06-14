import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../services/pdf_generator_service.dart';
import '../settings/settings_screen.dart';
import 'task_list_screen.dart';
import '../../app_theme.dart';
import 'dart:async';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int _currentIndex = 0;
  Map<String, dynamic>? _staffProfile;
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _leaveHistory = [];
  List<Map<String, dynamic>> _attendanceHistory = [];
  
  bool _isLoading = true;
  bool _isCheckedIn = false;
  String? _lastCheckInTime;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final user = SupabaseService.instance.client.auth.currentUser;
    if (user == null || user.email == null) {
       setState(() { _isLoading = false; _errorMessage = "Session expired. Please log in again."; });
       return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });
    
    try {
      final profile = await SupabaseService.instance.getStaffProfileByEmail(user.email!);
      if (profile == null) throw "Staff record not found.";
      
      final String staffId = profile['staff_id'];

      final results = await Future.wait([
        SupabaseService.instance.getTasks(staffId),
        SupabaseService.instance.getNotifications('staff'),
        SupabaseService.instance.getStaffAttendanceHistory(staffId),
        SupabaseService.instance.getStaffLeaveHistory(staffId),
      ]);
      
      if (mounted) {
        setState(() {
          _staffProfile = profile;
          final allTasks = results[0] as List<Map<String, dynamic>>;
          _tasks = allTasks.where((t) => t['status'] != 'Completed').toList();
          _announcements = results[1] as List<Map<String, dynamic>>;
          _attendanceHistory = results[2] as List<Map<String, dynamic>>;
          _leaveHistory = results[3] as List<Map<String, dynamic>>;
          
          final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final todayRecords = _attendanceHistory.where((a) => a['date'] == today).toList();
          if (todayRecords.isNotEmpty) {
            final latest = todayRecords.first;
            _isCheckedIn = latest['status'] == 'Checked-In';
            if (_isCheckedIn) _lastCheckInTime = latest['time'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _errorMessage = "Connection error. Please check your internet."; });
    }
  }

  Future<void> _handleCheckInOut() async {
    if (_staffProfile == null) return;
    final staffId = _staffProfile!['staff_id'];
    final newStatus = _isCheckedIn ? 'Checked-Out' : 'Checked-In';
    try {
      await SupabaseService.instance.staffCheckInOut(staffId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status Updated: $newStatus'), backgroundColor: _isCheckedIn ? Colors.orange.shade800 : Colors.green.shade800, behavior: SnackBarBehavior.floating));
        _loadDashboardData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : _currentIndex == 0 ? _buildOverviewTab(theme, gemini) : _buildRecordsTab(theme, gemini),
      ) ?? const SizedBox(),
      bottomNavigationBar: _buildModernNavBar(theme),
    );
  }

  Widget _buildOverviewTab(ThemeData theme, GeminiThemeExtension? gemini) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: theme.primaryColor,
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
                  _buildIDCard(theme, gemini),
                  const SizedBox(height: 32),
                  _buildAttendancePanel(theme, gemini),
                  const SizedBox(height: 48),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildSectionHeader('MY ACTIVE TASKS', Icons.assignment_turned_in_rounded), TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskListScreen(staffId: _staffProfile?['staff_id'] ?? ""))), child: const Text('View All', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))]),
                  _buildTasksSection(theme, gemini),
                  const SizedBox(height: 40),
                  _buildSectionHeader('SCHOOL ANNOUNCEMENTS', Icons.campaign_rounded),
                  _buildAnnouncementsSection(theme, gemini),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsTab(ThemeData theme, GeminiThemeExtension? gemini) {
    return CustomScrollView(
      slivers: [
        _buildHeroAppBar(theme, gemini, title: 'MY ACTIVITY HISTORY'),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('PAYSLIP RECORDS', Icons.account_balance_wallet_rounded),
                _buildPayslipCard(theme, gemini),
                const SizedBox(height: 48),
                _buildSectionHeader('LEAVE REQUEST STATUS', Icons.history_edu_rounded),
                _buildLeaveHistory(theme, gemini),
                const SizedBox(height: 48),
                _buildSectionHeader('ATTENDANCE HISTORY', Icons.verified_user_rounded),
                _buildAttendanceHistory(theme, gemini),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIDCard(ThemeData theme, GeminiThemeExtension? gemini) {
    final content = Row(children: [
      CircleAvatar(radius: 40, backgroundColor: theme.primaryColor.withOpacity(0.1), child: Text(_staffProfile?['name']?[0] ?? 'S', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: theme.primaryColor))),
      const SizedBox(width: 20),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_staffProfile?['name']?.toString().toUpperCase() ?? 'STAFF MEMBER', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(_staffProfile?['role']?.toString().toUpperCase() ?? 'STAFF ROLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.primaryColor, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text('ID: ${_staffProfile?['staff_id'] ?? 'Loading...'}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
      ])),
      IconButton(icon: const Icon(Icons.qr_code_2_rounded, size: 30), onPressed: () {})
    ]);

    return gemini?.buildGlowContainer(
      borderRadius: 35, borderThickness: 2, backgroundColor: theme.cardColor.withOpacity(0.9), padding: const EdgeInsets.all(24),
      child: content,
    ) ?? Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(35)), child: content);
  }

  Widget _buildAttendancePanel(ThemeData theme, GeminiThemeExtension? gemini) {
    final statusColor = _isCheckedIn ? Colors.green : Colors.redAccent;
    final content = Row(children: [
      Icon(_isCheckedIn ? Icons.verified_user_rounded : Icons.gpp_maybe_rounded, color: statusColor, size: 30),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_isCheckedIn ? 'STATUS: ON DUTY' : 'STATUS: OFF DUTY', style: TextStyle(fontWeight: FontWeight.w900, color: statusColor, letterSpacing: 1.5, fontSize: 12)), if (_isCheckedIn && _lastCheckInTime != null) Text('Shift started at: $_lastCheckInTime', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey))])),
      ElevatedButton(onPressed: _handleCheckInOut, style: ElevatedButton.styleFrom(backgroundColor: statusColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 8), child: Text(_isCheckedIn ? 'CHECK OUT' : 'CHECK IN', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)))
    ]);

    return gemini?.buildGlowContainer(
      borderRadius: 24, borderThickness: 2, backgroundColor: statusColor.withOpacity(0.05), padding: const EdgeInsets.all(20), useAIBorder: true,
      child: content,
    ) ?? Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: statusColor.withOpacity(0.05), borderRadius: BorderRadius.circular(24)), child: content);
  }

  Widget _buildPayslipCard(ThemeData theme, GeminiThemeExtension? gemini) {
    final double salary = (_staffProfile?['salary'] as num? ?? 0.0).toDouble();
    final content = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.payments_rounded, color: Colors.green, size: 24)),
      title: const Text('Current Basic Salary', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.blueGrey)),
      subtitle: Text('Ksh ${NumberFormat('#,###').format(salary)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      trailing: ElevatedButton(onPressed: () { if (_staffProfile != null) PdfGeneratorService.generatePayslip(_staffProfile!, DateFormat('MMMM yyyy').format(DateTime.now())); }, style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('VIEW PDF', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
    );

    return gemini?.buildGlowContainer(
      borderRadius: 30, borderThickness: 1.5, backgroundColor: theme.cardColor.withOpacity(0.9), padding: EdgeInsets.zero, useAIBorder: true,
      child: content,
    ) ?? Card(child: content);
  }

  Widget _buildHeroAppBar(ThemeData theme, GeminiThemeExtension? gemini, {String title = 'STAFF PORTAL'}) {
    return SliverAppBar(expandedHeight: 120.0, pinned: true, backgroundColor: Colors.transparent, elevation: 0, flexibleSpace: FlexibleSpaceBar(title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2, color: Colors.white)), centerTitle: true, background: Container(decoration: BoxDecoration(gradient: gemini?.primaryGradient, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)), boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)]), child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.badge_rounded, size: 160, color: Colors.white.withOpacity(0.1)))]))));
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    return InkWell(onTap: () => setState(() => _currentIndex = index), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey, size: 24), const SizedBox(height: 2), Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isSelected ? Theme.of(context).primaryColor : Colors.grey))]));
  }

  Widget _buildModernNavBar(ThemeData theme) {
    return Container(margin: const EdgeInsets.fromLTRB(20, 0, 20, 20), height: 70, decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.95), borderRadius: BorderRadius.circular(30), border: Border.all(color: theme.dividerColor.withOpacity(0.05)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30)]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_navItem(0, Icons.dashboard_rounded, 'Overview'), _navItem(1, Icons.history_rounded, 'My Records')]));
  }

  Widget _buildSectionHeader(String title, IconData icon) { return Padding(padding: const EdgeInsets.only(left: 4, bottom: 16), child: Row(children: [Icon(icon, size: 16, color: Colors.blueGrey), const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2))])); }

  Widget _emptyState(IconData icon, String msg) { return Container(padding: const EdgeInsets.symmetric(vertical: 32), width: double.infinity, child: Column(children: [Icon(icon, size: 40, color: Colors.grey.withOpacity(0.3)), const SizedBox(height: 12), Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5))])); }

  void _showTaskDialog(Map<String, dynamic> task) { final theme = Theme.of(context); showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(35))), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('TASK DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)), const SizedBox(height: 12), Text(task['title'] ?? 'Staff Duty', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 16), Text(task['description'] ?? 'No additional instructions provided.', style: const TextStyle(fontSize: 14, height: 1.5)), const SizedBox(height: 32), SizedBox(width: double.infinity, height: 60, child: ElevatedButton(onPressed: () async { await SupabaseService.instance.updateTaskStatus(task['task_id'].toString(), 'Completed'); if (mounted) { Navigator.pop(context); _loadDashboardData(); } }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('MARK AS COMPLETED', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)))), const SizedBox(height: 32)]))); }
  void _showAnnouncementDialog(Map<String, dynamic> n) { final theme = Theme.of(context); showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(35))), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('SCHOOL ANNOUNCEMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blue, letterSpacing: 2)), const SizedBox(height: 12), Text(n['title'] ?? 'Notice', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 16), Text(n['message'] ?? '', style: const TextStyle(fontSize: 15, height: 1.6, fontWeight: FontWeight.w500)), const SizedBox(height: 40), SizedBox(width: double.infinity, height: 50, child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.bold)))), const SizedBox(height: 20)]))); }
  void _showLeaveDialog() { final theme = Theme.of(context); final reasonCtrl = TextEditingController(); String leaveType = 'Sick Leave'; showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => Container(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24), decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(35))), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('LEAVE APPLICATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)), const SizedBox(height: 24), DropdownButtonFormField<String>(value: leaveType, items: ['Sick Leave', 'Personal', 'Vacation', 'Emergency'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(), onChanged: (v) => leaveType = v!, decoration: InputDecoration(labelText: 'Type of Leave', border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)))), const SizedBox(height: 20), TextField(controller: reasonCtrl, maxLines: 3, decoration: InputDecoration(labelText: 'Reason for Leave', border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)))), const SizedBox(height: 32), SizedBox(width: double.infinity, height: 60, child: ElevatedButton(onPressed: () async { if (reasonCtrl.text.isNotEmpty && _staffProfile != null) { final data = {'staff_id': _staffProfile!['staff_id'], 'type': leaveType, 'reason': reasonCtrl.text.trim(), 'status': 'Pending', 'date': DateFormat('yyyy-MM-dd').format(DateTime.now())}; await SupabaseService.instance.requestLeave(data); if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave request submitted to HR'))); _loadDashboardData(); } } }, style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('SUBMIT REQUEST', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)))), const SizedBox(height: 40)]))); }
  Widget _buildErrorPanel(String msg) { return Container(margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.withOpacity(0.1))), child: Row(children: [const Icon(Icons.sync_problem_rounded, color: Colors.red), const SizedBox(width: 12), Expanded(child: Text(msg, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold))), IconButton(icon: const Icon(Icons.refresh, color: Colors.red, size: 20), onPressed: _loadDashboardData)])); }
  Widget _buildTasksSection(ThemeData theme, GeminiThemeExtension? gemini) { if (_tasks.isEmpty) return _emptyState(Icons.task_alt_rounded, 'ALL TASKS COMPLETED'); return Column(children: _tasks.map((t) => Padding(padding: const EdgeInsets.only(bottom: 12), child: gemini?.buildGlowContainer(borderRadius: 24, borderThickness: 1, backgroundColor: theme.cardColor.withOpacity(0.85), padding: EdgeInsets.zero, child: ListTile(onTap: () => _showTaskDialog(t), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.assignment_outlined, color: Colors.orange, size: 22)), title: Text(t['title'] ?? 'Task', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)), subtitle: Text('Priority: ${t['priority'] ?? "Medium"} \nDue: ${t['due_date']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.4)), trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey))))).toList()); }
  Widget _buildAnnouncementsSection(ThemeData theme, GeminiThemeExtension? gemini) { if (_announcements.isEmpty) return _emptyState(Icons.campaign_outlined, 'NO NEW ANNOUNCEMENTS'); return Column(children: _announcements.take(3).map((n) => Padding(padding: const EdgeInsets.only(bottom: 12), child: gemini?.buildGlowContainer(borderRadius: 24, borderThickness: 1, backgroundColor: theme.cardColor.withOpacity(0.85), padding: EdgeInsets.zero, child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.campaign_rounded, color: Colors.blue, size: 22)), title: Text(n['title'] ?? 'Notice', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)), subtitle: Text(n['message'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)))))).toList()); }

  Widget _buildLeaveHistory(ThemeData theme, GeminiThemeExtension? gemini) {
    if (_leaveHistory.isEmpty) return _emptyState(Icons.history_edu_rounded, 'NO LEAVE HISTORY FOUND');
    return Column(children: _leaveHistory.map((l) => Padding(padding: const EdgeInsets.only(bottom: 12), child: gemini?.buildGlowContainer(borderRadius: 24, borderThickness: 1, backgroundColor: theme.cardColor.withOpacity(0.85), padding: EdgeInsets.zero, child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.event_note_rounded, color: Colors.blue, size: 22)), title: Text(l['type'] ?? 'Leave Request', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)), subtitle: Text('Date: ${l['date']} \nStatus: ${l['status']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.4)), trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: (l['status'] == 'Approved' ? Colors.green : Colors.orange).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text(l['status']?.toUpperCase() ?? 'PENDING', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: l['status'] == 'Approved' ? Colors.green : Colors.orange))))))).toList());
  }

  Widget _buildAttendanceHistory(ThemeData theme, GeminiThemeExtension? gemini) {
    if (_attendanceHistory.isEmpty) return _emptyState(Icons.verified_user_rounded, 'NO ATTENDANCE RECORDS');
    return Column(children: _attendanceHistory.map((a) => Padding(padding: const EdgeInsets.only(bottom: 12), child: gemini?.buildGlowContainer(borderRadius: 24, borderThickness: 1, backgroundColor: theme.cardColor.withOpacity(0.85), padding: EdgeInsets.zero, child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 22)), title: Text(a['status'] ?? 'Checked', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)), subtitle: Text('Date: ${a['date']} \nTime: ${a['time']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.4)))))).toList());
  }

  Widget _buildStaffDrawer(ThemeData theme) { return Drawer(backgroundColor: theme.scaffoldBackgroundColor, child: ListView(padding: EdgeInsets.zero, children: [DrawerHeader(decoration: BoxDecoration(gradient: LinearGradient(colors: [theme.primaryColor, Colors.indigo.shade900])), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [Text('Kagema System', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)), Text('STAFF DIRECTORY', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))])), ListTile(leading: const Icon(Icons.settings_rounded), title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(role: 'Staff')))), ListTile(leading: const Icon(Icons.logout_rounded, color: Colors.red), title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)), onTap: () => Navigator.pushReplacementNamed(context, '/login'))])); }
}
