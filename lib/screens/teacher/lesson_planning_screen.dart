import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Planning & Syllabus', style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)]),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Lesson Plans', icon: Icon(Icons.description_rounded)),
            Tab(text: 'Syllabus Coverage', icon: Icon(Icons.checklist_rtl_rounded)),
          ],
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
                  _buildPlansList(theme),
                  _buildSyllabusCoverage(theme),
                ],
              ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('New Plan'),
        icon: const Icon(Icons.add),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildPlansList(ThemeData theme) {
    if (_lessonPlans.isEmpty) return const Center(child: Text('No lesson plans in cloud.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _lessonPlans.length,
      itemBuilder: (context, index) {
        final plan = _lessonPlans[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            title: Text('Topic: ${plan['topic'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Subject: ${plan['subject']} | Grade: ${plan['grade']}'),
            trailing: _statusChip(plan['is_completed'] == true ? 'Completed' : 'Pending'),
            onTap: () {},
          ),
        );
      },
    );
  }

  Widget _buildSyllabusCoverage(ThemeData theme) {
    if (_syllabusStatus.isEmpty) return const Center(child: Text('No syllabus data found in cloud.'));
    
    double progress = (_syllabusStatus['completion_percentage'] as num?)?.toDouble() ?? 0.0;
    if (progress > 1.0) progress /= 100; // Normalize
    
    List<String> remaining = List<String>.from(_syllabusStatus['remaining_topics'] ?? []);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_syllabusStatus['subject_name'] ?? 'General', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(progress >= 1.0 ? Colors.green : Colors.blue),
                  ),
                ),
                const SizedBox(height: 8),
                Text('${(progress * 100).toInt()}% Cloud Sync Coverage', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text('REMAINING TOPICS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
        const SizedBox(height: 12),
        ...remaining.map((topic) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.pending_actions_rounded, color: Colors.orange),
            title: Text(topic),
          ),
        )),
      ],
    );
  }

  Widget _statusChip(String status) {
    Color color = status == 'Approved' || status == 'Completed' ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }
}
