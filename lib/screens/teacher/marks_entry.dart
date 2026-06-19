import 'package:flutter/material.dart';
import 'dart:ui';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';

class MarksEntryScreen extends StatefulWidget {
  final String grade;
  final String stream;
  final String subject;

  const MarksEntryScreen({
    super.key,
    required this.grade,
    required this.stream,
    required this.subject,
  });

  @override
  State<MarksEntryScreen> createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends State<MarksEntryScreen> {
  List<Student> students = [];
  Map<String, TextEditingController> markControllers = {};
  String selectedExamType = 'MID TERM EXAM';
  String selectedTerm = 'Term 1';
  int selectedYear = DateTime.now().year;
  bool isLoading = true;
  bool isSaving = false;

  final String _roleId = 'teacher';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final studentMaps = await SupabaseService.instance.getStudentsByClass(widget.grade, widget.stream);
      students = studentMaps.map((m) => Student.fromMap(m)).toList();
      
      markControllers.clear();
      for (var s in students) {
        markControllers[s.studentId] = TextEditingController();
        final existing = await SupabaseService.instance.getMarksFiltered(
          studentId: s.studentId,
          term: selectedTerm,
          year: selectedYear,
        );
        final subjectMark = existing.where((m) => m['subject'] == widget.subject && m['exam_type'] == selectedExamType);
        if (subjectMark.isNotEmpty) {
          markControllers[s.studentId]!.text = (subjectMark.first['score'] as num).toStringAsFixed(0);
        }
      }
      if (mounted) setState(() => isLoading = false);
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _saveMarks() async {
    setState(() => isSaving = true);
    try {
      List<Map<String, dynamic>> marksToUpload = [];
      for (var student in students) {
        final scoreText = markControllers[student.studentId]!.text.trim();
        if (scoreText.isNotEmpty) {
          double score = double.tryParse(scoreText) ?? 0.0;
          marksToUpload.add({
            'mark_id': '${student.studentId}_${widget.subject}_${selectedExamType.replaceAll(' ', '_')}_$selectedTerm',
            'student_id': student.studentId,
            'student_name': student.name,
            'grade': widget.grade,
            'stream': widget.stream,
            'subject': widget.subject,
            'exam_type': selectedExamType,
            'score': score,
            'term': selectedTerm,
            'year': selectedYear,
          });
        }
      }
      if (marksToUpload.isNotEmpty) await SupabaseService.instance.saveMarks(marksToUpload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ACADEMIC DATA SYNCED', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 11)),
            backgroundColor: KagemaColors.teacherGreen,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          )
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DATA UPLOAD FAILED'), backgroundColor: KagemaColors.parentRed));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final isDark = context.isDark;
    final roleColor = RoleColors.of(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: Text('${widget.subject.toUpperCase()} ENTRY', 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 4, color: Colors.white)
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
                child: Icon(Icons.auto_graph_rounded, size: 180, color: Colors.white.withValues(alpha: 0.12)),
              ),
            ],
          ),
        ),
      ),
      body: theme?.buildCreativeBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: RoleColors.complement(_roleId),
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: isLoading 
            ? Center(child: CircularProgressIndicator(color: roleColor, strokeWidth: 3))
            : students.isEmpty 
              ? _buildEmptyState(dt)
              : Column(
                  children: [
                    SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
                    _buildHeaderPanel(dt, theme),
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final s = students[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: theme?.buildGlowContainer(
                              accentColor: KagemaColors.accountantAmber,
                              borderRadius: 28,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: KagemaColors.accountantAmber.withValues(alpha: 0.4), width: 2)),
                                    child: CircleAvatar(
                                      radius: 24,
                                      backgroundColor: dt.roleSoftBg(KagemaColors.accountantAmber), 
                                      child: Text(s.name[0].toUpperCase(), style: const TextStyle(color: KagemaColors.accountantAmber, fontWeight: FontWeight.w900, fontSize: 18))
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s.name.toUpperCase(), 
                                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5, color: dt.textPrimary)
                                        ),
                                        const SizedBox(height: 2),
                                        Text('ADM: ${s.admissionNumber}', 
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 1)
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildElectricScoreInput(markControllers[s.studentId]!, dt),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    _buildSaveButton(dt),
                  ],
                ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildElectricScoreInput(TextEditingController controller, DT dt) {
    return Container(
      width: 80,
      height: 50,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: KagemaColors.parentRed.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: -2)
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: KagemaColors.parentRed),
        decoration: InputDecoration(
          hintText: '--',
          hintStyle: TextStyle(color: dt.hint),
          filled: true,
          fillColor: dt.inputBg,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: dt.cardBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: KagemaColors.parentRed, width: 2.5)),
        ),
      ),
    );
  }

  Widget _buildHeaderPanel(DT dt, GeminiThemeExtension? theme) {
    final roleColor = RoleColors.of(_roleId);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: theme?.buildGlowContainer(
        accentColor: roleColor,
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(selectedExamType, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1, color: dt.textPrimary)),
                const SizedBox(height: 4),
                Text(selectedTerm.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: roleColor, letterSpacing: 2.5)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: dt.surfaceBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$selectedYear', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2, color: dt.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(DT dt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Container(
        width: double.infinity,
        height: 65,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: KagemaColors.parentRed.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: ElevatedButton(
          onPressed: isSaving ? null : _saveMarks,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [KagemaColors.parentRed, Color(0xFFD50000)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              alignment: Alignment.center,
              child: isSaving 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                : const Text('SYNCHRONIZE ALL SCORES', 
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 12, color: Colors.white)
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_rounded, size: 80, color: dt.iconInactive),
          const SizedBox(height: 24),
          Text('NO PUPIL RECORDS FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 3, fontSize: 13)),
        ],
      ),
    );
  }
}
