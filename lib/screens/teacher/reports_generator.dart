import 'package:flutter/material.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../services/pdf_generator_service.dart';
import '../../app_theme.dart';

class ReportsGeneratorScreen extends StatefulWidget {
  final String grade;
  final String stream;

  const ReportsGeneratorScreen({super.key, required this.grade, required this.stream});

  @override
  State<ReportsGeneratorScreen> createState() => _ReportsGeneratorScreenState();
}

class _ReportsGeneratorScreenState extends State<ReportsGeneratorScreen> {
  List<Student> _students = [];
  String _selectedTerm = 'Term 1';
  int _selectedYear = DateTime.now().year;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getStudentsByClass(widget.grade, widget.stream);
      if (mounted) {
        setState(() {
          _students = data.map((m) => Student.fromMap(m)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generatePdfReport(Student student, List<Map<String, dynamic>> marksData) async {
    final List<Mark> marks = marksData.map((m) => Mark.fromMap(m)).toList();
    await PdfGeneratorService.generateReportCard(student, marks, _selectedTerm, _selectedYear);
  }

  Future<void> _showReportPreview(Student student) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final marksData = await SupabaseService.instance.getMarksForStudent(
        student.studentId, 
        _selectedTerm, 
        _selectedYear
      );

      if (mounted) {
        Navigator.pop(context);
        _buildPreviewSheet(student, marksData);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync Error: $e')));
      }
    }
  }

  void _buildPreviewSheet(Student student, List<Map<String, dynamic>> marks) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Report Preview: ${student.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(height: 32),
            Expanded(
              child: marks.isEmpty 
                ? const Center(child: Text('No marks recorded for this term.'))
                : ListView.builder(
                    itemCount: marks.length,
                    itemBuilder: (context, i) {
                      final m = marks[i];
                      return ListTile(
                        title: Text(m['subject'] ?? 'Subject', style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text('${m['score']}%', style: TextStyle(fontWeight: FontWeight.w900, color: theme.primaryColor)),
                      );
                    },
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: marks.isEmpty ? null : () => _generatePdfReport(student, marks), 
                icon: const Icon(Icons.picture_as_pdf), 
                label: const Text('GENERATE & PRINT PDF', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Cloud Report Center', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.red.shade800, Colors.red.shade400]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final s = _students[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Colors.red.withOpacity(0.1),
                              child: Text(s.name[0], style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('ADM: ${s.admissionNumber}'),
                            trailing: const Icon(Icons.analytics_outlined, color: Colors.redAccent),
                            onTap: () => _showReportPreview(s),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedTerm,
              items: ['Term 1', 'Term 2', 'Term 3'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _selectedTerm = v!),
              decoration: const InputDecoration(labelText: 'Academic Term', border: InputBorder.none),
            ),
          ),
          const VerticalDivider(),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _selectedYear,
              items: [2023, 2024, 2025].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
              onChanged: (v) => setState(() => _selectedYear = v!),
              decoration: const InputDecoration(labelText: 'Year', border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }
}
