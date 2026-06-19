import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';

class LessonPlanningScreen extends StatefulWidget {
  const LessonPlanningScreen({super.key});

  @override
  State<LessonPlanningScreen> createState() => _LessonPlanningScreenState();
}

class _LessonPlanningScreenState extends State<LessonPlanningScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _lessonPlans = [];
  Map<String, dynamic> _syllabusStatus = {};
  bool _isLoading = true;
  final String _roleId = 'teacher';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait<dynamic>([
        SupabaseService.instance.getLessonPlans(),
        SupabaseService.instance.getSyllabusStatus('Mathematics'),
      ]);
      
      if (mounted) {
        setState(() {
          _lessonPlans = List<Map<String, dynamic>>.from(results[0]);
          _syllabusStatus = results[1] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddPlanDialog(DT dt, Color roleColor) {
    final topicCtrl = TextEditingController();
    String selectedSubject = 'Mathematics';
    String selectedGrade = 'Grade 1';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: LiquidGlassCard(
          borderRadius: 35,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: dt.divider, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text('LESSON PLAN REGISTRATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text('New Lesson Plan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1, color: dt.textPrimary)),
              const SizedBox(height: 32),
              _buildInputField(dt, 'Topic Description', Icons.topic_rounded, topicCtrl, roleColor),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedSubject,
                dropdownColor: dt.cardBg,
                style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
                items: ['Mathematics', 'English', 'Science', 'Social Studies', 'CRE'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => selectedSubject = v!,
                decoration: InputDecoration(labelText: 'Subject', prefixIcon: Icon(Icons.subject_rounded, color: roleColor)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedGrade,
                dropdownColor: dt.cardBg,
                style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
                items: ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) => selectedGrade = v!,
                decoration: InputDecoration(labelText: 'Target Grade', prefixIcon: Icon(Icons.school_rounded, color: roleColor)),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () async {
                    if (topicCtrl.text.isNotEmpty) {
                      final data = {
                        'topic': topicCtrl.text.trim(),
                        'subject': selectedSubject,
                        'grade': selectedGrade,
                        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                        'is_completed': false,
                      };
                      await SupabaseService.instance.saveLessonPlan(data);
                      if (mounted) {
                        Navigator.pop(context);
                        _loadData();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: roleColor, foregroundColor: Colors.white),
                  child: const Text('SAVE LESSON PLAN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dt = DT.of(context);
    final roleColor = RoleColors.of(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: const Text('PLANNING CENTER', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3, color: Colors.white)
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
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.architecture_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          tabs: const [
            Tab(text: 'LESSON PLANS', icon: Icon(Icons.description_rounded, size: 20)),
            Tab(text: 'SYLLABUS COVERAGE', icon: Icon(Icons.checklist_rtl_rounded, size: 20)),
          ],
        ),
      ),
      body: NeuralBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: RoleColors.complement(_roleId),
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: Padding(
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 48),
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: roleColor))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPlansList(dt, roleColor),
                    _buildSyllabusCoverage(dt, roleColor),
                  ],
                ),
          ),
        ),
      ),
      floatingActionButton: RolePlasma(
        color: roleColor,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddPlanDialog(dt, roleColor),
          backgroundColor: roleColor,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_task_rounded),
          label: const Text('NEW LESSON PLAN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
        ),
      ),
    );
  }

  Widget _buildPlansList(DT dt, Color roleColor) {
    if (_lessonPlans.isEmpty) return _buildEmptyState(dt, 'NO LESSON PLANS FOUND');
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: _lessonPlans.length,
      itemBuilder: (context, index) {
        final plan = _lessonPlans[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LiquidGlassCard(
            accentColor: KagemaColors.staffSky,
            borderRadius: 28,
            padding: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: dt.roleSoftBg(KagemaColors.staffSky), shape: BoxShape.circle),
                child: const Icon(Icons.assignment_rounded, color: KagemaColors.staffSky, size: 24),
              ),
              title: Text('Topic: ${plan['topic'] ?? 'N/A'}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: dt.textPrimary)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Subject: ${plan['subject']} | Grade: ${plan['grade']}', 
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dt.textSecondary)
                ),
              ),
              trailing: _statusChip(dt, plan['is_completed'] == true ? 'Completed' : 'Pending'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSyllabusCoverage(DT dt, Color roleColor) {
    if (_syllabusStatus.isEmpty) return _buildEmptyState(dt, 'NO SYLLABUS DATA FOUND');
    
    double progress = (_syllabusStatus['completion_percentage'] as num?)?.toDouble() ?? 0.0;
    if (progress > 1.0) progress /= 100;
    
    List<String> remaining = List<String>.from(_syllabusStatus['remaining_topics'] ?? []);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: [
        LiquidGlassCard(
          accentColor: roleColor,
          borderRadius: 30,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_syllabusStatus['subject_name']?.toString().toUpperCase() ?? 'GENERAL SYLLABUS', 
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1, color: dt.textPrimary)
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: dt.surfaceBg,
                  valueColor: AlwaysStoppedAnimation(progress >= 1.0 ? KagemaColors.teacherGreen : roleColor),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${(progress * 100).toInt()}% COMPLETED', 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: roleColor, letterSpacing: 1)
                  ),
                  const Text('VERIFIED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: KagemaColors.teacherGreen, letterSpacing: 1.5)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text('REMAINING TOPICS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2.5)
          ),
        ),
        const SizedBox(height: 16),
        ...remaining.map((topic) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LiquidGlassCard(
              accentColor: KagemaColors.accountantAmber,
              borderRadius: 24,
              padding: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: dt.roleSoftBg(KagemaColors.accountantAmber), shape: BoxShape.circle),
                  child: const Icon(Icons.pending_actions_rounded, color: KagemaColors.accountantAmber, size: 18),
                ),
                title: Text(topic, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: dt.textPrimary)),
              ),
            ),
          );
        }),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _statusChip(DT dt, String status) {
    Color color = status == 'Approved' || status == 'Completed' ? KagemaColors.teacherGreen : KagemaColors.accountantAmber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: dt.roleSoftBg(color), 
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(status.toUpperCase(), 
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1)
      ),
    );
  }

  Widget _buildEmptyState(DT dt, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_rounded, size: 80, color: dt.iconInactive),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(color: dt.textMuted, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
