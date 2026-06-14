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
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _buildPreviewSheet(Student student, List<Map<String, dynamic>> marks) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: gemini?.buildCreativeBackground(
          isDark: theme.brightness == Brightness.dark,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                const Text('Report Preview', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text(student.name.toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 32),
                Expanded(
                  child: marks.isEmpty 
                    ? const Center(child: Text('No student records found for this term.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)))
                    : ListView.builder(
                        itemCount: marks.length,
                        itemBuilder: (context, i) {
                          final m = marks[i];
                          final content = ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            title: Text(m['subject'] ?? 'Subject', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                            trailing: Text('${m['score']}%', style: TextStyle(fontWeight: FontWeight.w900, color: theme.primaryColor, fontSize: 16)),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: gemini?.buildGlowContainer(
                              borderRadius: 20,
                              borderThickness: 1,
                              backgroundColor: theme.cardColor.withOpacity(0.7),
                              padding: EdgeInsets.zero,
                              child: content,
                            ) ?? Card(child: content),
                          );
                        },
                      ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: marks.isEmpty ? null : () => _generatePdfReport(student, marks), 
                    icon: const Icon(Icons.picture_as_pdf_rounded), 
                    label: const Text('GENERATE OFFICIAL REPORT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900, 
                      foregroundColor: Colors.white, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ) ?? const SizedBox(),
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
        title: const Text('Reports Center', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade900, Colors.red.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.picture_as_pdf_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.red))
            : _students.isEmpty
                ? _buildEmptyState()
                : Column(
                    children: [
                      _buildHeader(theme, gemini),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final s = _students[index];
                            final content = ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.red.withOpacity(0.1),
                                child: Text(s.name[0], style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 18)),
                              ),
                              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                              subtitle: Text('ADM: ${s.admissionNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              trailing: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), shape: BoxShape.circle),
                                child: const Icon(Icons.analytics_rounded, color: Colors.red, size: 20),
                              ),
                              onTap: () => _showReportPreview(s),
                            );

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: gemini?.buildGlowContainer(
                                borderRadius: 24,
                                borderThickness: 1,
                                backgroundColor: theme.cardColor.withOpacity(0.85),
                                padding: EdgeInsets.zero,
                                child: content,
                              ) ?? Card(child: content),
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

  Widget _buildHeader(ThemeData theme, GeminiThemeExtension? gemini) {
    final content = Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedTerm,
            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey),
            items: ['Term 1', 'Term 2', 'Term 3'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _selectedTerm = v!),
            decoration: const InputDecoration(labelText: 'Academic Term', border: InputBorder.none, labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ),
        const VerticalDivider(width: 32),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: _selectedYear,
            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey),
            items: [2023, 2024, 2025].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
            onChanged: (v) => setState(() => _selectedYear = v!),
            decoration: const InputDecoration(labelText: 'Academic Year', border: InputBorder.none, labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: gemini?.buildGlowContainer(
        borderRadius: 20,
        borderThickness: 1.5,
        backgroundColor: theme.cardColor.withOpacity(0.9),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: content,
      ) ?? Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
        child: content,
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('NO STUDENTS REGISTERED', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
