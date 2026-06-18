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
          final parentId = widget.parentToEdit!['parent_id'] ?? widget.parentToEdit!['parentId'];
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
        SnackBar(
          content: const Text('Selection Required: Link at least one student', style: TextStyle(fontWeight: FontWeight.bold)), 
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final parentId = widget.parentToEdit != null 
          ? (widget.parentToEdit!['parent_id'] ?? widget.parentToEdit!['parentId'])
          : 'PAR-${const Uuid().v4().substring(0, 8).toUpperCase()}';
      
      final parentData = {
        'parent_id': parentId, 
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'occupation': _occupationController.text.trim(),
        'address': _addressController.text.trim(),
      };

      await SupabaseService.instance.insertParent(parentData);

      // Unlink removed children
      if (widget.parentToEdit != null) {
        final originalChildren = _allStudents.where((s) => s.parentId == parentId).toList();
        for (var child in originalChildren) {
          if (!_selectedChildren.any((s) => s.studentId == child.studentId)) {
            final updatedData = child.toMap();
            updatedData['parent_id'] = null;
            await SupabaseService.instance.saveStudent(updatedData);
          }
        }
      }

      // Link selected children
      for (var child in _selectedChildren) {
        final updatedData = child.toMap();
        updatedData['parent_id'] = parentId;
        updatedData['parent_name'] = parentData['name'];
        updatedData['parent_phone'] = parentData['phone'];
        await SupabaseService.instance.saveStudent(updatedData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Parent Profile ${widget.parentToEdit != null ? 'Updated' : 'Created'} and Linked Successfully!'), 
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
        title: Text(widget.parentToEdit != null ? 'EDIT PARENT' : 'PARENT REGISTRATION', 
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
              colors: [Colors.orange.shade900, Colors.deepOrange.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.family_restroom_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormContainer(theme, gemini),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text('ASSIGN CHILDREN', 
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)
                    ),
                  ),
                  _buildChildrenSelector(theme, gemini),
                  const SizedBox(height: 48),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveParent,
                        icon: _isSaving ? const SizedBox.shrink() : const Icon(Icons.save_rounded),
                        label: _isSaving 
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) 
                          : Text(widget.parentToEdit != null ? 'SAVE CHANGES' : 'COMPLETE REGISTRATION', 
                              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 8,
                          shadowColor: Colors.orange.withOpacity(0.5),
                        ),
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

  Widget _buildFormContainer(ThemeData theme, GeminiThemeExtension? gemini) {
    final content = Column(
      children: [
        _buildField(theme, _nameController, 'Parent Full Name', Icons.person_outline),
        const SizedBox(height: 20),
        _buildField(theme, _phoneController, 'Phone Number', Icons.phone_android_rounded, keyboardType: TextInputType.phone),
        const SizedBox(height: 20),
        _buildField(theme, _emailController, 'Email Address', Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 20),
        _buildField(theme, _occupationController, 'Occupation', Icons.work_outline_rounded),
        const SizedBox(height: 20),
        _buildField(theme, _addressController, 'Home Address', Icons.home_rounded),
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
        prefixIcon: Icon(icon, color: Colors.orange.shade800, size: 20),
        filled: true,
        fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
      validator: (v) => v!.isEmpty ? 'Field required' : null,
    );
  }

  Widget _buildChildrenSelector(ThemeData theme, GeminiThemeExtension? gemini) {
    if (_isLoadingStudents) return const Center(child: CircularProgressIndicator(color: Colors.orange));
    
    final content = SizedBox(
      height: 250,
      child: _allStudents.isEmpty 
        ? const Center(child: Text('NO STUDENTS FOUND', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)))
        : ListView.builder(
            itemCount: _allStudents.length,
            itemBuilder: (context, index) {
              final student = _allStudents[index];
              final isSelected = _selectedChildren.any((s) => s.studentId == student.studentId);
              return CheckboxListTile(
                title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                subtitle: Text('ADM: ${student.admissionNumber} • ${student.grade}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                value: isSelected,
                activeColor: Colors.orange.shade800,
                checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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

    return gemini?.buildGlowContainer(
      borderRadius: 24,
      borderThickness: 1,
      backgroundColor: theme.cardColor.withOpacity(0.85),
      padding: EdgeInsets.zero,
      child: content,
    ) ?? Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.shade100.withOpacity(0.2)),
      ),
      child: content,
    );
  }
}
