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

  void _showAddDialog({Map<String, dynamic>? assignmentToEdit}) {
    final theme = Theme.of(context);
    final isEditing = assignmentToEdit != null;
    final titleController = TextEditingController(text: assignmentToEdit?['title']);
    final descController = TextEditingController(text: assignmentToEdit?['description']);
    DateTime selectedDueDate = isEditing 
        ? DateTime.parse(assignmentToEdit['due_date']) 
        : DateTime.now().add(const Duration(days: 1));

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEditing ? 'Adjust Assignment' : 'Post New Assignment', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.purple.shade700)),
              const SizedBox(height: 8),
              Text(isEditing ? 'Modify the details of this cloud task' : 'Send academic tasks to the pupil\'s cloud portal', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 32),
              TextField(
                controller: titleController, 
                decoration: InputDecoration(
                  labelText: 'Assignment Title', 
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController, 
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Instructions & Details', 
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                ),
              ),
              const SizedBox(height: 24),
              StatefulBuilder(
                builder: (context, setModalState) => ListTile(
                  title: const Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(DateFormat('EEEE, MMM d, yyyy').format(selectedDueDate)),
                  leading: const Icon(Icons.calendar_month, color: Colors.purple),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context, 
                      initialDate: selectedDueDate, 
                      firstDate: DateTime.now().subtract(const Duration(days: 30)), 
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setModalState(() => selectedDueDate = picked);
                    }
                  },
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty) {
                      final data = {
                        'title': titleController.text.trim(),
                        'description': descController.text.trim(),
                        'subject': widget.subject,
                        'grade': widget.grade,
                        'stream': widget.stream,
                        'due_date': DateFormat('yyyy-MM-dd').format(selectedDueDate),
                        'posted_date': assignmentToEdit?['posted_date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      };
                      
                      if (isEditing) {
                        data['homework_id'] = assignmentToEdit['homework_id'];
                      }

                      await SupabaseService.instance.postHomework(data);
                      if (mounted) {
                        Navigator.pop(context);
                        _loadHomework();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(isEditing ? 'UPDATE BROADCAST' : 'AUTHORIZE BROADCAST', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> h) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment?'),
        content: Text('Are you sure you want to remove "${h['title']}"? Pupils will no longer see this in their portal.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await SupabaseService.instance.deleteHomework(h['homework_id']);
      _loadHomework();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Homework: ${widget.grade}', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.purple.shade800, Colors.purple.shade400]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple.withOpacity(0.1),
                            child: const Icon(Icons.assignment_rounded, color: Colors.purple, size: 20),
                          ),
                          title: Text(h['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Due: ${h['due_date']} • ${h['subject']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                                onPressed: () => _showAddDialog(assignmentToEdit: h),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                onPressed: () => _confirmDelete(h),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Add Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
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
