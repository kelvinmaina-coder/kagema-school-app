import 'package:flutter/material.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class ChildDisciplineScreen extends StatefulWidget {
  final Student student;
  const ChildDisciplineScreen({super.key, required this.student});

  @override
  State<ChildDisciplineScreen> createState() => _ChildDisciplineScreenState();
}

class _ChildDisciplineScreenState extends State<ChildDisciplineScreen> {
  List<Map<String, dynamic>> _incidents = [];
  bool _isLoading = true;
  final String _roleId = 'parent';

  @override
  void initState() {
    super.initState();
    _loadDiscipline();
  }

  Future<void> _loadDiscipline() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getStudentDiscipline(widget.student.studentId);
      if (mounted) {
        setState(() {
          _incidents = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
        title: Text('${widget.student.name.toUpperCase()}\'S CONDUCT', 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 3, color: Colors.white)
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
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + context.pt + 10),
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: roleColor))
              : _incidents.isEmpty 
                ? _buildEmptyState(dt)
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    itemCount: _incidents.length,
                    itemBuilder: (context, index) {
                      final item = _incidents[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: theme.buildGlowContainer(
                          accentColor: dt.error,
                          borderRadius: 28,
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: dt.roleSoftBg(dt.error), shape: BoxShape.circle),
                              child: Icon(Icons.warning_amber_rounded, color: dt.error, size: 24),
                            ),
                            title: Text(item['title']?.toString().toUpperCase() ?? 'INCIDENT ENTRY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary, letterSpacing: 0.5)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(item['description'] ?? 'No details provided.', 
                                style: TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w600, color: dt.textSecondary)
                              ),
                            ),
                            trailing: Text(item['date'] ?? '', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: dt.textMuted)),
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
          Text('DISCIPLINE RECORD CLEAR', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2, fontSize: 12)),
        ],
      ),
    );
  }
}
