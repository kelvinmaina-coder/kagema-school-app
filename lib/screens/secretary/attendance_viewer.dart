import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class AttendanceViewerScreen extends StatefulWidget {
  const AttendanceViewerScreen({super.key});

  @override
  State<AttendanceViewerScreen> createState() => _AttendanceViewerScreenState();
}

class _AttendanceViewerScreenState extends State<AttendanceViewerScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      // Fetches school-wide records from Supabase
      final records = await SupabaseService.instance.getGlobalAttendanceByDate(dateStr);
      
      if (mounted) {
        setState(() {
          _attendanceRecords = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Attendance Viewer Error: $e");
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
        title: const Text('Attendance Monitor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.amber.shade800, Colors.amber.shade500]),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                _loadAttendance();
              }
            },
          ),
        ],
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Padding(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('EEE, MMM d, yyyy').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Total: ${_attendanceRecords.length}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _attendanceRecords.isEmpty
                        ? const Center(child: Text('No cloud records found for this date.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _attendanceRecords.length,
                            itemBuilder: (context, index) {
                              final r = _attendanceRecords[index];
                              final isPresent = r['status'] == 'Present';
                              return Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isPresent ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                    child: Icon(isPresent ? Icons.check : Icons.close, color: isPresent ? Colors.green : Colors.red),
                                  ),
                                  title: Text(r['target_name'] ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Status: ${r['status']} • Grade: ${r['grade'] ?? "N/A"}'),
                                ),
                              );
                            },
                          ),
              ),
              _buildStats(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats(ThemeData theme) {
    int present = _attendanceRecords.where((r) => r['status'] == 'Present').length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('Present', '$present', Colors.green),
          _stat('Absent', '${_attendanceRecords.length - present}', Colors.red),
        ],
      ),
    );
  }

  Widget _stat(String l, String v, Color c) {
    return Column(children: [Text(v, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c)), Text(l, style: const TextStyle(fontSize: 10, color: Colors.grey))]);
  }
}
