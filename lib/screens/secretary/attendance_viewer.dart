import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
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
    final db = await DatabaseService.instance.database;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    
    final records = await db.query('attendance', where: 'date = ? AND targetType = "Student"', whereArgs: [dateStr]);
    
    if (mounted) {
      setState(() {
        _attendanceRecords = records;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Attendance Monitoring'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.amber.shade700, Colors.amber.shade500]),
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
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Date: ${DateFormat('EEE, MMM d, yyyy').format(_selectedDate)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Records: ${_attendanceRecords.length}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _attendanceRecords.isEmpty
                        ? const Center(child: Text('No attendance records for this date.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _attendanceRecords.length,
                            itemBuilder: (context, index) {
                              final r = _attendanceRecords[index];
                              final isPresent = r['status'] == 'Present';
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isPresent ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                    child: Icon(isPresent ? Icons.check : Icons.close, color: isPresent ? Colors.green : Colors.red),
                                  ),
                                  title: Text(r['targetName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Status: ${r['status']} • ${r['grade'] ?? ""} ${r['stream'] ?? ""}'),
                                  trailing: Text(r['time'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ),
                              );
                            },
                          ),
              ),
              _buildSummarySection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(ThemeData theme) {
    int present = _attendanceRecords.where((r) => r['status'] == 'Present').length;
    int absent = _attendanceRecords.where((r) => r['status'] == 'Absent').length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Present', '$present', Colors.green),
          _summaryItem('Absent', '$absent', Colors.red),
          _summaryItem('Total', '${_attendanceRecords.length}', Colors.blue),
        ],
      ),
    );
  }

  Widget _summaryItem(String l, String v, Color c) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(v, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: c)),
        Text(l, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
