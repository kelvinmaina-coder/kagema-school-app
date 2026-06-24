import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';
import '../../services/authentication_service.dart';
import '../../app_theme.dart';

class AttendanceAdminScreen extends StatefulWidget {
  const AttendanceAdminScreen({super.key});

  @override
  State<AttendanceAdminScreen> createState() => _AttendanceAdminScreenState();
}

class _AttendanceAdminScreenState extends State<AttendanceAdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _studentStats = {'present': 0, 'total': 0};
  Map<String, dynamic> _staffStats = {'present': 0, 'total': 0};
  bool _isLoading = true;
  final String _roleId = 'admin';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllStats();
    
    // EVENT HANDLING: Listen for global authentication/sync changes
    // If the data syncs in the background, this will trigger a refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthenticationService>(context, listen: false).addListener(_handleSyncEvent);
    });
  }

  @override
  void dispose() {
    // Clean up event listener
    Provider.of<AuthenticationService>(context, listen: false).removeListener(_handleSyncEvent);
    _tabController.dispose();
    super.dispose();
  }

  // --- THIS IS THE EVENT HANDLER ---
  void _handleSyncEvent() {
    if (mounted) _loadAllStats();
  }

  Future<void> _loadAllStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final summary = await SupabaseService.instance.getDashboardSummary();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final attendance = await SupabaseService.instance.getGlobalAttendanceByDate(today);
      
      int sPresent = attendance.where((a) => a['status'] == 'Present' && a['target_type'] != 'Staff').length;
      int stPresent = attendance.where((a) => a['status'] == 'Checked-In').length;

      if (mounted) {
        setState(() {
          _studentStats = {'present': sPresent, 'total': summary['students'] ?? 0};
          _staffStats = {'present': stPresent, 'total': summary['staff'] ?? 0};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
        title: const Text('ATTENDANCE INTEL', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 3, color: Colors.white)
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: RoleColors.gradient(_roleId, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.verified_user_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadAllStats,
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(50), 
            color: Colors.white.withValues(alpha: 0.2),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3))
          ),
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          tabs: const [Tab(text: 'STUDENTS'), Tab(text: 'FACULTY')],
        ),
      ),
      body: theme?.buildCreativeBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: _isLoading 
            ? Center(child: CircularProgressIndicator(color: roleColor))
            : Padding(
                padding: EdgeInsets.only(top: AppBar().preferredSize.height + context.pt + 48),
                child: RefreshIndicator(
                  onRefresh: _loadAllStats,
                  color: roleColor,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStatsPage(dt, theme, roleColor, _studentStats, 'Pupil Quota', KagemaColors.staffSky),
                      _buildStatsPage(dt, theme, roleColor, _staffStats, 'Staff Quota', KagemaColors.teacherGreen),
                    ],
                  ),
                ),
              ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildStatsPage(DT dt, GeminiThemeExtension? theme, Color roleColor, Map<String, dynamic> stats, String label, Color accentColor) {
    double rate = stats['total'] == 0 ? 0 : (stats['present'] / stats['total']) * 100;
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          theme?.buildGlowContainer(
            accentColor: accentColor,
            borderRadius: 35,
            padding: const EdgeInsets.all(40),
            useAIBorder: true,
            child: Column(
              children: [
                Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.7), letterSpacing: 2.5)),
                const SizedBox(height: 32),
                Stack(
                  alignment: Alignment.center, 
                  children: [
                    SizedBox(
                      width: 160, height: 160, 
                      child: CircularProgressIndicator(
                        value: rate/100, 
                        strokeWidth: 16, 
                        backgroundColor: Colors.white.withValues(alpha: 0.1), 
                        color: Colors.white, 
                        strokeCap: StrokeCap.round
                      )
                    ),
                    Text('${rate.toInt()}%', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
                  ]
                ),
              ]
            ),
          ) ?? const SizedBox.shrink(),
          const SizedBox(height: 48),
          _miniCard(dt, theme, 'ACTIVE NODES PRESENT', '${stats['present']}', dt.success),
          const SizedBox(height: 16),
          _miniCard(dt, theme, 'TOTAL REGISTRY COUNT', '${stats['total']}', dt.info),
        ],
      ),
    );
  }

  Widget _miniCard(DT dt, GeminiThemeExtension? theme, String label, String value, Color color) {
    return theme?.buildGlowContainer(
      accentColor: color,
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, fontSize: 9, letterSpacing: 1.5)), 
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: color, letterSpacing: -0.5))
        ]
      ),
    ) ?? const SizedBox.shrink();
  }
}
