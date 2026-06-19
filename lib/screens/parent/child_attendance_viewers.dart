import 'package:flutter/material.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class ChildAttendanceScreen extends StatefulWidget {
  final Student student;
  const ChildAttendanceScreen({super.key, required this.student});

  @override
  State<ChildAttendanceScreen> createState() => _ChildAttendanceScreenState();
}

class _ChildAttendanceScreenState extends State<ChildAttendanceScreen> {
  List<Attendance> records = [];
  bool isLoading = true;
  final String _roleId = 'parent';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    try {
      final listData = await SupabaseService.instance.getChildAttendance(widget.student.studentId);
      if (mounted) {
        setState(() {
          records = (listData ?? []).map((m) => Attendance.fromMap(m)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
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
        title: Text('${widget.student.name.toUpperCase()}\'S ATTENDANCE', 
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14, letterSpacing: 2)
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
                child: Icon(Icons.verified_user_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
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
          child: isLoading 
            ? Center(child: CircularProgressIndicator(color: roleColor, strokeWidth: 3)) 
            : Column(
                children: [
                  SizedBox(height: AppBar().preferredSize.height + context.pt + 10),
                  _buildHeader(dt, theme),
                  Expanded(
                    child: records.isEmpty
                        ? _buildEmptyState(dt)
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: records.length,
                            itemBuilder: (context, index) {
                              final r = records[index];
                              final isPresent = r.status == 'Present';
                              final statusColor = isPresent ? dt.success : dt.error;
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: theme.buildGlowContainer(
                                  accentColor: statusColor,
                                  borderRadius: 24,
                                  padding: EdgeInsets.zero,
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: dt.roleSoftBg(statusColor), shape: BoxShape.circle),
                                      child: Icon(isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded, color: statusColor, size: 22),
                                    ),
                                    title: Text(r.date, style: TextStyle(fontWeight: FontWeight.w900, color: dt.textPrimary, letterSpacing: 0.5)),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: dt.roleSoftBg(statusColor), borderRadius: BorderRadius.circular(8)),
                                      child: Text(r.status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1)),
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

  Widget _buildHeader(DT dt, GeminiThemeExtension? theme) {
    int presentCount = records.where((r) => r.status == 'Present').length;
    double percentage = records.isEmpty ? 0 : (presentCount / records.length) * 100;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20), 
      child: theme?.buildGlowContainer(
        accentColor: dt.success,
        borderRadius: 28, 
        padding: const EdgeInsets.all(24), 
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text('CONSISTENCY SCORE', style: TextStyle(color: dt.textMuted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2.5)), 
                const SizedBox(height: 8), 
                Text('${percentage.toInt()}% Cloud Verified', style: TextStyle(color: dt.success, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5))
              ]
            ),
            RolePlasma(
              color: dt.success,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: dt.roleSoftBg(dt.success), shape: BoxShape.circle),
                child: Icon(Icons.star_rounded, color: dt.success, size: 28),
              ),
            ),
          ]
        )
      )
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_rounded, size: 60, color: dt.iconInactive), 
          const SizedBox(height: 12), 
          Text('NO NEURAL RECORDS FOUND', style: TextStyle(color: dt.textMuted, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12))
        ]
      )
    );
  }
}
