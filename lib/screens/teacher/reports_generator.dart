import 'package:flutter/material.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
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
      debugPrint("Reports Data Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateReport(Student student) async {
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Fetch specific marks from Supabase for this report
      final marks = await SupabaseService.instance.getMarksForStudent(
        student.studentId, 
        _selectedTerm, 
        _selectedYear
      );

      if (mounted) {
        Navigator.pop(context);
        _showReportPreview(student, marks);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync Error: $e')));
      }
    }
  }

  void _showReportPreview(Student student, List<Map<String, dynamic>> marks) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Report Card: ${student.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: marks.isEmpty 
                ? const Center(child: Text('No marks recorded for this term.'))
                : ListView.builder(
                    itemCount: marks.length,
                    itemBuilder: (context, i) {
                      final m = marks[i];
                      return ListTile(
                        title: Text(m['subject'] ?? 'Subject'),
                        trailing: Text('${m['score']}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {}, 
              icon: const Icon(Icons.print), 
              label: const Text('GENERATE PDF REPORT')
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Report Generator'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildConfigHeader(theme),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final s = _students[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text(s.name[0])),
                        title: Text(s.name),
                        subtitle: Text('ADM: ${s.admissionNumber}'),
                        trailing: const Icon(Icons.description, color: Colors.redAccent),
                        onTap: () => _generateReport(s),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildConfigHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.redAccent.withOpacity(0.1),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedTerm,
              items: ['Term 1', 'Term 2', 'Term 3'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _selectedTerm = v!),
              decoration: const InputDecoration(labelText: 'Select Term', isDense: true),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _selectedYear,
              items: [2023, 2024, 2025].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
              onChanged: (v) => setState(() => _selectedYear = v!),
              decoration: const InputDecoration(labelText: 'Year', isDense: true),
            ),
          ),
        ],
      ),
    );
  }
}
