import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  List<Attendance> _records = [];
  bool _isLoading = true;
  int _present = 0;
  int _absent = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final listData = await SupabaseService.instance.getChildAttendance(widget.student.studentId);
      final list = (listData ?? []).map((m) => Attendance.fromMap(m)).toList();
      int p = list.where((r) => r.status == 'Present').length;
      if (mounted) {
        setState(() {
          _records = list;
          _present = p;
          _absent = list.length - p;
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
        title: Text('${widget.student.name}\'s Attendance', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.teal.shade900, Colors.teal.shade500], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.verified_user_rounded, size: 140, color: Colors.white.withOpacity(0.1)))]),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : Column(
              children: [
                SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
                _buildSummaryCard(theme, gemini),
                Expanded(
                  child: _records.isEmpty 
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _records.length,
                        itemBuilder: (context, index) {
                          final r = _records[index];
                          final isP = r.status == 'Present';
                          final content = ListTile(
                            leading: Icon(isP ? Icons.check_circle_rounded : Icons.cancel_rounded, color: isP ? Colors.green : Colors.red),
                            title: Text(r.date, style: const TextStyle(fontWeight: FontWeight.w900)),
                            trailing: Text(r.status.toUpperCase(), style: TextStyle(color: isP ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
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

  Widget _buildSummaryCard(ThemeData theme, GeminiThemeExtension? gemini) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: gemini?.buildGlowContainer(
        borderRadius: 28, borderThickness: 2, backgroundColor: theme.cardColor.withOpacity(0.9), padding: const EdgeInsets.all(24), useAIBorder: true,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_stat('PRESENT', '$_present', Colors.green), _stat('ABSENT', '$_absent', Colors.red)]),
      ),
    );
  }

  Widget _stat(String l, String v, Color c) => Column(children: [Text(v, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: c)), Text(l, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))]);

  Widget _buildEmptyState() => const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.event_busy_rounded, size: 80, color: Colors.grey), SizedBox(height: 16), Text('NO ATTENDANCE RECORDS FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1))]));
}
