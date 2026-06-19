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
  final String _roleId = 'secretary';

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
    final dt = context.dt;
    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Please select Date of Birth'), backgroundColor: dt.error));
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
            content: Text(isEditing ? 'Student details updated successfully!' : 'Student registered successfully!', style: const TextStyle(fontWeight: FontWeight.w700)), 
            backgroundColor: dt.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (e == "OFFLINE_QUEUED") {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Working Offline: Record saved locally.', style: TextStyle(fontWeight: FontWeight.w700)), backgroundColor: dt.warning, behavior: SnackBarBehavior.floating),
          );
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync Error: $e'), backgroundColor: dt.error));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDob() async {
    final dt = context.dt;
    final roleColor = RoleColors.of(_roleId);
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime.now().subtract(const Duration(days: 365 * 6)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: roleColor,
            onPrimary: Colors.white,
            surface: dt.cardBg,
            onSurface: dt.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDob = date);
  }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final isDark = context.isDark;
    final roleColor = RoleColors.of(_roleId);
    final compColor = RoleColors.complement(_roleId);
    final isEditing = widget.studentToEdit != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: Text(isEditing ? 'EDIT STUDENT' : 'STUDENT REGISTRATION', 
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, color: Colors.white, fontSize: 16)
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
            gradient: RoleColors.gradient(_roleId, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.person_add_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ),
      ),
      body: theme?.buildCreativeBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildFormContainer(dt, theme, roleColor),
                    const SizedBox(height: 40),
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: roleColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _enrollStudent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: roleColor,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSaving 
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) 
                          : Text(isEditing ? 'UPDATE DETAILS' : 'CONFIRM REGISTRATION', 
                              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildFormContainer(DT dt, GeminiThemeExtension? theme, Color roleColor) {
    return theme?.buildGlowContainer(
      accentColor: KagemaColors.staffSky,
      borderRadius: 30,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STUDENT INFORMATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
          const SizedBox(height: 24),
          _buildField(dt, _nameController, 'Full Name', Icons.person_outline),
          const SizedBox(height: 20),
          _buildField(dt, _admController, 'Admission Number', Icons.badge_outlined),
          const SizedBox(height: 20),
          
          InkWell(
            onTap: _pickDob,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: dt.inputBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: dt.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.cake_outlined, color: roleColor, size: 20),
                  const SizedBox(width: 12),
                  Text(_selectedDob == null ? 'Select Birth Date' : DateFormat('MMM dd, yyyy').format(_selectedDob!),
                    style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary)),
                  const Spacer(),
                  if (_selectedDob != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: dt.roleSoftBg(roleColor), borderRadius: BorderRadius.circular(8)),
                      child: Text('${DateTime.now().year - _selectedDob!.year} YRS', 
                        style: TextStyle(fontWeight: FontWeight.w900, color: roleColor, fontSize: 10)),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          Text('GUARDIAN INFORMATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
          const SizedBox(height: 24),
          _buildField(dt, _parentNameController, 'Guardian Name', Icons.family_restroom_outlined),
          const SizedBox(height: 20),
          _buildField(dt, _parentPhoneController, 'Contact Number', Icons.phone_outlined, keyboardType: TextInputType.phone),

          const SizedBox(height: 32),
          Divider(color: dt.divider),
          const SizedBox(height: 24),
          _buildDropdowns(dt, roleColor),
        ],
      ),
    ) ?? const SizedBox.shrink();
  }

  Widget _buildField(DT dt, TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: KagemaColors.staffSky, size: 20),
      ),
      validator: (v) => v!.isEmpty ? 'Field required' : null,
    );
  }

  Widget _buildDropdowns(DT dt, Color roleColor) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedGrade,
          dropdownColor: dt.cardBg,
          style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
          items: ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'JSS 1', 'JSS 2', 'JSS 3']
              .map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: (v) => setState(() => _selectedGrade = v!),
          decoration: _inputDecoration('Grade', Icons.school_outlined, dt),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _selectedStream,
          dropdownColor: dt.cardBg,
          style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
          items: ['North', 'South', 'East', 'West'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _selectedStream = v!),
          decoration: _inputDecoration('Stream', Icons.grid_view_rounded, dt),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, DT dt) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: KagemaColors.staffSky, size: 20),
    );
  }
}
