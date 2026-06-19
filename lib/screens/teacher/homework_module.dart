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
  final String _roleId = 'teacher';

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

  void _showAddDialog(DT dt, GeminiThemeExtension? theme, Color roleColor, {Map<String, dynamic>? assignmentToEdit}) {
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
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: theme?.buildGlowContainer(
          accentColor: roleColor,
          borderRadius: 35,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: dt.divider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text(isEditing ? 'MODIFY ASSIGNMENT' : 'POST NEW ASSIGNMENT', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)
                ),
                const SizedBox(height: 8),
                Text(isEditing ? 'Update Details' : 'New Homework', 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1, color: dt.textPrimary)
                ),
                const SizedBox(height: 32),
                _buildInputField(dt, 'Assignment Title', Icons.title_rounded, titleController, KagemaColors.secretaryViolet),
                const SizedBox(height: 16),
                _buildInputField(dt, 'Instructions', Icons.notes_rounded, descController, KagemaColors.secretaryViolet, maxLines: 3),
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
                        color: dt.inputBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: dt.cardBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: KagemaColors.secretaryViolet),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('DUE DATE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: dt.textMuted)),
                              Text(DateFormat('EEEE, MMM d, yyyy').format(selectedDueDate), 
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: dt.textPrimary)),
                            ],
                          ),
                          const Spacer(),
                          Icon(Icons.edit_calendar_rounded, size: 18, color: dt.iconInactive),
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
                    child: Text(isEditing ? 'COMMIT UPDATES' : 'POST ASSIGNMENT', 
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)
                    ),
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

  Widget _buildInputField(DT dt, String label, IconData icon, TextEditingController ctrl, Color color, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Future<void> _confirmDelete(DT dt, Map<String, dynamic> h) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dt.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Delete Assignment?', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textPrimary)),
        content: Text('Are you sure you want to remove "${h['title']}"? It will disappear from all student portals.', style: TextStyle(color: dt.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('CANCEL', style: TextStyle(color: dt.textMuted))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: KagemaColors.parentRed, fontWeight: FontWeight.bold))),
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
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final roleColor = RoleColors.of(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: Text('HOMEWORK: ${widget.grade}', 
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3, fontSize: 16)
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: RoleColors.gradient(_roleId, dark: context.isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.assignment_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ),
      ),
      body: theme?.buildCreativeBackground(
        isDark: context.isDark,
        primaryBlob: roleColor,
        secondaryBlob: RoleColors.complement(_roleId),
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: context.isDark,
          child: Padding(
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10),
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: roleColor))
              : _assignments.isEmpty
                  ? _buildEmptyState(dt)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      itemCount: _assignments.length,
                      itemBuilder: (context, index) {
                        final h = _assignments[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: theme?.buildGlowContainer(
                            accentColor: KagemaColors.secretaryViolet,
                            borderRadius: 28,
                            padding: EdgeInsets.zero,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: dt.roleSoftBg(KagemaColors.secretaryViolet), shape: BoxShape.circle),
                                child: const Icon(Icons.assignment_rounded, color: KagemaColors.secretaryViolet, size: 24),
                              ),
                              title: Text(h['title'] ?? 'Homework Task', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: dt.textPrimary)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('Due: ${h['due_date']} \nSubject: ${h['subject']}', 
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.4, color: dt.textSecondary)
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_note_rounded, color: KagemaColors.staffSky),
                                    onPressed: () => _showAddDialog(dt, theme, roleColor, assignmentToEdit: h),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: KagemaColors.parentRed),
                                    onPressed: () => _confirmDelete(dt, h),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
      floatingActionButton: RolePlasma(
        color: roleColor,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddDialog(dt, theme, roleColor),
          icon: const Icon(Icons.add_task_rounded),
          label: const Text('ADD ASSIGNMENT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_rounded, size: 80, color: dt.iconInactive),
          const SizedBox(height: 16),
          Text('NO HOMEWORK ASSIGNED', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
        ],
      ),
    );
  }
}
