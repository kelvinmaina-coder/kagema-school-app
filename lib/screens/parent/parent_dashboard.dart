import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../settings/settings_screen.dart';
import 'fees_payment.dart';
import 'child_performance_screen.dart';
import 'child_attendance_viewers.dart';
import 'homework_screen.dart';
import 'child_list_screen.dart';
import 'announcements_screen.dart';
import 'child_discipline_screen.dart';
import 'child_timetable_screen.dart';
import 'child_library_screen.dart';
import 'parent_calendar_screen.dart';
import '../../app_theme.dart';

class ParentDashboard extends StatefulWidget {
  final String parentPhone;
  const ParentDashboard({super.key, required this.parentPhone});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _selectedIndex = 0;
  List<Student> children = [];
  Student? selectedChild;
  bool isLoading = true;
  
  double _attendancePercent = 0.0;
  double _avgGrade = 0.0;
  double _feeBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final childMaps = await SupabaseService.instance.getParentChildren(widget.parentPhone);
      if (mounted) {
        setState(() {
          children = childMaps.map((m) => Student.fromMap(m)).toList();
          if (children.isNotEmpty) { selectedChild ??= children[0]; }
        });
        if (selectedChild != null) await _loadChildVitals();
      }
    } catch (e) {
      debugPrint("Parent Sync Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadChildVitals() async {
    if (selectedChild == null) return;
    try {
      final results = await Future.wait<dynamic>([
        SupabaseService.instance.getStudentMarks(selectedChild!.studentId),
        SupabaseService.instance.getChildAttendance(selectedChild!.studentId),
        SupabaseService.instance.getStudentBalance(selectedChild!.studentId, selectedChild!.grade),
      ]);
      if (mounted) {
        setState(() {
          final marks = results[0] as List<Map<String, dynamic>>;
          final att = results[1] as List<Map<String, dynamic>>;
          final balanceData = results[2] as Map<String, dynamic>;
          _avgGrade = marks.isEmpty ? 0.0 : marks.fold(0.0, (sum, m) => sum + (m['score'] ?? 0)) / marks.length;
          _attendancePercent = att.isEmpty ? 0.0 : (att.where((a) => a['status'] == 'Present').length / att.length) * 100;
          _feeBalance = (balanceData['balance'] ?? 0.0).toDouble();
        });
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // INTELLIGENT RESPONSIVENESS: Limit content width on Desktop/Tablet
    double maxWidth = screenWidth > 1200 ? 1000 : (screenWidth > 800 ? 800 : screenWidth);

    return Scaffold(
      extendBody: true,
      body: gemini?.buildCreativeBackground(
        isDark: isDark,
        maxWidth: maxWidth, 
        child: isLoading 
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor, strokeWidth: 3))
          : IndexedStack(
              index: _selectedIndex,
              children: [
                _buildHomeTab(theme, gemini, screenWidth),
                const AnnouncementsScreen(),
                ChildListScreen(parentPhone: widget.parentPhone),
                const SettingsScreen(role: 'Parent'),
              ],
            ),
      ) ?? const SizedBox(),
      bottomNavigationBar: _buildModernNavBar(theme, gemini, screenWidth),
    );
  }

  Widget _buildHomeTab(ThemeData theme, GeminiThemeExtension? gemini, double screenWidth) {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: theme.primaryColor,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeroAppBar(theme, gemini),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth > 600 ? 40 : 20, 
                vertical: 32
              ),
              child: children.isEmpty 
                ? _buildEmptyState(theme.brightness == Brightness.dark)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChildSelector(theme, gemini),
                      const SizedBox(height: 40),
                      _buildSectionLabel('INTELLIGENT INSIGHTS'),
                      const SizedBox(height: 16),
                      _buildVitalsRow(theme, gemini, screenWidth),
                      const SizedBox(height: 40),
                      _buildSectionLabel('STUDENT SERVICES'),
                      const SizedBox(height: 16),
                      _buildServiceGrid(theme, gemini, screenWidth),
                      const SizedBox(height: 140),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsRow(ThemeData theme, GeminiThemeExtension? gemini, double screenWidth) {
    // Wrap vitals on very small screens
    if (screenWidth < 360) {
       return Column(
         children: [
           Row(children: [
             _vitalBox(theme, gemini, 'ATTENDANCE', '${_attendancePercent.toInt()}%', const Color(0xFF2979FF), true),
             const SizedBox(width: 12),
             _vitalBox(theme, gemini, 'AVG SCORE', '${_avgGrade.toInt()}%', const Color(0xFFFFAB40), false),
           ]),
           const SizedBox(height: 12),
           _vitalBox(theme, gemini, 'FEES DUE', 'KSH ${_feeBalance.toInt()}', _feeBalance > 0 ? const Color(0xFFFF3D00) : const Color(0xFF00E676), false),
         ],
       );
    }
    
    return Row(
      children: [
        _vitalBox(theme, gemini, 'ATTENDANCE', '${_attendancePercent.toInt()}%', const Color(0xFF2979FF), true),
        const SizedBox(width: 12),
        _vitalBox(theme, gemini, 'FEES DUE', 'KSH ${_feeBalance.toInt()}', _feeBalance > 0 ? const Color(0xFFFF3D00) : const Color(0xFF00E676), false),
        const SizedBox(width: 12),
        _vitalBox(theme, gemini, 'AVG SCORE', '${_avgGrade.toInt()}%', const Color(0xFFFFAB40), false),
      ],
    );
  }

  Widget _vitalBox(ThemeData theme, GeminiThemeExtension? gemini, String label, String value, Color color, bool useAIBorder) {
    final isDark = theme.brightness == Brightness.dark;
    
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value, 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color, shadows: [Shadow(color: color.withOpacity(0.2), blurRadius: 15)])
        ), 
        const SizedBox(height: 6), 
        Text(label, 
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 1.5)
        )
      ]
    );

    return Expanded(
      flex: 1,
      child: gemini?.buildGlowContainer(
        borderRadius: 24,
        borderThickness: 1.5,
        backgroundColor: isDark ? const Color(0xF2121418) : const Color(0xF2FFFFFF),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        useAIBorder: useAIBorder, 
        child: content,
      ) ?? Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xF2121418) : const Color(0xF2FFFFFF),
          borderRadius: BorderRadius.circular(24),
        ),
        child: content,
      ),
    );
  }

  Widget _buildServiceGrid(ThemeData theme, GeminiThemeExtension? gemini, double screenWidth) {
    // Dynamic column count for responsiveness
    int crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _serviceCard(theme, gemini, 'ROLL CALL', Icons.event_available_rounded, const Color(0xFF2979FF), () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildAttendanceScreen(student: selectedChild!)))),
        _serviceCard(theme, gemini, 'PERFORMANCE', Icons.auto_graph_rounded, const Color(0xFFFFAB40), () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildPerformanceScreen(student: selectedChild!)))),
        _serviceCard(theme, gemini, 'FEE PORTAL', Icons.account_balance_wallet_rounded, const Color(0xFF00E676), () => Navigator.push(context, MaterialPageRoute(builder: (_) => FeesPaymentScreen(student: selectedChild!)))),
        _serviceCard(theme, gemini, 'HOMEWORK', Icons.assignment_rounded, const Color(0xFF7C4DFF), () => Navigator.push(context, MaterialPageRoute(builder: (_) => HomeworkScreen(grade: selectedChild!.grade, stream: selectedChild!.stream)))),
        _serviceCard(theme, gemini, 'TIMETABLE', Icons.calendar_view_week_rounded, const Color(0xFF00B0FF), () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildTimetableScreen(student: selectedChild!)))),
        _serviceCard(theme, gemini, 'LIBRARY', Icons.local_library_rounded, const Color(0xFF607D8B), () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildLibraryScreen(student: selectedChild!)))),
        _serviceCard(theme, gemini, 'CONDUCT', Icons.gavel_rounded, const Color(0xFFFF3D00), () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildDisciplineScreen(student: selectedChild!)))),
        _serviceCard(theme, gemini, 'CALENDAR', Icons.event_note_rounded, const Color(0xFFFF4081), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentCalendarScreen()))),
      ],
    );
  }

  Widget _serviceCard(ThemeData theme, GeminiThemeExtension? gemini, String title, IconData icon, Color color, VoidCallback onTap) {
    final isDark = theme.brightness == Brightness.dark;
    
    final cardContent = Column(
      mainAxisAlignment: MainAxisAlignment.center, 
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ), 
        const SizedBox(height: 12), 
        Text(title, 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1.5, color: isDark ? Colors.white70 : Colors.black87)
        )
      ]
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: gemini?.buildGlowContainer(
          borderRadius: 28,
          borderThickness: 1.2,
          backgroundColor: isDark ? const Color(0xF21A1C22) : const Color(0xF2FFFFFF),
          padding: const EdgeInsets.all(12),
          child: cardContent,
        ) ?? Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xF21A1C22) : const Color(0xF2FFFFFF),
            borderRadius: BorderRadius.circular(28),
          ),
          child: cardContent,
        ),
      ),
    );
  }

  Widget _buildModernNavBar(ThemeData theme, GeminiThemeExtension? gemini, double screenWidth) {
    final isDark = theme.brightness == Brightness.dark;
    
    // Narrow navigation for tablets/desktop to keep it looking clean
    double navWidth = screenWidth > 800 ? 500 : screenWidth - 40;

    return Center(
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 25),
        width: navWidth,
        height: 75,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xF2121418) : const Color(0xF2FFFFFF), 
          borderRadius: BorderRadius.circular(30), 
          border: Border.all(color: Colors.white.withOpacity(isDark ? 0.05 : 0.4)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _navIcon(0, Icons.grid_view_rounded, 'HUB'),
                _navIcon(1, Icons.campaign_rounded, 'ALERTS'),
                _navIcon(2, Icons.family_restroom_rounded, 'FAMILY'),
                _navIcon(3, Icons.person_rounded, 'PROFILE'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navIcon(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    final color = isSelected ? Theme.of(context).primaryColor : Colors.blueGrey.withOpacity(0.5);
    
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 26),
          ), 
          const SizedBox(height: 4),
          Text(label, 
            style: TextStyle(
              fontSize: 8, 
              fontWeight: FontWeight.w900, 
              color: color,
              letterSpacing: 1
            )
          )
        ]
      ),
    );
  }

  Widget _buildChildSelector(ThemeData theme, GeminiThemeExtension? gemini) {
    if (children.isEmpty) return const SizedBox.shrink();
    final isDark = theme.brightness == Brightness.dark;

    final selectorContent = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.primaryColor, width: 2),
          ),
          child: CircleAvatar(
            radius: 18, 
            backgroundColor: theme.primaryColor.withOpacity(0.1), 
            child: Text(selectedChild?.name[0] ?? '?', 
              style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)
            )
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Student>(
              value: selectedChild,
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF1A1C22) : Colors.white,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.primaryColor),
              items: children.map((c) => DropdownMenuItem(
                value: c, 
                child: Text(c.name.toUpperCase(), 
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: isDark ? Colors.white : Colors.black87, letterSpacing: 1)
                )
              )).toList(),
              onChanged: (v) { if (v != null) { setState(() => selectedChild = v); _loadChildVitals(); } },
            ),
          ),
        ),
      ],
    );

    return gemini?.buildGlowContainer(
      borderRadius: 30, 
      borderThickness: 1.5, 
      backgroundColor: isDark ? const Color(0xF2121418) : const Color(0xF2FFFFFF), 
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4), 
      useAIBorder: true,
      child: selectorContent,
    ) ?? Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xF2121418) : const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(30),
      ),
      child: selectorContent,
    );
  }

  Widget _buildHeroAppBar(ThemeData theme, GeminiThemeExtension? gemini) {
    return SliverAppBar(
      expandedHeight: 140.0, 
      pinned: true, 
      backgroundColor: Colors.transparent, 
      elevation: 0,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text('PARENT PORTAL', 
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 16, 
            letterSpacing: 4, 
            color: Colors.white,
            shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)]
          )
        ),
        background: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(decoration: BoxDecoration(gradient: gemini?.primaryGradient)),
              Positioned(
                right: -30, 
                bottom: -20, 
                child: Icon(Icons.hub_rounded, size: 180, color: Colors.white.withOpacity(0.05))
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(width: 4, height: 14, decoration: BoxDecoration(color: const Color(0xFF00E676), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(text, 
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 3)
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 80), 
          Icon(Icons.diversity_3_rounded, size: 80, color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)), 
          const SizedBox(height: 24), 
          Text('NO LINKED STUDENTS', 
            style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : Colors.black26, letterSpacing: 3, fontSize: 13)
          ), 
          const SizedBox(height: 8), 
          Text('Link your account at the school office.', 
            style: TextStyle(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1), fontSize: 11, fontWeight: FontWeight.bold)
          ),
        ]
      )
    );
  }
}
