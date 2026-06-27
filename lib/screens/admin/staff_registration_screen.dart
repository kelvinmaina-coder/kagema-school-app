import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../services/supabase_service.dart';
import '../../services/offline_db_service.dart';
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
  final _salaryController = TextEditingController();
  final _deptController = TextEditingController();

  String _selectedRole = 'Teacher';
  bool _isSaving = false;
  bool _isDeleting = false;
  final String _roleId = 'admin';

  final List<String> _roles = ['Teacher', 'Accountant', 'Secretary', 'Admin', 'Support Staff'];

  @override
  void initState() {
    super.initState();
    if (widget.staffToEdit != null) {
      _nameController.text = widget.staffToEdit!['name'] ?? '';
      _phoneController.text = widget.staffToEdit!['phone'] ?? '';
      _emailController.text = widget.staffToEdit!['email'] ?? '';
      _salaryController.text = (widget.staffToEdit!['salary'] ?? '').toString();
      _deptController.text = widget.staffToEdit!['department'] ?? '';
      _selectedRole = widget.staffToEdit!['role'] ?? 'Teacher';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _salaryController.dispose();
    _deptController.dispose();
    super.dispose();
  }

  // ─── VALIDATORS ──────────────────────────────────────────────
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Enter valid email';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone required';
    final phoneRegex = RegExp(r'^\+?[\d\s-]{10,15}$');
    if (!phoneRegex.hasMatch(value)) return 'Enter valid phone (e.g., 0712345678)';
    return null;
  }

  String? _validateSalary(String? value) {
    if (value == null || value.isEmpty) return 'Salary required';
    final numeric = value.replaceAll(',', '');
    if (double.tryParse(numeric) == null) return 'Enter valid number';
    if (double.parse(numeric) < 0) return 'Salary cannot be negative';
    return null;
  }

  // ─── FORMAT SALARY ───────────────────────────────────────────
  void _formatSalary(String value) {
    if (value.isEmpty) return;
    final numeric = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeric.isEmpty) return;
    final formatted = NumberFormat('#,###').format(int.parse(numeric));
    _salaryController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  // ─── SAVE STAFF ──────────────────────────────────────────────
  Future<void> _saveStaff() async {
    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }

    final dt = context.dt;
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
        'department': _deptController.text.trim().isEmpty ? 'General' : _deptController.text.trim(),
        'salary': double.tryParse(_salaryController.text.replaceAll(',', '')) ?? 0.0,
        'status': 'Active',
      };

      print('📤 Sending staff data: $staffData');

      // 1. SAVE LOCALLY
      await OfflineDbService.instance.saveStaffLocal(staffData);

      // 2. SAVE TO SUPABASE
      if (widget.staffToEdit != null) {
        await SupabaseService.instance.updateStaff(staffData);
      } else {
        await SupabaseService.instance.insertStaff(staffData);
      }

      print('✅ Staff saved successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Staff ${widget.staffToEdit != null ? 'Updated' : 'Registered'} Successfully!',
                style: const TextStyle(fontWeight: FontWeight.w700)
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Error saving staff: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Saved locally. Sync later: $e',
                  style: const TextStyle(fontWeight: FontWeight.w700)
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            )
        );
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── DELETE STAFF ────────────────────────────────────────────
  Future<void> _deleteStaff() async {
    if (widget.staffToEdit == null) return;

    setState(() => _isDeleting = true);
    try {
      final staffId = widget.staffToEdit!['staff_id'];

      // 1. Delete from Supabase
      await SupabaseService.instance.deleteStaff(staffId);

      // 2. Delete from local
      await OfflineDbService.instance.deleteStaffLocal(staffId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Staff Deleted Successfully!'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Error deleting staff: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting staff: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  // ─── CONFIRM DELETE ──────────────────────────────────────────
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: _deleteStaff,
            child: _isDeleting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                : const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ─── CLEAR FORM ──────────────────────────────────────────────
  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _salaryController.clear();
    _deptController.clear();
    setState(() => _selectedRole = 'Teacher');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dt = DT.of(context);
    final roleColor = RoleColors.of(_roleId);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: dt.pageBg,
        appBar: AppBar(
          title: Text(
              widget.staffToEdit != null ? 'EDIT STAFF' : 'STAFF REGISTRATION',
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: Colors.white,
                  fontSize: 16
              )
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (widget.staffToEdit != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: _confirmDelete,
                tooltip: 'Delete Staff',
              ),
          ],
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: RoleColors.gradient(_roleId, dark: isDark),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20, top: -10,
                  child: Icon(Icons.badge_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
                ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            NeuralBackground(
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
                          // Staff ID Display
                          _buildStaffIdDisplay(dt, roleColor),
                          const SizedBox(height: 20),
                          _buildFormContainer(dt, roleColor),
                          const SizedBox(height: 16),
                          // Clear Form Button (only for new staff)
                          if (widget.staffToEdit == null)
                            TextButton(
                              onPressed: _clearForm,
                              child: const Text('CLEAR FORM'),
                            ),
                          const SizedBox(height: 20),
                          _buildSubmitButton(dt, roleColor),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Loading Overlay
            if (_isSaving || _isDeleting)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffIdDisplay(DT dt, Color roleColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: dt.roleSoftBg(roleColor),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: roleColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.badge, color: Colors.grey),
          const SizedBox(width: 12),
          Text(
            'Staff ID: ${widget.staffToEdit?['staff_id'] ?? 'NEW'}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: dt.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(DT dt, Color roleColor) {
    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: roleColor.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 10)
          )
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveStaff,
        icon: _isSaving
            ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3
            )
        )
            : const Icon(Icons.verified_user_rounded),
        label: _isSaving
            ? const Text(
            'SAVING...',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 13
            )
        )
            : Text(
            widget.staffToEdit != null ? 'UPDATE STAFF' : 'REGISTER STAFF',
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 13
            )
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: roleColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)
          ),
          minimumSize: const Size(double.infinity, 65),
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
          Text(
              'STAFF DETAILS',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: dt.textMuted,
                  letterSpacing: 2
              )
          ),
          const SizedBox(height: 24),
          _buildField(dt, _nameController, 'Full Name', Icons.person_outline),
          const SizedBox(height: 20),
          _buildField(dt, _phoneController, 'Phone Number', Icons.phone_android_rounded,
              keyboardType: TextInputType.phone, validator: _validatePhone),
          const SizedBox(height: 20),
          _buildField(dt, _emailController, 'Email Address', Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress, validator: _validateEmail),
          const SizedBox(height: 20),
          _buildField(dt, _deptController, 'Department (e.g. Science)', Icons.business_center_rounded),
          const SizedBox(height: 20),
          _buildField(dt, _salaryController, 'Basic Salary (Ksh)', Icons.payments_rounded,
              keyboardType: TextInputType.number, validator: _validateSalary, onChanged: _formatSalary),
          const SizedBox(height: 32),
          Divider(color: dt.divider),
          const SizedBox(height: 24),
          Text(
              'DESIGNATED ROLE',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: dt.textMuted,
                  letterSpacing: 2
              )
          ),
          const SizedBox(height: 16),
          _buildRoleDropdown(dt),
        ],
      ),
    );
  }

  Widget _buildField(
      DT dt,
      TextEditingController controller,
      String label,
      IconData icon, {
        TextInputType? keyboardType,
        String? Function(String?)? validator,
        void Function(String)? onChanged,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(
          fontWeight: FontWeight.bold,
          color: dt.textPrimary
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: dt.textMuted,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: KagemaColors.staffSky, size: 20),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: dt.divider)
        ),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: dt.divider)
        ),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: KagemaColors.staffSky, width: 2)
        ),
        filled: true,
        fillColor: dt.cardBg.withOpacity(0.5),
      ),
      validator: validator ?? (v) {
        if (v == null || v.isEmpty) {
          return 'Field required';
        }
        return null;
      },
    );
  }

  Widget _buildRoleDropdown(DT dt) {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      dropdownColor: dt.cardBg,
      style: TextStyle(
          fontWeight: FontWeight.bold,
          color: dt.textPrimary
      ),
      items: _roles.map((r) => DropdownMenuItem(
          value: r,
          child: Text(r)
      )).toList(),
      onChanged: (v) => setState(() => _selectedRole = v!),
      decoration: InputDecoration(
        labelText: 'Role',
        labelStyle: TextStyle(
          color: dt.textMuted,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: const Icon(Icons.security_rounded, color: KagemaColors.staffSky, size: 20),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: dt.divider)
        ),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: dt.divider)
        ),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: KagemaColors.staffSky, width: 2)
        ),
        filled: true,
        fillColor: dt.cardBg.withOpacity(0.5),
      ),
    );
  }
}