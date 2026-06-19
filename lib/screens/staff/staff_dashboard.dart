import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../services/pdf_generator_service.dart';
import '../settings/settings_screen.dart';
import 'task_list_screen.dart';
import '../../app_theme.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});
  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  Map<String, dynamic>? _staffProfile;
  List<Map<String, dynamic>> _tasks         = [];
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _leaveHistory  = [];
  List<Map<String, dynamic>> _attendanceHistory = [];

  bool    _isLoading      = true;
  bool    _isCheckedIn    = false;
  String? _lastCheckInTime;
  String? _errorMessage;

  final String _roleId = 'staff';

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _loadDashboardData();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    final user = SupabaseService.instance.client.auth.currentUser;
    if (user == null || user.email == null) {
      if (mounted) {
        setState(() {
          _isLoading    = false;
          _errorMessage = 'Session expired. Please log in again.';
        });
      }
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final profile = await SupabaseService.instance
          .getStaffProfileByEmail(user.email!);
      if (profile == null) throw Exception('Staff record not found.');

      final staffId = profile['staff_id'] as String;
      final results = await Future.wait([
        SupabaseService.instance.getTasks(staffId),
        SupabaseService.instance.getNotifications('staff'),
        SupabaseService.instance.getStaffAttendanceHistory(staffId),
        SupabaseService.instance.getStaffLeaveHistory(staffId),
      ]);

      if (!mounted) return;
      setState(() {
        _staffProfile = profile;
        final allTasks = results[0] as List<Map<String, dynamic>>;
        _tasks         = allTasks.where((t) => t['status'] != 'Completed').toList();
        _announcements = results[1] as List<Map<String, dynamic>>;
        _attendanceHistory = results[2] as List<Map<String, dynamic>>;
        _leaveHistory  = results[3] as List<Map<String, dynamic>>;

        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final todayRec = _attendanceHistory.where((a) => a['date'] == today).toList();
        if (todayRec.isNotEmpty) {
          final latest = todayRec.first;
          _isCheckedIn     = latest['status'] == 'Checked-In';
          _lastCheckInTime = _isCheckedIn ? latest['time'] : null;
        } else {
          _isCheckedIn     = false;
          _lastCheckInTime = null;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading    = false;
          _errorMessage = 'Connection error. Please check your internet.';
        });
      }
    }
  }

  Future<void> _handleCheckInOut() async {
    if (_staffProfile == null) return;
    final staffId   = _staffProfile!['staff_id'] as String;
    final newStatus = _isCheckedIn ? 'Checked-Out' : 'Checked-In';
    try {
      await SupabaseService.instance.staffCheckInOut(staffId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Status Updated: $newStatus',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          backgroundColor: _isCheckedIn ? KagemaColors.accountantAmber : KagemaColors.teacherGreen,
        ));
        await _loadDashboardData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: KagemaColors.parentRed,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final roleColor = RoleColors.of(_roleId);
    final compColor = RoleColors.complement(_roleId);

    return Scaffold(
      backgroundColor: dt.pageBg,
      drawer: _buildDrawer(dt, roleColor),
      body: theme?.buildCreativeBackground(
        isDark: context.isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: context.isDark,
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: roleColor, strokeWidth: 2.5))
              : _currentIndex == 0
              ? _buildOverviewTab(dt, roleColor, theme)
              : _buildRecordsTab(dt, roleColor, theme),
        ),
      ) ?? const SizedBox.shrink(),
      bottomNavigationBar: _buildNavBar(dt, roleColor),
    );
  }

  Widget _buildOverviewTab(DT dt, Color roleColor, GeminiThemeExtension? theme) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: roleColor,
      edgeOffset: 120,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(dt, roleColor),
          if (_errorMessage != null)
            SliverToBoxAdapter(child: _buildErrorBanner(dt)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.sw > 650 ? 32 : 20, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIDCard(dt, roleColor, theme),
                  const SizedBox(height: 20),
                  _buildQuickStats(dt, roleColor, theme),
                  const SizedBox(height: 28),
                  _buildAttendancePanel(dt, roleColor, theme),
                  const SizedBox(height: 36),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionHeader('MY ACTIVE TASKS', Icons.assignment_turned_in_rounded, roleColor),
                      TextButton(
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(
                              builder: (_) => TaskListScreen(
                                  staffId: _staffProfile?['staff_id'] ?? ''),
                            )),
                        child: Text('View All',
                            style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildTasksList(dt, roleColor, theme),
                  const SizedBox(height: 36),
                  _sectionHeader('SCHOOL ANNOUNCEMENTS', Icons.campaign_rounded, roleColor),
                  const SizedBox(height: 16),
                  _buildAnnouncementsList(dt, roleColor, theme),
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsTab(DT dt, Color roleColor, GeminiThemeExtension? theme) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(dt, roleColor, title: 'MY ACTIVITY HISTORY'),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.sw > 650 ? 32 : 20, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('PAYSLIP', Icons.account_balance_wallet_rounded, roleColor),
                const SizedBox(height: 16),
                _buildPayslipCard(dt, roleColor, theme),
                const SizedBox(height: 36),
                _sectionHeader('LEAVE REQUEST STATUS', Icons.history_edu_rounded, roleColor),
                const SizedBox(height: 16),
                _buildLeaveHistory(dt, roleColor, theme),
                const SizedBox(height: 36),
                _sectionHeader('ATTENDANCE HISTORY', Icons.verified_user_rounded, roleColor),
                const SizedBox(height: 16),
                _buildAttendanceHistory(dt, roleColor, theme),
                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(DT dt, Color roleColor, {String title = 'STAFF PORTAL'}) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      elevation: 0,
      backgroundColor: roleColor,
      leading: Builder(builder: (ctx) => IconButton(
        icon: const Icon(Icons.menu_rounded, color: Colors.white),
        onPressed: () => Scaffold.of(ctx).openDrawer(),
      )),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        title: Text(title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2.5),
        ),
        background: _buildAppBarBackground(dt, roleColor),
      ),
    );
  }

  Widget _buildAppBarBackground(DT dt, Color roleColor) {
    final name = _staffProfile?['name'] as String? ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    final role = _staffProfile?['role']?.toString() ?? 'Staff Member';
    final greeter = TimeGreeter.now;

    return Stack(
      children: [
        Container(color: roleColor),
        Positioned(
          right: -20, top: -10,
          child: Icon(Icons.badge_rounded, size: 180, color: Colors.white.withValues(alpha: 0.1)),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 60),
            child: Row(
              children: [
                RolePlasma(
                  color: Colors.white,
                  active: _isCheckedIn,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    child: Text(initials, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${greeter.prefix} ${name.split(' ').first}! ${greeter.emoji}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(role.toUpperCase(),
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.75), letterSpacing: 2),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          color: _isCheckedIn ? KagemaColors.teacherGreen : Colors.white.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(_isCheckedIn ? 'ON DUTY' : 'OFF DUTY',
                        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIDCard(DT dt, Color roleColor, GeminiThemeExtension? theme) {
    final name = _staffProfile?['name']?.toString() ?? 'Staff Member';
    final role = _staffProfile?['role']?.toString() ?? 'Staff';
    final staffId = _staffProfile?['staff_id']?.toString() ?? '—';

    return theme?.buildGlowContainer(
      accentColor: roleColor,
      borderRadius: 32,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: roleColor.withValues(alpha: 0.35), width: 2),
            ),
            child: Center(
              child: Text(name[0].toUpperCase(),
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: roleColor),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: dt.textPrimary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: dt.roleSoftBg(roleColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(role.toUpperCase(),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: roleColor, letterSpacing: 1.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text('ID: $staffId', style: TextStyle(fontSize: 11, color: dt.textMuted, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    ) ?? const SizedBox.shrink();
  }

  Widget _buildQuickStats(DT dt, Color roleColor, GeminiThemeExtension? theme) {
    final activeTasks    = _tasks.length;
    final pendingLeave   = _leaveHistory.where((l) => l['status'] == 'Pending').length;
    final daysPresent    = _attendanceHistory.where((a) => a['status'] == 'Checked-In').length;

    return Row(
      children: [
        _statChip(dt, theme, '$activeTasks', 'Active Tasks', Icons.assignment_outlined, roleColor),
        const SizedBox(width: 10),
        _statChip(dt, theme, '$pendingLeave', 'Leave Pending', Icons.event_note_rounded, KagemaColors.accountantAmber),
        const SizedBox(width: 10),
        _statChip(dt, theme, '$daysPresent', 'Days Present', Icons.check_circle_outline_rounded, KagemaColors.teacherGreen),
      ],
    );
  }

  Widget _statChip(DT dt, GeminiThemeExtension? theme, String value, String label, IconData icon, Color color) {
    return Expanded(
      child: theme?.buildGlowContainer(
        accentColor: color,
        borderRadius: 22,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, height: 1)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: dt.textMuted),
            ),
          ],
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildAttendancePanel(DT dt, Color roleColor, GeminiThemeExtension? theme) {
    final statusColor = _isCheckedIn ? KagemaColors.teacherGreen : KagemaColors.parentRed;
    final statusText  = _isCheckedIn ? 'ON DUTY' : 'OFF DUTY';
    final btnLabel    = _isCheckedIn ? 'CHECK OUT' : 'CHECK IN';

    return AISpectrumBorder(
      primaryColor: statusColor,
      secondaryColor: roleColor,
      borderRadius: 28,
      child: theme?.buildGlowContainer(
        accentColor: statusColor,
        borderRadius: 28,
        padding: const EdgeInsets.all(20),
        backgroundColor: dt.roleSoftBg(statusColor),
        child: Row(
          children: [
            ScaleTransition(
              scale: _isCheckedIn ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.14), shape: BoxShape.circle),
                child: Icon(_isCheckedIn ? Icons.verified_user_rounded : Icons.gpp_maybe_rounded, color: statusColor, size: 28),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STATUS: $statusText', style: TextStyle(fontWeight: FontWeight.w900, color: statusColor, letterSpacing: 1.5, fontSize: 12)),
                  const SizedBox(height: 3),
                  Text(_isCheckedIn && _lastCheckInTime != null ? 'Shift started at: $_lastCheckInTime' : 'Ready to begin?',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: dt.textMuted),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _handleCheckInOut,
              style: ElevatedButton.styleFrom(backgroundColor: statusColor),
              child: Text(btnLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
            ),
          ],
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildPayslipCard(DT dt, Color roleColor, GeminiThemeExtension? theme) {
    final salary = (_staffProfile?['salary'] as num? ?? 0.0).toDouble();

    return theme?.buildGlowContainer(
      accentColor: KagemaColors.teacherGreen,
      borderRadius: 28,
      useAIBorder: true,
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: dt.roleSoftBg(KagemaColors.teacherGreen), shape: BoxShape.circle),
            child: const Icon(Icons.payments_rounded, color: KagemaColors.teacherGreen, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Basic Salary', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: dt.textMuted)),
                const SizedBox(height: 4),
                Text('Ksh ${NumberFormat('#,###').format(salary)}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: dt.textPrimary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_staffProfile != null) PdfGeneratorService.generatePayslip(_staffProfile!, DateFormat('MMMM yyyy').format(DateTime.now()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: KagemaColors.teacherGreen),
            child: const Text('VIEW PDF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    ) ?? const SizedBox.shrink();
  }

  Widget _buildTasksList(DT dt, Color roleColor, GeminiThemeExtension? theme) {
    if (_tasks.isEmpty) return _emptyState(Icons.task_alt_rounded, 'ALL TASKS COMPLETED', dt, roleColor);
    return Column(
      children: _tasks.map((t) {
        final priority = t['priority']?.toString() ?? 'Medium';
        final priorityColor = priority == 'High' ? KagemaColors.parentRed : (priority == 'Low' ? KagemaColors.teacherGreen : KagemaColors.accountantAmber);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: theme?.buildGlowContainer(
            accentColor: priorityColor,
            borderRadius: 24,
            padding: EdgeInsets.zero,
            child: ListTile(
              onTap: () => _showTaskDialog(t, dt, roleColor),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: dt.roleSoftBg(priorityColor), shape: BoxShape.circle),
                child: Icon(Icons.assignment_outlined, color: priorityColor, size: 22),
              ),
              title: Text(t['title'] ?? 'Task', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary)),
              subtitle: Text('Due: ${t['due_date'] ?? '—'}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: dt.textMuted)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: dt.roleSoftBg(priorityColor), borderRadius: BorderRadius.circular(10)),
                child: Text(priority.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: priorityColor)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnnouncementsList(DT dt, Color roleColor, GeminiThemeExtension? theme) {
    if (_announcements.isEmpty) return _emptyState(Icons.campaign_outlined, 'NO NEW ANNOUNCEMENTS', dt, roleColor);
    return Column(
      children: _announcements.take(3).map((n) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: theme?.buildGlowContainer(
            accentColor: roleColor,
            borderRadius: 24,
            padding: EdgeInsets.zero,
            child: ListTile(
              onTap: () => _showAnnouncementDialog(n, dt),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: dt.roleSoftBg(KagemaColors.azure), shape: BoxShape.circle),
                child: const Icon(Icons.campaign_rounded, color: KagemaColors.azure, size: 22),
              ),
              title: Text(n['title'] ?? 'Notice', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary)),
              subtitle: Text(n['message'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: dt.textMuted)),
              trailing: Icon(Icons.chevron_right_rounded, color: dt.iconInactive),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLeaveHistory(DT dt, Color roleColor, GeminiThemeExtension? theme) {
    if (_leaveHistory.isEmpty) return _emptyState(Icons.history_edu_rounded, 'NO LEAVE HISTORY', dt, roleColor);
    return Column(
      children: _leaveHistory.map((l) {
        final status = l['status']?.toString() ?? 'Pending';
        final statusColor = status == 'Approved' ? KagemaColors.teacherGreen : (status == 'Rejected' ? KagemaColors.parentRed : KagemaColors.accountantAmber);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: theme?.buildGlowContainer(
            accentColor: statusColor,
            borderRadius: 24,
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: dt.roleSoftBg(statusColor), shape: BoxShape.circle),
                child: Icon(Icons.event_note_rounded, color: statusColor, size: 22),
              ),
              title: Text(l['type'] ?? 'Leave Request', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary)),
              subtitle: Text('Date: ${l['date'] ?? '—'}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: dt.textMuted)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: dt.roleSoftBg(statusColor), borderRadius: BorderRadius.circular(10)),
                child: Text(status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: statusColor)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAttendanceHistory(DT dt, Color roleColor, GeminiThemeExtension? theme) {
    if (_attendanceHistory.isEmpty) return _emptyState(Icons.verified_user_rounded, 'NO RECORDS', dt, roleColor);
    return Column(
      children: _attendanceHistory.map((a) {
        final status = a['status']?.toString() ?? '';
        final statusColor = status == 'Checked-In' ? KagemaColors.teacherGreen : roleColor;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: theme?.buildGlowContainer(
            accentColor: statusColor,
            borderRadius: 24,
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: dt.roleSoftBg(statusColor), shape: BoxShape.circle),
                child: Icon(Icons.check_circle_outline_rounded, color: statusColor, size: 22),
              ),
              title: Text(status, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary)),
              subtitle: Text('${a['date'] ?? '—'}  ·  ${a['time'] ?? '—'}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: dt.textMuted)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNavBar(DT dt, Color roleColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: dt.cardBg,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: dt.cardBorder, width: 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 24)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(0, Icons.dashboard_rounded, 'Overview', dt, roleColor),
            _navItem(1, Icons.history_rounded, 'Records', dt, roleColor),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, DT dt, Color roleColor) {
    final selected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: KagemaMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(color: selected ? dt.roleSoftBg(roleColor) : Colors.transparent, borderRadius: BorderRadius.circular(22)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? roleColor : dt.iconInactive, size: 24),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: selected ? roleColor : dt.iconInactive)),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(DT dt, Color roleColor) {
    final name = _staffProfile?['name']?.toString() ?? 'Staff Member';
    final role = _staffProfile?['role']?.toString() ?? 'Staff';

    return Drawer(
      backgroundColor: dt.cardBg,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
            decoration: BoxDecoration(color: roleColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 34, backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
                const SizedBox(height: 14),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text(role.toUpperCase(), style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 10, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          _drawerTile(dt, icon: Icons.request_page_rounded, label: 'Apply for Leave', onTap: () { Navigator.pop(context); _showLeaveDialog(dt, roleColor); }),
          _drawerTile(dt, icon: Icons.settings_rounded, label: 'Settings', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(role: 'Staff')))),
          _drawerTile(dt, icon: Icons.logout_rounded, label: 'Logout', color: KagemaColors.parentRed, onTap: () => Navigator.pushReplacementNamed(context, '/login')),
        ],
      ),
    );
  }

  Widget _drawerTile(DT dt, {required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    final c = color ?? dt.textPrimary;
    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: c)),
      onTap: onTap,
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color roleColor) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: roleColor, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 10),
        Icon(icon, size: 15, color: roleColor),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: roleColor, letterSpacing: 2)),
      ],
    );
  }

  Widget _emptyState(IconData icon, String msg, DT dt, Color roleColor) {
    return Center(
      child: Column(
        children: [
          Icon(icon, size: 44, color: roleColor.withValues(alpha: 0.25)),
          const SizedBox(height: 14),
          Text(msg, style: TextStyle(color: dt.textMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(DT dt) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: dt.roleSoftBg(KagemaColors.parentRed), borderRadius: BorderRadius.circular(18), border: Border.all(color: KagemaColors.parentRed.withValues(alpha: 0.18))),
      child: Text(_errorMessage!, style: const TextStyle(color: KagemaColors.parentRed, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  void _showTaskDialog(Map<String, dynamic> task, DT dt, Color roleColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => LiquidGlassCard(
        borderRadius: 36,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task['title'] ?? 'Staff Duty', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: dt.textPrimary)),
            const SizedBox(height: 14),
            Text(task['description'] ?? 'No instructions.', style: TextStyle(fontSize: 14, color: dt.textSecondary)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await SupabaseService.instance.updateTaskStatus(task['task_id'].toString(), 'Completed');
                if (mounted) { Navigator.pop(context); _loadDashboardData(); }
              },
              style: ElevatedButton.styleFrom(backgroundColor: KagemaColors.teacherGreen),
              child: const Center(child: Text('MARK AS COMPLETED')),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnnouncementDialog(Map<String, dynamic> n, DT dt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => LiquidGlassCard(
        borderRadius: 36,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n['title'] ?? 'Notice', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: dt.textPrimary)),
            const SizedBox(height: 14),
            Text(n['message'] ?? '', style: TextStyle(fontSize: 15, color: dt.textSecondary)),
          ],
        ),
      ),
    );
  }

  void _showLeaveDialog(DT dt, Color roleColor) {
    final reasonCtrl = TextEditingController();
    String leaveType = 'Sick Leave';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: LiquidGlassCard(
          borderRadius: 36,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: leaveType,
                items: ['Sick Leave', 'Personal', 'Vacation', 'Emergency'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (v) => leaveType = v!,
              ),
              const SizedBox(height: 16),
              TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason')),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () async {
                  if (reasonCtrl.text.isNotEmpty && _staffProfile != null) {
                    await SupabaseService.instance.requestLeave({'staff_id': _staffProfile!['staff_id'], 'type': leaveType, 'reason': reasonCtrl.text.trim(), 'status': 'Pending', 'date': DateFormat('yyyy-MM-dd').format(DateTime.now())});
                    if (mounted) { Navigator.pop(context); _loadDashboardData(); }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: roleColor),
                child: const Center(child: Text('SUBMIT REQUEST')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
