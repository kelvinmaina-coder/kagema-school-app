import 'package:flutter/material.dart';
import 'dart:ui';
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
    final isDark = theme.brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(color: Colors.white.withOpacity(isDark ? 0.05 : 0.2)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          child: gemini?.buildCreativeBackground(
            isDark: isDark,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 32),
                  const Text('ACADEMIC PREVIEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 3)),
                  const SizedBox(height: 12),
                  Text(student.name.toUpperCase(), 
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: 0.5)
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: marks.isEmpty 
                      ? Center(child: Text('NO RECORDS FOUND FOR THIS TERM', style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontWeight: FontWeight.w900, letterSpacing: 1)))
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: marks.length,
                          itemBuilder: (context, i) {
                            final m = marks[i];
                            final content = ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              title: Text(m['subject'] ?? 'Subject', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                              trailing: Text('${m['score']}%', 
                                style: TextStyle(fontWeight: FontWeight.w900, color: theme.primaryColor, fontSize: 18, shadows: [Shadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 8)])
                              ),
                            );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: gemini?.buildGlowContainer(
                                borderRadius: 24,
                                borderThickness: 1,
                                backgroundColor: isDark ? const Color(0x991A1C22) : const Color(0x99FFFFFF),
                                padding: EdgeInsets.zero,
                                child: content,
                              ) ?? Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0x991A1C22) : const Color(0x99FFFFFF),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: content,
                              ),
                            );
                          },
                        ),
                  ),
                  const SizedBox(height: 32),
                  _buildGenerateButton(theme, gemini, student, marks),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateButton(ThemeData theme, GeminiThemeExtension? gemini, Student student, List<Map<String, dynamic>> marks) {
    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gemini?.primaryGradient ?? LinearGradient(colors: [Colors.red.shade900, Colors.red.shade600]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: marks.isEmpty ? null : () => _generatePdfReport(student, marks),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('GENERATE OFFICIAL REPORT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
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
        title: const Text('REPORTS CENTER', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4, fontSize: 16)),
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
              Container(decoration: BoxDecoration(gradient: gemini?.primaryGradient)),
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.picture_as_pdf_rounded, size: 160, color: Colors.white.withOpacity(0.12)),
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
            : _students.isEmpty
                ? _buildEmptyState(isDark)
                : Column(
                    children: [
                      _buildHeader(theme, gemini),
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final s = _students[index];
                            final content = ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              leading: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: theme.primaryColor.withOpacity(0.3), width: 2)),
                                child: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                                  child: Text(s.name[0], style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w900, fontSize: 20)),
                                ),
                              ),
                              title: Text(s.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                              subtitle: Text('ADM: ${s.admissionNumber}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : Colors.black.withOpacity(0.1), letterSpacing: 1)),
                              trailing: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                                child: Icon(Icons.analytics_rounded, color: theme.primaryColor, size: 22),
                              ),
                              onTap: () => _showReportPreview(s),
                            );

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: gemini?.buildGlowContainer(
                                borderRadius: 28,
                                borderThickness: 1.2,
                                backgroundColor: isDark ? const Color(0xF21A1C22) : const Color(0xF2FFFFFF),
                                padding: EdgeInsets.zero,
                                child: content,
                              ) ?? Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xF21A1C22) : const Color(0xF2FFFFFF),
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: content,
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

  Widget _buildHeader(ThemeData theme, GeminiThemeExtension? gemini) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: gemini?.buildGlowContainer(
        borderRadius: 24,
        borderThickness: 1.5,
        backgroundColor: isDark ? const Color(0xF21A1C22) : const Color(0xF2FFFFFF),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedTerm,
                dropdownColor: isDark ? const Color(0xFF1A1C22) : Colors.white,
                style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                items: ['Term 1', 'Term 2', 'Term 3'].map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
                onChanged: (v) => setState(() => _selectedTerm = v!),
                decoration: InputDecoration(
                  labelText: 'ACADEMIC TERM', 
                  border: InputBorder.none, 
                  labelStyle: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: theme.primaryColor, letterSpacing: 1)
                ),
              ),
            ),
            Container(width: 1, height: 30, color: isDark ? Colors.white10 : Colors.black.withOpacity(0.1), margin: const EdgeInsets.symmetric(horizontal: 16)),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedYear,
                dropdownColor: isDark ? const Color(0xFF1A1C22) : Colors.white,
                style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                items: [2023, 2024, 2025].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                onChanged: (v) => setState(() => _selectedYear = v!),
                decoration: InputDecoration(
                  labelText: 'YEAR', 
                  border: InputBorder.none, 
                  labelStyle: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: theme.primaryColor, letterSpacing: 1)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_rounded, size: 80, color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 24),
          const Text('NO STUDENTS REGISTERED', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2, fontSize: 12)),
        ],
      ),
    );
  }
}
