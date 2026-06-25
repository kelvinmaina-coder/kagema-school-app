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
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final isDark = context.isDark;
    final roleColor = RoleColors.of(widget.userRole);
    final compColor = RoleColors.complement(widget.userRole);
    final bool canEdit = ['admin', 'secretary'].contains(widget.userRole.toLowerCase());

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: Text(currentStudent.name.toUpperCase(), 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2, color: Colors.white)
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
            gradient: RoleColors.gradient(widget.userRole, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
        ),
        actions: canEdit ? [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white), 
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentRegistrationScreen(studentToEdit: currentStudent)))
          )
        ] : null,
      ),
      body: theme?.buildCreativeBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20, 
              left: 20, right: 20, bottom: 40
            ),
            child: Column(
              children: [
                _buildProfileHeader(dt, theme, roleColor),
                const SizedBox(height: 32),
                _buildVitalsRow(dt, theme),
                const SizedBox(height: 48),
                _buildInfoSection(dt, theme, 'ACADEMIC IDENTITY', roleColor, [
                  _infoRow(dt, Icons.badge_outlined, 'Admission No', currentStudent.admissionNumber),
                  _infoRow(dt, Icons.school_outlined, 'Current Grade', currentStudent.grade),
                  _infoRow(dt, Icons.grid_view_rounded, 'Class Stream', currentStudent.stream),
                ]),
                const SizedBox(height: 32),
                _buildInfoSection(dt, theme, 'BIOMETRIC DATA', roleColor, [
                  _infoRow(dt, Icons.person_outline, 'Gender', currentStudent.gender),
                  _infoRow(dt, Icons.cake_outlined, 'Date of Birth', currentStudent.dateOfBirth),
                  _infoRow(dt, Icons.history_rounded, 'Calculated Age', '${currentStudent.age} Years'),
                ]),
                const SizedBox(height: 140),
              ],
            ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildVitalsRow(DT dt, GeminiThemeExtension? theme) {
    return Row(
      children: [
        _vitalItem(dt, theme, 'Presence', '${_attendance.toInt()}%', KagemaColors.azure),
        const SizedBox(width: 12),
        _vitalItem(dt, theme, 'Arrears', 'Ksh ${_balance.toInt()}', _balance > 0 ? KagemaColors.parentRed : KagemaColors.teacherGreen),
        const SizedBox(width: 12),
        _vitalItem(dt, theme, 'Proficiency', '${_avgGrade.toInt()}%', KagemaColors.accountantAmber),
      ],
    );
  }

  Widget _vitalItem(DT dt, GeminiThemeExtension? theme, String l, String v, Color c) {
    return Expanded(
      child: theme?.buildGlowContainer(
        accentColor: c,
        borderRadius: 22,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Column(
          children: [
            Text(v, style: TextStyle(fontWeight: FontWeight.w900, color: c, fontSize: 16, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(l.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 1))
          ]
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildProfileHeader(DT dt, GeminiThemeExtension? theme, Color roleColor) {
    return theme?.buildGlowContainer(
      accentColor: roleColor,
      borderRadius: 40,
      padding: const EdgeInsets.all(32),
      useAIBorder: true,
      child: Column(
        children: [
          RolePlasma(
            color: roleColor,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2)),
              child: CircleAvatar(
                radius: 46, 
                backgroundColor: Colors.white.withValues(alpha: 0.15), 
                child: Text(currentStudent.name[0].toUpperCase(), style: const TextStyle(fontSize: 42, color: Colors.white, fontWeight: FontWeight.w900))
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(currentStudent.name.toUpperCase(), 
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1), 
            textAlign: TextAlign.center
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text('NEURAL NODE: ${currentStudent.studentId.substring(0, 8).toUpperCase()}', 
              style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)
            ),
          ),
        ],
      ),
    ) ?? const SizedBox.shrink();
  }

  Widget _buildInfoSection(DT dt, GeminiThemeExtension? theme, String title, Color roleColor, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 16), 
          child: Row(
            children: [
              Container(width: 4, height: 14, decoration: BoxDecoration(color: roleColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textSecondary, letterSpacing: 2.5)),
            ],
          )
        ),
        theme?.buildGlowContainer(
          accentColor: roleColor,
          borderRadius: 32,
          padding: const EdgeInsets.all(12),
          child: Column(children: rows),
        ) ?? const SizedBox.shrink(),
      ],
    );
  }

  Widget _infoRow(DT dt, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), 
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: dt.surfaceBg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: dt.iconInactive),
          ),
          const SizedBox(width: 16),
          Text(label, style: TextStyle(color: dt.textMuted, fontSize: 13, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(value.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: dt.textPrimary, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
