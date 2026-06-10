import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../settings/settings_screen.dart';
import 'fees_payment.dart';
import 'child_performance_screen.dart';
import 'child_attendance_viewers.dart';
import 'homework_screen.dart';
import 'child_list_screen.dart';
import 'announcements_screen.dart';
import '../../app_theme.dart';

class ParentDashboard extends StatefulWidget {
  final String parentPhone;
  const ParentDashboard({super.key, required this.parentPhone});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  List<Student> children = [];
  Student? selectedChild;
  bool isLoading = true;
  StreamSubscription? _notifSubscription;

  // Stats for selected child
  double _attendancePercent = 0.0;
  double _avgGrade = 0.0;
  double _feeBalance = 0.0;
  List<Map<String, dynamic>> _recentNotices = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _setupNotifications();
  }

  void _setupNotifications() {
    _notifSubscription = SupabaseService.instance.notificationStream.listen((data) {
      _loadAllData();
    });
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    
    try {
      final childMaps = await SupabaseService.instance.getParentChildren(widget.parentPhone);
      final notices = await SupabaseService.instance.getNotifications('Parent');
      
      if (mounted) {
        setState(() {
          children = childMaps.map((m) => Student.fromMap(m)).toList();
          _recentNotices = notices.take(2).toList();
          if (children.isNotEmpty) {
            selectedChild ??= children[0];
          }
        });
        
        if (selectedChild != null) {
          await _loadChildVitals();
        }
      }
    } catch (e) {
      debugPrint("ParentDashboard Load Error: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadChildVitals() async {
    if (selectedChild == null) return;
    
    try {
      // FIXED: Added explicit Future typing to avoid List<dynamic> inference error
      final results = await Future.wait<dynamic>([
        SupabaseService.instance.getStudentMarks(selectedChild!.studentId),
        SupabaseService.instance.getChildAttendance(selectedChild!.studentId),
        SupabaseService.instance.getStudentBalance(selectedChild!.studentId, selectedChild!.grade),
      ]);

      final marks = results[0] as List<Map<String, dynamic>>;
      final att = results[1] as List<Map<String, dynamic>>;
      final balanceData = results[2] as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _avgGrade = marks.isEmpty ? 0.0 : marks.fold(0.0, (sum, m) => sum + (m['score'] ?? 0)) / marks.length;
          _attendancePercent = att.isEmpty ? 0.0 : (att.where((a) => a['status'] == 'Present').length / att.length) * 100;
          _feeBalance = balanceData['balance'] ?? 0.0;
        });
      }
    } catch (e) {
      debugPrint("Child Vitals Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : children.isEmpty
                ? _buildNoChildren(theme)
                : RefreshIndicator(
                    onRefresh: _loadAllData,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        _buildHeroAppBar(theme, gemini),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 24),
                                _buildChildSelector(theme),
                                const SizedBox(height: 24),
                                _buildSectionLabel(theme, 'CHILD VITALS'),
                                const SizedBox(height: 16),
                                _buildVitalsRow(theme),
                                const SizedBox(height: 32),
                                _buildSectionLabel(theme, 'DASHBOARD CARDS'),
                                const SizedBox(height: 16),
                                _buildDashboardGrid(theme),
                                const SizedBox(height: 32),
                                _buildSectionLabel(theme, 'LATEST ANNOUNCEMENTS'),
                                const SizedBox(height: 16),
                                _buildAnnouncementsPreview(theme),
                                const SizedBox(height: 40),
                                _buildCreativeSignOut(theme),
                                const SizedBox(height: 60),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeroAppBar(ThemeData theme, GeminiThemeExtension? gemini) {
    return SliverAppBar(
      expandedHeight: 160.0,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PARENT PORTAL', style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            Text(selectedChild?.parentName ?? 'Guardian', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.white)),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: gemini?.primaryGradient ?? LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)]),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
          ),
          child: Stack(
            children: [
              Positioned(right: -20, bottom: -10, child: Icon(Icons.family_restroom_rounded, size: 200, color: Colors.white.withOpacity(0.05))),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white, size: 18)),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(role: 'Parent'))),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildChildSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: theme.primaryColor, child: Text(selectedChild?.name[0] ?? '?', style: const TextStyle(color: Colors.white))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('VIEWING DATA FOR', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                DropdownButtonHideUnderline(
                  child: DropdownButton<Student>(
                    value: selectedChild,
                    isDense: true,
                    items: children.map((c) => DropdownMenuItem(value: c, child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          selectedChild = v;
                        });
                        _loadChildVitals();
                      }
                    },
                  ),
                ),
                Text('${selectedChild?.grade ?? ""} • ADM: ${selectedChild?.admissionNumber ?? ""}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
              ],
            ),
          ),
          const Icon(Icons.swap_horiz_rounded, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildVitalsRow(ThemeData theme) {
    return Row(
      children: [
        _vitalBox(theme, 'Attendance', '${_attendancePercent.toInt()}%', Colors.blue),
        const SizedBox(width: 12),
        _vitalBox(theme, 'Fee Bal', 'Ksh ${_feeBalance.toInt()}', _feeBalance > 0 ? Colors.red : Colors.green),
        const SizedBox(width: 12),
        _vitalBox(theme, 'Mean Score', '${_avgGrade.toInt()}%', Colors.orange),
      ],
    );
  }

  Widget _vitalBox(ThemeData theme, String l, String v, Color c) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(v, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: c)),
            const SizedBox(height: 4),
            Text(l, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardGrid(ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _mosaicCard(theme, 'My Children', Icons.people_outline, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildListScreen(parentPhone: widget.parentPhone)))),
        _mosaicCard(theme, 'Attendance', Icons.event_available_rounded, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildAttendanceScreen(student: selectedChild!)))),
        _mosaicCard(theme, 'Exam Results', Icons.auto_graph_rounded, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildPerformanceScreen(student: selectedChild!)))),
        _mosaicCard(theme, 'Fee Management', Icons.payments_rounded, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => FeesPaymentScreen(student: selectedChild!)))),
        _mosaicCard(theme, 'Homework', Icons.assignment_rounded, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => HomeworkScreen(grade: selectedChild!.grade, stream: selectedChild!.stream)))),
        _mosaicCard(theme, 'Announcements', Icons.campaign_rounded, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsScreen()))),
      ],
    );
  }

  Widget _mosaicCard(ThemeData theme, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementsPreview(ThemeData theme) {
    if (_recentNotices.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No announcements found in cloud.', style: TextStyle(fontSize: 12, color: Colors.grey))));
    return Column(
      children: _recentNotices.map((n) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: const Icon(Icons.info_outline, color: Colors.teal),
          title: Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(n['message'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsScreen())),
        ),
      )).toList(),
    );
  }

  Widget _buildCreativeSignOut(ThemeData theme) {
    return InkWell(
      onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.red.withOpacity(0.1))),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.red, size: 20),
            SizedBox(width: 12),
            Text('LOGOUT PORTAL', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String text) {
    return Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.primaryColor.withOpacity(0.5), letterSpacing: 2));
  }

  Widget _buildNoChildren(ThemeData theme) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.person_off_rounded, size: 80, color: Colors.grey),
      const SizedBox(height: 16),
      const Text('No pupils linked to this phone number.', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 24),
      _buildCreativeSignOut(theme),
    ]));
  }
}
