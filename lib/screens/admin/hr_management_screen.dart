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

  Future<void> _updateLeave(String id, String status) async {
    try {
      await SupabaseService.instance.updateLeaveStatus(id, status);
      _loadHRData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Leave Status Updated: $status'), backgroundColor: Colors.teal.shade800),
        );
      }
    } catch (e) {
      debugPrint("Update Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Neural HR Hub', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, Colors.teal.shade900], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.badge_rounded, size: 140, color: Colors.white.withOpacity(0.1)))]),
        ),
        actions: [IconButton(icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white), onPressed: () async { final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffRegistrationScreen())); if (result == true) _loadHRData(); })],
        bottom: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(borderRadius: BorderRadius.circular(50), color: Colors.white.withOpacity(0.2), border: Border.all(color: Colors.white.withOpacity(0.3), width: 1)),
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [Tab(text: 'DIRECTORY', icon: Icon(Icons.groups_rounded, size: 18)), Tab(text: 'PAYROLL', icon: Icon(Icons.payments_rounded, size: 18)), Tab(text: 'LEAVE', icon: Icon(Icons.beach_access_rounded, size: 18))],
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 48),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.teal))
            : TabBarView(controller: _tabController, children: [_buildDirectoryTab(theme, gemini), _buildPayrollTab(theme, gemini), _buildLeaveTab(theme, gemini)]),
        ),
      ),
    );
  }

  Widget _buildDirectoryTab(ThemeData theme, GeminiThemeExtension? gemini) {
    if (_staffList.isEmpty) return _buildEmptyState(Icons.group_off_rounded, 'NEURAL DIRECTORY EMPTY');
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _staffList.length,
      itemBuilder: (context, index) {
        final staff = _staffList[index];
        final content = ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), leading: CircleAvatar(radius: 25, backgroundColor: theme.primaryColor.withOpacity(0.1), child: Text(staff['name']?[0] ?? 'S', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w900, fontSize: 18))), title: Text(staff['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(staff['role'] ?? 'Staff', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), Text(staff['phone'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade500))]), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.edit_note_rounded, color: Colors.blue), onPressed: () async { final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => StaffRegistrationScreen(staffToEdit: staff))); if (result == true) _loadHRData(); }), IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.red), onPressed: () => _confirmDelete(staff['staff_id']))]));
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: gemini?.buildGlowContainer(borderRadius: 24, borderThickness: 1, backgroundColor: theme.cardColor.withOpacity(0.85), padding: EdgeInsets.zero, child: content) ?? Card(child: content));
      },
    );
  }

  Widget _buildLeaveTab(ThemeData theme, GeminiThemeExtension? gemini) {
    if (_leaveRequests.isEmpty) return _buildEmptyState(Icons.beach_access_rounded, 'NO PENDING REQUESTS');
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _leaveRequests.length,
      itemBuilder: (context, index) {
        final req = _leaveRequests[index];
        final isPending = req['status'] == 'Pending';
        final content = ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: const Icon(Icons.person_pin_rounded, color: Colors.teal),
          title: Text(req['staff']?['name'] ?? 'Staff Node', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          subtitle: Text('Type: ${req['type']}\nReason: ${req['reason']}', style: const TextStyle(fontSize: 11, height: 1.4)),
          trailing: isPending ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.check_circle_rounded, color: Colors.green), onPressed: () => _updateLeave(req['leave_id'].toString(), 'Approved')),
              IconButton(icon: const Icon(Icons.cancel_rounded, color: Colors.red), onPressed: () => _updateLeave(req['leave_id'].toString(), 'Rejected')),
            ],
          ) : Text(req['status'].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey)),
        );
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: gemini?.buildGlowContainer(borderRadius: 24, borderThickness: 1, backgroundColor: theme.cardColor.withOpacity(0.85), padding: EdgeInsets.zero, child: content) ?? Card(child: content));
      },
    );
  }

  Widget _buildPayrollTab(ThemeData theme, GeminiThemeExtension? gemini) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(children: [_statCard(theme, gemini, 'QUANTUM PAYROLL ESTIMATE', 'Ksh ${NumberFormat('#,###').format(_payrollSummary['total'])}', Icons.account_balance_wallet, Colors.green), const SizedBox(height: 20), _statCard(theme, gemini, 'ACTIVE SYSTEM NODES', '${_payrollSummary['staffCount']}', Icons.hub_rounded, Colors.blue), const SizedBox(height: 48), SizedBox(width: double.infinity, height: 60, child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.print_rounded), label: const Text('GENERATE NEURAL PAYSLIPS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)), style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 8, shadowColor: theme.primaryColor.withOpacity(0.4))))]),
    );
  }

  Widget _statCard(ThemeData theme, GeminiThemeExtension? gemini, String label, String val, IconData icon, Color color) {
    final content = Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 30)), const SizedBox(width: 20), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 1.5)), Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color))])]);
    return gemini?.buildGlowContainer(borderRadius: 28, borderThickness: 1.5, backgroundColor: theme.cardColor.withOpacity(0.9), padding: const EdgeInsets.all(24), child: content) ?? Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(28)), child: content);
  }

  Future<void> _confirmDelete(String id) async { final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), title: const Text('Purge Entity?', style: TextStyle(fontWeight: FontWeight.w900)), content: const Text('This action will erase the identity from the neural net permanently.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ABORT')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('PURGE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))])); if (confirmed == true) { try { await SupabaseService.instance.deleteStaff(id); _loadHRData(); } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync Error: $e'))); } } }

  Widget _buildEmptyState(IconData icon, String msg) { return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 80, color: Colors.grey.withOpacity(0.3)), const SizedBox(height: 16), Text(msg, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 1.5))])); }
}
