import 'package:flutter/material.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class AddEditStudentScreen extends StatefulWidget {
  final Student? student;
  const AddEditStudentScreen({super.key, this.student});

  @override
  State<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _admController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _dobController = TextEditingController();
  
  String? selectedGrade;
  String? selectedStream;
  bool _isLoading = false;

  final List<String> grades = ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7 - JSS', 'Grade 8 - JSS', 'Grade 9 - JSS'];
  final List<String> streams = ['North', 'East', 'West', 'South', 'Stream A', 'Stream B', 'Stream C'];

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      _nameController.text = widget.student!.name;
      _admController.text = widget.student!.admissionNumber;
      _parentPhoneController.text = widget.student!.parentPhone;
      _parentNameController.text = widget.student!.parentName;
      _dobController.text = widget.student!.dateOfBirth;
      selectedGrade = widget.student!.grade;
      selectedStream = widget.student!.stream;
    } else {
      _dobController.text = '01/01/2015';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (selectedGrade == null || selectedStream == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identity required: Select Grade and Stream')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final studentData = {
        'student_id': widget.student?.studentId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _nameController.text.trim(),
        'admission_number': _admController.text.trim(),
        'grade': selectedGrade!,
        'stream': selectedStream!,
        'parent_phone': _parentPhoneController.text.trim(),
        'parent_name': _parentNameController.text.trim(),
        'date_of_birth': _dobController.text.trim(),
        'status': 'Active',
      };

      await SupabaseService.instance.saveStudent(studentData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.student == null ? 'Pupil enrolled in cloud' : 'Cloud record updated'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          )
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cloud Sync Error: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    const Color themeColor = Color(0xFF009688);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.student == null ? 'New Enrollment' : 'Edit Pupil', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [themeColor, themeColor.withOpacity(0.7)]),
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
                  _buildFormCard(theme, [
                    const Text('STUDENT IDENTIFICATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
                    const SizedBox(height: 20),
                    _buildModernField(_nameController, 'Full Pupil Name', Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildModernField(_admController, 'Admission Number', Icons.badge_outlined),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildModernDropdown('Grade', grades, selectedGrade, (v) => setState(() => selectedGrade = v))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildModernDropdown('Stream', streams, selectedStream, (v) => setState(() => selectedStream = v))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    const Text('PARENT / GUARDIAN DATA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
                    const SizedBox(height: 20),
                    _buildModernField(_parentNameController, 'Guardian Name', Icons.family_restroom_rounded),
                    const SizedBox(height: 16),
                    _buildModernField(_parentPhoneController, 'Contact Number', Icons.phone_android_rounded, keyboardType: TextInputType.phone),
                  ]),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 5,
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : Text(widget.student == null ? 'INITIALIZE ENROLLMENT' : 'UPDATE CLOUD RECORD', 
                            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
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

  Widget _buildFormCard(ThemeData theme, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildModernField(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildModernDropdown(String label, List<String> items, String? val, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: val,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
      onChanged: onChanged,
    );
  }
}
