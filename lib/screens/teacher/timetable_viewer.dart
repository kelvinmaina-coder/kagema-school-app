import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class TimetableViewer extends StatefulWidget {
  const TimetableViewer({super.key});

  @override
  State<TimetableViewer> createState() => _TimetableViewerState();
}

class _TimetableViewerState extends State<TimetableViewer> {
  List<Map<String, dynamic>> _schedule = [];
  bool _isLoading = true;
  String _selectedDay = 'Monday';
  final String _roleId = 'teacher';

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final String teacherId = SupabaseService.instance.client.auth.currentUser?.id ?? "";
      final data = await SupabaseService.instance.getTeacherSchedule(teacherId);
      if (mounted) {
        setState(() {
          _schedule = data;
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
    
    final daySchedule = _schedule.where((s) => s['day'] == _selectedDay).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: dt.pageBg,
      appBar: AppBar(
        title: const Text('TEACHING MATRIX', 
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
                child: Icon(Icons.calendar_view_week_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
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
          child: Column(
            children: [
              SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 10),
              _buildDayPicker(dt, roleColor),
              Expanded(
                child: _isLoading 
                  ? Center(child: CircularProgressIndicator(color: roleColor))
                  : daySchedule.isEmpty
                      ? _buildEmptyState(dt)
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: daySchedule.length,
                          itemBuilder: (context, index) {
                            final item = daySchedule[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: theme.buildGlowContainer(
                                accentColor: roleColor,
                                borderRadius: 28,
                                padding: EdgeInsets.zero,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: dt.roleSoftBg(roleColor), shape: BoxShape.circle),
                                    child: Icon(Icons.timer_outlined, color: roleColor, size: 24),
                                  ),
                                  title: Text(item['subject']?.toString().toUpperCase() ?? 'DUTY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: dt.textPrimary, letterSpacing: 0.5)),
                                  subtitle: Text('${item['time_slot']} • ${item['grade']}', 
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dt.textSecondary)
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: dt.roleSoftBg(roleColor),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(item['room']?.toString().toUpperCase() ?? 'RM 1', 
                                      style: TextStyle(fontWeight: FontWeight.w900, color: roleColor, fontSize: 10, letterSpacing: 1)
                                    ),
                                  ),
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
    );
  }

  Widget _buildDayPicker(DT dt, Color roleColor) {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'].map((day) {
          final isSelected = _selectedDay == day;
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ChoiceChip(
              label: Text(day, style: TextStyle(
                color: isSelected ? Colors.white : dt.textMuted, 
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1,
              )),
              selected: isSelected,
              selectedColor: roleColor,
              backgroundColor: dt.cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onSelected: (v) => setState(() => _selectedDay = day),
              side: BorderSide(color: isSelected ? Colors.transparent : dt.cardBorder),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available_rounded, size: 80, color: dt.iconInactive),
          const SizedBox(height: 16),
          Text('NO SLOTS ASSIGNED', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 2)),
        ],
      ),
    );
  }
}
