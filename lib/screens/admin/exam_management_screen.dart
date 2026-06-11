import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

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
          _exams = exams.where((e) => e['event_type'] == 'Exam' || e['type'] == 'Main Exam').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Exam & Grade Center', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)]),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
          child: Column(
            children: [
              _buildGradingScaleHeader(theme),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _exams.isEmpty 
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _exams.length,
                        itemBuilder: (context, index) {
                          final exam = _exams[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                                child: Icon(Icons.quiz_rounded, color: theme.primaryColor),
                              ),
                              title: Text(exam['title'] ?? exam['name'] ?? 'Exam', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Date: ${exam['start_date'] ?? exam['date']} • Type: ${exam['event_type'] ?? exam['type']}'),
                                  const SizedBox(height: 8),
                                  _statusChip(exam['status'] ?? 'Active'),
                                ],
                              ),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExamDialog,
        label: const Text('New Exam', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddExamDialog() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Schedule Cloud Exam', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: theme.primaryColor)),
            const SizedBox(height: 24),
            const TextField(decoration: InputDecoration(labelText: 'Exam Title (e.g. Mid Term)', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Academic Year', border: OutlineInputBorder())),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white),
                child: const Text('AUTHORIZE SCHEDULE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGradingScaleHeader(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('CBC Cloud Grading System', style: TextStyle(fontWeight: FontWeight.bold)),
          Icon(Icons.verified_user_rounded, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color = Colors.grey;
    if (status == 'Active' || status == 'Completed') color = Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No exams scheduled.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}
