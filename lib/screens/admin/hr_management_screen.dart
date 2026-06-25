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
  final String _roleId = 'admin';

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

  Future<void> _syncLeaveStatus(String id, String status) async {
    try {
      await SupabaseService.instance.updateLeaveStatus(id, status);
      _loadHRData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave Status Applied: $status', style: const TextStyle(fontWeight: FontWeight.w700)), 
            backgroundColor: context.dt.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Sync Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final isDark = context.isDark;
    final roleColor = RoleColors.of(_roleId);
    final compColor = RoleColors.complement(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: const Text('STAFF HUB', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: RoleColors.gradient(_roleId, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.badge_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)))]),
        ),
        actions: [IconButton(icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white), onPressed: () async { final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffRegistrationScreen())); if (result == true) _loadHRData(); })],
        bottom: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(borderRadius: BorderRadius.circular(50), color: Colors.white.withValues(alpha: 0.2), border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1)),
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          tabs: const [Tab(text: 'DIRECTORY', icon: Icon(Icons.groups_rounded, size: 18)), Tab(text: 'PAYROLL', icon: Icon(Icons.payments_rounded, size: 18)), Tab(text: 'LEAVE', icon: Icon(Icons.beach_access_rounded, size: 18))],
        ),
      ),
      body: theme?.buildCreativeBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: Padding(
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 48),
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: roleColor))
              : TabBarView(controller: _tabController, children: [_buildDirectoryTab(dt, theme), _buildPayrollTab(dt, theme), _buildLeaveTab(dt, theme)]),
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildDirectoryTab(DT dt, GeminiThemeExtension? theme) {
    if (_staffList.isEmpty) return _buildEmptyState(dt, Icons.group_off_rounded, 'STAFF DIRECTORY EMPTY');
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: _staffList.length,
      itemBuilder: (context, index) {
        final staff = _staffList[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12), 
          child: theme?.buildGlowContainer(
            accentColor: KagemaColors.staffSky, 
            borderRadius: 24, 
            padding: EdgeInsets.zero, 
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), 
              leading: CircleAvatar(radius: 24, backgroundColor: dt.roleSoftBg(KagemaColors.staffSky), child: Text(staff['name']?[0]?.toUpperCase() ?? 'S', style: TextStyle(color: KagemaColors.staffSky, fontWeight: FontWeight.w900, fontSize: 18))), 
              title: Text(staff['name']?.toString().toUpperCase() ?? 'UNKNOWN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary, letterSpacing: 0.5)), 
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(staff['role'] ?? 'Staff', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: dt.textSecondary)), Text(staff['phone'] ?? '', style: TextStyle(fontSize: 10, color: dt.textMuted))]), 
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.edit_note_rounded, color: KagemaColors.staffSky), onPressed: () async { final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => StaffRegistrationScreen(staffToEdit: staff))); if (result == true) _loadHRData(); }), IconButton(icon: Icon(Icons.delete_outline_rounded, color: dt.error), onPressed: () => _confirmDelete(staff['staff_id']))])
            ),
          ) ?? const SizedBox.shrink()
        );
      },
    );
  }

  Widget _buildLeaveTab(DT dt, GeminiThemeExtension? theme) {
    if (_leaveRequests.isEmpty) return _buildEmptyState(dt, Icons.beach_access_rounded, 'NO PENDING REQUESTS');
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: _leaveRequests.length,
      itemBuilder: (context, index) {
        final req = _leaveRequests[index];
        final isPending = req['status'] == 'Pending';
        final statusColor = req['status'] == 'Approved' ? dt.success : (req['status'] == 'Rejected' ? dt.error : dt.warning);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12), 
          child: theme?.buildGlowContainer(
            accentColor: statusColor, 
            borderRadius: 24, 
            padding: EdgeInsets.zero, 
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: dt.roleSoftBg(statusColor), shape: BoxShape.circle),
                child: Icon(Icons.person_pin_rounded, color: statusColor, size: 24),
              ),
              title: Text(req['staff']?['name']?.toString().toUpperCase() ?? 'STAFF MEMBER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary, letterSpacing: 0.5)),
              subtitle: Text('Type: ${req['type']}\nReason: ${req['reason']}', style: TextStyle(fontSize: 11, height: 1.4, color: dt.textSecondary, fontWeight: FontWeight.w600)),
              trailing: isPending ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: Icon(Icons.check_circle_rounded, color: dt.success), onPressed: () => _syncLeaveStatus(req['leave_id'].toString(), 'Approved')),
                  IconButton(icon: Icon(Icons.cancel_rounded, color: dt.error), onPressed: () => _syncLeaveStatus(req['leave_id'].toString(), 'Rejected')),
                ],
              ) : Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: dt.roleSoftBg(statusColor), borderRadius: BorderRadius.circular(8)),
                child: Text(req['status'].toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 9, color: statusColor, letterSpacing: 1)),
              ),
            ),
          ) ?? const SizedBox.shrink()
        );
      },
    );
  }

  Widget _buildPayrollTab(DT dt, GeminiThemeExtension? theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _statCard(dt, theme, 'MONTHLY PAYROLL TOTAL', 'Ksh ${NumberFormat('#,###').format(_payrollSummary['total'])}', Icons.account_balance_wallet, dt.success), 
          const SizedBox(height: 20), 
          _statCard(dt, theme, 'ACTIVE STAFF MEMBERS', '${_payrollSummary['staffCount']}', Icons.hub_rounded, dt.info), 
          const SizedBox(height: 48), 
          Container(
            width: double.infinity,
            height: 65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: RoleColors.of(_roleId).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: ElevatedButton.icon(
              onPressed: () {}, 
              icon: const Icon(Icons.print_rounded), 
              label: const Text('GENERATE STAFF PAYSLIPS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)), 
              style: ElevatedButton.styleFrom(backgroundColor: RoleColors.of(_roleId), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)))
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(DT dt, GeminiThemeExtension? theme, String label, String val, IconData icon, Color color) {
    return theme?.buildGlowContainer(
      accentColor: color,
      borderRadius: 28, 
      padding: const EdgeInsets.all(24), 
      child: Row(
        children: [
          RolePlasma(
            color: color,
            child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: dt.roleSoftBg(color), shape: BoxShape.circle), child: Icon(icon, color: color, size: 30)),
          ), 
          const SizedBox(width: 20), 
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 1.5)), Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color))])
        ]
      )
    ) ?? const SizedBox.shrink();
  }

  Future<void> _confirmDelete(String id) async { 
    final dt = context.dt;
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(backgroundColor: dt.cardBg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), title: Text('Remove Staff?', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textPrimary)), content: Text('This action will permanently remove this staff member from the system.', style: TextStyle(color: dt.textSecondary)), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text('CANCEL', style: TextStyle(color: dt.textMuted))), TextButton(onPressed: () => Navigator.pop(context, true), child: Text('REMOVE', style: TextStyle(color: dt.error, fontWeight: FontWeight.bold)))])); 
    if (confirmed == true) { try { await SupabaseService.instance.deleteStaff(id); _loadHRData(); } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync Error: $e'), backgroundColor: dt.error)); } }
  }

  Widget _buildEmptyState(DT dt, IconData icon, String msg) { return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 80, color: dt.iconInactive), const SizedBox(height: 16), Text(msg, style: TextStyle(color: dt.textMuted, fontWeight: FontWeight.w900, letterSpacing: 1.5))])); }
}
