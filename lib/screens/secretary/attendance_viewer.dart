import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../app_theme.dart';

class AttendanceViewerScreen extends StatefulWidget {
  const AttendanceViewerScreen({super.key});

  @override
  State<AttendanceViewerScreen> createState() => _AttendanceViewerScreenState();
}

class _AttendanceViewerScreenState extends State<AttendanceViewerScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoading = true;
  final String _roleId = 'secretary';

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final records = await SupabaseService.instance.getGlobalAttendanceByDate(dateStr);
      
      if (mounted) {
        setState(() {
          _attendanceRecords = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Attendance Viewer Error: $e");
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
        title: const Text('ATTENDANCE MONITOR', 
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
                child: Icon(Icons.verified_user_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                _loadAttendance();
              }
            },
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
              SizedBox(height: AppBar().preferredSize.height + context.pt + 20),
              _buildDateHeader(dt, theme, roleColor),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: roleColor))
                    : _attendanceRecords.isEmpty
                        ? _buildEmptyState(dt)
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: _attendanceRecords.length,
                            itemBuilder: (context, index) {
                              final r = _attendanceRecords[index];
                              final isPresent = r['status'] == 'Present';
                              final color = isPresent ? dt.success : dt.error;
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: theme.buildGlowContainer(
                                  accentColor: color,
                                  borderRadius: 24,
                                  padding: EdgeInsets.zero,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5)),
                                      child: CircleAvatar(
                                        radius: 24,
                                        backgroundColor: dt.roleSoftBg(color),
                                        child: Icon(isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color, size: 24),
                                      ),
                                    ),
                                    title: Text(r['target_name']?.toString().toUpperCase() ?? 'PUPIL NAME', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary, letterSpacing: 0.5)),
                                    subtitle: Text('Grade: ${r['grade'] ?? "N/A"} â€¢ ${r['stream'] ?? "General"}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: dt.textSecondary)),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: dt.roleSoftBg(color), borderRadius: BorderRadius.circular(8)),
                                      child: Text(r['status'].toString().toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1)),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              _buildStats(dt, theme),
            ],
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildDateHeader(DT dt, GeminiThemeExtension? theme, Color roleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: theme?.buildGlowContainer(
        accentColor: roleColor,
        borderRadius: 20,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.event_note_rounded, color: roleColor, size: 20),
                const SizedBox(width: 12),
                Text(DateFormat('EEEE, MMM d, yyyy').format(_selectedDate).toUpperCase(), 
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: dt.textPrimary)
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: dt.roleSoftBg(roleColor), borderRadius: BorderRadius.circular(8)),
              child: Text('LOGS: ${_attendanceRecords.length}', 
                style: TextStyle(color: roleColor, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1)
              ),
            ),
          ],
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildStats(DT dt, GeminiThemeExtension? theme) {
    int presentCount = _attendanceRecords.where((r) => r['status'] == 'Present').length;
    int absentCount = _attendanceRecords.length - presentCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: BoxDecoration(
        color: dt.cardBg.withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, -10))],
        border: Border.all(color: dt.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statBit(dt, 'PRESENT', '$presentCount', dt.success),
          Container(width: 1, height: 30, color: dt.divider),
          _statBit(dt, 'ABSENT', '$absentCount', dt.error),
        ],
      ),
    );
  }

  Widget _statBit(DT dt, String l, String v, Color c) {
    return Column(
      children: [
        Text(v, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: c, letterSpacing: -1)),
        const SizedBox(height: 2),
        Text(l, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_rounded, size: 80, color: dt.iconInactive),
          const SizedBox(height: 16),
          Text('NO ATTENDANCE RECORDS FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: dt.textMuted, letterSpacing: 1.5, fontSize: 12)),
        ],
      ),
    );
  }
}
