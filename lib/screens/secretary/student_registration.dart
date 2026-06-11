import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() => _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _admController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  String _selectedGrade = 'Grade 1';
  String _selectedStream = 'North';
  String _selectedGender = 'Male';
  bool _isSaving = false;

  Future<void> _enrollStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final studentData = {
        'name': _nameController.text.trim(),
        'admission_number': _admController.text.trim(),
        'grade': _selectedGrade,
        'stream': _selectedStream,
        'gender': _selectedGender,
        'parent_phone': _parentPhoneController.text.trim(),
        'status': 'Active',
      };

      await SupabaseService.instance.saveStudent(studentData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pupil enrolled successfully to cloud!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('New Admission', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, Colors.indigo]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildFormContainer(theme),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _enrollStudent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 8,
                      ),
                      child: _isSaving 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text('CONFIRM ENROLLMENT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContainer(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Column(
        children: [
          _buildField(_nameController, 'Full Pupil Name', Icons.person),
          const SizedBox(height: 20),
          _buildField(_admController, 'Admission Number', Icons.badge),
          const SizedBox(height: 20),
          _buildField(_parentPhoneController, 'Parent/Guardian Phone', Icons.phone, keyboardType: TextInputType.phone),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          _buildDropdowns(theme),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
      ),
      validator: (v) => v!.isEmpty ? 'Required field' : null,
    );
  }

  Widget _buildDropdowns(ThemeData theme) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedGrade,
          items: ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'JSS 1', 'JSS 2', 'JSS 3']
              .map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: (v) => setState(() => _selectedGrade = v!),
          decoration: InputDecoration(
            labelText: 'Academic Grade',
            prefixIcon: const Icon(Icons.school),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _selectedStream,
          items: ['North', 'South', 'East', 'West'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _selectedStream = v!),
          decoration: InputDecoration(
            labelText: 'Class Stream',
            prefixIcon: const Icon(Icons.grid_view_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }
}
