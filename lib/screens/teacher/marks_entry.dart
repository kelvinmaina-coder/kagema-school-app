import 'package:flutter/material.dart';
import 'dart:ui';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

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
            backgroundColor: const Color(0xFF00E676),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          )
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DATA UPLOAD FAILED'), backgroundColor: Color(0xFFFF3D00)));
    } finally {
      if (mounted) setState(() => isSaving = false);
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
        title: Text('${widget.subject.toUpperCase()} ENTRY', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 4, color: Colors.white, shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)])
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
              Container(decoration: BoxDecoration(gradient: gemini?.primaryGradient)),
              Positioned(
                right: -30, top: -10,
                child: Icon(Icons.auto_graph_rounded, size: 180, color: Colors.white.withOpacity(0.12)),
              ),
            ],
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: isDark,
        child: isLoading 
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor, strokeWidth: 3))
          : students.isEmpty 
            ? _buildEmptyState(isDark)
            : Column(
                children: [
                  SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
                  _buildHeaderPanel(theme, gemini),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final s = students[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: gemini?.buildGlowContainer(
                            borderRadius: 28,
                            borderThickness: 1.5,
                            backgroundColor: isDark ? const Color(0xF21A1C22) : const Color(0xF2FFFFFF),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFFAB40).withOpacity(0.4), width: 2)),
                                  child: CircleAvatar(
                                    radius: 22,
                                    backgroundColor: const Color(0xFFFFAB40).withOpacity(0.1), 
                                    child: Text(s.name[0], style: const TextStyle(color: Color(0xFFFFAB40), fontWeight: FontWeight.w900, fontSize: 18))
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.name.toUpperCase(), 
                                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5, color: isDark ? Colors.white : Colors.black87)
                                      ),
                                      const SizedBox(height: 2),
                                      Text('ADM: ${s.admissionNumber}', 
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : Colors.black38, letterSpacing: 1)
                                      ),
                                    ],
                                  ),
                                ),
                                _buildElectricScoreInput(markControllers[s.studentId]!, isDark),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildSaveButton(theme, gemini),
                ],
              ),
      ),
    );
  }

  Widget _buildElectricScoreInput(TextEditingController controller, bool isDark) {
    return Container(
      width: 80,
      height: 50,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: const Color(0xFFFF3D00).withOpacity(0.05), blurRadius: 10, spreadRadius: -2)
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFFFF3D00)),
        decoration: InputDecoration(
          hintText: '--',
          hintStyle: TextStyle(color: isDark ? Colors.white10 : Colors.black12),
          filled: true,
          fillColor: isDark ? Colors.black26 : Colors.black.withOpacity(0.03),
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF3D00), width: 2.5)),
        ),
      ),
    );
  }

  Widget _buildHeaderPanel(ThemeData theme, GeminiThemeExtension? gemini) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: gemini?.buildGlowContainer(
        borderRadius: 24,
        borderThickness: 1.5,
        backgroundColor: isDark ? const Color(0xF21A1C22) : const Color(0xF2FFFFFF),
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(selectedExamType, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1, color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 4),
                Text(selectedTerm.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: theme.primaryColor, letterSpacing: 2.5)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$selectedYear', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2, color: isDark ? Colors.white60 : Colors.black45)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(ThemeData theme, GeminiThemeExtension? gemini) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Container(
        width: double.infinity,
        height: 65,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: const Color(0xFFFF3D00).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
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
                colors: [Color(0xFFFF3D00), Color(0xFFD50000)],
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

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_rounded, size: 80, color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 24),
          const Text('NO PUPIL RECORDS FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 3, fontSize: 13)),
        ],
      ),
    );
  }
}
