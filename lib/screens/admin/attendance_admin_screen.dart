import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllStats();
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
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Attendance Intelligence', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, Colors.purple.shade900], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.verified_user_rounded, size: 140, color: Colors.white.withOpacity(0.1)))]),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(borderRadius: BorderRadius.circular(50), color: Colors.white.withOpacity(0.2)),
          indicatorPadding: const EdgeInsets.all(8),
          tabs: const [Tab(text: 'STUDENTS'), Tab(text: 'FACULTY')],
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : Padding(
              padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 48),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildStatsPage(theme, gemini, _studentStats, 'Pupil Quota'),
                  _buildStatsPage(theme, gemini, _staffStats, 'Staff Quota'),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildStatsPage(ThemeData theme, GeminiThemeExtension? gemini, Map<String, dynamic> stats, String label) {
    double rate = stats['total'] == 0 ? 0 : (stats['present'] / stats['total']) * 100;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          gemini?.buildGlowContainer(
            borderRadius: 35, borderThickness: 2, backgroundColor: theme.cardColor.withOpacity(0.9), padding: const EdgeInsets.all(40),
            child: Column(children: [
              Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
              const SizedBox(height: 32),
              Stack(alignment: Alignment.center, children: [
                SizedBox(width: 160, height: 160, child: CircularProgressIndicator(value: rate/100, strokeWidth: 16, backgroundColor: theme.primaryColor.withOpacity(0.1), color: theme.primaryColor, strokeCap: StrokeCap.round)),
                Text('${rate.toInt()}%', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
              ]),
            ]),
          ) ?? const SizedBox(),
          const SizedBox(height: 48),
          _miniCard(theme, 'Active Nodes Present', '${stats['present']}', Colors.green),
          const SizedBox(height: 12),
          _miniCard(theme, 'Total Registry Count', '${stats['total']}', Colors.blue),
        ],
      ),
    );
  }

  Widget _miniCard(ThemeData theme, String l, String v, Color c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.9), borderRadius: BorderRadius.circular(24), border: Border.all(color: c.withOpacity(0.1))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: const TextStyle(fontWeight: FontWeight.bold)), Text(v, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: c))]),
    );
  }
}
