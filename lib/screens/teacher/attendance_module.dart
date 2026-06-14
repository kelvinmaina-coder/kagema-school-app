import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class AttendanceModule extends StatefulWidget {
  final String grade;
  final String stream;

  const AttendanceModule({super.key, required this.grade, required this.stream});

  @override
  State<AttendanceModule> createState() => _AttendanceModuleState();
}

class _AttendanceModuleState extends State<AttendanceModule> {
  List<Student> students = [];
  Map<String, String> attendanceStatus = {}; 
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final studentMaps = await SupabaseService.instance.getStudentsByClass(widget.grade, widget.stream);
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final history = await SupabaseService.instance.getAttendanceHistory(widget.grade, widget.stream, dateStr);
      
      if (mounted) {
        setState(() {
          students = studentMaps.map((m) => Student.fromMap(m)).toList();
          attendanceStatus.clear();
          for (var s in students) {
            attendanceStatus[s.studentId] = 'Present';
          }
          for (var record in history) {
            final id = record['target_id']?.toString() ?? '';
            if (id.isNotEmpty) attendanceStatus[id] = record['status'];
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _saveAttendance() async {
    setState(() => isSaving = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    try {
      List<Map<String, dynamic>> records = [];
      for (var student in students) {
        records.add({
          'attendance_id': '${dateStr}_${student.studentId}',
          'date': dateStr,
          'target_id': student.studentId,
          'target_name': student.name,
          'grade': widget.grade,
          'stream': widget.stream,
          'status': attendanceStatus[student.studentId]!,
          'target_type': 'Student',
        });
      }
      await SupabaseService.instance.markAttendance(records);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Attendance Records Saved Successfully', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.teal.shade800,
            behavior: SnackBarBehavior.floating,
          )
        );
        _loadData(); 
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Student Attendance', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.teal.shade900, Colors.teal.shade500], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.fingerprint_rounded, size: 140, color: Colors.white.withOpacity(0.1)))]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
            onPressed: () async {
              final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2023), lastDate: DateTime.now());
              if (picked != null) {
                setState(() => selectedDate = picked);
                _loadData();
              }
            },
          )
        ],
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.teal))
            : students.isEmpty 
              ? _buildEmptyState()
              : Column(
                children: [
                  SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
                  _buildHeaderPanel(theme, gemini),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final s = students[index];
                        final isPresent = attendanceStatus[s.studentId] == 'Present';
                        final content = ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: isPresent ? Colors.teal.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            child: Text(s.name[0], style: TextStyle(color: isPresent ? Colors.teal : Colors.red, fontWeight: FontWeight.w900, fontSize: 18)),
                          ),
                          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                          subtitle: Text('ADM: ${s.admissionNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          trailing: Switch.adaptive(
                            value: isPresent,
                            activeColor: Colors.teal,
                            onChanged: (val) => setState(() => attendanceStatus[s.studentId] = val ? 'Present' : 'Absent'),
                          ),
                        );
                        return Padding(padding: const EdgeInsets.only(bottom: 12), child: gemini?.buildGlowContainer(borderRadius: 24, borderThickness: 1, backgroundColor: theme.cardColor.withOpacity(0.85), padding: EdgeInsets.zero, child: content) ?? Card(child: content));
                      },
                    ),
                  ),
                  _buildSyncButton(theme, gemini),
                ],
              ),
      ),
    );
  }

  Widget _buildHeaderPanel(ThemeData theme, GeminiThemeExtension? gemini) {
    int present = attendanceStatus.values.where((v) => v == 'Present').length;
    final content = Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(DateFormat('EEEE, MMM d').format(selectedDate).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)), const SizedBox(height: 2), Text('${widget.grade} • ${widget.stream}', style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade400, fontWeight: FontWeight.w900, letterSpacing: 0.5))]),
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text('$present / ${students.length} MARKED', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1))),
    ]);
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: gemini?.buildGlowContainer(borderRadius: 24, borderThickness: 1.5, backgroundColor: theme.cardColor.withOpacity(0.9), padding: const EdgeInsets.all(20), child: content) ?? Card(child: content));
  }

  Widget _buildSyncButton(ThemeData theme, GeminiThemeExtension? gemini) {
    return Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 40), child: SizedBox(width: double.infinity, height: 60, child: ElevatedButton(onPressed: isSaving ? null : _saveAttendance, style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 8), child: Text(isSaving ? 'SAVING RECORDS...' : 'SAVE ATTENDANCE', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)))));
  }

  Widget _buildEmptyState() => const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.person_off_rounded, size: 80, color: Colors.grey), SizedBox(height: 16), Text('NO STUDENTS FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5))]));
}
