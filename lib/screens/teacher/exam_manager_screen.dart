import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';

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
    if (!mounted) return;
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

  void _showAddExamDialog() {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final titleCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        ),
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
                const Text('ADD NEW EXAM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)),
                const SizedBox(height: 8),
                const Text('Exam Registration', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 32),
                _buildInputField('Exam Name (e.g. End of Term)', Icons.title_rounded, titleCtrl, theme),
                const SizedBox(height: 24),
                StatefulBuilder(
                  builder: (context, setModalState) => InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context, 
                        initialDate: selectedDate, 
                        firstDate: DateTime.now(), 
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setModalState(() => selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: Colors.orange),
                          const SizedBox(width: 12),
                          Text(DateFormat('EEEE, MMM d, yyyy').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          const Icon(Icons.edit_calendar_rounded, size: 18, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.isNotEmpty) {
                        final data = {
                          'title': titleCtrl.text.trim(),
                          'start_date': DateFormat('yyyy-MM-dd').format(selectedDate),
                          'event_type': 'Exam',
                        };
                        await SupabaseService.instance.upsertEvent(data);
                        if (mounted) {
                          Navigator.pop(context);
                          _loadExams();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    child: const Text('SAVE EXAM', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ) ?? const SizedBox(),
      ),
    );
  }

  Widget _buildInputField(String label, IconData icon, TextEditingController ctrl, ThemeData theme) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.orange, size: 20),
        filled: true,
        fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Exam Schedule', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5, color: Colors.white)
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
                child: Icon(Icons.quiz_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
            : Column(
                children: [
                  _buildGradingOverview(theme, gemini),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _exams.isEmpty 
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: _exams.length,
                          itemBuilder: (context, index) {
                            final exam = _exams[index];
                            final content = ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.quiz_rounded, color: Colors.orange, size: 24),
                              ),
                              title: Text(exam['title'] ?? 'Exam', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('Scheduled: ${exam['start_date'] ?? 'N/A'}', 
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                            );

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: gemini?.buildGlowContainer(
                                borderRadius: 28,
                                borderThickness: 1,
                                backgroundColor: theme.cardColor.withOpacity(0.85),
                                padding: EdgeInsets.zero,
                                child: content,
                              ) ?? Card(child: content),
                            );
                          },
                        ),
                  ),
                ],
              ),
        ),
      ),
      floatingActionButton: gemini?.buildGlowContainer(
        borderRadius: 30,
        borderThickness: 2,
        backgroundColor: Colors.orange.shade800,
        padding: EdgeInsets.zero,
        child: FloatingActionButton.extended(
          onPressed: _showAddExamDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_task_rounded),
          label: const Text('Schedule New Exam', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _buildGradingOverview(ThemeData theme, GeminiThemeExtension? gemini) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statItem('Exams Scheduled', '${_exams.length}', Colors.blue),
        const VerticalDivider(color: Colors.white10),
        _statItem('Sync Status', 'System Connected', Colors.green),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: gemini?.buildGlowContainer(
        borderRadius: 24,
        borderThickness: 1.5,
        backgroundColor: theme.cardColor.withOpacity(0.9),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: content,
      ) ?? Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: content,
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(label.toUpperCase(), style: TextStyle(fontSize: 8, color: Colors.blueGrey.shade400, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('NO EXAMS FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
