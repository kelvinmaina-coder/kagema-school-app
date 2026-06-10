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
    try {
      final list = await SupabaseService.instance.getAttendanceForStudent(widget.student.studentId);
      if (mounted) {
        setState(() {
          records = list.map((m) => Attendance.fromMap(m)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Load Attendance Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text('${widget.student.name} - Attendance', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : Column(
                    children: [
                      _buildHeader(theme, gemini),
                      Expanded(
                        child: records.isEmpty
                            ? _buildEmptyState('No attendance records found in cloud.')
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: records.length,
                                itemBuilder: (context, index) {
                                  final r = records[index];
                                  bool isPresent = r.status == 'Present';
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: (isPresent ? Colors.green : Colors.red).withOpacity(0.1),
                                        child: Icon(isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded, color: isPresent ? Colors.green : Colors.red, size: 20),
                                      ),
                                      title: Text(r.date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: (isPresent ? Colors.green : Colors.red).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          r.status.toUpperCase(),
                                          style: TextStyle(color: isPresent ? Colors.green.shade800 : Colors.red.shade800, fontWeight: FontWeight.w900, fontSize: 10),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, GeminiThemeExtension? gemini) {
    int presentCount = records.where((r) => r.status == 'Present').length;
    double percent = records.isEmpty ? 0 : (presentCount / records.length) * 100;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ATTENDANCE SCORE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              Text('${percent.toInt()}% Consistency', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: percent / 100,
                strokeWidth: 4,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const Icon(Icons.star_rounded, color: Colors.white, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class ChildHomeworkScreen extends StatefulWidget {
  final Student student;
  const ChildHomeworkScreen({super.key, required this.student});

  @override
  State<ChildHomeworkScreen> createState() => _ChildHomeworkScreenState();
}

class _ChildHomeworkScreenState extends State<ChildHomeworkScreen> {
  List<Homework> assignments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await SupabaseService.instance.getHomeworkByClass(widget.student.grade, widget.student.stream);
      if (mounted) {
        setState(() {
          assignments = list.map((m) => Homework.fromMap(m)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Load Homework Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('Homework Assignments', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : Column(
                    children: [
                      _buildHeader(theme, gemini),
                      Expanded(
                        child: assignments.isEmpty
                            ? _buildEmptyState('No pending homework for your class in cloud.')
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: assignments.length,
                                itemBuilder: (context, index) {
                                  final h = assignments[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: ExpansionTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.purple.withOpacity(0.1),
                                        child: const Icon(Icons.assignment_rounded, color: Colors.purple, size: 20),
                                      ),
                                      title: Text(h.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                      subtitle: Text('${h.subject} | Due: ${h.dueDate}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Divider(),
                                              const SizedBox(height: 8),
                                              const Text('INSTRUCTIONS:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
                                              const SizedBox(height: 4),
                                              Text(h.description, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.blueGrey)),
                                              const SizedBox(height: 20),
                                              SizedBox(
                                                width: double.infinity,
                                                height: 45,
                                                child: ElevatedButton.icon(
                                                  onPressed: () {
                                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status update feature coming soon to cloud!')));
                                                  },
                                                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                                                  label: const Text('MARK AS DONE'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.purple.shade700,
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, GeminiThemeExtension? gemini) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.purple.shade700.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('STUDY PROTOCOL', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          Text('${assignments.length} Tasks Pending', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
