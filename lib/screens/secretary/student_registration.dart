import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/offline_db_service.dart';
import '../../models/school_models.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';

class StudentRegistrationScreen extends StatefulWidget {
  final Student? studentToEdit;
  const StudentRegistrationScreen({super.key, this.studentToEdit});

  @override
  State<StudentRegistrationScreen> createState() => _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _admController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentNameController = TextEditingController();
  
  DateTime? _selectedDob;
  String _selectedGrade = 'Grade 1';
  String _selectedStream = 'North';
  String _selectedGender = 'Male';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.studentToEdit != null) {
      final s = widget.studentToEdit!;
      _nameController.text = s.name;
      _admController.text = s.admissionNumber;
      _parentNameController.text = s.parentName;
      _parentPhoneController.text = s.parentPhone;
      _selectedGrade = s.grade;
      _selectedStream = s.stream;
      _selectedGender = s.gender;
      if (s.dateOfBirth.isNotEmpty) {
        try {
          _selectedDob = DateFormat('yyyy-MM-dd').parse(s.dateOfBirth);
        } catch (_) {}
      }
    }
  }

  Future<void> _enrollStudent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Date of Birth')));
      return;
    }

    setState(() => _isSaving = true);
    final isEditing = widget.studentToEdit != null;
    final String studentId = isEditing ? widget.studentToEdit!.studentId : 'STU-${DateTime.now().millisecondsSinceEpoch}';
    
    final studentData = {
      'student_id': studentId,
      'name': _nameController.text.trim(),
      'admission_number': _admController.text.trim(),
      'grade': _selectedGrade,
      'stream': _selectedStream,
      'gender': _selectedGender,
      'date_of_birth': DateFormat('yyyy-MM-dd').format(_selectedDob!),
      'parent_name': _parentNameController.text.trim(),
      'parent_phone': _parentPhoneController.text.trim(),
      'status': widget.studentToEdit?.status ?? 'Active',
      if (isEditing) 'parent_id': widget.studentToEdit?.parentId,
      if (isEditing) 'admission_date': widget.studentToEdit?.admissionDate,
    };

    try {
      // 1. Save Locally Immediately
      await OfflineDbService.instance.saveStudentLocal(studentData);
      
      // 2. Attempt Cloud Sync
      await SupabaseService.instance.saveStudent(studentData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Pupil record updated successfully!' : 'Student registered and cached locally!'), 
            backgroundColor: Colors.green
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (e == "OFFLINE_QUEUED") {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Working Offline: Record saved locally and will sync when online.'), backgroundColor: Colors.orange),
          );
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDob() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime.now().subtract(const Duration(days: 365 * 6)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _selectedDob = date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final isEditing = widget.studentToEdit != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isEditing ? 'Update Profile' : 'New Admission', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        : Text(isEditing ? 'UPDATE PUPIL DATA' : 'CONFIRM ENROLLMENT', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BASIC INFORMATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          _buildField(_nameController, 'Full Pupil Name', Icons.person),
          const SizedBox(height: 20),
          _buildField(_admController, 'Admission Number', Icons.badge),
          const SizedBox(height: 20),
          
          InkWell(
            onTap: _pickDob,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: theme.inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cake_rounded, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(_selectedDob == null ? 'Select Date of Birth' : DateFormat('MMM dd, yyyy').format(_selectedDob!)),
                  const Spacer(),
                  if (_selectedDob != null)
                    Text('Age: ${DateTime.now().year - _selectedDob!.year}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          const Text('PARENT/GUARDIAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          _buildField(_parentNameController, 'Guardian Name', Icons.person_pin),
          const SizedBox(height: 16),
          _buildField(_parentPhoneController, 'Active Phone', Icons.phone, keyboardType: TextInputType.phone),

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
