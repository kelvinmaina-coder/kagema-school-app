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
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final list = await SupabaseService.instance.getAllStaff();
      if (mounted) {
        setState(() {
          staffList = list;
          isLoading = false;
        });
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    bool canManage = widget.role == 'Admin' || widget.role == 'Secretary';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Staff Intelligence', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.teal.shade800, Colors.teal.shade400]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Column(
          children: [
            SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
            _buildSearchBox(theme),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredStaff.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _filteredStaff.length,
                          itemBuilder: (context, index) {
                            final staff = _filteredStaff[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.teal.withOpacity(0.1),
                                  child: Text(staff['name'][0], style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                                ),
                                title: Text(staff['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${staff['role']} • ${staff['department']}'),
                                trailing: canManage 
                                    ? IconButton(icon: const Icon(Icons.edit_note_rounded, color: Colors.teal), onPressed: () => _showStaffForm(staff: staff))
                                    : const Icon(Icons.chevron_right, color: Colors.grey),
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
              backgroundColor: Colors.teal.shade700,
              icon: const Icon(Icons.person_add_rounded, color: Colors.white),
              label: const Text('Onboard Staff', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildSearchBox(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: const InputDecoration(
          hintText: 'Search faculty by name...',
          prefixIcon: Icon(Icons.search, color: Colors.teal),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  void _showStaffForm({Map<String, dynamic>? staff}) {
    final theme = Theme.of(context);
    final nameController = TextEditingController(text: staff?['name']);
    final roleController = TextEditingController(text: staff?['role']);
    final deptController = TextEditingController(text: staff?['department']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(staff == null ? 'Recruit New Faculty' : 'Modify Staff Profile', 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.teal.shade700)),
              const SizedBox(height: 24),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Official Name', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: roleController, decoration: const InputDecoration(labelText: 'Designation', prefixIcon: Icon(Icons.badge_outlined), border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: deptController, decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.business_rounded), border: OutlineInputBorder())),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      final staffData = {
                        'staff_id': staff?['staff_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        'name': nameController.text,
                        'role': roleController.text,
                        'department': deptController.text,
                      };
                      if (staff == null) {
                        await SupabaseService.instance.insertStaff(staffData);
                      } else {
                        await SupabaseService.instance.updateStaff(staffData);
                      }
                      if (mounted) {
                        Navigator.pop(context);
                        _loadStaff();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('AUTHORIZE & SYNC', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.badge_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No faculty members found.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
