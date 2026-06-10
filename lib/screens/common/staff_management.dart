import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class StaffManagementScreen extends StatefulWidget {
  final String role;
  const StaffManagementScreen({super.key, required this.role});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  List<Map<String, dynamic>> staffList = [];
  bool isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => isLoading = true);
    try {
      // Switched to Supabase Cloud
      final list = await SupabaseService.instance.getAllStaff();
      if (mounted) {
        setState(() {
          staffList = list;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Staff Load Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredStaff {
    if (_searchQuery.isEmpty) return staffList;
    return staffList.where((s) => 
      s['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) || 
      s['role'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  void _showStaffForm({Map<String, dynamic>? staff}) {
    final nameController = TextEditingController(text: staff?['name']);
    final roleController = TextEditingController(text: staff?['role']);
    final deptController = TextEditingController(text: staff?['department']);
    final salaryController = TextEditingController(text: staff?['salary']?.toString());
    final phoneController = TextEditingController(text: staff?['phone']);
    final emailController = TextEditingController(text: staff?['email']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(staff == null ? 'Recruit New Staff' : 'Edit Staff Profile', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildField(nameController, 'Full Name', Icons.person),
              _buildField(roleController, 'Designation (e.g. Senior Teacher)', Icons.badge),
              _buildField(deptController, 'Department', Icons.business),
              _buildField(phoneController, 'Phone', Icons.phone, keyboardType: TextInputType.phone),
              _buildField(emailController, 'Work Email', Icons.email, keyboardType: TextInputType.emailAddress),
              _buildField(salaryController, 'Monthly Salary', Icons.payments, keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      final staffData = {
                        'staff_id': staff?['staff_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        'name': nameController.text,
                        'role': roleController.text,
                        'department': deptController.text,
                        'phone': phoneController.text,
                        'email': emailController.text,
                        'salary': double.tryParse(salaryController.text) ?? 0.0,
                      };
                      
                      try {
                        if (staff == null) {
                          await SupabaseService.instance.insertStaff(staffData);
                        } else {
                          await SupabaseService.instance.updateStaff(staffData);
                        }
                        if (mounted) {
                          Navigator.pop(context);
                          _loadStaff();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(staff == null ? 'Staff onboarded successfully' : 'Profile updated'),
                            backgroundColor: Colors.teal,
                          ));
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync Error: $e'), backgroundColor: Colors.red));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal, 
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: Text(staff == null ? 'CONFIRM RECRUITMENT' : 'SAVE CHANGES', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: Colors.teal),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from System?'),
        content: Text('Delete ${staff['name']}? This action is irreversible on the cloud.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              await SupabaseService.instance.deleteStaff(staff['staff_id']);
              Navigator.pop(context);
              _loadStaff();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    bool canManage = widget.role == 'Admin' || widget.role == 'Secretary';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Directory'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.teal.withOpacity(0.1),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search by name or department...',
                  prefixIcon: const Icon(Icons.search, color: Colors.teal),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredStaff.length,
                      itemBuilder: (context, index) {
                        final staff = _filteredStaff[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: CircleAvatar(child: Text(staff['name'][0])),
                            title: Text(staff['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${staff['role']} • ${staff['department']}'),
                            trailing: canManage 
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showStaffForm(staff: staff)),
                                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(staff)),
                                    ],
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showStaffForm(),
              backgroundColor: Colors.teal,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text('Add Staff', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }
}
