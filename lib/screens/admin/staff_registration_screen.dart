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
            content: Text('Staff Profile ${widget.staffToEdit != null ? 'Updated' : 'Created'} Successfully!'), 
            backgroundColor: Colors.teal.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
        title: Text(widget.staffToEdit != null ? 'EDIT STAFF' : 'STAFF REGISTRATION', 
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
              colors: [theme.primaryColor, Colors.teal.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
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
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildFormContainer(theme, gemini),
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
                            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                        shadowColor: Colors.teal.withOpacity(0.4),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STAFF DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)),
        const SizedBox(height: 24),
        _buildField(theme, _nameController, 'Full Name', Icons.person_outline),
        const SizedBox(height: 20),
        _buildField(theme, _phoneController, 'Phone Number', Icons.phone_android_rounded, keyboardType: TextInputType.phone),
        const SizedBox(height: 20),
        _buildField(theme, _emailController, 'Email Address', Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 20),
        _buildField(theme, _salaryController, 'Basic Salary (Ksh)', Icons.payments_rounded, keyboardType: TextInputType.number),
        const SizedBox(height: 32),
        const Divider(color: Colors.white10),
        const SizedBox(height: 24),
        Text('DESIGNATED ROLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade400, letterSpacing: 2)),
        const SizedBox(height: 16),
        _buildRoleDropdown(theme),
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
        prefixIcon: Icon(icon, color: Colors.teal, size: 20),
        filled: true,
        fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
      validator: (v) => v!.isEmpty ? 'Field required' : null,
    );
  }

  Widget _buildRoleDropdown(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
      items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
      onChanged: (v) => setState(() => _selectedRole = v!),
      decoration: InputDecoration(
        labelText: 'Role',
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: const Icon(Icons.security_rounded, color: Colors.teal, size: 20),
        filled: true,
        fillColor: theme.brightness == Brightness.dark ? Colors.black26 : Colors.white54,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
    );
  }
}
