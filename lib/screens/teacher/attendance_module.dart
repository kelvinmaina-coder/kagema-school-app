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
      // FIXED: Use the correct method name from SupabaseService
      final history = await SupabaseService.instance.getAttendanceHistory(widget.grade, widget.stream, dateStr);
      
      setState(() {
        students = studentMaps.map((m) => Student.fromMap(m)).toList();
        attendanceStatus.clear();
        
        for (var s in students) {
          attendanceStatus[s.studentId] = 'Present';
        }
        
        for (var record in history) {
          final id = record['target_id']?.toString() ?? '';
          if (id.isNotEmpty) {
            attendanceStatus[id] = record['status'];
          }
        }
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading attendance: $e");
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
          'term': 'Term 3', 
          'year': selectedDate.year,
        });
      }
      
      await SupabaseService.instance.markAttendance(records);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance Synced to Cloud!'), backgroundColor: Colors.green),
        );
        _loadData(); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
              );
              if (picked != null && picked != selectedDate) {
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
                  _buildHeader(),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final s = students[index];
                        final isPresent = attendanceStatus[s.studentId] == 'Present';
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Text(s.name[0])),
                            title: Text(s.name),
                            subtitle: Text('ADM: ${s.admissionNumber}'),
                            trailing: Switch(
                              value: isPresent,
                              activeColor: Colors.green,
                              inactiveTrackColor: Colors.red.shade100,
                              inactiveThumbColor: Colors.red,
                              onChanged: (val) {
                                setState(() {
                                  attendanceStatus[s.studentId] = val ? 'Present' : 'Absent';
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _saveAttendance,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                        child: Text(isSaving ? 'SYNCING...' : 'SYNC ATTENDANCE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  )
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.teal.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(DateFormat('EEEE, MMM d, yyyy').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Present: ${attendanceStatus.values.where((v) => v == 'Present').length} / ${students.length}'),
        ],
      ),
    );
  }
}
