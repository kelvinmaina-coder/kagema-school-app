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
    setState(() => isLoading = true);
    try {
      final studentMaps = await SupabaseService.instance.getStudentsByClass(widget.grade, widget.stream);
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final history = await SupabaseService.instance.getAttendanceHistory(widget.grade, widget.stream, dateStr);
      
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance Cloud-Synced!'), backgroundColor: Colors.teal));
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
        title: const Text('Daily Roll Call', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.teal.shade800, Colors.teal.shade400]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
              );
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
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10),
                  _buildHeaderPanel(theme),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final s = students[index];
                        final isPresent = attendanceStatus[s.studentId] == 'Present';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isPresent ? Colors.teal.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              child: Text(s.name[0], style: TextStyle(color: isPresent ? Colors.teal : Colors.red, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('ADM: ${s.admissionNumber}'),
                            trailing: Switch.adaptive(
                              value: isPresent,
                              activeColor: Colors.teal,
                              onChanged: (val) => setState(() => attendanceStatus[s.studentId] = val ? 'Present' : 'Absent'),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildSyncButton(theme),
                ],
              ),
      ),
    );
  }

  Widget _buildHeaderPanel(ThemeData theme) {
    int present = attendanceStatus.values.where((v) => v == 'Present').length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.9), borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('EEEE, MMM d').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              Text('${widget.grade} ${widget.stream}', style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text('$present / ${students.length} PRESENT', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w900, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: isSaving ? null : _saveAttendance,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
          ),
          child: Text(isSaving ? 'SYNCING...' : 'AUTHORIZE CLOUD UPLOAD', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
      ),
    );
  }
}
