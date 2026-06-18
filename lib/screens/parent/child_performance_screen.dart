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
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('PERFORMANCE HUB', 
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 16, 
            letterSpacing: 4, 
            color: Colors.white, 
            shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)]
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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE65100), Color(0xFFFFAB40)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                right: -30, top: -10,
                child: Icon(Icons.auto_graph_rounded, size: 160, color: Colors.white.withOpacity(0.12)),
              ),
            ],
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: isDark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
          child: _isLoading 
            ? Center(child: CircularProgressIndicator(color: theme.primaryColor, strokeWidth: 3))
            : Column(
                children: [
                  _buildPerformanceHero(theme, gemini, isDark),
                  const SizedBox(height: 32),
                  _buildSectionLabel('SUBJECT ANALYTICS'),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _marksData.isEmpty 
                      ? _buildEmptyState(isDark)
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: _marksData.length,
                          itemBuilder: (context, index) {
                            final m = _marksData[index];
                            final score = (m['score'] ?? 0).toDouble();
                            final scoreColor = _getScoreColor(score);
                            
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
                                        color: scoreColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: scoreColor.withOpacity(0.2))
                                      ),
                                      child: Icon(Icons.analytics_rounded, color: scoreColor, size: 22),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(m['subject']?.toString().toUpperCase() ?? 'SUBJECT', 
                                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5, color: isDark ? Colors.white : Colors.black87)
                                          ),
                                          Text(m['exam_type']?.toString().toUpperCase() ?? 'ASSESSMENT', 
                                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : Colors.black26, letterSpacing: 1)
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
                  _buildDownloadButton(theme, gemini),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildPerformanceHero(ThemeData theme, GeminiThemeExtension? gemini, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: gemini?.buildGlowContainer(
        borderRadius: 35,
        borderThickness: 2.5,
        backgroundColor: isDark ? const Color(0xF21A1C22) : const Color(0xF2FFFFFF),
        padding: const EdgeInsets.all(32),
        useAIBorder: true,
        child: Column(
          children: [
            Text('TERM AGGREGATE', 
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 3)
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${_average.toInt()}', 
                  style: TextStyle(
                    fontSize: 64, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: -3,
                    color: isDark ? Colors.white : Colors.black87,
                    shadows: [Shadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 20)]
                  )
                ),
                Text('%', 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: theme.primaryColor)
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withOpacity(0.1), 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00E676).withOpacity(0.2))
              ),
              child: const Text('STATUS: EXCEEDING EXPECTATIONS', 
                style: TextStyle(fontSize: 9, color: Color(0xFF00E676), fontWeight: FontWeight.w900, letterSpacing: 1.5)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton(ThemeData theme, GeminiThemeExtension? gemini) {
    if (_marksData.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Container(
        width: double.infinity,
        height: 65,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: const Color(0xFFE65100).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 5))],
        ),
        child: ElevatedButton(
          onPressed: _downloadReport, 
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE65100), Color(0xFFD84315)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Container(
              alignment: Alignment.center,
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
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(width: 4, height: 14, decoration: BoxDecoration(color: const Color(0xFFE65100), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2.5)),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF00E676);
    if (score >= 60) return const Color(0xFF2979FF);
    if (score >= 40) return const Color(0xFFFFAB40);
    return const Color(0xFFFF3D00);
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_rounded, size: 80, color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 24),
          const Text('NO ANALYTICS DATA FOUND', 
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 3, fontSize: 12)
          ),
        ],
      ),
    );
  }
}
