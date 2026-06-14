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
    if (!mounted) return;
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
        title: const Text('My Teaching Matrix', 
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
              colors: [Colors.indigo.shade900, Colors.indigo.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.calendar_view_week_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Column(
          children: [
            SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
            _buildDayPicker(theme, gemini),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
                : daySchedule.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        itemCount: daySchedule.length,
                        itemBuilder: (context, index) {
                          final item = daySchedule[index];
                          final content = ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.timer_outlined, color: Colors.indigo, size: 24),
                            ),
                            title: Text(item['subject'] ?? 'Neural Duty', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('${item['time_slot']} • ${item['grade']}', 
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(item['room'] ?? 'RM 1', 
                                style: TextStyle(fontWeight: FontWeight.w900, color: theme.primaryColor, fontSize: 10, letterSpacing: 1)
                              ),
                            ),
                          );

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: gemini?.buildGlowContainer(
                              borderRadius: 28,
                              borderThickness: 1,
                              backgroundColor: theme.cardColor.withOpacity(0.85),
                              padding: EdgeInsets.zero,
                              child: content,
                            ) ?? Card(child: content),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayPicker(ThemeData theme, GeminiThemeExtension? gemini) {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'].map((day) {
          final isSelected = _selectedDay == day;
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ChoiceChip(
              label: Text(day, style: TextStyle(
                color: isSelected ? Colors.white : Colors.blueGrey.shade400, 
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1,
              )),
              selected: isSelected,
              selectedColor: Colors.indigo.shade800,
              backgroundColor: theme.cardColor.withOpacity(0.6),
              elevation: 4,
              shadowColor: Colors.indigo.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: isSelected ? Colors.transparent : Colors.blueGrey.withOpacity(0.1)),
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
          Text('NO NEURAL SLOTS ASSIGNED', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
