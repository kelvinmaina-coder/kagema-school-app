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
        'joined_at': DateTime.now().toIso8601String(),
      };

      if (widget.staffToEdit != null) {
        await SupabaseService.instance.updateStaff(staffData);
      } else {
        await SupabaseService.instance.insertStaff(staffData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Staff member ${widget.staffToEdit != null ? 'updated' : 'registered'} successfully!'), backgroundColor: Colors.green),
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
        title: Text(widget.staffToEdit != null ? 'Edit Staff Profile' : 'Staff Onboarding', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primaryColor, Colors.teal.shade700]),
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
                children: [
                  _buildFormContainer(theme),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveStaff,
                      icon: _isSaving ? const SizedBox.shrink() : const Icon(Icons.cloud_upload_rounded),
                      label: _isSaving 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : Text(widget.staffToEdit != null ? 'UPDATE PROFILE' : 'REGISTER STAFF', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
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
          _buildField(_nameController, 'Full Legal Name', Icons.person_outline),
          const SizedBox(height: 20),
          _buildField(_phoneController, 'Phone Number', Icons.phone_android, keyboardType: TextInputType.phone),
          const SizedBox(height: 20),
          _buildField(_emailController, 'Email Address', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 20),
          _buildField(_salaryController, 'Monthly Salary (Ksh)', Icons.payments_outlined, keyboardType: TextInputType.number),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          _buildRoleDropdown(theme),
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
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
      ),
      validator: (v) => v!.isEmpty ? 'This field is required' : null,
    );
  }

  Widget _buildRoleDropdown(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
      onChanged: (v) => setState(() => _selectedRole = v!),
      decoration: InputDecoration(
        labelText: 'Designated Role',
        prefixIcon: const Icon(Icons.assignment_ind_rounded, color: Colors.teal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
      ),
    );
  }
}
