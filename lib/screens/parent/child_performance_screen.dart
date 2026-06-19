import 'package:flutter/material.dart';
import 'dart:ui';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../services/pdf_generator_service.dart';
import '../../app_theme.dart';

class ChildPerformanceScreen extends StatefulWidget {
  final Student student;
  const ChildPerformanceScreen({super.key, required this.student});

  @override
  State<ChildPerformanceScreen> createState() => _ChildPerformanceScreenState();
}

class _ChildPerformanceScreenState extends State<ChildPerformanceScreen> {
  List<Map<String, dynamic>> _marksData = [];
  bool _isLoading = true;
  double _average = 0.0;
  final String _roleId = 'parent';

  @override
  void initState() {
    super.initState();
    _loadPerformance();
  }

  Future<void> _loadPerformance() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getStudentMarks(widget.student.studentId);
      if (mounted) {
        setState(() {
          _marksData = data;
          _average = data.isEmpty ? 0.0 : data.fold(0.0, (sum, m) => sum + (m['score'] ?? 0)) / data.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadReport() async {
    final List<Mark> marks = _marksData.map((m) => Mark.fromMap(m)).toList();
    await PdfGeneratorService.generateReportCard(
      widget.student, 
      marks, 
      'Current Term', 
      DateTime.now().year
    );
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
        title: const Text('PERFORMANCE HUB', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 4, color: Colors.white)
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
            fit: StackFit.expand,
            children: [
              Positioned(
                right: -30, top: -10,
                child: Icon(Icons.auto_graph_rounded, size: 160, color: Colors.white.withValues(alpha: 0.12)),
              ),
            ],
          ),
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
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + context.pt + 10),
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: roleColor))
              : Column(
                  children: [
                    _buildPerformanceHero(dt, theme, roleColor),
                    const SizedBox(height: 32),
                    _buildSectionLabel(dt, 'SUBJECT ANALYTICS'),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _marksData.isEmpty 
                        ? _buildEmptyState(dt)
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: _marksData.length,
                            itemBuilder: (context, index) {
                              final m = _marksData[index];
                              final score = (m['score'] ?? 0).toDouble();
                              final scoreColor = _getScoreColor(score, dt);
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: theme.buildGlowContainer(
                                  accentColor: scoreColor,
                                  borderRadius: 28,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: dt.roleSoftBg(scoreColor),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.analytics_rounded, color: scoreColor, size: 22),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(m['subject']?.toString().toUpperCase() ?? 'SUBJECT', 
                                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5, color: dt.textPrimary)
                                            ),
                                            Text(m['exam_type']?.toString().toUpperCase() ?? 'ASSESSMENT', 
                                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 1)
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text('${score.toInt()}%', 
                                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: scoreColor, letterSpacing: -0.5)
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    ),
                    _buildDownloadButton(dt, roleColor),
                  ],
                ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildPerformanceHero(DT dt, GeminiThemeExtension? theme, Color roleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: theme?.buildGlowContainer(
        accentColor: roleColor,
        borderRadius: 35,
        padding: const EdgeInsets.all(32),
        useAIBorder: true,
        child: Column(
          children: [
            Text('TERM AGGREGATE', 
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.7), letterSpacing: 3)
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${_average.toInt()}', 
                  style: const TextStyle(
                    fontSize: 64, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: -3,
                    color: Colors.white,
                  )
                ),
                Text('%', 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.6))
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15), 
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_average >= 50 ? 'STATUS: EXCEEDING EXPECTATIONS' : 'STATUS: NEEDS IMPROVEMENT', 
                style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5)
              ),
            ),
          ],
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildDownloadButton(DT dt, Color roleColor) {
    if (_marksData.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Container(
        width: double.infinity,
        height: 65,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: roleColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 5))],
        ),
        child: ElevatedButton(
          onPressed: _downloadReport, 
          style: ElevatedButton.styleFrom(
            backgroundColor: roleColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.picture_as_pdf_rounded, size: 20),
              SizedBox(width: 12),
              Text('GENERATE PDF REPORT CARD', 
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 11)
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(DT dt, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(width: 4, height: 14, decoration: BoxDecoration(color: dt.info, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2.5)),
        ],
      ),
    );
  }

  Color _getScoreColor(double score, DT dt) {
    if (score >= 80) return dt.success;
    if (score >= 60) return dt.info;
    if (score >= 40) return dt.warning;
    return dt.error;
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_rounded, size: 80, color: dt.iconInactive),
          const SizedBox(height: 24),
          Text('NO ANALYTICS DATA FOUND', 
            style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 3, fontSize: 12)
          ),
        ],
      ),
    );
  }
}
