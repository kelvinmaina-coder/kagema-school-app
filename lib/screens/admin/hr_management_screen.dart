import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class HRManagementScreen extends StatefulWidget {
  const HRManagementScreen({super.key});

  @override
  State<HRManagementScreen> createState() => _HRManagementScreenState();
}

class _HRManagementScreenState extends State<HRManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _leaveRequests = [];
  Map<String, dynamic> _payrollSummary = {'total': 0.0, 'staffCount': 0};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final payroll = await SupabaseService.instance.getPayrollSummary();
      final leaves = await SupabaseService.instance.getLeaveRequests();
      if (mounted) {
        setState(() {
          _payrollSummary = payroll;
          _leaveRequests = leaves;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("HR Load Error: $e");
      if (mounted) setState(() => isLoading = false);
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
            gradient: LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)]),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Payroll', icon: Icon(Icons.payments_rounded)),
            Tab(text: 'Leave', icon: Icon(Icons.vacation_rounded)),
            Tab(text: 'Staff Attendance', icon: Icon(Icons.fingerprint_rounded)),
          ],
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 48),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPayrollDashboard(theme),
                    _buildLeaveRequests(theme),
                    _buildStaffAttendance(theme),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPayrollDashboard(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _infoCard(theme, 'ESTIMATED MONTHLY PAYROLL', 'Ksh ${_payrollSummary['total']}', Icons.account_balance_wallet, Colors.green),
          const SizedBox(height: 20),
          _infoCard(theme, 'TOTAL ACTIVE EMPLOYEES', '${_payrollSummary['staffCount']}', Icons.people_alt, Colors.blue),
        ],
      ),
    );
  }

  Widget _infoCard(ThemeData theme, String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.9), borderRadius: BorderRadius.circular(28)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
              Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLeaveRequests(ThemeData theme) {
    if (_leaveRequests.isEmpty) return const Center(child: Text('No active leave requests.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _leaveRequests.length,
      itemBuilder: (context, index) {
        final request = _leaveRequests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            title: Text(request['reason'] ?? 'Leave Request', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Status: ${request['status']} • Date: ${request['start_date']}'),
            trailing: Icon(
              request['status'] == 'Approved' ? Icons.check_circle : Icons.pending,
              color: request['status'] == 'Approved' ? Colors.green : Colors.orange,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaffAttendance(ThemeData theme) {
    return const Center(child: Text('Staff attendance logs are synced here.'));
  }
}
