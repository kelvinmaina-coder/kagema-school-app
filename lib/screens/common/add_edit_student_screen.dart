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
        const SnackBar(content: Text('Please select Grade and Stream'), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final studentData = {
        'studentId': widget.student?.studentId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _nameController.text.trim(),
        'admissionNumber': _admController.text.trim(),
        'grade': selectedGrade!,
        'stream': selectedStream!,
        'parentPhone': _parentPhoneController.text.trim(),
        'parentName': _parentNameController.text.trim(),
        'parentEmail': widget.student?.parentEmail ?? '',
        'address': widget.student?.address ?? '',
        'dateOfBirth': _dobController.text.trim(),
        'status': 'Active',
        'medicalInfo': widget.student?.medicalInfo ?? 'N/A',
      };

      // Call Supabase Cloud Service
      await SupabaseService.instance.saveStudentWithParent(studentData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.student == null ? 'Student Enrolled in Cloud' : 'Cloud Record Updated'),
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(themeColor),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('STUDENT IDENTIFICATION'),
                      _buildFormCard([
                        _buildModernTextField(
                          controller: _nameController,
                          label: 'Student Full Name',
                          icon: Icons.person_outline_rounded,
                          color: themeColor,
                        ),
                        _buildModernTextField(
                          controller: _admController,
                          label: 'Admission Number',
                          icon: Icons.badge_outlined,
                          color: themeColor,
                        ),
                        Row(
                          children: [
                            Expanded(child: _buildModernDropdown('Grade', grades, selectedGrade, (v) => setState(() => selectedGrade = v), themeColor)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildModernDropdown('Stream', streams, selectedStream, (v) => setState(() => selectedStream = v), themeColor)),
                          ],
                        ),
                        _buildModernTextField(
                          controller: _dobController,
                          label: 'Date of Birth',
                          icon: Icons.calendar_month_outlined,
                          color: themeColor,
                          isReadOnly: true,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _dobController.text = "${picked.day}/${picked.month}/${picked.year}");
                            }
                          },
                        ),
                      ]),
                      
                      const SizedBox(height: 30),
                      _buildSectionHeader('PARENT / GUARDIAN DETAILS'),
                      _buildFormCard([
                        _buildModernTextField(
                          controller: _parentNameController,
                          label: 'Guardian Name',
                          icon: Icons.family_restroom_rounded,
                          color: themeColor,
                        ),
                        _buildModernTextField(
                          controller: _parentPhoneController,
                          label: 'Contact Phone',
                          icon: Icons.phone_android_rounded,
                          color: themeColor,
                          keyboardType: TextInputType.phone,
                        ),
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
                          ),
                          child: _isLoading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(widget.student == null ? 'REGISTER STUDENT' : 'UPDATE RECORD', 
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(Color color) {
    return SliverAppBar(
      expandedHeight: 140.0,
      pinned: true,
      backgroundColor: color,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(widget.student == null ? 'New Enrollment' : 'Edit Student', 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        centerTitle: true,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.2)),
    );
  }

  Widget _buildFormCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    TextInputType? keyboardType,
    bool isReadOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: isReadOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: color, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildModernDropdown(String label, List<String> items, String? val, Function(String?) onChanged, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: val,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        validator: (v) => v == null ? 'Select' : null,
      ),
    );
  }
}
