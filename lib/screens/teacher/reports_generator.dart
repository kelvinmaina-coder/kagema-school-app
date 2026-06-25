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
  final String _roleId = 'teacher';

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
    final dt = context.dt;
    final roleColor = RoleColors.of(_roleId);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator(color: roleColor)),
    );

    try {
      final marksData = await SupabaseService.instance.getMarksForStudent(
        student.studentId, 
        _selectedTerm, 
        _selectedYear
      );

      if (mounted) {
        Navigator.pop(context);
        _buildPreviewSheet(student, marksData, dt, roleColor);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: KagemaColors.parentRed));
      }
    }
  }

  void _buildPreviewSheet(Student student, List<Map<String, dynamic>> marks, DT dt, Color roleColor) {
    final theme = context.kagemaTheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => theme?.buildGlowContainer(
        accentColor: roleColor,
        borderRadius: 40,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: dt.divider, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 32),
              Text('ACADEMIC PREVIEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 3)),
              const SizedBox(height: 12),
              Text(student.name.toUpperCase(), 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: dt.textPrimary, letterSpacing: 0.5)
              ),
              const SizedBox(height: 32),
              Expanded(
                child: marks.isEmpty 
                  ? Center(child: Text('NO RECORDS FOUND FOR THIS TERM', style: TextStyle(color: dt.textMuted, fontWeight: FontWeight.w900, letterSpacing: 1)))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: marks.length,
                      itemBuilder: (context, i) {
                        final m = marks[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12, left: 24, right: 24),
                          child: theme.buildGlowContainer(
                            accentColor: roleColor,
                            borderRadius: 24,
                            padding: EdgeInsets.zero,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              title: Text(m['subject'] ?? 'Subject', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: dt.textPrimary)),
                              trailing: Text('${m['score']}%', 
                                style: TextStyle(fontWeight: FontWeight.w900, color: roleColor, fontSize: 18)
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildGenerateButton(student, marks, roleColor),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildGenerateButton(Student student, List<Map<String, dynamic>> marks, Color roleColor) {
    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: roleColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: marks.isEmpty ? null : () => _generatePdfReport(student, marks),
        style: ElevatedButton.styleFrom(
          backgroundColor: roleColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text('GENERATE OFFICIAL REPORT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
          ],
        ),
      ),
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
        title: const Text('REPORTS CENTER', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3, fontSize: 16)),
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
                right: -20, top: -10,
                child: Icon(Icons.picture_as_pdf_rounded, size: 160, color: Colors.white.withValues(alpha: 0.12)),
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
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10),
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: roleColor))
              : _students.isEmpty
                  ? _buildEmptyState(dt)
                  : Column(
                      children: [
                        _buildHeader(dt, theme, roleColor),
                        Expanded(
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                            itemCount: _students.length,
                            itemBuilder: (context, index) {
                              final s = _students[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: theme.buildGlowContainer(
                                  accentColor: roleColor,
                                  borderRadius: 28,
                                  padding: EdgeInsets.zero,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    leading: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: roleColor.withValues(alpha: 0.3), width: 2)),
                                      child: CircleAvatar(
                                        radius: 25,
                                        backgroundColor: dt.roleSoftBg(roleColor),
                                        child: Text(s.name[0].toUpperCase(), style: TextStyle(color: roleColor, fontWeight: FontWeight.w900, fontSize: 20)),
                                      ),
                                    ),
                                    title: Text(s.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary, letterSpacing: 0.5)),
                                    subtitle: Text('ADM: ${s.admissionNumber}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 1)),
                                    trailing: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: dt.roleSoftBg(roleColor), shape: BoxShape.circle),
                                      child: Icon(Icons.analytics_rounded, color: roleColor, size: 22),
                                    ),
                                    onTap: () => _showReportPreview(s),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildHeader(DT dt, GeminiThemeExtension? theme, Color roleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: theme?.buildGlowContainer(
        accentColor: roleColor,
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedTerm,
                dropdownColor: dt.cardBg,
                style: TextStyle(fontWeight: FontWeight.w900, color: dt.textPrimary, fontSize: 13),
                items: ['Term 1', 'Term 2', 'Term 3'].map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
                onChanged: (v) => setState(() => _selectedTerm = v!),
                decoration: InputDecoration(
                  labelText: 'ACADEMIC TERM', 
                  border: InputBorder.none, 
                  labelStyle: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: roleColor, letterSpacing: 1)
                ),
              ),
            ),
            Container(width: 1, height: 30, color: dt.divider, margin: const EdgeInsets.symmetric(horizontal: 16)),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedYear,
                dropdownColor: dt.cardBg,
                style: TextStyle(fontWeight: FontWeight.w900, color: dt.textPrimary, fontSize: 13),
                items: [2023, 2024, 2025].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                onChanged: (v) => setState(() => _selectedYear = v!),
                decoration: InputDecoration(
                  labelText: 'YEAR', 
                  border: InputBorder.none, 
                  labelStyle: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: roleColor, letterSpacing: 1)
                ),
              ),
            ),
          ],
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_rounded, size: 80, color: dt.iconInactive),
          const SizedBox(height: 24),
          Text('NO STUDENTS REGISTERED', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2, fontSize: 12)),
        ],
      ),
    );
  }
}
