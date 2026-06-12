import 'package:flutter/material.dart';
import '../../models/school_models.dart';
import '../../app_theme.dart';
import '../../services/supabase_service.dart';
import '../secretary/student_registration.dart';

class StudentDetailScreen extends StatefulWidget {
  final Student student;
  final String userRole;

  const StudentDetailScreen({super.key, required this.student, required this.userRole});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  late Student currentStudent;

  @override
  void initState() {
    super.initState();
    currentStudent = widget.student;
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to remove ${currentStudent.name} from the system? This action is irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('DELETE', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.instance.deleteStudent(currentStudent.studentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student record deleted permanently.')));
          Navigator.pop(context, true); // Return true to indicate refresh needed
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  Future<void> _handleEdit() async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => StudentRegistrationScreen(studentToEdit: currentStudent))
    );
    
    if (result == true) {
      // Reload student data - for simplicity we just pop back to list to refresh everything
      Navigator.pop(context, true);
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
        title: Text(currentStudent.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: canEdit ? [
          IconButton(icon: const Icon(Icons.edit_note_rounded), onPressed: _handleEdit),
          IconButton(icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent), onPressed: _handleDelete),
        ] : null,
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
                _infoRow(Icons.badge_outlined, 'Admission No', currentStudent.admissionNumber),
                _infoRow(Icons.school_outlined, 'Current Grade', currentStudent.grade),
                _infoRow(Icons.grid_view_rounded, 'Class Stream', currentStudent.stream),
              ]),
              const SizedBox(height: 20),
              _buildInfoSection(theme, 'BIOMETRIC DATA', [
                _infoRow(Icons.person_outline, 'Gender', currentStudent.gender),
                _infoRow(Icons.cake_outlined, 'Date of Birth', currentStudent.dateOfBirth),
                _infoRow(Icons.history_rounded, 'Calculated Age', '${currentStudent.age} Years'),
              ]),
              const SizedBox(height: 20),
              _buildInfoSection(theme, 'EMERGENCY CONTACTS', [
                _infoRow(Icons.family_restroom_outlined, 'Guardian', currentStudent.parentName),
                _infoRow(Icons.phone_outlined, 'Contact', currentStudent.parentPhone),
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
      width: double.infinity,
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
            child: Text(currentStudent.name[0], style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Text(currentStudent.name.toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
            child: Text('STATUS: ${currentStudent.status.toUpperCase()}', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
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
