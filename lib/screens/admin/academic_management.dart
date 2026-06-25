import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class AcademicManagementScreen extends StatefulWidget {
  const AcademicManagementScreen({super.key});

  @override
  State<AcademicManagementScreen> createState() => _AcademicManagementScreenState();
}

class _AcademicManagementScreenState extends State<AcademicManagementScreen> {
  List<String> _classes = [];
  List<String> _subjects = [];
  bool _isLoading = true;
  final String _roleId = 'admin';

  @override
  void initState() {
    super.initState();
    _loadAcademicData();
  }

  Future<void> _loadAcademicData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final classes = await SupabaseService.instance.getClasses();
      final subjects = await SupabaseService.instance.getSubjects();
      if (mounted) {
        setState(() {
          _classes = classes;
          _subjects = subjects;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddDialog(String type) {
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final roleColor = RoleColors.of(_roleId);
    final ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: theme?.buildGlowContainer(
          accentColor: roleColor,
          borderRadius: 35,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: dt.divider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text('ADD NEW ${type.toUpperCase()}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
                const SizedBox(height: 24),
                TextField(
                  controller: ctrl,
                  style: TextStyle(color: dt.textPrimary, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Name', 
                    prefixIcon: Icon(type == 'Class' ? Icons.school : Icons.book, color: roleColor),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      if (ctrl.text.isNotEmpty) {
                        setState(() { if (type == 'Class') _classes.add(ctrl.text.trim()); else _subjects.add(ctrl.text.trim()); });
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('SAVE TO RECORDS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
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
        title: const Text('ACADEMIC HUB', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 3, color: Colors.white)),
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
        ),
      ),
      body: theme?.buildCreativeBackground(
        isDark: isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: isDark,
          child: _isLoading 
            ? Center(child: CircularProgressIndicator(color: roleColor))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(top: AppBar().preferredSize.height + context.pt + 20, left: 20, right: 20, bottom: 40),
                child: Column(
                  children: [
                    _buildSection('STREAMS & GRADES', _classes, Icons.class_rounded, dt.info, dt, theme, () => _showAddDialog('Class')),
                    const SizedBox(height: 32),
                    _buildSection('SUBJECT DIRECTORY', _subjects, Icons.menu_book_rounded, dt.warning, dt, theme, () => _showAddDialog('Subject')),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildSection(String title, List<String> items, IconData icon, Color color, DT dt, GeminiThemeExtension? theme, VoidCallback onAdd) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 10), Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 1.5))]),
          IconButton(icon: Icon(Icons.add_circle_outline_rounded, color: color, size: 20), onPressed: onAdd),
        ]),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10, 
          runSpacing: 10, 
          children: items.map((i) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), 
            decoration: BoxDecoration(
              color: dt.roleSoftBg(color), 
              borderRadius: BorderRadius.circular(12), 
              border: Border.all(color: color.withValues(alpha: 0.1))
            ), 
            child: Text(i, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: dt.textPrimary))
          )).toList()
        ),
      ],
    );
    return theme?.buildGlowContainer(
      accentColor: color,
      borderRadius: 28, 
      padding: const EdgeInsets.all(24), 
      child: content
    ) ?? const SizedBox.shrink();
  }
}
