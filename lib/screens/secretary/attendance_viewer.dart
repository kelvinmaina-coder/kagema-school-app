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
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
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
        title: const Text('Attendance Monitor', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5, color: Colors.white)
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
              colors: [Colors.amber.shade900, Colors.amber.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.verified_user_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
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
              _buildDateHeader(theme, gemini),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                    : _attendanceRecords.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: _attendanceRecords.length,
                            itemBuilder: (context, index) {
                              final r = _attendanceRecords[index];
                              final isPresent = r['status'] == 'Present';
                              final color = isPresent ? Colors.green : Colors.red;
                              
                              final content = ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: color.withOpacity(0.1),
                                  child: Icon(isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color, size: 24),
                                ),
                                title: Text(r['target_name'] ?? 'Student Name', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                                subtitle: Text('Grade: ${r['grade'] ?? "N/A"} • ${r['stream'] ?? "General"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Text(r['status'].toString().toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                                ),
                              );

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: gemini?.buildGlowContainer(
                                  borderRadius: 24,
                                  borderThickness: 1,
                                  backgroundColor: theme.cardColor.withOpacity(0.85),
                                  padding: EdgeInsets.zero,
                                  child: content,
                                ) ?? Card(child: content),
                              );
                            },
                          ),
              ),
              _buildStats(theme, gemini),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader(ThemeData theme, GeminiThemeExtension? gemini) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.event_note_rounded, color: Colors.blueGrey.shade400, size: 20),
            const SizedBox(width: 12),
            Text(DateFormat('EEEE, MMM d, yyyy').format(_selectedDate).toUpperCase(), 
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)
            ),
          ],
        ),
        Text('TOTAL: ${_attendanceRecords.length}', 
          style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: gemini?.buildGlowContainer(
        borderRadius: 20,
        borderThickness: 1.5,
        backgroundColor: theme.cardColor.withOpacity(0.9),
        padding: const EdgeInsets.all(16),
        child: content,
      ) ?? Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20)),
        child: content,
      ),
    );
  }

  Widget _buildStats(ThemeData theme, GeminiThemeExtension? gemini) {
    int present = _attendanceRecords.where((r) => r['status'] == 'Present').length;
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statBit('PRESENT', '$present', Colors.green),
        _statBit('ABSENT', '${_attendanceRecords.length - present}', Colors.red),
      ],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, -10))],
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: content,
    );
  }

  Widget _statBit(String l, String v, Color c) {
    return Column(
      children: [
        Text(v, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: c, letterSpacing: -1)),
        Text(l, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('NO ATTENDANCE RECORDS FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
