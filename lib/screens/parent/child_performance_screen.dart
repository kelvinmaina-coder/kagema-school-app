import 'package:flutter/material.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../services/pdf_generator_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';

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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('${widget.student.name}\'s Index', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.orange.shade900, Colors.deepOrange.shade600], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.auto_graph_rounded, size: 140, color: Colors.white.withOpacity(0.1)))]),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
            : Column(
                children: [
                  _buildIndexHero(theme, gemini),
                  const SizedBox(height: 32),
                  Expanded(
                    child: _marksData.isEmpty 
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _marksData.length,
                          itemBuilder: (context, index) {
                            final m = _marksData[index];
                            final content = ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.query_stats_rounded, color: Colors.orange, size: 22)),
                              title: Text(m['subject'] ?? 'Subject', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                              subtitle: Text(m['exam_type'] ?? 'Cycle Assessment', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                              trailing: Text('${m['score']}%', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: theme.primaryColor)),
                            );
                            return Padding(padding: const EdgeInsets.only(bottom: 12), child: gemini?.buildGlowContainer(borderRadius: 24, borderThickness: 1, backgroundColor: theme.cardColor.withOpacity(0.85), padding: EdgeInsets.zero, child: content) ?? Card(child: content));
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

  Widget _buildIndexHero(ThemeData theme, GeminiThemeExtension? gemini) {
    final content = Column(
      children: [
        const Text('OVERALL ACADEMIC INDEX', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
        const SizedBox(height: 12),
        Text('${_average.toInt()}%', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1)),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Text('NEURAL STATUS: EXCEEDING', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.w900, letterSpacing: 1))),
      ],
    );
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: gemini?.buildGlowContainer(borderRadius: 30, borderThickness: 2, backgroundColor: theme.cardColor.withOpacity(0.9), padding: const EdgeInsets.all(32), useAIBorder: true, child: content) ?? Container(width: double.infinity, padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(28)), child: content));
  }

  Widget _buildDownloadButton(ThemeData theme, GeminiThemeExtension? gemini) {
    if (_marksData.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: SizedBox(
        width: double.infinity, height: 60,
        child: ElevatedButton.icon(
          onPressed: _downloadReport, 
          icon: const Icon(Icons.picture_as_pdf_rounded),
          label: const Text('DOWNLOAD OFFICIAL REPORT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade900, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 8, shadowColor: Colors.orange.withOpacity(0.4)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() => const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.layers_clear_rounded, size: 80, color: Colors.grey), SizedBox(height: 16), Text('ACADEMIC NODE INITIALIZING', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5))]));
}
