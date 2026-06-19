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
  final String _roleId = 'teacher';

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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddExamDialog(DT dt, GeminiThemeExtension? theme, Color roleColor) {
    final titleCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: theme?.buildGlowContainer(
          accentColor: roleColor,
          borderRadius: 35,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: dt.divider, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text('ADD NEW EXAM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text('Exam Registration', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1, color: dt.textPrimary)),
              const SizedBox(height: 32),
              _buildInputField(dt, 'Exam Name (e.g. End of Term)', Icons.title_rounded, titleCtrl, roleColor),
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
                    decoration: BoxDecoration(color: dt.roleSoftBg(roleColor), borderRadius: BorderRadius.circular(20), border: Border.all(color: dt.cardBorder)),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_rounded, color: roleColor),
                        const SizedBox(width: 12),
                        Text(DateFormat('EEEE, MMM d, yyyy').format(selectedDate), style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary)),
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
                  child: const Text('SAVE EXAM', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ) ?? const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildInputField(DT dt, String label, IconData icon, TextEditingController ctrl, Color roleColor) {
    return TextField(
      controller: ctrl,
      style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: roleColor, size: 20),
      ),
    );
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
        title: const Text('EXAM SCHEDULE', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3, color: Colors.white)
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: RoleColors.gradient(_roleId, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.quiz_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
              ),
            ],
          ),
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
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10),
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: roleColor))
              : Column(
                  children: [
                    _buildGradingOverview(dt, theme, roleColor),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _exams.isEmpty 
                        ? _buildEmptyState(dt)
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: _exams.length,
                            itemBuilder: (context, index) {
                              final exam = _exams[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: theme?.buildGlowContainer(
                                  accentColor: roleColor,
                                  borderRadius: 28,
                                  padding: EdgeInsets.zero,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: dt.roleSoftBg(roleColor), shape: BoxShape.circle),
                                      child: Icon(Icons.quiz_rounded, color: roleColor, size: 24),
                                    ),
                                    title: Text(exam['title'] ?? 'Exam', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: dt.textPrimary)),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text('Scheduled: ${exam['start_date'] ?? 'N/A'}', 
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dt.textSecondary)
                                      ),
                                    ),
                                    trailing: Icon(Icons.chevron_right_rounded, color: dt.iconInactive),
                                  ),
                                ),
                              );
                            },
                          ),
                    ),
                  ],
                ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
      floatingActionButton: RolePlasma(
        color: roleColor,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddExamDialog(dt, theme, roleColor),
          icon: const Icon(Icons.add_task_rounded),
          label: const Text('SCHEDULE NEW EXAM', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
        ),
      ),
    );
  }

  Widget _buildGradingOverview(DT dt, GeminiThemeExtension? theme, Color roleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: theme?.buildGlowContainer(
        accentColor: roleColor,
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem(dt, 'Exams Scheduled', '${_exams.length}', KagemaColors.azure),
            _vDivider(dt),
            _statItem(dt, 'Sync Status', 'Connected', KagemaColors.teacherGreen),
          ],
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _vDivider(DT dt) => Container(width: 1, height: 35, color: dt.divider);

  Widget _statItem(DT dt, String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(label.toUpperCase(), style: TextStyle(fontSize: 8, color: dt.textMuted, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_rounded, size: 80, color: dt.iconInactive),
          const SizedBox(height: 16),
          Text('NO EXAMS FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
        ],
      ),
    );
  }
}
