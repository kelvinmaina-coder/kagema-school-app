import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class StaffRegistrationScreen extends StatefulWidget {
  final Map<String, dynamic>? staffToEdit;
  const StaffRegistrationScreen({super.key, this.staffToEdit});

  @override
  State<StaffRegistrationScreen> createState() => _StaffRegistrationScreenState();
}

class _StaffRegistrationScreenState extends State<StaffRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _idController = TextEditingController();
  final _salaryController = TextEditingController();
  
  String _selectedRole = 'Teacher';
  bool _isSaving = false;
  final String _roleId = 'admin';

  final List<String> _roles = ['Teacher', 'Accountant', 'Secretary', 'Admin', 'Support Staff'];

  @override
  void initState() {
    super.initState();
    if (widget.staffToEdit != null) {
      _nameController.text = widget.staffToEdit!['name'] ?? '';
      _phoneController.text = widget.staffToEdit!['phone'] ?? '';
      _emailController.text = widget.staffToEdit!['email'] ?? '';
      _idController.text = widget.staffToEdit!['staff_id'] ?? '';
      _salaryController.text = (widget.staffToEdit!['salary'] ?? '').toString();
      _selectedRole = widget.staffToEdit!['role'] ?? 'Teacher';
    }
  }

  Future<void> _saveStaff() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final staffId = widget.staffToEdit != null 
          ? widget.staffToEdit!['staff_id'] 
          : 'STF-${const Uuid().v4().substring(0, 8).toUpperCase()}';

      final staffData = {
        'staff_id': staffId,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'salary': double.tryParse(_salaryController.text) ?? 0.0,
        'status': 'Active',
        'joined_at': widget.staffToEdit?['joined_at'] ?? DateTime.now().toIso8601String(),
      };

      if (widget.staffToEdit != null) {
        await SupabaseService.instance.updateStaff(staffData);
      } else {
        await SupabaseService.instance.insertStaff(staffData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Staff Profile ${widget.staffToEdit != null ? 'Updated' : 'Created'} Successfully!', style: const TextStyle(fontWeight: FontWeight.w700)), 
            backgroundColor: KagemaColors.teacherGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: KagemaColors.parentRed));
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
        title: Text(widget.staffToEdit != null ? 'EDIT STAFF' : 'STAFF REGISTRATION', 
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
                child: Icon(Icons.badge_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
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
                  children: [
                    _buildFormContainer(dt, roleColor),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveStaff,
                        icon: _isSaving ? const SizedBox.shrink() : const Icon(Icons.save_rounded),
                        label: _isSaving 
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) 
                          : Text(widget.staffToEdit != null ? 'SAVE CHANGES' : 'COMPLETE REGISTRATION', 
                              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: roleColor,
                          foregroundColor: Colors.white,
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

  Widget _buildFormContainer(DT dt, Color roleColor) {
    return LiquidGlassCard(
      accentColor: KagemaColors.staffSky,
      borderRadius: 30,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STAFF DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
          const SizedBox(height: 24),
          _buildField(dt, _nameController, 'Full Name', Icons.person_outline),
          const SizedBox(height: 20),
          _buildField(dt, _phoneController, 'Phone Number', Icons.phone_android_rounded, keyboardType: TextInputType.phone),
          const SizedBox(height: 20),
          _buildField(dt, _emailController, 'Email Address', Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 20),
          _buildField(dt, _salaryController, 'Basic Salary (Ksh)', Icons.payments_rounded, keyboardType: TextInputType.number),
          const SizedBox(height: 32),
          Divider(color: dt.divider),
          const SizedBox(height: 24),
          Text('DESIGNATED ROLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
          const SizedBox(height: 16),
          _buildRoleDropdown(dt),
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
        prefixIcon: Icon(icon, color: KagemaColors.staffSky, size: 20),
      ),
      validator: (v) => v!.isEmpty ? 'Field required' : null,
    );
  }

  Widget _buildRoleDropdown(DT dt) {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      dropdownColor: dt.cardBg,
      style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
      items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
      onChanged: (v) => setState(() => _selectedRole = v!),
      decoration: const InputDecoration(
        labelText: 'Role',
        prefixIcon: Icon(Icons.security_rounded, color: KagemaColors.staffSky, size: 20),
      ),
    );
  }
}
