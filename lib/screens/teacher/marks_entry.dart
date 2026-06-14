import 'package:flutter/material.dart';
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
        // Fetch existing marks
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
            content: const Text('Marks Uploaded Successfully', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
          )
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Marks Entry: ${widget.subject}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
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
              colors: [Colors.orange.shade900, Colors.deepOrange.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.auto_graph_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : students.isEmpty 
            ? _buildEmptyState()
            : Column(
                children: [
                  SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
                  _buildHeaderPanel(theme, gemini),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final s = students[index];
                        final content = ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.orange.withOpacity(0.1), 
                            child: Text(s.name[0], style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w900))
                          ),
                          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                          subtitle: Text('ADM: ${s.admissionNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          trailing: SizedBox(
                            width: 80,
                            height: 50,
                            child: gemini?.buildGlowContainer(
                              borderRadius: 12,
                              borderThickness: 1,
                              backgroundColor: Colors.orange.withOpacity(0.05),
                              padding: EdgeInsets.zero,
                              child: TextField(
                                controller: markControllers[s.studentId],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.orange),
                                decoration: const InputDecoration(
                                  hintText: '00',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
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
                  _buildSaveButton(theme, gemini),
                ],
              ),
      ),
    );
  }

  Widget _buildHeaderPanel(ThemeData theme, GeminiThemeExtension? gemini) {
    final content = Row(
      children: [
        Icon(Icons.layers_rounded, color: Colors.blueGrey.shade400, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(selectedExamType, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey, fontSize: 12, letterSpacing: 1))),
        const VerticalDivider(width: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Text(selectedTerm, style: TextStyle(fontWeight: FontWeight.w900, color: theme.primaryColor, fontSize: 11)),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: gemini?.buildGlowContainer(
        borderRadius: 20,
        borderThickness: 1.5,
        backgroundColor: theme.cardColor.withOpacity(0.9),
        padding: const EdgeInsets.all(16),
        child: content,
      ) ?? Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
        child: content,
      ),
    );
  }

  Widget _buildSaveButton(ThemeData theme, GeminiThemeExtension? gemini) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: isSaving ? null : _saveMarks,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade900,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            shadowColor: Colors.orange.withOpacity(0.5),
          ),
          child: Text(
            isSaving ? 'UPLOADING MARKS...' : 'CONFIRM UPLOAD', 
            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)
          ),
        ),
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
          Text('NO STUDENTS ASSIGNED', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
