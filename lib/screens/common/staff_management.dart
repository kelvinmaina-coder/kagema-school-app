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
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final isDark = context.isDark;
    final roleColor = RoleColors.of(widget.role);
    final compColor = RoleColors.complement(widget.role);
    
    bool canManage = widget.role.toLowerCase() == 'admin' || widget.role.toLowerCase() == 'secretary';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: const Text('STAFF DIRECTORY', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3, color: Colors.white)
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
            gradient: RoleColors.gradient(widget.role, dark: isDark),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadStaff,
          ),
        ],
      ),
      body: theme?.buildCreativeBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: Column(
            children: [
              SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
              _buildSearchBox(dt, roleColor, theme),
              const SizedBox(height: 20),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator(color: roleColor))
                    : _filteredStaff.isEmpty
                        ? _buildEmptyState(dt)
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: _filteredStaff.length,
                            itemBuilder: (context, index) {
                              final staff = _filteredStaff[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: theme?.buildGlowContainer(
                                  accentColor: roleColor,
                                  borderRadius: 24,
                                  padding: EdgeInsets.zero,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: roleColor.withValues(alpha: 0.4), width: 1.5),
                                      ),
                                      child: CircleAvatar(
                                        radius: 24,
                                        backgroundColor: dt.roleSoftBg(roleColor),
                                        child: Text(staff['name'][0].toUpperCase(), 
                                          style: TextStyle(color: roleColor, fontWeight: FontWeight.w900, fontSize: 18)
                                        ),
                                      ),
                                    ),
                                    title: Text(staff['name'].toString().toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary, letterSpacing: 0.5)),
                                    subtitle: Text('${staff['role']} • ${staff['department'] ?? 'General'}', 
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: dt.textSecondary)
                                    ),
                                    trailing: canManage 
                                        ? IconButton(icon: Icon(Icons.edit_note_rounded, color: RoleColors.of('staff')), 
                                            onPressed: () => _showStaffForm(staff: staff))
                                        : Icon(Icons.chevron_right_rounded, color: dt.iconInactive),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ) ?? const SizedBox.shrink(),
      floatingActionButton: canManage ? RolePlasma(
        color: roleColor,
        child: FloatingActionButton.extended(
          onPressed: () => _showStaffForm(),
          backgroundColor: roleColor,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add_rounded),
          label: const Text('ADD STAFF', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
        ),
      ) : null,
    );
  }

  Widget _buildSearchBox(DT dt, Color color, GeminiThemeExtension? theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: theme?.buildGlowContainer(
        accentColor: color,
        borderRadius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
          decoration: InputDecoration(
            hintText: 'SEARCH STAFF MEMBERS...',
            hintStyle: TextStyle(color: dt.hint, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            prefixIcon: Icon(Icons.search_rounded, color: color, size: 22),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
        ),
      ),
    );
  }

  void _showStaffForm({Map<String, dynamic>? staff}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => StaffRegistrationScreen(staffToEdit: staff))).then((_) => _loadStaff());
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.badge_outlined, size: 80, color: dt.iconInactive),
          const SizedBox(height: 16),
          Text('NO STAFF MEMBERS FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2, fontSize: 12)),
        ],
      ),
    );
  }
}
