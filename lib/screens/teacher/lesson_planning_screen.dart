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
      debugPrint("Lesson Planning Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddPlanDialog() {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final topicCtrl = TextEditingController();
    String selectedSubject = 'Mathematics';
    String selectedGrade = 'Grade 1';

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                const Text('LESSON PLAN REGISTRATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)),
                const SizedBox(height: 8),
                const Text('New Lesson Plan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 32),
                _buildInputField('Topic Description', Icons.topic_rounded, topicCtrl, theme),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedSubject,
                  items: ['Mathematics', 'English', 'Science', 'Social Studies', 'CRE'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => selectedSubject = v!,
                  decoration: _inputDecoration('Subject', Icons.subject_rounded, theme),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedGrade,
                  items: ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => selectedGrade = v!,
                  decoration: _inputDecoration('Target Grade', Icons.school_rounded, theme),
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
                    style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    child: const Text('SAVE LESSON PLAN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ) ?? const SizedBox(),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, ThemeData theme) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      prefixIcon: Icon(icon, color: theme.primaryColor, size: 20),
      filled: true,
      fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
    );
  }

  Widget _buildInputField(String label, IconData icon, TextEditingController ctrl, ThemeData theme) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: _inputDecoration(label, icon, theme),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Planning Center', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2, color: Colors.white)
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
              colors: [theme.primaryColor, Colors.indigo.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.architecture_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: Colors.white.withOpacity(0.2),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'LESSON PLANS', icon: Icon(Icons.description_rounded, size: 20)),
            Tab(text: 'SYLLABUS COVERAGE', icon: Icon(Icons.checklist_rtl_rounded, size: 20)),
          ],
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 48),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildPlansList(theme, gemini),
                  _buildSyllabusCoverage(theme, gemini),
                ],
              ),
        ),
      ),
      floatingActionButton: gemini?.buildGlowContainer(
        borderRadius: 30,
        borderThickness: 2,
        backgroundColor: theme.primaryColor,
        padding: EdgeInsets.zero,
        child: FloatingActionButton.extended(
          onPressed: _showAddPlanDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_task_rounded),
          label: const Text('New Lesson Plan', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _buildPlansList(ThemeData theme, GeminiThemeExtension? gemini) {
    if (_lessonPlans.isEmpty) return _buildEmptyState('NO LESSON PLANS FOUND');
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: _lessonPlans.length,
      itemBuilder: (context, index) {
        final plan = _lessonPlans[index];
        final content = ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.assignment_rounded, color: Colors.indigo, size: 24),
          ),
          title: Text('Topic: ${plan['topic'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Subject: ${plan['subject']} | Grade: ${plan['grade']}', 
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)
            ),
          ),
          trailing: _statusChip(plan['is_completed'] == true ? 'Completed' : 'Pending'),
          onTap: () {},
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: gemini?.buildGlowContainer(
            borderRadius: 28,
            borderThickness: 1,
            backgroundColor: theme.cardColor.withOpacity(0.85),
            padding: EdgeInsets.zero,
            child: content,
          ) ?? Card(child: content),
        );
      },
    );
  }

  Widget _buildSyllabusCoverage(ThemeData theme, GeminiThemeExtension? gemini) {
    if (_syllabusStatus.isEmpty) return _buildEmptyState('NO SYLLABUS DATA FOUND');
    
    double progress = (_syllabusStatus['completion_percentage'] as num?)?.toDouble() ?? 0.0;
    if (progress > 1.0) progress /= 100;
    
    List<String> remaining = List<String>.from(_syllabusStatus['remaining_topics'] ?? []);

    final headerContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_syllabusStatus['subject_name']?.toString().toUpperCase() ?? 'GENERAL SYLLABUS', 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: theme.primaryColor.withOpacity(0.05),
            valueColor: AlwaysStoppedAnimation(progress >= 1.0 ? Colors.green : theme.primaryColor),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${(progress * 100).toInt()}% COMPLETED', 
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.primaryColor, letterSpacing: 1)
            ),
            const Text('VERIFIED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.green, letterSpacing: 1.5)),
          ],
        ),
      ],
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: [
        gemini?.buildGlowContainer(
          borderRadius: 30,
          borderThickness: 2,
          backgroundColor: theme.cardColor.withOpacity(0.9),
          padding: const EdgeInsets.all(24),
          child: headerContent,
        ) ?? Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(28)),
          child: headerContent,
        ),
        const SizedBox(height: 48),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text('REMAINING TOPICS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2.5)
          ),
        ),
        const SizedBox(height: 16),
        ...remaining.map((topic) {
          final content = ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.pending_actions_rounded, color: Colors.orange, size: 18),
            ),
            title: Text(topic, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: gemini?.buildGlowContainer(
              borderRadius: 24,
              borderThickness: 1,
              backgroundColor: theme.cardColor.withOpacity(0.85),
              padding: EdgeInsets.zero,
              child: content,
            ) ?? Card(child: content),
          );
        }),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _statusChip(String status) {
    Color color = status == 'Approved' || status == 'Completed' ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(status.toUpperCase(), 
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1)
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
