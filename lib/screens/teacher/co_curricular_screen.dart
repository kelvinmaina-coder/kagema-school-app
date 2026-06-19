import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';

class CoCurricularScreen extends StatefulWidget {
  const CoCurricularScreen({super.key});

  @override
  State<CoCurricularScreen> createState() => _CoCurricularScreenState();
}

class _CoCurricularScreenState extends State<CoCurricularScreen> {
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;
  final String _roleId = 'teacher';

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getActivities();
      if (mounted) {
        setState(() {
          _activities = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddDialog(DT dt, GeminiThemeExtension? theme, Color roleColor) {
    final titleCtrl = TextEditingController();
    final statsCtrl = TextEditingController();
    String category = 'Sports';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: theme?.buildGlowContainer(
          accentColor: KagemaColors.secretaryViolet,
          borderRadius: 35,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: dt.divider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text('LOG ACTIVITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text('New Activity Record', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1, color: dt.textPrimary)),
                const SizedBox(height: 32),
                _buildInputField(dt, 'Activity Name (e.g. Drama)', Icons.hub_rounded, titleCtrl, roleColor),
                const SizedBox(height: 16),
                _buildInputField(dt, 'Participant Stats (e.g. 35 Students)', Icons.groups_rounded, statsCtrl, roleColor),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  dropdownColor: dt.cardBg,
                  style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
                  items: ['Sports', 'Clubs', 'Music', 'Drama'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => category = v!,
                  decoration: InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_rounded, color: roleColor)),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.isNotEmpty) {
                        final data = {
                          'title': titleCtrl.text.trim(),
                          'stats': statsCtrl.text.trim(),
                          'category': category,
                          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                        };
                        await SupabaseService.instance.upsertActivity(data);
                        if (mounted) {
                          Navigator.pop(context);
                          _loadActivities();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KagemaColors.secretaryViolet, 
                    ),
                    child: const Text('SAVE ACTIVITY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
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

  Widget _buildInputField(DT dt, String label, IconData icon, TextEditingController ctrl, Color roleColor) {
    return TextField(
      controller: ctrl,
      style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: roleColor, size: 20),
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
        title: const Text('ACTIVITIES', 
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
                child: Icon(Icons.sports_basketball_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
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
          child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: roleColor))
              : _activities.isEmpty
                  ? _buildEmptyState(dt)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(
                        top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10,
                        left: 20, right: 20, bottom: 100
                      ),
                      itemCount: _activities.length,
                      itemBuilder: (context, index) {
                        final act = _activities[index];
                        return _buildDutyCard(dt, theme, act['title'], act['stats'], act['date'], KagemaColors.secretaryViolet);
                      },
                    ),
        ),
      ) ?? const SizedBox.shrink(),
      floatingActionButton: RolePlasma(
        color: KagemaColors.secretaryViolet,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddDialog(dt, theme, roleColor),
          backgroundColor: KagemaColors.secretaryViolet,
          icon: const Icon(Icons.add_task_rounded),
          label: const Text('ADD ACTIVITY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
        ),
      ),
    );
  }

  Widget _buildDutyCard(DT dt, GeminiThemeExtension? theme, String title, String stats, String detail, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: theme?.buildGlowContainer(
        accentColor: color,
        borderRadius: 28,
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: dt.roleSoftBg(color), shape: BoxShape.circle),
            child: Icon(Icons.groups_rounded, color: color, size: 24),
          ),
          title: Text(title.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary, letterSpacing: 0.5)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('$stats\nDate: $detail', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.4, color: dt.textSecondary)),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: dt.iconInactive),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_rounded, size: 80, color: dt.iconInactive),
          const SizedBox(height: 16),
          Text('NO ACTIVITIES RECORDED', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
        ],
      ),
    );
  }
}
