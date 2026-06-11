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
      setState(() => isLoading = false);
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marks Synced to Cloud!'), backgroundColor: Colors.green));
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
        title: Text('Grade Entry: ${widget.subject}', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.orange.shade800, Colors.orange.shade400]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10),
                _buildHeaderPanel(theme),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final s = students[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: Colors.orange.withOpacity(0.1), child: Text(s.name[0])),
                          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('ADM: ${s.admissionNumber}'),
                          trailing: SizedBox(
                            width: 70,
                            child: TextField(
                              controller: markControllers[s.studentId],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange),
                              decoration: InputDecoration(
                                hintText: '00',
                                filled: true,
                                fillColor: Colors.orange.withOpacity(0.05),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _buildSaveButton(theme),
              ],
            ),
      ),
    );
  }

  Widget _buildHeaderPanel(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Expanded(child: Text(selectedExamType, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 11))),
          const VerticalDivider(),
          Text(selectedTerm, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: isSaving ? null : _saveMarks,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade800,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
          ),
          child: Text(isSaving ? 'UPLOADING DATA...' : 'AUTHORIZE CLOUD SYNC', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
      ),
    );
  }
}
