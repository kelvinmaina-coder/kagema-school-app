import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class TimetableViewer extends StatefulWidget {
  const TimetableViewer({super.key});

  @override
  State<TimetableViewer> createState() => _TimetableViewerState();
}

class _TimetableViewerState extends State<TimetableViewer> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _teachingEntries = [];
  List<Map<String, dynamic>> _examEntries = [];
  bool _isLoading = true;
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  int _viewIndex = 0; // 0 for Teaching, 1 for Exam

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadTimetables();
  }

  Future<void> _loadTimetables() async {
    setState(() => _isLoading = true);
    try {
      final teacherId = SupabaseService.instance.client.auth.currentUser?.id ?? "";
      
      // Fetch everything from Supabase cloud
      final response = await SupabaseService.instance.client
          .from('timetable')
          .select()
          .eq('teacher_id', teacherId);

      final List<Map<String, dynamic>> allEntries = List<Map<String, dynamic>>.from(response);
      
      setState(() {
        _teachingEntries = allEntries.where((e) => e['type'] == 'Teaching' || e['type'] == null).toList();
        _examEntries = allEntries.where((e) => e['type'] == 'Exam').toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Timetable Load Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_viewIndex == 0 ? 'Teaching Timetable' : 'Exam Timetable', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _viewIndex == 0 ? Colors.teal : Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_viewIndex == 0 ? Icons.quiz : Icons.menu_book),
            onPressed: () => setState(() => _viewIndex = _viewIndex == 0 ? 1 : 0),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: _days.map((day) => Tab(text: day.substring(0, 3).toUpperCase())).toList(),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: _days.map((day) => _buildDaySchedule(day)).toList(),
              ),
      ),
    );
  }

  Widget _buildDaySchedule(String day) {
    final entries = (_viewIndex == 0 ? _teachingEntries : _examEntries).where((e) => e['day'] == day).toList();
    entries.sort((a, b) => (a['time_slot'] ?? '').compareTo(b['time_slot'] ?? ''));

    if (entries.isEmpty) {
      return const Center(child: Text('No duties scheduled for this day in cloud.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(entry['time_slot'] ?? '--:--', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            title: Text(entry['subject'] ?? 'Subject', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${entry['grade'] ?? ''} ${entry['stream'] ?? ''} • Room ${entry['room'] ?? 'N/A'}'),
          ),
        );
      },
    );
  }
}
