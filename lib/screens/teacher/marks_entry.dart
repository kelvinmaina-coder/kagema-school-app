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
        
        // FIXED: Use the correct method name from SupabaseService
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
      debugPrint("Error loading marks: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _calculateGrade(double score) {
    if (score >= 80) return 'EE';
    if (score >= 60) return 'ME';
    if (score >= 40) return 'AE';
    return 'BE';
  }

  int _calculatePoints(double score) {
    if (score >= 80) return 4;
    if (score >= 60) return 3;
    if (score >= 40) return 2;
    return 1;
  }

  String _getAchievementLevel(String grade) {
    if (grade == 'EE') return 'Exceeding Expectations';
    if (grade == 'ME') return 'Meeting Expectations';
    if (grade == 'AE') return 'Approaching Expectations';
    return 'Below Expectations';
  }

  Future<void> _saveMarks() async {
    setState(() => isSaving = true);
    try {
      List<Map<String, dynamic>> marksToUpload = [];
      
      for (var student in students) {
        final scoreText = markControllers[student.studentId]!.text.trim();
        if (scoreText.isNotEmpty) {
          double score = double.tryParse(scoreText) ?? 0.0;
          String grade = _calculateGrade(score);
          
          marksToUpload.add({
            'mark_id': '${student.studentId}_${widget.subject}_${selectedExamType.replaceAll(' ', '_')}_$selectedTerm',
            'student_id': student.studentId,
            'student_name': student.name,
            'grade': widget.grade,
            'stream': widget.stream,
            'subject': widget.subject,
            'exam_type': selectedExamType,
            'score': score,
            'achievement_level': _getAchievementLevel(grade),
            'points': _calculatePoints(score),
            'term': selectedTerm,
            'year': selectedYear,
          });
        }
      }
      
      if (marksToUpload.isNotEmpty) {
        await SupabaseService.instance.saveMarks(marksToUpload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marks successfully synced to cloud!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Marks: ${widget.subject}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildConfigPanel(theme),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final s = students[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text(s.name[0])),
                          title: Text(s.name),
                          subtitle: Text('ADM: ${s.admissionNumber}'),
                          trailing: SizedBox(
                            width: 60,
                            child: TextField(
                              controller: markControllers[s.studentId],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                hintText: '00',
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _saveMarks,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(isSaving ? 'SYNCING...' : 'SYNC MARKS', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                )
              ],
            ),
      ),
    );
  }

  Widget _buildConfigPanel(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.orange.withOpacity(0.1),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedExamType,
              items: ['OPENER EXAM', 'MID TERM EXAM', 'END TERM EXAM'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
              onChanged: (v) {
                setState(() => selectedExamType = v!);
                _loadData();
              },
              decoration: const InputDecoration(labelText: 'Exam Phase', isDense: true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedTerm,
              items: ['Term 1', 'Term 2', 'Term 3'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) {
                setState(() => selectedTerm = v!);
                _loadData();
              },
              decoration: const InputDecoration(labelText: 'Term', isDense: true),
            ),
          ),
        ],
      ),
    );
  }
}
