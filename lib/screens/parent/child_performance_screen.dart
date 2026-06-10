import 'package:flutter/material.dart';
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
  List<Mark> _marks = [];
  bool _isLoading = true;
  String _selectedTerm = 'Term 1';
  int _selectedYear = 2024;

  @override
  void initState() {
    super.initState();
    _loadMarks();
  }

  Future<void> _loadMarks() async {
    setState(() => _isLoading = true);
    try {
      final list = await SupabaseService.instance.getMarksForStudent(
        widget.student.studentId, 
        _selectedTerm, 
        _selectedYear
      );
      if (mounted) {
        setState(() {
          _marks = list.map((m) => Mark.fromMap(m)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Load Marks Error: $e");
      if (mounted) setState(() => _isLoading = false);
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
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('Academic Performance', style: TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  onPressed: _marks.isEmpty ? null : () => PdfGeneratorService.generateReportCard(widget.student, _marks, _selectedTerm, _selectedYear),
                )
              ],
            ),
            _buildTermSelector(theme),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _marks.isEmpty
                      ? _buildEmptyState()
                      : _buildMarksList(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(15)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTerm,
                  isExpanded: true,
                  items: ['Term 1', 'Term 2', 'Term 3'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) {
                    setState(() => _selectedTerm = v!);
                    _loadMarks();
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _summaryBadge('Mean Score', '${_calculateMean()}%', Colors.orange),
        ],
      ),
    );
  }

  String _calculateMean() {
    if (_marks.isEmpty) return '0';
    double total = _marks.fold(0.0, (sum, m) => sum + m.score);
    return (total / _marks.length).toStringAsFixed(0);
  }

  Widget _summaryBadge(String l, String v, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(l, style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMarksList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _marks.length,
      itemBuilder: (context, index) {
        final m = _marks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Text(m.subject.isNotEmpty ? m.subject[0] : '?', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
            ),
            title: Text(m.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Level: ${m.achievementLevel}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${m.score.toInt()}%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                Text('Pts: ${m.points}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assessment_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No results recorded in cloud for this term.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
