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
    if (!mounted) return;
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
    final gemini = theme.extension<GeminiThemeExtension>();
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
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: gemini?.buildCreativeBackground(
          isDark: theme.brightness == Brightness.dark,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),
                  Text(isEditing ? 'MODIFY ASSIGNMENT' : 'POST NEURAL TASK', 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)
                  ),
                  const SizedBox(height: 8),
                  Text(isEditing ? 'Adjust Parameters' : 'Academic Broadcast', 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)
                  ),
                  const SizedBox(height: 32),
                  _buildNeuralField('Assignment Title', Icons.title_rounded, titleController, theme),
                  const SizedBox(height: 16),
                  _buildNeuralField('Intelligence Instructions', Icons.notes_rounded, descController, theme, maxLines: 3),
                  const SizedBox(height: 24),
                  StatefulBuilder(
                    builder: (context, setModalState) => InkWell(
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
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: Colors.purple),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('DUE TIMESTAMP', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey)),
                                Text(DateFormat('EEEE, MMM d, yyyy').format(selectedDueDate), 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                      ),
                      child: Text(isEditing ? 'COMMIT UPDATES' : 'AUTHORIZE BROADCAST', 
                        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 12)
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ) ?? const SizedBox(),
      ),
    );
  }

  Widget _buildNeuralField(String label, IconData icon, TextEditingController ctrl, ThemeData theme, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.purple, size: 20),
        filled: true,
        fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> h) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Retract Task?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to remove "${h['title']}"? It will disappear from all pupil portals.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ABORT')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('PURGE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
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
        title: Text('Neural Task: ${widget.grade}', 
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)
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
              colors: [Colors.purple.shade900, Colors.purple.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.assignment_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
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
            ? const Center(child: CircularProgressIndicator(color: Colors.purple))
            : _assignments.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    itemCount: _assignments.length,
                    itemBuilder: (context, index) {
                      final h = _assignments[index];
                      final content = ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.assignment_rounded, color: Colors.purple, size: 24),
                        ),
                        title: Text(h['title'] ?? 'Neural Task', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Due: ${h['due_date']} \nSubject: ${h['subject']}', 
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.4)
                          ),
                        ),
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
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
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
      ),
      floatingActionButton: gemini?.buildGlowContainer(
        borderRadius: 30,
        borderThickness: 2,
        backgroundColor: Colors.purple.shade700,
        padding: EdgeInsets.zero,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddDialog(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_task_rounded),
          label: const Text('Broadcast Intelligence', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
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
          Text('NO NEURAL TASKS BROADCAST', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
