import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';

class TaskListScreen extends StatefulWidget {
  final String staffId;
  const TaskListScreen({super.key, required this.staffId});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getTasks(widget.staffId);
      setState(() {
        _tasks = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Task Intelligence', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, Colors.orange.shade900], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          tabs: const [Tab(text: 'ACTIVE'), Tab(text: 'ARCHIVED')],
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 48),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildTaskGrid(theme, gemini, false),
                  _buildTaskGrid(theme, gemini, true),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildTaskGrid(ThemeData theme, GeminiThemeExtension? gemini, bool showCompleted) {
    final filtered = _tasks.where((t) => (t['status'] == 'Completed') == showCompleted).toList();
    if (filtered.isEmpty) return _buildEmptyState(showCompleted);

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final t = filtered[index];
        final content = ListTile(
          leading: Icon(showCompleted ? Icons.check_circle : Icons.pending_actions, color: showCompleted ? Colors.green : Colors.orange),
          title: Text(t['title'] ?? 'Neural Duty', style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text('Due: ${t['due_date']}'),
          trailing: showCompleted ? null : IconButton(
            icon: const Icon(Icons.done_all_rounded, color: Colors.green),
            onPressed: () async {
              await SupabaseService.instance.updateTaskStatus(t['task_id'].toString(), 'Completed');
              _loadTasks();
            },
          ),
        );
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: gemini?.buildGlowContainer(borderRadius: 24, borderThickness: 1, backgroundColor: theme.cardColor.withOpacity(0.85), padding: EdgeInsets.zero, child: content) ?? Card(child: content));
      },
    );
  }

  Widget _buildEmptyState(bool archived) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(archived ? Icons.archive_outlined : Icons.task_alt, size: 80, color: Colors.grey.withOpacity(0.3)), const SizedBox(height: 16), Text(archived ? 'ARCHIVE EMPTY' : 'ALL TASKS SYNCED', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2))]));
}
