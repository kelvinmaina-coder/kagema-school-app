import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class TimetableViewer extends StatefulWidget {
  const TimetableViewer({super.key});

  @override
  State<TimetableViewer> createState() => _TimetableViewerState();
}

class _TimetableViewerState extends State<TimetableViewer> {
  List<Map<String, dynamic>> _schedule = [];
  bool _isLoading = true;
  String _selectedDay = 'Monday';

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    setState(() => _isLoading = true);
    try {
      final String teacherId = SupabaseService.instance.client.auth.currentUser?.id ?? "";
      final data = await SupabaseService.instance.getTeacherSchedule(teacherId);
      
      if (mounted) {
        setState(() {
          _schedule = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Timetable Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final daySchedule = _schedule.where((s) => s['day'] == _selectedDay).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('My Teaching Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
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
        child: Column(
          children: [
            SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10),
            _buildDayPicker(theme),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : daySchedule.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: daySchedule.length,
                        itemBuilder: (context, index) {
                          final item = daySchedule[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.timer_outlined, color: Colors.indigo),
                              ),
                              title: Text(item['subject'] ?? 'Duty', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${item['time_slot']} • ${item['grade']}'),
                              trailing: Text(item['room'] ?? 'RM 1', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey)),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayPicker(ThemeData theme) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'].map((day) {
          final isSelected = _selectedDay == day;
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ChoiceChip(
              label: Text(day, style: TextStyle(color: isSelected ? Colors.white : Colors.indigo, fontWeight: FontWeight.bold)),
              selected: isSelected,
              selectedColor: Colors.indigo,
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.indigo.withOpacity(0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (v) => setState(() => _selectedDay = day),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No lessons scheduled for this day.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}
