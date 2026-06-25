import 'package:flutter/material.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class ChildTimetableScreen extends StatefulWidget {
  final Student student;
  const ChildTimetableScreen({super.key, required this.student});

  @override
  State<ChildTimetableScreen> createState() => _ChildTimetableScreenState();
}

class _ChildTimetableScreenState extends State<ChildTimetableScreen> {
  List<Map<String, dynamic>> _timetable = [];
  bool _isLoading = true;
  final String _roleId = 'parent';

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getClassTimetable(widget.student.grade, widget.student.stream);
      if (mounted) {
        setState(() {
          _timetable = data;
          _isLoading = false;
        });
      }
    } catch (e) {
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
        title: Text('${widget.student.name.toUpperCase()}\'S SCHEDULE', 
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14, letterSpacing: 2)
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: RoleColors.gradient(_roleId, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(children: [Positioned(right: -20, top: -10, child: Icon(Icons.calendar_view_week_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)))]),
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
              : _timetable.isEmpty 
                ? _buildEmptyState(dt)
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    itemCount: _timetable.length,
                    itemBuilder: (context, index) {
                      final slot = _timetable[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: LiquidGlassCard(
                          accentColor: KagemaColors.staffSky,
                          borderRadius: 28,
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: dt.roleSoftBg(KagemaColors.staffSky), shape: BoxShape.circle),
                              child: const Icon(Icons.schedule_rounded, color: KagemaColors.staffSky, size: 24),
                            ),
                            title: Text(slot['subject'] ?? 'Logic', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: dt.textPrimary)),
                            subtitle: Text('${slot['day']} â€¢ ${slot['time_slot']}', 
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dt.textSecondary)
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: dt.roleSoftBg(roleColor), borderRadius: BorderRadius.circular(10)),
                              child: Text(slot['room'] ?? 'RM 1', style: TextStyle(fontWeight: FontWeight.w900, color: roleColor, fontSize: 10, letterSpacing: 1)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(DT dt) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.event_busy_rounded, size: 80, color: dt.iconInactive), const SizedBox(height: 16), Text('NO SCHEDULE ASSIGNED', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2))]));
}
