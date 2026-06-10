import 'package:flutter/material.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class StudentDetailScreen extends StatefulWidget {
  final Student student;
  final String userRole;

  const StudentDetailScreen({super.key, required this.student, required this.userRole});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  List<Map<String, dynamic>> _attendance = [];
  List<Map<String, dynamic>> _marks = [];
  Map<String, dynamic> _feeBalance = {'required': 0.0, 'paid': 0.0, 'balance': 0.0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllDetails();
  }

  Future<void> _loadAllDetails() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait<dynamic>([
        SupabaseService.instance.getAttendanceForStudent(widget.student.studentId),
        SupabaseService.instance.getAllMarksForStudent(widget.student.studentId),
        SupabaseService.instance.getStudentBalance(widget.student.studentId, widget.student.grade),
      ]);

      if (mounted) {
        setState(() {
          _attendance = List<Map<String, dynamic>>.from(results[0]);
          _marks = List<Map<String, dynamic>>.from(results[1]);
          _feeBalance = results[2] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Student Detail Load Error: $e");
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
        title: Text(widget.student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.only(
                top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20,
                left: 20, right: 20, bottom: 40
              ),
              child: Column(
                children: [
                  _buildProfileHeader(theme),
                  const SizedBox(height: 24),
                  _buildFinancialSummary(theme),
                  const SizedBox(height: 24),
                  _buildStatsRow(theme),
                  const SizedBox(height: 32),
                  _buildInfoSection(theme, 'CONTACT INFORMATION', [
                    _infoTile(Icons.phone, 'Guardian Phone', widget.student.parentPhone),
                    _infoTile(Icons.email, 'Guardian Email', widget.student.parentEmail ?? 'N/A'),
                    _infoTile(Icons.home, 'Home Address', widget.student.address),
                  ]),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            child: Text(widget.student.name[0], style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.primaryColor)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.student.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('ADM: ${widget.student.admissionNumber}', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Chip(
                  label: Text('${widget.student.grade} ${widget.student.stream}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                  backgroundColor: theme.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.shade700, Colors.green.shade400]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('FEE BALANCE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
              Text('Ksh ${_feeBalance['balance']}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
            ],
          ),
          const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 40),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    int present = _attendance.where((a) => a['status'] == 'Present').length;
    double attRate = _attendance.isEmpty ? 0 : (present / _attendance.length) * 100;
    
    return Row(
      children: [
        _statCard(theme, 'Attendance', '${attRate.toInt()}%', Colors.blue),
        const SizedBox(width: 16),
        _statCard(theme, 'Exams Sat', '${_marks.length}', Colors.orange),
      ],
    );
  }

  Widget _statCard(ThemeData theme, String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.primaryColor.withOpacity(0.5), letterSpacing: 1.5)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.9), borderRadius: BorderRadius.circular(24)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String val) {
    return ListTile(
      leading: Icon(icon, size: 20, color: Colors.grey),
      title: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      subtitle: Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
