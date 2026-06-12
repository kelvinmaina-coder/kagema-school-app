import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../services/supabase_service.dart';
import '../../models/school_models.dart';
import '../../app_theme.dart';

class ParentRegistrationScreen extends StatefulWidget {
  final Map<String, dynamic>? parentToEdit;
  const ParentRegistrationScreen({super.key, this.parentToEdit});

  @override
  State<ParentRegistrationScreen> createState() => _ParentRegistrationScreenState();
}

class _ParentRegistrationScreenState extends State<ParentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _occupationController = TextEditingController();
  final _addressController = TextEditingController();

  List<Student> _allStudents = [];
  List<Student> _selectedChildren = [];
  bool _isLoadingStudents = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.parentToEdit != null) {
      _nameController.text = widget.parentToEdit!['name'] ?? '';
      _phoneController.text = widget.parentToEdit!['phone'] ?? '';
      _emailController.text = widget.parentToEdit!['email'] ?? '';
      _occupationController.text = widget.parentToEdit!['occupation'] ?? '';
      _addressController.text = widget.parentToEdit!['address'] ?? '';
    }
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final data = await SupabaseService.instance.getAllStudents();
      setState(() {
        _allStudents = data.map((m) => Student.fromMap(m)).toList();
        if (widget.parentToEdit != null) {
          final parentId = widget.parentToEdit!['parentId'];
          _selectedChildren = _allStudents.where((s) => s.parentId == parentId).toList();
        }
        _isLoadingStudents = false;
      });
    } catch (e) {
      setState(() => _isLoadingStudents = false);
    }
  }

  Future<void> _saveParent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedChildren.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please link at least one child'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final parentId = widget.parentToEdit != null 
          ? widget.parentToEdit!['parentId'] 
          : 'PAR-${const Uuid().v4().substring(0, 8).toUpperCase()}';
      
      final parentData = {
        'parentId': parentId,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'occupation': _occupationController.text.trim(),
        'address': _addressController.text.trim(),
      };

      await SupabaseService.instance.insertParent(parentData);

      // Link children by updating their parentId
      // First, un-link children that were removed (if editing)
      if (widget.parentToEdit != null) {
        final originalChildren = _allStudents.where((s) => s.parentId == parentId).toList();
        for (var child in originalChildren) {
          if (!_selectedChildren.any((s) => s.studentId == child.studentId)) {
            final updatedData = child.toMap();
            updatedData['parentId'] = null;
            await SupabaseService.instance.saveStudent(updatedData);
          }
        }
      }

      for (var child in _selectedChildren) {
        final updatedData = child.toMap();
        updatedData['parentId'] = parentId;
        updatedData['parentName'] = parentData['name'];
        updatedData['parentPhone'] = parentData['phone'];
        await SupabaseService.instance.saveStudent(updatedData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Parent ${widget.parentToEdit != null ? 'updated' : 'registered'} and linked successfully!'), backgroundColor: Colors.green),
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
        title: Text(widget.parentToEdit != null ? 'Update Parent Info' : 'Parent Registration', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.orange.shade800, Colors.deepOrange]),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormContainer(theme),
                  const SizedBox(height: 30),
                  const Text('LINK CHILDREN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  _buildChildrenSelector(theme),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveParent,
                      icon: _isSaving ? const SizedBox.shrink() : const Icon(Icons.how_to_reg_rounded),
                      label: _isSaving 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : Text(widget.parentToEdit != null ? 'UPDATE GUARDIAN INFO' : 'FINALIZE REGISTRATION', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 8,
                      ),
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
          _buildField(_nameController, 'Full Parent Name', Icons.person_outline),
          const SizedBox(height: 20),
          _buildField(_phoneController, 'Phone Number', Icons.phone_android, keyboardType: TextInputType.phone),
          const SizedBox(height: 20),
          _buildField(_emailController, 'Email Address', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 20),
          _buildField(_occupationController, 'Occupation', Icons.work_outline),
          const SizedBox(height: 20),
          _buildField(_addressController, 'Residential Address', Icons.home_outlined),
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
        prefixIcon: Icon(icon, color: Colors.orange.shade800),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
      ),
      validator: (v) => v!.isEmpty ? 'This field is required' : null,
    );
  }

  Widget _buildChildrenSelector(ThemeData theme) {
    if (_isLoadingStudents) return const Center(child: CircularProgressIndicator());
    
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: ListView.builder(
        itemCount: _allStudents.length,
        itemBuilder: (context, index) {
          final student = _allStudents[index];
          final isSelected = _selectedChildren.any((s) => s.studentId == student.studentId);
          return CheckboxListTile(
            title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('ADM: ${student.admissionNumber} • ${student.grade}'),
            value: isSelected,
            activeColor: Colors.orange.shade800,
            onChanged: (val) {
              setState(() {
                if (val!) {
                  _selectedChildren.add(student);
                } else {
                  _selectedChildren.removeWhere((s) => s.studentId == student.studentId);
                }
              });
            },
          );
        },
      ),
    );
  }
}
