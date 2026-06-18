import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import '../admin/staff_registration_screen.dart';

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
    final Color primaryColor = _getRoleColor();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Staff Directory', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5, color: Colors.white)
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
              colors: [primaryColor.withOpacity(0.9), primaryColor.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadStaff,
          ),
        ],
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Column(
          children: [
            SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
            _buildSearchBox(theme, primaryColor, gemini),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : _filteredStaff.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: _filteredStaff.length,
                          itemBuilder: (context, index) {
                            final staff = _filteredStaff[index];
                            final content = ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundColor: primaryColor.withOpacity(0.1),
                                child: Text(staff['name'][0], 
                                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 18)
                                ),
                              ),
                              title: Text(staff['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                              subtitle: Text('${staff['role']} • ${staff['department'] ?? 'General'}', 
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)
                              ),
                              trailing: canManage 
                                  ? IconButton(icon: const Icon(Icons.edit_note_rounded, color: Colors.blue), 
                                      onPressed: () => _showStaffForm(staff: staff))
                                  : const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                            );

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: gemini?.buildGlowContainer(
                                borderRadius: 24,
                                borderThickness: 1,
                                backgroundColor: theme.cardColor.withOpacity(0.85),
                                padding: EdgeInsets.zero,
                                child: content,
                              ) ?? Card(child: content),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: canManage ? gemini?.buildGlowContainer(
        borderRadius: 30,
        borderThickness: 2,
        backgroundColor: primaryColor,
        padding: EdgeInsets.zero,
        child: FloatingActionButton.extended(
          onPressed: () => _showStaffForm(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add_rounded),
          label: const Text('Add Staff', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ) : null,
    );
  }

  Widget _buildSearchBox(ThemeData theme, Color color, GeminiThemeExtension? gemini) {
    final content = TextField(
      onChanged: (v) => setState(() => _searchQuery = v),
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: 'Search staff members...',
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        prefixIcon: Icon(Icons.search_rounded, color: color, size: 22),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: gemini?.buildGlowContainer(
        borderRadius: 20,
        borderThickness: 1.5,
        backgroundColor: theme.cardColor.withOpacity(0.9),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: content,
      ) ?? Container(
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: content,
      ),
    );
  }

  void _showStaffForm({Map<String, dynamic>? staff}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => StaffRegistrationScreen(staffToEdit: staff))).then((_) => _loadStaff());
  }

  Color _getRoleColor() {
    switch (widget.role.toLowerCase()) {
      case 'admin': return const Color(0xFF1A237E);
      case 'teacher': return const Color(0xFF00695C);
      case 'secretary': return const Color(0xFF4A148C);
      default: return const Color(0xFFD84315);
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.badge_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('NO STAFF MEMBERS FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
