import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../services/supabase_service.dart';
import '../../services/offline_db_service.dart';
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
  final String _roleId = 'admin';

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
      if (mounted) {
        setState(() {
          _allStudents = data.map((m) => Student.fromMap(m)).toList();
          if (widget.parentToEdit != null) {
            final parentId = widget.parentToEdit!['parent_id'] ?? widget.parentToEdit!['parentId'];
            _selectedChildren = _allStudents.where((s) => s.parentId == parentId).toList();
          }
          _isLoadingStudents = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStudents = false);
    }
  }

  Future<void> _saveParent() async {
    if (!_formKey.currentState!.validate()) return;
    final dt = context.dt;

    if (_selectedChildren.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selection Required: Link at least one student', style: TextStyle(fontWeight: FontWeight.bold)), 
          backgroundColor: KagemaColors.accountantAmber,
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

      // 1. SAVE LOCALLY (Zero-Loss Resilience)
      await OfflineDbService.instance.saveParentLocal(parentData);

      // 2. CLOUD SUBMISSION
      await SupabaseService.instance.insertParent(parentData);

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
            content: Text('Parent Profile ${widget.parentToEdit != null ? 'Updated' : 'Created'} Successfully!', 
              style: const TextStyle(fontWeight: FontWeight.w700)), 
            backgroundColor: dt.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved Locally: Record is safe on device.', style: TextStyle(fontWeight: FontWeight.w700)), 
            backgroundColor: dt.warning,
            behavior: SnackBarBehavior.floating,
          )
        );
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dt = DT.of(context);
    final roleColor = RoleColors.of(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: Text(widget.parentToEdit != null ? 'EDIT GUARDIAN' : 'PARENT REGISTRATION', 
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
                child: Icon(Icons.family_restroom_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ),
      ),
      body: NeuralBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: RoleColors.complement(_roleId),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormContainer(dt),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text('CHILD LINKING', 
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)
                      ),
                    ),
                    _buildChildrenSelector(dt),
                    const SizedBox(height: 40),
                    Container(
                      width: double.infinity,
                      height: 65,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: KagemaColors.accountantAmber.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 10))],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveParent,
                        icon: _isSaving ? const SizedBox.shrink() : const Icon(Icons.verified_user_rounded),
                        label: _isSaving 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                          : Text(widget.parentToEdit != null ? 'SAVE CHANGES' : 'COMPLETE REGISTRATION', 
                              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KagemaColors.accountantAmber,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContainer(DT dt) {
    return LiquidGlassCard(
      accentColor: KagemaColors.accountantAmber,
      borderRadius: 30,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildField(dt, _nameController, 'Parent Full Name', Icons.person_outline),
          const SizedBox(height: 20),
          _buildField(dt, _phoneController, 'Phone Number', Icons.phone_android_rounded, keyboardType: TextInputType.phone),
          const SizedBox(height: 20),
          _buildField(dt, _emailController, 'Email Address', Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 20),
          _buildField(dt, _occupationController, 'Occupation', Icons.work_outline_rounded),
          const SizedBox(height: 20),
          _buildField(dt, _addressController, 'Home Address', Icons.home_rounded),
        ],
      ),
    );
  }

  Widget _buildField(DT dt, TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: KagemaColors.accountantAmber, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: dt.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: dt.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: KagemaColors.accountantAmber)),
      ),
      validator: (v) => v!.isEmpty ? 'Field required' : null,
    );
  }

  Widget _buildChildrenSelector(DT dt) {
    if (_isLoadingStudents) return const Center(child: CircularProgressIndicator(color: KagemaColors.accountantAmber));
    
    return LiquidGlassCard(
      accentColor: KagemaColors.accountantAmber,
      borderRadius: 24,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 250,
        child: _allStudents.isEmpty 
          ? Center(child: Text('NO STUDENTS FOUND', style: TextStyle(fontWeight: FontWeight.bold, color: dt.textMuted)))
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _allStudents.length,
              itemBuilder: (context, index) {
                final student = _allStudents[index];
                final isSelected = _selectedChildren.any((s) => s.studentId == student.studentId);
                return CheckboxListTile(
                  title: Text(student.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: dt.textPrimary, letterSpacing: 0.5)),
                  subtitle: Text('ADM: ${student.admissionNumber} • ${student.grade}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: dt.textSecondary)),
                  value: isSelected,
                  activeColor: KagemaColors.accountantAmber,
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
      ),
    );
  }
}
