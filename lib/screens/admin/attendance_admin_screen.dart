import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class AttendanceAdminScreen extends StatefulWidget {
  const AttendanceAdminScreen({super.key});

  @override
  State<AttendanceAdminScreen> createState() => _AttendanceAdminScreenState();
}

class _AttendanceAdminScreenState extends State<AttendanceAdminScreen> {
  Map<String, dynamic> _stats = {'present': 0, 'total': 0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendanceStats();
  }

  Future<void> _loadAttendanceStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await SupabaseService.instance.getAttendanceStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Attendance Stats Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    double rate = _stats['total'] == 0 ? 0 : (_stats['present'] / _stats['total']) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Overview'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildSummaryCard(theme, rate),
                  const SizedBox(height: 32),
                  _buildStatRow('Present Today', '${_stats['present']}', Colors.green),
                  const SizedBox(height: 16),
                  _buildStatRow('Total Enrollment', '${_stats['total']}', Colors.blue),
                  const SizedBox(height: 16),
                  _buildStatRow('Absent/Pending', '${_stats['total'] - _stats['present']}', Colors.red),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, double rate) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          const Text('DAILY ATTENDANCE RATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: rate / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.shade200,
                  color: rate > 90 ? Colors.green : Colors.orange,
                ),
              ),
              Text('${rate.toInt()}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
        ],
      ),
    );
  }
}
