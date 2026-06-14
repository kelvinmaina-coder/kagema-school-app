import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class ExamManagementScreen extends StatefulWidget {
  const ExamManagementScreen({super.key});

  @override
  State<ExamManagementScreen> createState() => _ExamManagementScreenState();
}

class _ExamManagementScreenState extends State<ExamManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _exams = [];

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final exams = await SupabaseService.instance.getEvents();
      if (mounted) {
        setState(() {
          _exams = exams.where((e) => e['event_type'] == 'Exam').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddExamDialog({Map<String, dynamic>? examToEdit}) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final titleCtrl = TextEditingController(text: examToEdit?['title']);
    DateTime selectedDate = examToEdit != null ? DateTime.parse(examToEdit['start_date']) : DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(35))),
        child: gemini?.buildCreativeBackground(
          isDark: theme.brightness == Brightness.dark,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                const Text('ADD ACADEMIC EXAM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)),
                const SizedBox(height: 32),
                _buildInputField('Exam Title', Icons.title_rounded, titleCtrl, theme),
                const SizedBox(height: 24),
                StatefulBuilder(builder: (context, setModalState) => InkWell(
                  onTap: () async {
                    final p = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (p != null) setModalState(() => selectedDate = p);
                  },
                  child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.5), borderRadius: BorderRadius.circular(20)), child: Row(children: [const Icon(Icons.calendar_month_rounded, color: Colors.orange), const SizedBox(width: 12), Text(DateFormat('EEEE, MMM d, yyyy').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.bold))])),
                )),
                const SizedBox(height: 40),
                SizedBox(width: double.infinity, height: 60, child: ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.isNotEmpty) {
                      final data = {
                        'event_id': examToEdit?['event_id'] ?? const Uuid().v4(),
                        'title': titleCtrl.text.trim(),
                        'start_date': DateFormat('yyyy-MM-dd').format(selectedDate),
                        'event_type': 'Exam',
                      };
                      await SupabaseService.instance.upsertEvent(data);
                      if (mounted) { Navigator.pop(context); _loadExams(); }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text('SAVE TO EXAM SCHEDULE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                )),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, IconData icon, TextEditingController ctrl, ThemeData theme) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: theme.primaryColor, size: 20), filled: true, fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Exam Schedule', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [theme.primaryColor, Colors.orange.shade900], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)))),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
            : _exams.isEmpty ? _buildEmptyState() : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _exams.length,
                itemBuilder: (context, index) {
                  final e = _exams[index];
                  return Padding(padding: const EdgeInsets.only(bottom: 12), child: gemini?.buildGlowContainer(borderRadius: 24, borderThickness: 1, backgroundColor: theme.cardColor.withOpacity(0.85), padding: EdgeInsets.zero, child: ListTile(leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.quiz, color: Colors.white)), title: Text(e['title'] ?? 'Exam', style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('Scheduled: ${e['start_date']}'), onTap: () => _showAddExamDialog(examToEdit: e))));
                },
              ),
        ),
      ),
      floatingActionButton: gemini?.buildGlowContainer(borderRadius: 30, borderThickness: 2, backgroundColor: Colors.orange.shade800, padding: EdgeInsets.zero, child: FloatingActionButton.extended(onPressed: () => _showAddExamDialog(), icon: const Icon(Icons.add_task), label: const Text('Schedule New Exam', style: TextStyle(fontWeight: FontWeight.w900)))),
    );
  }

  Widget _buildEmptyState() => const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.event_busy, size: 80, color: Colors.grey), SizedBox(height: 16), Text('NO EXAMS RECORDED', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey))]));
}
