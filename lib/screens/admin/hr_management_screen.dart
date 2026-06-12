import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';
import 'staff_registration_screen.dart';

class HRManagementScreen extends StatefulWidget {
  const HRManagementScreen({super.key});

  @override
  State<HRManagementScreen> createState() => _HRManagementScreenState();
}

class _HRManagementScreenState extends State<HRManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _leaveRequests = [];
  List<Map<String, dynamic>> _staffList = [];
  Map<String, dynamic> _payrollSummary = {'total': 0.0, 'staffCount': 0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadHRData();
  }

  Future<void> _loadHRData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final payroll = await SupabaseService.instance.getPayrollSummary();
      final leaves = await SupabaseService.instance.getLeaveRequests();
      final staff = await SupabaseService.instance.getAllStaff();
      
      if (mounted) {
        setState(() {
          _payrollSummary = payroll;
          _leaveRequests = leaves;
          _staffList = staff;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("HR Sync Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Human Resources', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, Colors.teal]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffRegistrationScreen()));
              if (result == true) _loadHRData();
            },
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'DIRECTORY', icon: Icon(Icons.groups_rounded, size: 18)),
            Tab(text: 'PAYROLL', icon: Icon(Icons.payments_rounded, size: 18)),
            Tab(text: 'LEAVE', icon: Icon(Icons.beach_access_rounded, size: 18)),
          ],
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 48),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildDirectoryTab(theme),
                  _buildPayrollTab(theme),
                  _buildLeaveTab(theme),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildDirectoryTab(ThemeData theme) {
    if (_staffList.isEmpty) {
      return _buildEmptyState(Icons.group_off_rounded, 'No staff members registered.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _staffList.length,
      itemBuilder: (context, index) {
        final staff = _staffList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Text(staff['role']?[0] ?? 'S', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
            ),
            title: Text(staff['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff['role'] ?? 'Staff'),
                Text(staff['phone'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                  onPressed: () async {
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => StaffRegistrationScreen(staffToEdit: staff)));
                    if (result == true) _loadHRData();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  onPressed: () => _confirmDelete(staff['staff_id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff?'),
        content: const Text('This action cannot be undone. All related records will be affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await SupabaseService.instance.deleteStaff(id);
        _loadHRData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildPayrollTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _statCard(theme, 'ESTIMATED MONTHLY PAYROLL', 'Ksh ${NumberFormat('#,###').format(_payrollSummary['total'])}', Icons.account_balance_wallet, Colors.green),
          const SizedBox(height: 20),
          _statCard(theme, 'TOTAL ACTIVE EMPLOYEES', '${_payrollSummary['staffCount']}', Icons.groups_rounded, Colors.blue),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: () {}, 
              icon: const Icon(Icons.print_rounded),
              label: const Text('GENERATE CLOUD PAYSLIPS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(ThemeData theme, String label, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
              Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveTab(ThemeData theme) {
    if (_leaveRequests.isEmpty) {
      return _buildEmptyState(Icons.beach_access_rounded, 'No pending leave requests found.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _leaveRequests.length,
      itemBuilder: (context, index) {
        final req = _leaveRequests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: const Icon(Icons.person, color: Colors.teal),
            ),
            title: Text(req['staff']?['name'] ?? 'Staff Member', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Reason: ${req['reason']}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Text(req['status'], style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 10)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
