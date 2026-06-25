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
    final screenWidth = context.sw;
    final isMobile = screenWidth < 600;

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
    final isMobile = context.sw < 600;

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
              padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : (context.sw > 650 ? 32 : 20),
                  vertical: isMobile ? 16 : 28
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIDCard(dt, roleColor, theme),
                  SizedBox(height: isMobile ? 16 : 20),
                  _buildQuickStats(dt, roleColor, theme),
                  SizedBox(height: isMobile ? 20 : 28),
                  _buildAttendancePanel(dt, roleColor, theme),
                  SizedBox(height: isMobile ? 24 : 36),
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
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: roleColor,
                            fontSize: isMobile ? 10 : 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildTasksList(dt, roleColor, theme),
                  SizedBox(height: isMobile ? 24 : 36),
                  _sectionHeader('SCHOOL ANNOUNCEMENTS', Icons.campaign_rounded, roleColor),
                  SizedBox(height: isMobile ? 12 : 16),
                  _buildAnnouncementsList(dt, roleColor, theme),
                  SizedBox(height: isMobile ? 80 : 110),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsTab(DT dt, Color roleColor, GeminiThemeExtension? theme) {
    final isMobile = context.sw < 600;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(dt, roleColor, title: 'MY ACTIVITY HISTORY'),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : (context.sw > 650 ? 32 : 20),
                vertical: isMobile ? 16 : 28
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('PAYSLIP', Icons.account_balance_wallet_rounded, roleColor),
                SizedBox(height: isMobile ? 12 : 16),
                _buildPayslipCard(dt, roleColor, theme),
                SizedBox(height: isMobile ? 24 : 36),
                _sectionHeader('LEAVE REQUEST STATUS', Icons.history_edu_rounded, roleColor),
                SizedBox(height: isMobile ? 12 : 16),
                _buildLeaveHistory(dt, roleColor, theme),
                SizedBox(height: isMobile ? 24 : 36),
                _sectionHeader('ATTENDANCE HISTORY', Icons.verified_user_rounded, roleColor),
                SizedBox(height: isMobile ? 12 : 16),
                _buildAttendanceHistory(dt, roleColor, theme),
                SizedBox(height: isMobile ? 80 : 110),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(DT dt, Color roleColor, {String title = 'STAFF PORTAL'}) {
    final isMobile = context.sw < 600;
    final name = _staffProfile?['name'] as String? ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    final role = _staffProfile?['role']?.toString() ?? 'Staff Member';
    final greeter = TimeGreeter.now;

    return SliverAppBar(
      expandedHeight: isMobile ? 160 : 200,
      pinned: true,
      elevation: 0,
      backgroundColor: roleColor,
      leading: Builder(builder: (ctx) => IconButton(
        icon: const Icon(Icons.menu_rounded, color: Colors.white),
        onPressed: () => Scaffold.of(ctx).openDrawer(),
      )),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
        title: Text(
          title,
          style: TextStyle(
            fontSize: isMobile ? 11 : 13,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2.5,
          ),
        ),
        background: Stack(
          children: [
            Container(color: roleColor),
            Positioned(
              right: -20, top: -10,
              child: Icon(
                Icons.badge_rounded,
                size: isMobile ? 120 : 180,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 24,
                    isMobile ? 12 : 16,
                    isMobile ? 16 : 24,
                    isMobile ? 40 : 60
                ),
                child: Row(
                  children: [
                    RolePlasma(
                      color: Colors.white,
                      active: _isCheckedIn,
                      child: CircleAvatar(
                        radius: isMobile ? 24 : 30,
                        backgroundColor: Colors.white.withOpacity(0.18),
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontSize: isMobile ? 20 : 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isMobile ? 12 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${greeter.prefix} ${name.split(' ').first}! ${greeter.emoji}',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 17,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            role.toUpperCase(),
                            style: TextStyle(
                              fontSize: isMobile ? 8 : 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withOpacity(0.75),
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color: _isCheckedIn ? KagemaColors.teacherGreen : Colors.white.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _isCheckedIn ? 'ON DUTY' : 'OFF DUTY',
                            style: TextStyle(
                              fontSize: isMobile ? 7 : 8,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIDCard(DT dt, Color roleColor, GeminiThemeExtension? theme) {
    final name = _staffProfile?['name']?.toString() ?? 'Staff Member';
    final role = _staffProfile?['role']?.toString() ?? 'Staff';
    final staffId = _staffProfile?['staff_id']?.toString() ?? '—';
    final isMobile = context.sw < 600;

    return theme?.buildGlowContainer(
      accentColor: roleColor,
      borderRadius: isMobile ? 24 : 32,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Row(
        children: [
          Container(
            width: isMobile ? 56 : 72,
            height: isMobile ? 56 : 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: roleColor.withOpacity(0.35), width: 2),
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: isMobile ? 24 : 30,
                  fontWeight: FontWeight.w900,
                  color: roleColor,
                ),
              ),
            ),
          ),
          SizedBox(width: isMobile ? 12 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: isMobile ? 14 : 16,
                    color: dt.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: dt.roleSoftBg(roleColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      fontSize: isMobile ? 8 : 9,
                      fontWeight: FontWeight.w900,
                      color: roleColor,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: $staffId',
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 11,
                    color: dt.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Small indicator
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 6 : 8,
              vertical: isMobile ? 3 : 4,
            ),
            decoration: BoxDecoration(
              color: _isCheckedIn ? KagemaColors.teacherGreen.withOpacity(0.1) : KagemaColors.parentRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isCheckedIn ? KagemaColors.teacherGreen.withOpacity(0.3) : KagemaColors.parentRed.withOpacity(0.3),
              ),
            ),
            child: Text(
              _isCheckedIn ? 'ACTIVE' : 'AWAY',
              style: TextStyle(
                fontSize: isMobile ? 7 : 8,
                fontWeight: FontWeight.w800,
                color: _isCheckedIn ? KagemaColors.teacherGreen : KagemaColors.parentRed,
                letterSpacing: 0.5,
              ),
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
    final isMobile = context.sw < 600;

    return Row(
      children: [
        _statChip(dt, theme, '$activeTasks', 'Active Tasks', Icons.assignment_outlined, roleColor, isMobile),
        SizedBox(width: isMobile ? 6 : 10),
        _statChip(dt, theme, '$pendingLeave', 'Leave Pending', Icons.event_note_rounded, KagemaColors.accountantAmber, isMobile),
        SizedBox(width: isMobile ? 6 : 10),
        _statChip(dt, theme, '$daysPresent', 'Days Present', Icons.check_circle_outline_rounded, KagemaColors.teacherGreen, isMobile),
      ],
    );
  }

  Widget _statChip(DT dt, GeminiThemeExtension? theme, String value, String label, IconData icon, Color color, bool isMobile) {
    return Expanded(
      child: theme?.buildGlowContainer(
        accentColor: color,
        borderRadius: isMobile ? 16 : 22,
        padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16, horizontal: isMobile ? 8 : 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: isMobile ? 18 : 22),
            SizedBox(height: isMobile ? 4 : 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1,
              ),
            ),
            SizedBox(height: isMobile ? 2 : 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 7 : 9,
                fontWeight: FontWeight.w700,
                color: dt.textMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
    final isMobile = context.sw < 600;

    return AISpectrumBorder(
      primaryColor: statusColor,
      secondaryColor: roleColor,
      borderRadius: isMobile ? 20 : 28,
      child: theme?.buildGlowContainer(
        accentColor: statusColor,
        borderRadius: isMobile ? 20 : 28,
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        backgroundColor: dt.roleSoftBg(statusColor),
        child: Row(
          children: [
            ScaleTransition(
              scale: _isCheckedIn ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
              child: Container(
                padding: EdgeInsets.all(isMobile ? 8 : 12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isCheckedIn ? Icons.verified_user_rounded : Icons.gpp_maybe_rounded,
                  color: statusColor,
                  size: isMobile ? 22 : 28,
                ),
              ),
            ),
            SizedBox(width: isMobile ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STATUS: $statusText',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                      letterSpacing: 1.5,
                      fontSize: isMobile ? 10 : 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _isCheckedIn && _lastCheckInTime != null ? 'Shift started at: $_lastCheckInTime' : 'Ready to begin?',
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 11,
                      fontWeight: FontWeight.w600,
                      color: dt.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _handleCheckInOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 8 : 12,
                ),
              ),
              child: Text(
                btnLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isMobile ? 9 : 10,
                ),
              ),
            ),
          ],
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildPayslipCard(DT dt, Color roleColor, GeminiThemeExtension? theme) {
    final salary = (_staffProfile?['salary'] as num? ?? 0.0).toDouble();
    final isMobile = context.sw < 600;

    return theme?.buildGlowContainer(
      accentColor: KagemaColors.teacherGreen,
      borderRadius: isMobile ? 20 : 28,
      useAIBorder: true,
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : 14),
            decoration: BoxDecoration(
              color: dt.roleSoftBg(KagemaColors.teacherGreen),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.payments_rounded,
              color: KagemaColors.teacherGreen,
              size: isMobile ? 20 : 26,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Basic Salary',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isMobile ? 10 : 12,
                    color: dt.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ksh ${NumberFormat('#,###').format(salary)}',
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w900,
                    color: dt.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_staffProfile != null) PdfGeneratorService.generatePayslip(_staffProfile!, DateFormat('MMMM yyyy').format(DateTime.now()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KagemaColors.teacherGreen,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 8 : 12,
              ),
            ),
            child: Text(
              'VIEW PDF',
              style: TextStyle(
                fontSize: isMobile ? 9 : 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    ) ?? const SizedBox.shrink();
  }

  Widget _buildTasksList(DT dt, Color roleColor, GeminiThemeExtension? theme) {
    final isMobile = context.sw < 600;

    if (_tasks.isEmpty) return _emptyState(Icons.task_alt_rounded, 'ALL TASKS COMPLETED', dt, roleColor);
    return Column(
      children: _tasks.map((t) {
        final priority = t['priority']?.toString() ?? 'Medium';
        final priorityColor = priority == 'High' ? KagemaColors.parentRed : (priority == 'Low' ? KagemaColors.teacherGreen : KagemaColors.accountantAmber);
        return Padding(
          padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
          child: theme?.buildGlowContainer(
            accentColor: priorityColor,
            borderRadius: isMobile ? 16 : 24,
            padding: EdgeInsets.zero,
            child: ListTile(
              onTap: () => _showTaskDialog(t, dt, roleColor),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 4 : 0,
              ),
              leading: Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: dt.roleSoftBg(priorityColor),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  color: priorityColor,
                  size: isMobile ? 18 : 22,
                ),
              ),
              title: Text(
                t['title'] ?? 'Task',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isMobile ? 13 : 14,
                  color: dt.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'Due: ${t['due_date'] ?? '—'}',
                style: TextStyle(
                  fontSize: isMobile ? 10 : 11,
                  fontWeight: FontWeight.w600,
                  color: dt.textMuted,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: dt.roleSoftBg(priorityColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: TextStyle(
                    fontSize: isMobile ? 8 : 9,
                    fontWeight: FontWeight.w900,
                    color: priorityColor,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnnouncementsList(DT dt, Color roleColor, GeminiThemeExtension? theme) {
    final isMobile = context.sw < 600;

    if (_announcements.isEmpty) return _emptyState(Icons.campaign_outlined, 'NO NEW ANNOUNCEMENTS', dt, roleColor);
    return Column(
      children: _announcements.take(3).map((n) {
        return Padding(
          padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
          child: theme?.buildGlowContainer(
            accentColor: roleColor,
            borderRadius: isMobile ? 16 : 24,
            padding: EdgeInsets.zero,
            child: ListTile(
              onTap: () => _showAnnouncementDialog(n, dt),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 4 : 0,
              ),
              leading: Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: dt.roleSoftBg(KagemaColors.azure),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: KagemaColors.azure,
                  size: 22,
                ),
              ),
              title: Text(
                n['title'] ?? 'Notice',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isMobile ? 13 : 14,
                  color: dt.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                n['message'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  color: dt.textMuted,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: dt.iconInactive,
                size: isMobile ? 18 : 20,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLeaveHistory(DT dt, Color roleColor, GeminiThemeExtension? theme) {
    final isMobile = context.sw < 600;

    if (_leaveHistory.isEmpty) return _emptyState(Icons.history_edu_rounded, 'NO LEAVE HISTORY', dt, roleColor);
    return Column(
      children: _leaveHistory.map((l) {
        final status = l['status']?.toString() ?? 'Pending';
        final statusColor = status == 'Approved' ? KagemaColors.teacherGreen : (status == 'Rejected' ? KagemaColors.parentRed : KagemaColors.accountantAmber);
        return Padding(
          padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
          child: theme?.buildGlowContainer(
            accentColor: statusColor,
            borderRadius: isMobile ? 16 : 24,
            padding: EdgeInsets.zero,
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 4 : 0,
              ),
              leading: Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: dt.roleSoftBg(statusColor),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_note_rounded,
                  color: statusColor,
                  size: isMobile ? 18 : 22,
                ),
              ),
              title: Text(
                l['type'] ?? 'Leave Request',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isMobile ? 13 : 14,
                  color: dt.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'Date: ${l['date'] ?? '—'}',
                style: TextStyle(
                  fontSize: isMobile ? 10 : 11,
                  fontWeight: FontWeight.w600,
                  color: dt.textMuted,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: dt.roleSoftBg(statusColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: isMobile ? 8 : 9,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAttendanceHistory(DT dt, Color roleColor, GeminiThemeExtension? theme) {
    final isMobile = context.sw < 600;

    if (_attendanceHistory.isEmpty) return _emptyState(Icons.verified_user_rounded, 'NO RECORDS', dt, roleColor);
    return Column(
      children: _attendanceHistory.map((a) {
        final status = a['status']?.toString() ?? '';
        final statusColor = status == 'Checked-In' ? KagemaColors.teacherGreen : roleColor;
        return Padding(
          padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
          child: theme?.buildGlowContainer(
            accentColor: statusColor,
            borderRadius: isMobile ? 16 : 24,
            padding: EdgeInsets.zero,
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 4 : 0,
              ),
              leading: Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: dt.roleSoftBg(statusColor),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  color: statusColor,
                  size: isMobile ? 18 : 22,
                ),
              ),
              title: Text(
                status,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isMobile ? 13 : 14,
                  color: dt.textPrimary,
                ),
              ),
              subtitle: Text(
                '${a['date'] ?? '—'}  ·  ${a['time'] ?? '—'}',
                style: TextStyle(
                  fontSize: isMobile ? 10 : 11,
                  fontWeight: FontWeight.w600,
                  color: dt.textMuted,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNavBar(DT dt, Color roleColor) {
    final isMobile = context.sw < 600;

    return Padding(
      padding: EdgeInsets.fromLTRB(isMobile ? 12 : 20, 0, isMobile ? 12 : 20, isMobile ? 16 : 24),
      child: Container(
        height: isMobile ? 60 : 72,
        decoration: BoxDecoration(
          color: dt.cardBg,
          borderRadius: BorderRadius.circular(isMobile ? 24 : 32),
          border: Border.all(color: dt.cardBorder, width: 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 24)],
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
    final isMobile = context.sw < 600;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: KagemaMotion.fast,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 22,
          vertical: isMobile ? 6 : 10,
        ),
        decoration: BoxDecoration(
          color: selected ? dt.roleSoftBg(roleColor) : Colors.transparent,
          borderRadius: BorderRadius.circular(isMobile ? 16 : 22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? roleColor : dt.iconInactive,
              size: isMobile ? 22 : 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 9 : 10,
                fontWeight: FontWeight.w800,
                color: selected ? roleColor : dt.iconInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(DT dt, Color roleColor) {
    final name = _staffProfile?['name']?.toString() ?? 'Staff Member';
    final role = _staffProfile?['role']?.toString() ?? 'Staff';
    final isMobile = context.sw < 600;

    return Drawer(
      backgroundColor: dt.cardBg,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                isMobile ? 40 : 60,
                isMobile ? 16 : 24,
                isMobile ? 20 : 28
            ),
            decoration: BoxDecoration(color: roleColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: isMobile ? 28 : 34,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: TextStyle(
                      fontSize: isMobile ? 22 : 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 10 : 14),
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  role.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: isMobile ? 9 : 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w700, color: c),
      ),
      onTap: onTap,
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color roleColor) {
    final isMobile = context.sw < 600;

    return Row(
      children: [
        Container(
          width: 4,
          height: isMobile ? 14 : 18,
          decoration: BoxDecoration(
            color: roleColor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: isMobile ? 13 : 15, color: roleColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: isMobile ? 9 : 10,
            fontWeight: FontWeight.w900,
            color: roleColor,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _emptyState(IconData icon, String msg, DT dt, Color roleColor) {
    final isMobile = context.sw < 600;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 20 : 30),
        child: Column(
          children: [
            Icon(
              icon,
              size: isMobile ? 36 : 44,
              color: roleColor.withOpacity(0.25),
            ),
            SizedBox(height: isMobile ? 10 : 14),
            Text(
              msg,
              style: TextStyle(
                color: dt.textMuted,
                fontSize: isMobile ? 9 : 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(DT dt) {
    final isMobile = context.sw < 600;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 20,
        vertical: isMobile ? 12 : 16,
      ),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: dt.roleSoftBg(KagemaColors.parentRed),
        borderRadius: BorderRadius.circular(isMobile ? 14 : 18),
        border: Border.all(color: KagemaColors.parentRed.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: KagemaColors.parentRed, size: isMobile ? 18 : 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: KagemaColors.parentRed,
                fontSize: isMobile ? 11 : 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: _loadDashboardData,
            icon: Icon(Icons.refresh_rounded, color: KagemaColors.parentRed),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            iconSize: isMobile ? 18 : 20,
          ),
        ],
      ),
    );
  }

  void _showTaskDialog(Map<String, dynamic> task, DT dt, Color roleColor) {
    final isMobile = context.sw < 600;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => LiquidGlassCard(
        borderRadius: isMobile ? 28 : 36,
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task['title'] ?? 'Staff Duty',
              style: TextStyle(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.w900,
                color: dt.textPrimary,
              ),
            ),
            SizedBox(height: isMobile ? 10 : 14),
            Text(
              task['description'] ?? 'No instructions.',
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                color: dt.textSecondary,
              ),
            ),
            SizedBox(height: isMobile ? 20 : 32),
            ElevatedButton(
              onPressed: () async {
                await SupabaseService.instance.updateTaskStatus(task['task_id'].toString(), 'Completed');
                if (mounted) { Navigator.pop(context); _loadDashboardData(); }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: KagemaColors.teacherGreen,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 30,
                  vertical: isMobile ? 10 : 14,
                ),
              ),
              child: Center(
                child: Text(
                  'MARK AS COMPLETED',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnnouncementDialog(Map<String, dynamic> n, DT dt) {
    final isMobile = context.sw < 600;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => LiquidGlassCard(
        borderRadius: isMobile ? 28 : 36,
        padding: EdgeInsets.all(isMobile ? 16 : 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              n['title'] ?? 'Notice',
              style: TextStyle(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.w900,
                color: dt.textPrimary,
              ),
            ),
            SizedBox(height: isMobile ? 10 : 14),
            Text(
              n['message'] ?? '',
              style: TextStyle(
                fontSize: isMobile ? 13 : 15,
                color: dt.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaveDialog(DT dt, Color roleColor) {
    final reasonCtrl = TextEditingController();
    String leaveType = 'Sick Leave';
    final isMobile = context.sw < 600;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: LiquidGlassCard(
          borderRadius: isMobile ? 28 : 36,
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'APPLY FOR LEAVE',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w900,
                  color: dt.textPrimary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: leaveType,
                items: ['Sick Leave', 'Personal', 'Vacation', 'Emergency'].map((l) => DropdownMenuItem(
                  value: l,
                  child: Text(l, style: TextStyle(fontSize: isMobile ? 13 : 14)),
                )).toList(),
                onChanged: (v) => leaveType = v!,
                decoration: InputDecoration(
                  labelText: 'Leave Type',
                  labelStyle: TextStyle(fontSize: isMobile ? 12 : 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  labelStyle: TextStyle(fontSize: isMobile ? 12 : 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (reasonCtrl.text.isNotEmpty && _staffProfile != null) {
                    await SupabaseService.instance.requestLeave({
                      'staff_id': _staffProfile!['staff_id'],
                      'type': leaveType,
                      'reason': reasonCtrl.text.trim(),
                      'status': 'Pending',
                      'date': DateFormat('yyyy-MM-dd').format(DateTime.now())
                    });
                    if (mounted) { Navigator.pop(context); _loadDashboardData(); }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: roleColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20 : 30,
                    vertical: isMobile ? 10 : 14,
                  ),
                ),
                child: Center(
                  child: Text(
                    'SUBMIT REQUEST',
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}