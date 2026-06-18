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
      'admission_date': isEditing ? widget.studentToEdit?.admissionDate : DateFormat('yyyy-MM-dd').format(DateTime.now()),
      if (isEditing) 'parent_id': widget.studentToEdit?.parentId,
    };

    try {
      await OfflineDbService.instance.saveStudentLocal(studentData);
      await SupabaseService.instance.saveStudent(studentData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Student details updated successfully!' : 'Student registered successfully!'), 
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (e == "OFFLINE_QUEUED") {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Working Offline: Record saved locally.'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
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
        title: Text(isEditing ? 'EDIT STUDENT' : 'STUDENT REGISTRATION', 
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white, fontSize: 16)
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
              colors: [theme.primaryColor, Colors.indigo.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.person_add_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildFormContainer(theme, gemini),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _enrollStudent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                        shadowColor: theme.primaryColor.withOpacity(0.5),
                      ),
                      child: _isSaving 
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) 
                        : Text(isEditing ? 'UPDATE DETAILS' : 'CONFIRM REGISTRATION', 
                            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
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

  Widget _buildFormContainer(ThemeData theme, GeminiThemeExtension? gemini) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STUDENT INFORMATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)),
        const SizedBox(height: 24),
        _buildField(theme, _nameController, 'Full Name', Icons.person_outline),
        const SizedBox(height: 20),
        _buildField(theme, _admController, 'Admission Number', Icons.badge_outlined),
        const SizedBox(height: 20),
        
        InkWell(
          onTap: _pickDob,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.cake_outlined, color: theme.primaryColor, size: 20),
                const SizedBox(width: 12),
                Text(_selectedDob == null ? 'Select Birth Date' : DateFormat('MMM dd, yyyy').format(_selectedDob!),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_selectedDob != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('${DateTime.now().year - _selectedDob!.year} YRS', 
                      style: TextStyle(fontWeight: FontWeight.w900, color: theme.primaryColor, fontSize: 10)),
                  ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        Text('GUARDIAN INFORMATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)),
        const SizedBox(height: 24),
        _buildField(theme, _parentNameController, 'Guardian Name', Icons.family_restroom_outlined),
        const SizedBox(height: 20),
        _buildField(theme, _parentPhoneController, 'Contact Number', Icons.phone_outlined, keyboardType: TextInputType.phone),

        const SizedBox(height: 32),
        const Divider(color: Colors.white10),
        const SizedBox(height: 24),
        _buildDropdowns(theme),
      ],
    );

    return gemini?.buildGlowContainer(
      borderRadius: 30,
      borderThickness: 1.5,
      backgroundColor: theme.cardColor.withOpacity(0.9),
      padding: const EdgeInsets.all(24),
      child: content,
    ) ?? Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(30)),
      child: content,
    );
  }

  Widget _buildField(ThemeData theme, TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(icon, color: theme.primaryColor, size: 20),
        filled: true,
        fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
      validator: (v) => v!.isEmpty ? 'Field required' : null,
    );
  }

  Widget _buildDropdowns(ThemeData theme) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedGrade,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
          items: ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'JSS 1', 'JSS 2', 'JSS 3']
              .map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: (v) => setState(() => _selectedGrade = v!),
          decoration: _inputDecoration('Grade', Icons.school_outlined, theme),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _selectedStream,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
          items: ['North', 'South', 'East', 'West'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _selectedStream = v!),
          decoration: _inputDecoration('Stream', Icons.grid_view_rounded, theme),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, ThemeData theme) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      prefixIcon: Icon(icon, color: theme.primaryColor, size: 20),
      filled: true,
      fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
    );
  }
}
