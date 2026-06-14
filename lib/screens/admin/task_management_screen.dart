import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen> {
  List<Map<String, dynamic>> _allTasks = [];
  List<Map<String, dynamic>> _staffList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SupabaseService.instance.client.from('tasks').select('*, staff(name)').order('due_date'),
        SupabaseService.instance.getAllStaff(),
      ]);
      setState(() {
        _allTasks = List<Map<String, dynamic>>.from(results[0]);
        _staffList = List<Map<String, dynamic>>.from(results[1]);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddTaskDialog() {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedStaffId;
    String priority = 'Medium';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(35))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('NEW TASK ASSIGNMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)),
              const SizedBox(height: 24),
              _buildField(titleCtrl, 'Task Title', Icons.assignment_rounded, theme),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStaffId,
                items: _staffList.map((s) => DropdownMenuItem(value: s['staff_id'].toString(), child: Text(s['name']))).toList(),
                onChanged: (v) => selectedStaffId = v,
                decoration: _inputDeco('Assign to Staff Member', Icons.person_search_rounded, theme),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: priority,
                items: ['Critical', 'High', 'Medium', 'Low'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => priority = v!,
                decoration: _inputDeco('Priority Level', Icons.speed_rounded, theme),
              ),
              const SizedBox(height: 16),
              _buildField(descCtrl, 'Task Instructions', Icons.notes_rounded, theme, maxLines: 2),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.isNotEmpty && selectedStaffId != null) {
                      final data = {
                        'task_id': const Uuid().v4(),
                        'title': titleCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'assigned_to': selectedStaffId,
                        'priority': priority,
                        'due_date': DateFormat('yyyy-MM-dd').format(selectedDate),
                        'status': 'Pending',
                      };
                      await SupabaseService.instance.client.from('tasks').insert(data);
                      if (mounted) { Navigator.pop(context); _loadData(); }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text('CONFIRM ASSIGNMENT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String l, IconData i, ThemeData t) => InputDecoration(labelText: l, prefixIcon: Icon(i, color: t.primaryColor), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)));

  Widget _buildField(TextEditingController c, String l, IconData i, ThemeData t, {int maxLines = 1}) => TextField(controller: c, maxLines: maxLines, decoration: _inputDeco(l, i, t));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Task Manager', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, Colors.indigo.shade900], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 20)],
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.assignment_ind_rounded, size: 140, color: Colors.white.withOpacity(0.1)))]),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20, left: 20, right: 20, bottom: 100),
              itemCount: _allTasks.length,
              itemBuilder: (context, index) {
                final task = _allTasks[index];
                final isDone = task['status'] == 'Completed';
                final color = isDone ? Colors.green : (task['priority'] == 'Critical' ? Colors.red : Colors.orange);
                
                final content = ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(isDone ? Icons.check_circle_rounded : Icons.pending_actions_rounded, color: color, size: 22)),
                  title: Text(task['title'] ?? 'Untitled Task', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  subtitle: Text('Assigned to: ${task['staff']?['name'] ?? "Unknown"}\nDue: ${task['due_date']}', style: const TextStyle(fontSize: 11, height: 1.4)),
                  trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text(task['priority'].toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 1))),
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: gemini?.buildGlowContainer(borderRadius: 24, borderThickness: 1, backgroundColor: theme.cardColor.withOpacity(0.85), padding: EdgeInsets.zero, child: content) ?? Card(child: content),
                );
              },
            ),
      ),
      floatingActionButton: gemini?.buildGlowContainer(
        borderRadius: 30, borderThickness: 2, backgroundColor: theme.primaryColor, padding: EdgeInsets.zero,
        child: FloatingActionButton.extended(onPressed: _showAddTaskDialog, backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white, icon: const Icon(Icons.add_task_rounded), label: const Text('Create New Task', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1))),
      ),
    );
  }
}
