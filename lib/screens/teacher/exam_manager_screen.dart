import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class ExamManagerScreen extends StatefulWidget {
  const ExamManagerScreen({super.key});

  @override
  State<ExamManagerScreen> createState() => _ExamManagerScreenState();
}

class _ExamManagerScreenState extends State<ExamManagerScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _exams = [];

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() => _isLoading = true);
    try {
      final results = await SupabaseService.instance.getEvents();
      if (mounted) {
        setState(() {
          _exams = results.where((e) => e['event_type'] == 'Exam').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Load Exams Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exams & Assessments', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.white,
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Column(
          children: [
            _buildGradingOverview(theme),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _exams.length,
                    itemBuilder: (context, index) {
                      final exam = _exams[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orangeAccent.withOpacity(0.1),
                            child: const Icon(Icons.quiz_rounded, color: Colors.orangeAccent),
                          ),
                          title: Text(exam['title'] ?? 'General Exam', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Date: ${exam['start_date'] ?? 'N/A'}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {},
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('New Exam'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildGradingOverview(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.orangeAccent.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Exams', '${_exams.length}', Colors.blue),
          _statItem('Status', 'Cloud Sync Active', Colors.green),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
