import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class DisciplineManagementScreen extends StatefulWidget {
  const DisciplineManagementScreen({super.key});

  @override
  State<DisciplineManagementScreen> createState() => _DisciplineManagementScreenState();
}

class _DisciplineManagementScreenState extends State<DisciplineManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _incidents = [];
  final String _roleId = 'admin';

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getIncidents();
      if (mounted) {
        setState(() {
          _incidents = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDelete(String id) async {
    final dt = context.dt;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dt.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('PURGE INCIDENT?', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textPrimary)),
        content: Text('This will permanently erase this conduct record from the system.', style: TextStyle(color: dt.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ABORT', style: TextStyle(color: dt.textMuted))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('PURGE', style: TextStyle(color: dt.error, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirmed == true) {
      await SupabaseService.instance.deleteIncident(id);
      _loadIncidents();
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
        title: const Text('CONDUCT CENTER', 
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
            gradient: RoleColors.gradient(_roleId, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.gavel_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
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
              : _incidents.isEmpty 
                ? _buildEmptyState(dt)
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: _incidents.length,
                    itemBuilder: (context, index) {
                      final item = _incidents[index];
                      final isPositive = item['category'] == 'Positive';
                      final itemColor = isPositive ? dt.success : dt.error;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: theme.buildGlowContainer(
                          accentColor: itemColor,
                          borderRadius: 24,
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: dt.roleSoftBg(itemColor), shape: BoxShape.circle),
                              child: Icon(isPositive ? Icons.stars_rounded : Icons.warning_rounded, color: itemColor, size: 24),
                            ),
                            title: Text(item['student_name']?.toString().toUpperCase() ?? 'STUDENT', 
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary, letterSpacing: 0.5)
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(item['description'] ?? 'No details provided.', 
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dt.textSecondary, height: 1.4)
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_sweep_rounded, color: dt.error.withValues(alpha: 0.6), size: 22),
                              onPressed: () => _handleDelete(item['incident_id'].toString()),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_rounded, size: 80, color: dt.success),
          const SizedBox(height: 16),
          Text('CONDUCT REGISTRY CLEAN', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 1.5, fontSize: 12)),
        ],
      ),
    );
  }
}
