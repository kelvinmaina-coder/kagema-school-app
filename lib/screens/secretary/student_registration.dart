import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class StudentRegistrationScreen extends StatefulWidget {
  final Student? studentToEdit;
  const StudentRegistrationScreen({super.key, this.studentToEdit});

  @override
  State<StudentRegistrationScreen> createState() => _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isSaving = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _admController;
  late TextEditingController _dobController;
  late TextEditingController _parentNameController;
  late TextEditingController _parentPhoneController;
  late TextEditingController _parentEmailController;
  late TextEditingController _addressController;
  String? selectedGrade;
  String? selectedStream;
  String? selectedGender;
  String studentStatus = 'Active';

  final List<String> grades = ['PP1', 'PP2', 'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'JSS 1', 'JSS 2', 'JSS 3'];
  final List<String> streams = ['A', 'B', 'C', 'North', 'East', 'West', 'South'];

  @override
  void initState() {
    super.initState();
    final s = widget.studentToEdit;
    _nameController = TextEditingController(text: s?.name);
    _admController = TextEditingController(text: s?.admissionNumber ?? _generateAdm());
    _dobController = TextEditingController(text: s?.dateOfBirth);
    _parentNameController = TextEditingController(text: s?.parentName);
    _parentPhoneController = TextEditingController(text: s?.parentPhone);
    _parentEmailController = TextEditingController(text: s?.parentEmail);
    _addressController = TextEditingController(text: s?.address);
    selectedGrade = s?.grade;
    selectedStream = s?.stream;
    selectedGender = s?.gender;
    studentStatus = s?.status ?? 'Active';
  }

  String _generateAdm() {
    return 'ADM-${DateFormat('yyyy').format(DateTime.now())}-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedGrade == null || selectedStream == null || selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final studentData = {
        'studentId': widget.studentToEdit?.studentId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'admissionNumber': _admController.text.trim(),
        'name': _nameController.text.trim(),
        'gender': selectedGender!,
        'grade': selectedGrade!,
        'stream': selectedStream!,
        'dateOfBirth': _dobController.text.trim(),
        'parentName': _parentNameController.text.trim(),
        'parentPhone': _parentPhoneController.text.trim(),
        'parentEmail': _parentEmailController.text.trim(),
        'address': _addressController.text.trim(),
        'status': studentStatus,
        'medicalInfo': 'N/A', // Default or add a field for this
      };

      // CALL SUPABASE SERVICE
      await SupabaseService.instance.saveStudentWithParent(studentData);
      
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cloud Sync Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Registration Successful'),
        content: Text(widget.studentToEdit == null ? 'Pupil has been enrolled and synced to cloud.' : 'Record updated successfully.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final Color primaryColor = const Color(0xFFAB47BC);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.studentToEdit == null ? 'New Admission' : 'Edit Pupil Record'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.8)]),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Column(
          children: [
            SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top),
            LinearProgressIndicator(value: (_currentStep + 1) / 2, backgroundColor: Colors.purple.shade50, color: primaryColor),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: _currentStep == 0 ? _buildAcademicStep(primaryColor) : _buildGuardianStep(primaryColor),
                  ),
                ),
              ),
            ),
            _buildFooter(primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicStep(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Student Particulars', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _buildTextField(_nameController, 'Full Name', Icons.person, color),
        _buildTextField(_admController, 'Admission Number', Icons.badge, color),
        Row(
          children: [
            Expanded(child: _buildDropdown('Gender', ['Male', 'Female', 'Other'], selectedGender, (v) => setState(() => selectedGender = v))),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField(_dobController, 'Date of Birth', Icons.calendar_today, color, isDate: true)),
          ],
        ),
        Row(
          children: [
            Expanded(child: _buildDropdown('Grade', grades, selectedGrade, (v) => setState(() => selectedGrade = v))),
            const SizedBox(width: 12),
            Expanded(child: _buildDropdown('Stream', streams, selectedStream, (v) => setState(() => selectedStream = v))),
          ],
        ),
        if (widget.studentToEdit != null)
          _buildDropdown('Enrollment Status', ['Active', 'Transferred', 'Graduated', 'Suspended'], studentStatus, (v) => setState(() => studentStatus = v!)),
      ],
    );
  }

  Widget _buildGuardianStep(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Guardian Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _buildTextField(_parentNameController, 'Guardian Name', Icons.account_circle, color),
        _buildTextField(_parentPhoneController, 'Phone Number', Icons.phone, color, keyboardType: TextInputType.phone),
        _buildTextField(_parentEmailController, 'Email', Icons.email, color, keyboardType: TextInputType.emailAddress),
        _buildTextField(_addressController, 'Address', Icons.home, color, maxLines: 2),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, Color color, {TextInputType? keyboardType, bool isDate = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: isDate,
        onTap: isDate ? () async {
          final p = await showDatePicker(context: context, initialDate: DateTime.now().subtract(const Duration(days: 365 * 6)), firstDate: DateTime(2000), lastDate: DateTime.now());
          if (p != null) controller.text = DateFormat('yyyy-MM-dd').format(p);
        } : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: color),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.5),
        ),
        validator: (v) => v!.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? val, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: val,
        decoration: InputDecoration(
          labelText: label, 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.5),
        ),
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildFooter(Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Row(
        children: [
          if (_currentStep == 1)
            Expanded(child: OutlinedButton(onPressed: () => setState(() => _currentStep = 0), child: const Text('BACK'))),
          if (_currentStep == 1) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_currentStep == 0) {
                  if (_formKey.currentState!.validate()) setState(() => _currentStep = 1);
                } else {
                  _saveStudent();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, minimumSize: const Size(0, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : Text(_currentStep == 0 ? 'NEXT' : 'SUBMIT'),
            ),
          ),
        ],
      ),
    );
  }
}
