import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class VisitorsManagerScreen extends StatefulWidget {
  const VisitorsManagerScreen({super.key});

  @override
  State<VisitorsManagerScreen> createState() => _VisitorsManagerScreenState();
}

class _VisitorsManagerScreenState extends State<VisitorsManagerScreen> {
  List<Map<String, dynamic>> _visitors = [];
  bool _isLoading = true;
  final String _roleId = 'secretary';

  @override
  void initState() {
    super.initState();
    _loadVisitors();
  }

  Future<void> _loadVisitors() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getVisitors();
      if (mounted) {
        setState(() {
          _visitors = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Visitor Log Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLogVisitorDialog({Map<String, dynamic>? visitorToEdit}) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final isDark = context.isDark;
    final roleColor = RoleColors.of(_roleId);
    final isEditing = visitorToEdit != null;
    final nameController = TextEditingController(text: visitorToEdit?['name']);
    final phoneController = TextEditingController(text: visitorToEdit?['phone']);
    final purposeController = TextEditingController(text: visitorToEdit?['purpose']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: theme?.buildGlowContainer(
          accentColor: roleColor,
          borderRadius: 35,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: dt.divider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text(isEditing ? 'MODIFY LOG' : 'VISITOR ENTRY', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)
                ),
                const SizedBox(height: 8),
                Text(isEditing ? 'Change Profile' : 'Identity Verification', 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1, color: dt.textPrimary)
                ),
                const SizedBox(height: 32),
                _buildFormField(dt, 'Legal Full Name', Icons.person_outline_rounded, nameController, roleColor),
                const SizedBox(height: 16),
                _buildFormField(dt, 'Contact Number', Icons.phone_android_rounded, phoneController, roleColor, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _buildFormField(dt, 'Visit Purpose', Icons.info_outline_rounded, purposeController, roleColor),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isNotEmpty) {
                        final data = {
                          'visitor_id': visitorToEdit?['visitor_id'],
                          'name': nameController.text.trim(),
                          'phone': phoneController.text.trim(),
                          'purpose': purposeController.text.trim(),
                          'date': visitorToEdit?['date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
                          'time_in': visitorToEdit?['time_in'] ?? DateTime.now().toIso8601String(),
                        };
                        
                        try {
                          await SupabaseService.instance.insertVisitor(data);
                          if (mounted) {
                            Navigator.pop(context);
                            _loadVisitors();
                          }
                        } catch (e) {
                          if (mounted) _loadVisitors();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: roleColor, 
                      foregroundColor: Colors.white, 
                    ),
                    child: Text(isEditing ? 'COMMIT SYNC' : 'AUTHORIZE ENTRY', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ) ?? const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildFormField(DT dt, String label, IconData icon, TextEditingController ctrl, Color roleColor, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: roleColor, size: 20),
      ),
    );
  }

  Future<void> _deleteVisitor(Map<String, dynamic> v) async {
    final dt = context.dt;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dt.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Delete Log?', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textPrimary)),
        content: Text('Are you sure you want to erase the log for "${v['name']}"?', style: TextStyle(color: dt.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ABORT', style: TextStyle(color: dt.textMuted))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('DELETE', style: TextStyle(color: dt.error, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirmed == true) {
      await SupabaseService.instance.client.from('visitors').delete().eq('visitor_id', v['visitor_id']);
      _loadVisitors();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final isDark = context.isDark;
    final roleColor = RoleColors.of(_roleId);
    final compColor = RoleColors.complement(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: const Text('VISITOR LOGS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3, fontSize: 16)),
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
                child: Icon(Icons.shield_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ),
      ),
      body: theme?.buildCreativeBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: Padding(
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + context.pt + 20),
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: roleColor))
              : _visitors.isEmpty
                  ? _buildEmptyState(dt)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _visitors.length,
                      itemBuilder: (context, index) {
                        final v = _visitors[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: theme.buildGlowContainer(
                            accentColor: dt.info,
                            borderRadius: 28,
                            padding: EdgeInsets.zero,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: dt.roleSoftBg(dt.info), shape: BoxShape.circle),
                                child: Icon(Icons.badge_rounded, color: dt.info, size: 24),
                              ),
                              title: Text(v['name']?.toString().toUpperCase() ?? 'VISITOR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: dt.textPrimary, letterSpacing: 0.5)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('${v['purpose']} \nTimestamp: ${v['date']}', 
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.4, color: dt.textSecondary)
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: dt.roleSoftBg(dt.success), borderRadius: BorderRadius.circular(8)),
                                    child: Text('VERIFIED', style: TextStyle(color: dt.success, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1)),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert_rounded, size: 20, color: dt.iconInactive),
                                    color: dt.cardBg,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    onSelected: (val) {
                                      if (val == 'edit') _showLogVisitorDialog(visitorToEdit: v);
                                      if (val == 'delete') _deleteVisitor(v);
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_note_rounded, size: 20, color: dt.textPrimary), title: Text('Edit Info', style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary)), dense: true)),
                                      PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_forever_rounded, color: dt.error, size: 20), title: Text('Remove', style: TextStyle(color: dt.error, fontWeight: FontWeight.bold)), dense: true)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ) ?? const SizedBox.shrink(),
                        );
                      },
                    ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
      floatingActionButton: RolePlasma(
        color: roleColor,
        child: FloatingActionButton.extended(
          onPressed: () => _showLogVisitorDialog(),
          backgroundColor: roleColor,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add_rounded),
          label: const Text('LOG NEW VISITOR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 80, color: dt.iconInactive),
          const SizedBox(height: 16),
          Text('VISITOR LOGS EMPTY', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
