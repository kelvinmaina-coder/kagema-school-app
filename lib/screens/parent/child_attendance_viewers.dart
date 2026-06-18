import 'package:flutter/material.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class ChildAttendanceScreen extends StatefulWidget {
  final Student student;
  const ChildAttendanceScreen({super.key, required this.student});

  @override
  State<ChildAttendanceScreen> createState() => _ChildAttendanceScreenState();
}

class _ChildAttendanceScreenState extends State<ChildAttendanceScreen> {
  List<Attendance> _records = [];
  bool _isLoading = true;
  int _present = 0;
  int _absent = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final listData = await SupabaseService.instance.getChildAttendance(widget.student.studentId);
      final list = listData.map((m) => Attendance.fromMap(m)).toList();
      int p = list.where((r) => r.status == 'Present').length;
      if (mounted) {
        setState(() {
          _records = list;
          _present = p;
          _absent = list.length - p;
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('ATTENDANCE LOG', 
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 16, 
            letterSpacing: 4, 
            color: Colors.white, 
            shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10)]
          )
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: gemini?.primaryGradient ?? LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.8)]),
                ),
              ),
              Positioned(
                right: -30, top: -10,
                child: Icon(Icons.verified_user_rounded, size: 180, color: Colors.white.withValues(alpha: 0.05)),
              ),
            ],
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: isDark,
        child: _isLoading 
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor, strokeWidth: 3))
          : Column(
              children: [
                SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 30),
                _buildSummaryCard(theme, gemini, isDark),
                const SizedBox(height: 30),
                _buildSectionLabel('DAILY RECORDS'),
                const SizedBox(height: 16),
                Expanded(
                  child: _records.isEmpty 
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _records.length,
                        itemBuilder: (context, index) {
                          final r = _records[index];
                          final isP = r.status == 'Present';
                          final color = isP ? const Color(0xFF00E676) : const Color(0xFFFF3D00);
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: gemini?.buildGlowContainer(
                              borderRadius: 28,
                              borderThickness: 1.2,
                              backgroundColor: isDark ? const Color(0xF21A1C22) : const Color(0xF2FFFFFF),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(isP ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color, size: 22),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r.date.toUpperCase(), 
                                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5, color: isDark ? Colors.white : Colors.black87)
                                        ),
                                        Text('ROLL CALL TAKEN', 
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : Colors.black26, letterSpacing: 1)
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: color.withValues(alpha: 0.2))
                                    ),
                                    child: Text(r.status.toUpperCase(), 
                                      style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
      ) ?? const SizedBox(),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, GeminiThemeExtension? gemini, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: gemini?.buildGlowContainer(
        borderRadius: 35,
        borderThickness: 2.5,
        backgroundColor: isDark ? const Color(0xF21A1C22) : const Color(0xF2FFFFFF),
        padding: const EdgeInsets.all(32),
        useAIBorder: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat('PRESENT', '$_present', const Color(0xFF00E676), isDark),
            Container(width: 1, height: 40, color: isDark ? Colors.white12 : Colors.black12),
            _stat('ABSENT', '$_absent', const Color(0xFFFF3D00), isDark),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color, bool isDark) => Column(
    children: [
      Text(value, 
        style: TextStyle(
          fontSize: 36, 
          fontWeight: FontWeight.w900, 
          color: color,
          shadows: [Shadow(color: color.withValues(alpha: 0.3), blurRadius: 15)]
        )
      ),
      const SizedBox(height: 4),
      Text(label, 
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 2)
      ),
    ],
  );

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(width: 4, height: 14, decoration: BoxDecoration(color: const Color(0xFF2979FF), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2.5)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 80, color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 24),
          const Text('NO ATTENDANCE RECORDS FOUND', 
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 3, fontSize: 12)
          ),
        ],
      ),
    );
  }
}
