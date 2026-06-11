import 'package:flutter/material.dart';
import '../../models/school_models.dart';
import '../../app_theme.dart';

class StudentDetailScreen extends StatelessWidget {
  final Student student;
  final String userRole;

  const StudentDetailScreen({super.key, required this.student, required this.userRole});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20,
            left: 20, right: 20, bottom: 40
          ),
          child: Column(
            children: [
              _buildProfileHeader(theme),
              const SizedBox(height: 24),
              _buildInfoSection(theme, 'ACADEMIC IDENTITY', [
                _infoRow(Icons.badge_outlined, 'Admission No', student.admissionNumber),
                _infoRow(Icons.school_outlined, 'Current Grade', student.grade),
                _infoRow(Icons.grid_view_rounded, 'Class Stream', student.stream),
              ]),
              const SizedBox(height: 20),
              _buildInfoSection(theme, 'BIOMETRIC DATA', [
                _infoRow(Icons.person_outline, 'Gender', student.gender),
                _infoRow(Icons.cake_outlined, 'Date of Birth', student.dateOfBirth),
              ]),
              const SizedBox(height: 20),
              _buildInfoSection(theme, 'EMERGENCY CONTACTS', [
                _infoRow(Icons.family_restroom_outlined, 'Guardian', student.parentName),
                _infoRow(Icons.phone_outlined, 'Contact', student.parentPhone),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 20)],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white24,
            child: Text(student.name[0], style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Text(student.name.toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
          Text('STATUS: ${student.status.toUpperCase()}', style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme, String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.primaryColor.withOpacity(0.5), letterSpacing: 2)),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.9), borderRadius: BorderRadius.circular(24)),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
