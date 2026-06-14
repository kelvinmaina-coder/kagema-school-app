import 'package:flutter/material.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class ChildAttendanceScreen extends StatefulWidget {
  final Student student;
  const ChildAttendanceScreen({super.key, required this.student});

  @override
  State<ChildAttendanceScreen> createState() => _ChildAttendanceScreenState();
}

class _ChildAttendanceScreenState extends State<ChildAttendanceScreen> {
  List<Attendance> records = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    try {
      final listData = await SupabaseService.instance.getChildAttendance(widget.student.studentId);
      if (mounted) {
        setState(() {
          records = (listData ?? []).map((m) => Attendance.fromMap(m)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('${widget.student.name}\'s Attendance', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, Colors.teal.shade900], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.verified_user_rounded, size: 140, color: Colors.white.withOpacity(0.1)))]),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.teal)) 
          : Column(
              children: [
                SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
                _buildHeader(theme, gemini),
                Expanded(
                  child: records.isEmpty
                      ? _buildEmptyState(Icons.event_note_rounded, 'NO NEURAL RECORDS FOUND')
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            final r = records[index];
                            final color = r.status == 'Present' ? Colors.green : Colors.red;
                            final content = ListTile(
                              leading: Icon(r.status == 'Present' ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color),
                              title: Text(r.date, style: const TextStyle(fontWeight: FontWeight.w900)),
                              trailing: Text(r.status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
                            );
                            return Padding(padding: const EdgeInsets.only(bottom: 12), child: gemini?.buildGlowContainer(borderRadius: 24, borderThickness: 1, backgroundColor: theme.cardColor.withOpacity(0.85), padding: EdgeInsets.zero, child: content) ?? Card(child: content));
                          },
                        ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, GeminiThemeExtension? gemini) {
    int present = records.where((r) => r.status == 'Present').length;
    double percent = records.isEmpty ? 0 : (present / records.length) * 100;
    final content = Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('CONSISTENCY SCORE', style: TextStyle(color: Colors.blueGrey, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)), const SizedBox(height: 8), Text('${percent.toInt()}% Cloud Verified', style: TextStyle(color: theme.primaryColor, fontSize: 18, fontWeight: FontWeight.w900))]),
      Icon(Icons.star_rounded, color: theme.primaryColor, size: 28),
    ]);
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: gemini?.buildGlowContainer(borderRadius: 28, borderThickness: 1.5, backgroundColor: theme.cardColor.withOpacity(0.9), padding: const EdgeInsets.all(24), child: content) ?? Card(child: content));
  }

  Widget _buildEmptyState(IconData icon, String msg) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 60, color: Colors.grey.withOpacity(0.3)), const SizedBox(height: 12), Text(msg, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 1))]));
}
