import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';

class ExamManagementScreen extends StatefulWidget {
  const ExamManagementScreen({super.key});

  @override
  State<ExamManagementScreen> createState() => _ExamManagementScreenState();
}

class _ExamManagementScreenState extends State<ExamManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _exams = [];
  List<Map<String, dynamic>> _filteredExams = [];
  final String _roleId = 'admin';

  // --- FILTERS ---
  String _selectedTerm = 'All';
  String _selectedStatus = 'All';
  List<String> _availableTerms = ['All', 'Term 1', 'Term 2', 'Term 3'];
  List<String> _statusOptions = ['All', 'Upcoming', 'Ongoing', 'Completed'];

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
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Exam load error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(_exams);

    // Filter by Term
    if (_selectedTerm != 'All') {
      filtered = filtered.where((e) => e['term'] == _selectedTerm).toList();
    }

    // Filter by Status
    if (_selectedStatus != 'All') {
      filtered = filtered.where((e) => e['status'] == _selectedStatus).toList();
    }

    setState(() => _filteredExams = filtered);
  }

  String _getExamStatus(Map<String, dynamic> exam) {
    final startDate = exam['start_date'];
    final endDate = exam['end_date'] ?? startDate;
    if (startDate == null) return 'Upcoming';

    final now = DateTime.now();
    final start = DateTime.tryParse(startDate);
    final end = endDate != null ? DateTime.tryParse(endDate) : start;

    if (start == null) return 'Upcoming';
    if (now.isBefore(start)) return 'Upcoming';
    if (end != null && now.isAfter(end)) return 'Completed';
    return 'Ongoing';
  }

  void _showAddEditExamDialog(DT dt, GeminiThemeExtension? theme, Color roleColor, {Map<String, dynamic>? examToEdit}) {
    final isEditing = examToEdit != null;
    final titleCtrl = TextEditingController(text: examToEdit?['title'] ?? '');
    final termCtrl = TextEditingController(text: examToEdit?['term'] ?? '');
    final subjectsCtrl = TextEditingController(text: examToEdit?['subjects'] ?? '');
    final classCtrl = TextEditingController(text: examToEdit?['target_class'] ?? '');

    DateTime selectedDate = examToEdit?['start_date'] != null
        ? DateTime.parse(examToEdit!['start_date'])
        : DateTime.now().add(const Duration(days: 7));

    String selectedStatus = examToEdit?['status'] ?? 'Upcoming';

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
                Text(isEditing ? 'MODIFY EXAM' : 'SCHEDULE SYSTEM EXAM',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text(isEditing ? 'Update Exam Details' : 'Exam Registration',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1, color: dt.textPrimary)),
                const SizedBox(height: 32),

                // Exam Title
                _buildInputField(dt, 'Exam Title (e.g. End of Term 1)', Icons.title_rounded, titleCtrl, roleColor),
                const SizedBox(height: 16),

                // Term
                _buildInputField(dt, 'Term (e.g. Term 1, Term 2)', Icons.article_rounded, termCtrl, roleColor),
                const SizedBox(height: 16),

                // Subjects
                _buildInputField(dt, 'Subjects (comma separated)', Icons.book_rounded, subjectsCtrl, roleColor),
                const SizedBox(height: 16),

                // Target Class
                _buildInputField(dt, 'Target Class (e.g. Grade 5)', Icons.class_rounded, classCtrl, roleColor),
                const SizedBox(height: 16),

                // Date Picker
                StatefulBuilder(
                  builder: (context, setModalState) => InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setModalState(() => selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: dt.roleSoftBg(roleColor),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: dt.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, color: roleColor),
                          const SizedBox(width: 12),
                          Text(DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                              style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary)),
                          const Spacer(),
                          Icon(Icons.edit_calendar_rounded, size: 18, color: dt.iconInactive),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Status Dropdown
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  dropdownColor: dt.cardBg,
                  style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.flag_rounded, color: roleColor, size: 20),
                  ),
                  items: ['Upcoming', 'Ongoing', 'Completed'].map((s) =>
                      DropdownMenuItem(value: s, child: Text(s))
                  ).toList(),
                  onChanged: (v) => selectedStatus = v!,
                ),
                const SizedBox(height: 40),

                // Buttons
                Row(
                  children: [
                    if (isEditing)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Exam?'),
                                content: const Text('This action cannot be undone.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _deleteExam(examToEdit!['event_id'].toString());
                              if (mounted) {
                                Navigator.pop(context);
                                _loadExams();
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    if (isEditing) const SizedBox(width: 12),
                    Expanded(
                      flex: isEditing ? 2 : 1,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (titleCtrl.text.isNotEmpty) {
                            final data = {
                              'title': titleCtrl.text.trim(),
                              'start_date': DateFormat('yyyy-MM-dd').format(selectedDate),
                              'event_type': 'Exam',
                              'term': termCtrl.text.trim(),
                              'subjects': subjectsCtrl.text.trim(),
                              'target_class': classCtrl.text.trim(),
                              'status': selectedStatus,
                            };

                            if (isEditing) {
                              data['event_id'] = examToEdit!['event_id'];
                              await SupabaseService.instance.upsertEvent(data);
                            } else {
                              await SupabaseService.instance.upsertEvent(data);
                            }

                            if (mounted) {
                              Navigator.pop(context);
                              _loadExams();
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          isEditing ? 'UPDATE EXAM' : 'AUTHORIZE EXAM',
                          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ) ?? const SizedBox.shrink(),
      ),
    );
  }

  Future<void> _deleteExam(String eventId) async {
    try {
      await SupabaseService.instance.client.from('events').delete().eq('event_id', eventId);
    } catch (e) {
      debugPrint("Delete exam error: $e");
    }
  }

  Widget _buildInputField(DT dt, String label, IconData icon, TextEditingController ctrl, Color roleColor) {
    return TextField(
      controller: ctrl,
      style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: roleColor, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildFilters(DT dt) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedTerm,
              dropdownColor: dt.cardBg,
              style: TextStyle(color: dt.textPrimary, fontSize: 12),
              decoration: InputDecoration(
                labelText: 'Term',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _availableTerms.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) { setState(() => _selectedTerm = v!); _applyFilters(); },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              dropdownColor: dt.cardBg,
              style: TextStyle(color: dt.textPrimary, fontSize: 12),
              decoration: InputDecoration(
                labelText: 'Status',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) { setState(() => _selectedStatus = v!); _applyFilters(); },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: () {
              setState(() {
                _selectedTerm = 'All';
                _selectedStatus = 'All';
                _applyFilters();
              });
            },
            tooltip: 'Clear filters',
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Upcoming': return Colors.blue;
      case 'Ongoing': return Colors.orange;
      case 'Completed': return Colors.green;
      default: return Colors.grey;
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
        title: const Text('EXAM MANAGEMENT',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3, color: Colors.white)
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadExams,
            tooltip: 'Refresh',
          ),
        ],
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
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + context.pt + 20),
            child: Column(
              children: [
                // Summary stats
                _buildSummaryStats(dt, roleColor),
                // Filters
                _buildFilters(dt),
                // Exam list
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: roleColor))
                      : _filteredExams.isEmpty
                      ? _buildEmptyState(dt)
                      : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredExams.length,
                    itemBuilder: (context, index) {
                      final exam = _filteredExams[index];
                      final status = _getExamStatus(exam);
                      final displayStatus = exam['status'] ?? status;
                      final statusColor = _getStatusColor(displayStatus);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => _showAddEditExamDialog(dt, theme, roleColor, examToEdit: exam),
                          borderRadius: BorderRadius.circular(24),
                          child: theme.buildGlowContainer(
                            accentColor: roleColor,
                            borderRadius: 24,
                            padding: EdgeInsets.zero,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          exam['title']?.toString().toUpperCase() ?? 'EXAM',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15,
                                            color: dt.textPrimary,
                                            letterSpacing: 0.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          displayStatus.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_rounded, size: 14, color: dt.textSecondary),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Date: ${exam['start_date'] ?? 'N/A'}',
                                        style: TextStyle(fontSize: 12, color: dt.textSecondary),
                                      ),
                                      const SizedBox(width: 16),
                                      if (exam['term'] != null && exam['term']!.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: roleColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            exam['term']!,
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: roleColor),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (exam['subjects'] != null && exam['subjects']!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        '📚 ${exam['subjects']}',
                                        style: TextStyle(fontSize: 11, color: dt.textMuted),
                                      ),
                                    ),
                                  if (exam['target_class'] != null && exam['target_class']!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        '🎯 ${exam['target_class']}',
                                        style: TextStyle(fontSize: 11, color: dt.textMuted),
                                      ),
                                    ),
                                ],
                              ),
                            ),
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
          onPressed: () => _showAddEditExamDialog(dt, theme, roleColor),
          icon: const Icon(Icons.add_task_rounded),
          label: const Text('SCHEDULE EXAM', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
        ),
      ),
    );
  }

  Widget _buildSummaryStats(DT dt, Color roleColor) {
    final total = _exams.length;
    final upcoming = _exams.where((e) => _getExamStatus(e) == 'Upcoming').length;
    final ongoing = _exams.where((e) => _getExamStatus(e) == 'Ongoing').length;
    final completed = _exams.where((e) => _getExamStatus(e) == 'Completed').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatCard(dt, 'Total', total.toString(), Icons.quiz_rounded, roleColor),
          const SizedBox(width: 6),
          _buildStatCard(dt, 'Upcoming', upcoming.toString(), Icons.schedule_rounded, Colors.blue),
          const SizedBox(width: 6),
          _buildStatCard(dt, 'Ongoing', ongoing.toString(), Icons.play_circle_rounded, Colors.orange),
          const SizedBox(width: 6),
          _buildStatCard(dt, 'Completed', completed.toString(), Icons.check_circle_rounded, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatCard(DT dt, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: dt.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: dt.cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: dt.textPrimary)),
            Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: dt.textMuted)),
          ],
        ),
      ),
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
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadExams,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('REFRESH'),
          ),
        ],
      ),
    );
  }
}