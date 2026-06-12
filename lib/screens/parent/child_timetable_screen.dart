import 'package:flutter/material.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class ChildTimetableScreen extends StatefulWidget {
  final Student student;
  const ChildTimetableScreen({super.key, required this.student});

  @override
  State<ChildTimetableScreen> createState() => _ChildTimetableScreenState();
}

class _ChildTimetableScreenState extends State<ChildTimetableScreen> {
  List<Map<String, dynamic>> _timetable = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getClassTimetable(widget.student.grade, widget.student.stream);
      if (mounted) {
        setState(() {
          _timetable = data;
          _isLoading = false;
        });
      }
    } catch (e) {
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
        title: const Text('Class Timetable', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.indigo.shade800, Colors.indigo.shade400]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _timetable.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _timetable.length,
                  itemBuilder: (context, index) {
                    final slot = _timetable[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.schedule_rounded, color: Colors.indigo),
                        ),
                        title: Text(slot['subject'] ?? 'Subject', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${slot['day']} | ${slot['start_time']} - ${slot['end_time']}'),
                        trailing: Text(slot['room'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_view_day_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No timetable scheduled yet.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}
