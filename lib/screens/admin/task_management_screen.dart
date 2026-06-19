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
  final String _roleId = 'admin';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SupabaseService.instance.client.from('tasks').select('*, staff(name)').order('due_date'),
        SupabaseService.instance.getAllStaff(),
      ]);
      if (mounted) {
        setState(() {
          _allTasks = List<Map<String, dynamic>>.from(results[0]);
          _staffList = List<Map<String, dynamic>>.from(results[1]);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddTaskDialog(DT dt, GeminiThemeExtension? theme, Color roleColor) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedStaffId;
    String priority = 'Medium';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: theme?.buildGlowContainer(
          accentColor: roleColor,
          borderRadius: 35,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: dt.divider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text('NEW TASK ASSIGNMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
                const SizedBox(height: 24),
                _buildField(dt, titleCtrl, 'Task Title', Icons.assignment_rounded, roleColor),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStaffId,
                  dropdownColor: dt.cardBg,
                  style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
                  items: _staffList.map((s) => DropdownMenuItem(value: s['staff_id'].toString(), child: Text(s['name']))).toList(),
                  onChanged: (v) => selectedStaffId = v,
                  decoration: _inputDeco(dt, 'Assign to Staff Member', Icons.person_search_rounded, roleColor),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: priority,
                  dropdownColor: dt.cardBg,
                  style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
                  items: ['Critical', 'High', 'Medium', 'Low'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => priority = v!,
                  decoration: _inputDeco(dt, 'Priority Level', Icons.speed_rounded, roleColor),
                ),
                const SizedBox(height: 16),
                _buildField(dt, descCtrl, 'Task Instructions', Icons.notes_rounded, roleColor, maxLines: 2),
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
                    style: ElevatedButton.styleFrom(backgroundColor: roleColor, foregroundColor: Colors.white),
                    child: const Text('CONFIRM ASSIGNMENT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ) ?? const SizedBox.shrink(),
      ),
    );
  }

  InputDecoration _inputDeco(DT dt, String l, IconData i, Color c) => InputDecoration(labelText: l, prefixIcon: Icon(i, color: c));

  Widget _buildField(DT dt, TextEditingController c, String l, IconData i, Color color, {int maxLines = 1}) => TextField(controller: c, maxLines: maxLines, style: TextStyle(color: dt.textPrimary, fontWeight: FontWeight.bold), decoration: _inputDeco(dt, l, i, color));

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
        title: const Text('TASK MANAGER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: RoleColors.gradient(_roleId, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.assignment_ind_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)))]),
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
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + context.pt + 20),
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: roleColor))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: _allTasks.length,
                  itemBuilder: (context, index) {
                    final task = _allTasks[index];
                    final isDone = task['status'] == 'Completed';
                    final color = isDone ? dt.success : (task['priority'] == 'Critical' ? dt.error : dt.warning);
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: theme.buildGlowContainer(
                        accentColor: color,
                        borderRadius: 24,
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: dt.roleSoftBg(color), shape: BoxShape.circle), child: Icon(isDone ? Icons.check_circle_rounded : Icons.pending_actions_rounded, color: color, size: 22)),
                          title: Text(task['title']?.toString().toUpperCase() ?? 'UNTITLED TASK', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary, letterSpacing: 0.5)),
                          subtitle: Text('Assigned to: ${task['staff']?['name'] ?? "Unknown"}\nDue: ${task['due_date']}', style: TextStyle(fontSize: 11, height: 1.4, color: dt.textSecondary, fontWeight: FontWeight.w600)),
                          trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: dt.roleSoftBg(color), borderRadius: BorderRadius.circular(10)), child: Text(task['priority'].toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 1))),
                        ),
                      ) ?? const SizedBox.shrink(),
                    );
                  },
                ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
      floatingActionButton: RolePlasma(
        color: roleColor,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddTaskDialog(dt, theme, roleColor),
          backgroundColor: roleColor, 
          elevation: 0, 
          foregroundColor: Colors.white, 
          icon: const Icon(Icons.add_task_rounded), 
          label: const Text('CREATE NEW TASK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11))
        ),
      ),
    );
  }
}
