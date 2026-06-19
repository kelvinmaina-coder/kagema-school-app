import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

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
  final String _roleId = 'staff';

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
      if (mounted) {
        setState(() {
          _tasks = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final isDark = context.isDark;
    final roleColor = RoleColors.of(_roleId);
    final compColor = RoleColors.complement(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: const Text('TASK INTELLIGENCE', 
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3, fontSize: 16)
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
            gradient: RoleColors.gradient(_roleId, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 20),
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          tabs: const [Tab(text: 'ACTIVE'), Tab(text: 'ARCHIVED')],
        ),
      ),
      body: theme?.buildCreativeBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: Padding(
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + context.pt + 48),
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: roleColor))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTaskGrid(dt, theme, false, roleColor),
                    _buildTaskGrid(dt, theme, true, roleColor),
                  ],
                ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildTaskGrid(DT dt, GeminiThemeExtension? theme, bool showCompleted, Color roleColor) {
    final filtered = _tasks.where((t) => (t['status'] == 'Completed') == showCompleted).toList();
    if (filtered.isEmpty) return _buildEmptyState(dt, showCompleted);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final t = filtered[index];
        final priority = t['priority']?.toString() ?? 'Medium';
        final priorityColor = priority == 'High' ? dt.error : (priority == 'Low' ? dt.success : dt.warning);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: theme?.buildGlowContainer(
            accentColor: priorityColor,
            borderRadius: 24,
            padding: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: dt.roleSoftBg(priorityColor), shape: BoxShape.circle),
                child: Icon(showCompleted ? Icons.check_circle_rounded : Icons.pending_actions_rounded, color: priorityColor, size: 24),
              ),
              title: Text(t['title']?.toString().toUpperCase() ?? 'NEURAL DUTY', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textPrimary, fontSize: 14, letterSpacing: 0.5)),
              subtitle: Text('Due: ${t['due_date']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dt.textSecondary)),
              trailing: showCompleted ? null : IconButton(
                icon: Icon(Icons.done_all_rounded, color: dt.success),
                onPressed: () async {
                  await SupabaseService.instance.updateTaskStatus(t['task_id'].toString(), 'Completed');
                  _loadTasks();
                },
              ),
            ),
          ) ?? const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildEmptyState(DT dt, bool archived) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(archived ? Icons.archive_outlined : Icons.task_alt, size: 80, color: dt.iconInactive),
          const SizedBox(height: 16),
          Text(archived ? 'ARCHIVE EMPTY' : 'ALL TASKS SYNCED', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
        ],
      ),
    );
  }
}
