import 'package:flutter/material.dart';
import '../../models/school_models.dart';
import '../../app_theme.dart';
import '../../services/supabase_service.dart';
import '../secretary/student_registration.dart';
import 'package:intl/intl.dart';

class StudentDetailScreen extends StatefulWidget {
  final Student student;
  final String userRole;

  const StudentDetailScreen({super.key, required this.student, required this.userRole});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  late Student currentStudent;
  bool _isSyncingVitals = true;
  double _attendance = 0.0;
  double _balance = 0.0;
  double _avgGrade = 0.0;

  @override
  void initState() {
    super.initState();
    currentStudent = widget.student;
    _syncNeuralVitals();
  }

  Future<void> _syncNeuralVitals() async {
    setState(() => _isSyncingVitals = true);
    try {
      final results = await Future.wait([
        SupabaseService.instance.getChildAttendance(currentStudent.studentId),
        SupabaseService.instance.getStudentBalance(currentStudent.studentId, currentStudent.grade),
        SupabaseService.instance.getStudentMarks(currentStudent.studentId),
      ]);
      
      final att = results[0] as List<Map<String, dynamic>>;
      final balData = results[1] as Map<String, dynamic>;
      final marks = results[2] as List<Map<String, dynamic>>;

      if (mounted) {
        setState(() {
          _attendance = att.isEmpty ? 0 : (att.where((a) => a['status'] == 'Present').length / att.length) * 100;
          _balance = (balData['balance'] ?? 0.0).toDouble();
          _avgGrade = marks.isEmpty ? 0 : marks.fold(0.0, (sum, m) => sum + (m['score'] ?? 0)) / marks.length;
          _isSyncingVitals = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSyncingVitals = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final bool canEdit = ['admin', 'secretary'].contains(widget.userRole.toLowerCase());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(currentStudent.name, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        actions: canEdit ? [
          IconButton(icon: const Icon(Icons.edit_note_rounded, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentRegistrationScreen(studentToEdit: currentStudent))))
        ] : null,
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20, left: 20, right: 20, bottom: 40),
          child: Column(
            children: [
              _buildProfileHeader(theme, gemini),
              const SizedBox(height: 32),
              _buildVitalsRow(theme, gemini),
              const SizedBox(height: 32),
              _buildInfoSection(theme, gemini, 'ACADEMIC IDENTITY', [
                _infoRow(Icons.badge_outlined, 'Admission No', currentStudent.admissionNumber),
                _infoRow(Icons.school_outlined, 'Current Grade', currentStudent.grade),
                _infoRow(Icons.grid_view_rounded, 'Class Stream', currentStudent.stream),
              ]),
              const SizedBox(height: 24),
              _buildInfoSection(theme, gemini, 'BIOMETRIC DATA', [
                _infoRow(Icons.person_outline, 'Gender', currentStudent.gender),
                _infoRow(Icons.cake_outlined, 'Date of Birth', currentStudent.dateOfBirth),
                _infoRow(Icons.history_rounded, 'Calculated Age', '${currentStudent.age} Years'),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVitalsRow(ThemeData theme, GeminiThemeExtension? gemini) {
    return Row(
      children: [
        _vitalItem('Presence', '${_attendance.toInt()}%', Colors.teal, gemini),
        const SizedBox(width: 12),
        _vitalItem('Arrears', 'Ksh ${_balance.toInt()}', _balance > 0 ? Colors.red : Colors.green, gemini),
        const SizedBox(width: 12),
        _vitalItem('Proficiency', '${_avgGrade.toInt()}%', Colors.orange, gemini),
      ],
    );
  }

  Widget _vitalItem(String l, String v, Color c, GeminiThemeExtension? gemini) {
    final content = Column(children: [
      Text(v, style: TextStyle(fontWeight: FontWeight.w900, color: c, fontSize: 16)),
      Text(l, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1))
    ]);
    return Expanded(child: gemini?.buildGlowContainer(borderRadius: 20, borderThickness: 1, backgroundColor: Theme.of(context).cardColor.withOpacity(0.9), padding: const EdgeInsets.symmetric(vertical: 16), child: content) ?? Card(child: content));
  }

  Widget _buildProfileHeader(ThemeData theme, GeminiThemeExtension? gemini) {
    final content = Column(
      children: [
        CircleAvatar(radius: 50, backgroundColor: Colors.white24, child: Text(currentStudent.name[0], style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w900))),
        const SizedBox(height: 16),
        Text(currentStudent.name.toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1), textAlign: TextAlign.center),
        Text('NEURAL NODE: ${currentStudent.studentId.substring(0, 8)}', style: const TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 2)),
      ],
    );
    return gemini?.buildGlowContainer(borderRadius: 35, borderThickness: 2, backgroundColor: theme.primaryColor.withOpacity(0.8), padding: const EdgeInsets.all(32), useAIBorder: true, child: content) ?? Container();
  }

  Widget _buildInfoSection(ThemeData theme, GeminiThemeExtension? gemini, String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(left: 8, bottom: 12), child: Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2.5))),
        gemini?.buildGlowContainer(borderRadius: 28, borderThickness: 1, backgroundColor: theme.cardColor.withOpacity(0.85), padding: const EdgeInsets.all(24), child: Column(children: rows)) ?? Card(child: Column(children: rows)),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [Icon(icon, size: 18, color: Colors.blueGrey), const SizedBox(width: 16), Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)), const Spacer(), Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13))]));
  }
}
