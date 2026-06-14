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
    if (!mounted) return;
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
        title: Text('${widget.student.name}\'s Schedule', 
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.indigo.shade900, Colors.indigo.shade500], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 20)],
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.calendar_view_week_rounded, size: 140, color: Colors.white.withOpacity(0.1)))]),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
            : _timetable.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  itemCount: _timetable.length,
                  itemBuilder: (context, index) {
                    final slot = _timetable[index];
                    final content = ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.schedule_rounded, color: Colors.indigo, size: 24),
                      ),
                      title: Text(slot['subject'] ?? 'Neural Logic', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('${slot['day']} • ${slot['time_slot']}', 
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text(slot['room'] ?? 'RM 1', style: TextStyle(fontWeight: FontWeight.w900, color: theme.primaryColor, fontSize: 10)),
                      ),
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: gemini?.buildGlowContainer(
                        borderRadius: 28, borderThickness: 1, backgroundColor: theme.cardColor.withOpacity(0.85), padding: EdgeInsets.zero,
                        child: content,
                      ) ?? Card(child: content),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() => const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.event_busy_rounded, size: 80, color: Colors.grey), SizedBox(height: 16), Text('NO NEURAL SCHEDULE ASSIGNED', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5))]));
}
