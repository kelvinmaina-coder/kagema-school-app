import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import '../../services/supabase_service.dart';
import '../settings/settings_screen.dart';
import 'student_registration.dart';
import '../common/parent_directory_screen.dart';
import 'appointment_management.dart';
import 'attendance_viewer.dart';
import 'secretary_reports.dart';
import 'visitors_manager.dart';
import '../admin/communication_hub_screen.dart';
import '../../app_theme.dart';

class SecretaryDashboard extends StatefulWidget {
  const SecretaryDashboard({super.key});

  @override
  State<SecretaryDashboard> createState() => _SecretaryDashboardState();
}

class _SecretaryDashboardState extends State<SecretaryDashboard> with TickerProviderStateMixin {
  int _currentIndex = 0;
  Map<String, dynamic> _stats = {
    'totalStudents': 0,
    'newAdmissions': 0,
    'upcomingAppointments': 0,
    'announcements': 0,
    'visitors_today': 0,
  };
  List<Map<String, dynamic>> _recentAppointments = [];
  bool _isLoading = true;
  String? _error;

  // Role Theme Color - Deep Amethyst/Indigo for the Office Admin
  final Color primaryAccent = const Color(0xFF7C4DFF); 
  final Color slateDeep = const Color(0xFF334155);

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        SupabaseService.instance.getSecretaryStats(),
        SupabaseService.instance.getAppointments(),
      ]);
      
      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, dynamic>;
          _recentAppointments = List<Map<String, dynamic>>.from(results[1] as List).take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "LINK UNSTABLE. SWIPE DOWN.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gemini = theme.extension<GeminiThemeExtension>();
    final screenWidth = MediaQuery.of(context).size.width;

    // RESPONSIVE ENGINE
    double maxWidth = screenWidth > 1200 ? 1100 : (screenWidth > 800 ? 850 : screenWidth);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0E12) : const Color(0xFFF4F7FA),
      body: gemini?.buildCreativeBackground(
        isDark: isDark,
        maxWidth: maxWidth,
        child: Stack(
          children: [
            _currentIndex == 0 ? _buildHomeTab(isDark, screenWidth, gemini) : _buildOperationsTab(isDark, screenWidth),
            _buildBottomNav(isDark, screenWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab(bool isDark, double screenWidth, GeminiThemeExtension? gemini) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: primaryAccent,
      edgeOffset: 120,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildElegantHeader('OFFICE COMMAND', Icons.admin_panel_settings_rounded),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth > 600 ? 32 : 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null) _buildErrorBanner(),
                  _buildSectionHeader('SYSTEM VITALS'),
                  const SizedBox(height: 20),
                  _buildStatsGrid(isDark, screenWidth, gemini),
                  const SizedBox(height: 40),
                  _buildSectionHeader('PRIORITY LOGS'),
                  const SizedBox(height: 20),
                  _buildRecentAppointments(isDark, screenWidth, gemini),
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElegantHeader(String title, IconData icon) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: primaryAccent,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        title: Text(title, 
          style: const TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 18, 
            letterSpacing: 4, 
            color: Colors.white,
          )
        ),
        background: Stack(
          children: [
            Container(color: primaryAccent),
            Positioned(
              right: -20, top: -10,
              child: Icon(icon, size: 180, color: Colors.white.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(bool isDark, double screenWidth, GeminiThemeExtension? gemini) {
    // ADJUST COLUMN COUNT BASED ON SCREEN SIZE
    int crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 2 : 2);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _statCard('STUDENTS', _stats['totalStudents'].toString(), Icons.people_rounded, const Color(0xFF3B82F6), isDark, gemini),
        _statCard('VISITORS', _stats['visitors_today'].toString(), Icons.badge_rounded, const Color(0xFF10B981), isDark, gemini),
        _statCard('APPOINTMENTS', _stats['upcomingAppointments'].toString(), Icons.event_rounded, const Color(0xFFF59E0B), isDark, gemini),
        _statCard('BULLETINS', _stats['announcements'].toString(), Icons.campaign_rounded, const Color(0xFF8B5CF6), isDark, gemini),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, bool isDark, GeminiThemeExtension? gemini) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // PULSING ICON BORDER
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isDark ? null : LinearGradient(
                  colors: [color.withOpacity(0.5), color, color.withOpacity(0.5)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                border: isDark ? Border.all(color: color.withOpacity(0.3), width: 1.5) : null,
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.2 * _pulseController.value), blurRadius: 8 * _pulseController.value, spreadRadius: 1)
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            );
          },
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : slateDeep, letterSpacing: -1)
            ),
            Text(label, 
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : const Color(0xFF64748B), letterSpacing: 1.5)
            ),
          ],
        ),
      ],
    );

    return gemini?.buildGlowContainer(
      borderRadius: 28,
      borderThickness: 1.5,
      padding: const EdgeInsets.all(16),
      backgroundColor: isDark ? const Color(0xFF1A1C2E) : Colors.white,
      child: content,
    ) ?? Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1C2E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: content,
    );
  }

  Widget _buildRecentAppointments(bool isDark, double screenWidth, GeminiThemeExtension? gemini) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_recentAppointments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(60),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1C2E).withOpacity(0.5) : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: Text('NO PENDING APPOINTMENTS', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.grey, fontSize: 10, letterSpacing: 1.5))),
      );
    }

    // GRID FOR TABLETS/DESKTOP
    if (screenWidth > 900) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 12,
          mainAxisExtent: 90,
        ),
        itemCount: _recentAppointments.length,
        itemBuilder: (context, index) => _buildAppointmentTile(_recentAppointments[index], isDark, gemini),
      );
    }

    return Column(
      children: _recentAppointments.map((appt) => _buildAppointmentTile(appt, isDark, gemini)).toList(),
    );
  }

  Widget _buildAppointmentTile(Map<String, dynamic> appt, bool isDark, GeminiThemeExtension? gemini) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1C2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [primaryAccent.withOpacity(0.2), primaryAccent])),
          child: CircleAvatar(
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            child: Text((appt['visitor_name'] ?? 'V')[0].toString().toUpperCase(), 
              style: TextStyle(color: primaryAccent, fontWeight: FontWeight.w900)
            ),
          ),
        ),
        title: Text(appt['visitor_name'] ?? 'Visitor', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? Colors.white : slateDeep)),
        subtitle: Text(appt['title']?.toString().toUpperCase() ?? 'GENERAL MEETING', 
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: primaryAccent.withOpacity(0.6), letterSpacing: 0.5)
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.blueGrey, size: 20),
      ),
    );
  }

  Widget _buildOperationsTab(bool isDark, double screenWidth) {
    int crossAxisCount = screenWidth > 900 ? 3 : (screenWidth > 600 ? 2 : 1);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildElegantHeader('OPERATIONS', Icons.grid_view_rounded),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth > 600 ? 32 : 20, vertical: 24),
          sliver: crossAxisCount == 1 
            ? SliverList(
                delegate: SliverChildListDelegate([
                  _buildSectionHeader('REGISTRY CONTROL'),
                  const SizedBox(height: 12),
                  _opTile('Student Admission', 'Enroll new pupils', Icons.person_add_rounded, const Color(0xFF3B82F6), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRegistrationScreen()))),
                  _opTile('Parent Directory', 'Contact database', Icons.family_restroom_rounded, const Color(0xFF10B981), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentDirectoryScreen()))),
                  const SizedBox(height: 24),
                  _buildSectionHeader('LOGISTICS & SECURITY'),
                  const SizedBox(height: 12),
                  _opTile('Visitors Manager', 'Gate tracking', Icons.badge_rounded, const Color(0xFF00ACC1), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorsManagerScreen()))),
                  _opTile('Office Schedule', 'Appointments', Icons.event_available_rounded, const Color(0xFFF59E0B), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentManagementScreen()))),
                  _opTile('Attendance Hub', 'Monitoring', Icons.fact_check_rounded, const Color(0xFF10B981), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceViewerScreen()))),
                  const SizedBox(height: 24),
                  _buildSectionHeader('COMMUNICATIONS'),
                  const SizedBox(height: 12),
                  _opTile('Official Bulletins', 'Broadcasts', Icons.campaign_rounded, const Color(0xFF8B5CF6), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunicationHubScreen()))),
                  _opTile('System Reports', 'Data export', Icons.assignment_rounded, const Color(0xFFEF4444), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecretaryReportsScreen()))),
                  const SizedBox(height: 140),
                ]),
              )
            : SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 90,
                ),
                delegate: SliverChildListDelegate([
                   _opTile('Admission', 'Enroll Pupils', Icons.person_add_rounded, const Color(0xFF3B82F6), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRegistrationScreen()))),
                   _opTile('Parents', 'Directory', Icons.family_restroom_rounded, const Color(0xFF10B981), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentDirectoryScreen()))),
                   _opTile('Visitors', 'Tracking', Icons.badge_rounded, const Color(0xFF00ACC1), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorsManagerScreen()))),
                   _opTile('Schedule', 'Appointments', Icons.event_available_rounded, const Color(0xFFF59E0B), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentManagementScreen()))),
                   _opTile('Attendance', 'Hub', Icons.fact_check_rounded, const Color(0xFF10B981), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceViewerScreen()))),
                   _opTile('Bulletins', 'Broadcasts', Icons.campaign_rounded, const Color(0xFF8B5CF6), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunicationHubScreen()))),
                   _opTile('Reports', 'Data Export', Icons.assignment_rounded, const Color(0xFFEF4444), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecretaryReportsScreen()))),
                ]),
              ),
        ),
      ],
    );
  }

  Widget _opTile(String title, String sub, IconData icon, Color color, bool isDark, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? const Color(0xFF1A1C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? Colors.white : slateDeep)),
                      const SizedBox(height: 2),
                      Text(sub.toUpperCase(), style: TextStyle(fontSize: 9, color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white12 : Colors.black12, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(bool isDark, double screenWidth) {
    double navWidth = screenWidth > 800 ? 500 : screenWidth - 40;

    return Positioned(
      bottom: 25, left: 0, right: 0,
      child: Center(
        child: Container(
          width: navWidth,
          height: 70,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1C2E).withOpacity(0.95) : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))],
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(0, Icons.grid_view_rounded, 'HUB'),
              _navItem(1, Icons.apps_rounded, 'TOOLS'),
              _navItem(2, Icons.settings_rounded, 'SETUP'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen(role: 'Secretary')));
          return;
        }
        setState(() => _currentIndex = index);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? primaryAccent : Colors.grey.withOpacity(0.5), size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isSelected ? primaryAccent : Colors.grey.withOpacity(0.5), letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: primaryAccent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.5, color: Color(0xFF475569))),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFFCDD2))),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFD32F2F)),
          const SizedBox(width: 12),
          Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 11, fontWeight: FontWeight.w800))),
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Color(0xFFD32F2F), size: 20), onPressed: _loadData),
        ],
      ),
    );
  }
}
