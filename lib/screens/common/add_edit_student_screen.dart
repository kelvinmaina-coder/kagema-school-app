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
        SnackBar(
          content: const Text('Neural Conflict: Select Grade and Stream', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        )
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final studentData = {
        'student_id': widget.student?.studentId ?? 'STU-${DateTime.now().millisecondsSinceEpoch}',
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
            content: Text(widget.student == null ? 'Neural Identity Registered' : 'Quantum Matrix Updated'),
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
          )
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cloud Sync Aborted: $e'), backgroundColor: Colors.red)
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
        title: Text(widget.student == null ? 'NEURAL ONBOARDING' : 'MODIFY IDENTITY', 
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
              colors: [themeColor, Colors.indigo.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: themeColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
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
                  _buildFormCard(theme, gemini, [
                    Text('PUPIL INTEL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)),
                    const SizedBox(height: 24),
                    _buildNeuralField(_nameController, 'Full Legal Identity', Icons.person_outline_rounded, theme),
                    const SizedBox(height: 20),
                    _buildNeuralField(_admController, 'Admission Identifier', Icons.badge_outlined, theme),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildNeuralDropdown('Grade', grades, selectedGrade, (v) => setState(() => selectedGrade = v), theme)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildNeuralDropdown('Stream', streams, selectedStream, (v) => setState(() => selectedStream = v), theme)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 24),
                    Text('GUARDIAN NEXUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)),
                    const SizedBox(height: 24),
                    _buildNeuralField(_parentNameController, 'Guardian Identity', Icons.family_restroom_rounded, theme),
                    const SizedBox(height: 20),
                    _buildNeuralField(_parentPhoneController, 'Neural Contact', Icons.phone_android_rounded, theme, keyboardType: TextInputType.phone),
                  ]),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                        shadowColor: themeColor.withOpacity(0.5),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) 
                        : Text(widget.student == null ? 'AUTHORIZE ENROLLMENT' : 'COMMIT MATRIX UPDATES', 
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

  Widget _buildFormCard(ThemeData theme, GeminiThemeExtension? gemini, List<Widget> children) {
    return gemini?.buildGlowContainer(
      borderRadius: 30,
      borderThickness: 1.5,
      backgroundColor: theme.cardColor.withOpacity(0.9),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ) ?? Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildNeuralField(TextEditingController ctrl, String label, IconData icon, ThemeData theme, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF009688), size: 20),
        filled: true,
        fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
      validator: (v) => v!.isEmpty ? 'Neural entry required' : null,
    );
  }

  Widget _buildNeuralDropdown(String label, List<String> items, String? val, Function(String?) onChanged, ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: val,
      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
      decoration: InputDecoration(
        labelText: label, 
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 11),
        filled: true,
        fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
      onChanged: onChanged,
    );
  }
}
