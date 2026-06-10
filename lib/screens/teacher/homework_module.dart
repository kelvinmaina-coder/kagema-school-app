import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class HomeworkModule extends StatefulWidget {
  final String grade;
  final String stream;
  final String subject;

  const HomeworkModule({
    super.key, 
    required this.grade, 
    required this.stream, 
    required this.subject
  });

  @override
  State<HomeworkModule> createState() => _HomeworkModuleState();
}

class _HomeworkModuleState extends State<HomeworkModule> {
  List<Map<String, dynamic>> _assignments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomework();
  }

  Future<void> _loadHomework() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getHomeworkByClass(widget.grade, widget.stream);
      if (mounted) {
        setState(() {
          _assignments = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Homework Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDueDate = DateTime.now().add(const Duration(days: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Post New Assignment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: titleController, 
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController, 
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Instructions', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty) {
                    await SupabaseService.instance.postHomework({
                      'title': titleController.text.trim(),
                      'description': descController.text.trim(),
                      'subject': widget.subject,
                      'grade': widget.grade,
                      'stream': widget.stream,
                      'due_date': DateFormat('yyyy-MM-dd').format(selectedDueDate),
                      'posted_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      'teacher_id': SupabaseService.instance.client.auth.currentUser?.id,
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      _loadHomework();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                child: const Text('POST TO CLOUD'),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Homework: ${widget.grade} ${widget.stream}'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _assignments.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _assignments.length,
                  itemBuilder: (context, index) {
                    final h = _assignments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.assignment, color: Colors.white, size: 20)),
                        title: Text(h['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Due: ${h['due_date']} • ${h['subject']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            await SupabaseService.instance.deleteHomework(h['homework_id']);
                            _loadHomework();
                          },
                        ),
                      ),
                    );
                  },
                ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Assignment', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No homework assigned yet.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
