import 'package:flutter/material.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class ChildListScreen extends StatefulWidget {
  final String parentPhone;
  const ChildListScreen({super.key, required this.parentPhone});

  @override
  State<ChildListScreen> createState() => _ChildListScreenState();
}

class _ChildListScreenState extends State<ChildListScreen> {
  List<Student> _children = [];
  bool _isLoading = true;
  final String _roleId = 'parent';

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final list = await SupabaseService.instance.getStudentsByParentPhone(widget.parentPhone);
      if (mounted) {
        setState(() {
          _children = list.map((json) => Student.fromMap(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading children: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dt = DT.of(context);
    final roleColor = RoleColors.of(_roleId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: const Text('FAMILY MATRIX', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: RoleColors.gradient(_roleId, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.people_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)))]),
        ),
      ),
      body: NeuralBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: RoleColors.complement(_roleId),
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: Padding(
            padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10),
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: roleColor))
                : _children.isEmpty 
                    ? _buildEmptyState(dt)
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        itemCount: _children.length,
                        itemBuilder: (context, index) {
                          final s = _children[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20), 
                            child: LiquidGlassCard(
                              accentColor: KagemaColors.azure,
                              borderRadius: 30,
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  CircleAvatar(radius: 40, backgroundColor: dt.roleSoftBg(KagemaColors.azure), child: Text(s.name[0], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: KagemaColors.azure))),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(s.name.toUpperCase(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: dt.textPrimary)),
                                      const SizedBox(height: 6),
                                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: dt.roleSoftBg(roleColor), borderRadius: BorderRadius.circular(8)), child: Text('ADM: ${s.admissionNumber}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: roleColor, letterSpacing: 1))),
                                      const SizedBox(height: 8),
                                      Text('${s.grade} • ${s.stream}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: dt.textSecondary)),
                                      const SizedBox(height: 12),
                                      _infoRow(dt, Icons.cake_outlined, s.dateOfBirth),
                                      _infoRow(dt, Icons.wc_rounded, s.gender),
                                    ]),
                                  ),
                                ],
                              ),
                            )
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(DT dt, IconData icon, String text) => Padding(padding: const EdgeInsets.only(top: 4), child: Row(children: [Icon(icon, size: 14, color: dt.textMuted), const SizedBox(width: 8), Text(text, style: TextStyle(fontSize: 12, color: dt.textMuted, fontWeight: FontWeight.w600))]));

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hub_rounded, size: 80, color: dt.iconInactive),
          const SizedBox(height: 16),
          Text('NO NEURAL NODES LINKED', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
          Text('Please visit the school registry to link your child.', style: TextStyle(color: dt.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}
