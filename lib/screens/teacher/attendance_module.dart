import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app_theme.dart';

class AttendanceModule extends StatefulWidget {
  final String initialGrade;
  final String initialStream;

  const AttendanceModule({
    super.key,
    required this.initialGrade,
    required this.initialStream,
  });

  @override
  State<AttendanceModule> createState() => _AttendanceModuleState();
}

class _AttendanceModuleState extends State<AttendanceModule> {
  late String selectedGrade;
  late String selectedStream;
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  List<Map<String, dynamic>> students = [];

  // All available grades (Kenya: Grade 1 to 9)
  final List<String> grades = List.generate(9, (i) => 'GRADE ${i + 1}');

  // Streams (can be customized)
  final List<String> streams = ['A', 'B', 'C', 'D'];

  final String _roleId = 'teacher';

  @override
  void initState() {
    super.initState();
    // Normalize input: convert "Grade 1" -> "GRADE 1", etc.
    selectedGrade = _normalizeGrade(widget.initialGrade);
    // If still not in list, default to first grade
    if (!grades.contains(selectedGrade)) {
      selectedGrade = grades.first;
    }
    selectedStream = _normalizeStream(widget.initialStream);
    if (!streams.contains(selectedStream)) {
      selectedStream = streams.first;
    }
    _fetchStudents();
  }

  // Helper: convert "Grade 1", "grade 1", "1" -> "GRADE 1"
  String _normalizeGrade(String input) {
    final trimmed = input.trim().toUpperCase();
    // If it already matches "GRADE X", return as is
    if (RegExp(r'^GRADE\s+[1-9]$').hasMatch(trimmed)) {
      return trimmed;
    }
    // Try to extract a number
    final match = RegExp(r'(\d+)').firstMatch(trimmed);
    if (match != null) {
      final num = int.parse(match.group(1)!);
      if (num >= 1 && num <= 9) {
        return 'GRADE $num';
      }
    }
    // Fallback
    return 'GRADE 1';
  }

  // Helper: normalise stream
  String _normalizeStream(String input) {
    final trimmed = input.trim().toUpperCase();
    if (streams.contains(trimmed)) return trimmed;
    return streams.first;
  }

  Future<void> _fetchStudents() async {
    setState(() => isLoading = true);
    // Simulate network call with real data from backend based on grade & stream
    await Future.delayed(const Duration(seconds: 1));
    // In real app: fetch from API using selectedGrade & selectedStream
    setState(() {
      students = List.generate(
        20,
            (index) => {
          'id': '${selectedGrade.substring(6)}${selectedStream}${100 + index}',
          'name': 'Student ${index + 1}',
          'status': 'present', // default present
        },
      );
      isLoading = false;
    });
  }

  // Toggle all students to a given status
  void _toggleAll(String status) {
    setState(() {
      for (var student in students) {
        student['status'] = status;
      }
    });
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
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('ROLL CALL',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 3, color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: RoleColors.gradient(_roleId, dark: isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -10,
                child: Icon(Icons.how_to_reg_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
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
              _buildHeader(dt, theme, roleColor),
              _buildQuickActions(dt, roleColor),
              _buildAttendanceList(dt, theme, roleColor),
              _buildSubmitButton(dt, roleColor),
            ],
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  // ===================== HEADER WITH DROPDOWNS =====================
  Widget _buildHeader(DT dt, GeminiThemeExtension? theme, Color roleColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: theme?.buildGlowContainer(
        accentColor: roleColor,
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(selectedDate).toUpperCase(),
                  style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: dt.textPrimary),
                ),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                      // Re-fetch students for new date? (optional)
                    }
                  },
                  child: Icon(Icons.calendar_today_rounded, size: 16, color: dt.iconInactive),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Grade & Stream Dropdowns
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    hint: 'CLASS',
                    value: selectedGrade,
                    items: grades,
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          selectedGrade = v;
                          _fetchStudents();
                        });
                      }
                    },
                    dt: dt,
                    roleColor: roleColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    hint: 'STREAM',
                    value: selectedStream,
                    items: streams,
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          selectedStream = v;
                          _fetchStudents();
                        });
                      }
                    },
                    dt: dt,
                    roleColor: roleColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  // ===================== DROPDOWN WIDGET (FIXED) =====================
  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
    required DT dt,
    required Color roleColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: dt.inputBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: dt.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, // must be exactly one of the items
          hint: Text(hint,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w900, color: dt.hint, letterSpacing: 1)),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: dt.iconInactive),
          dropdownColor: dt.cardBg,
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800, color: dt.textPrimary)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ===================== QUICK ACTIONS =====================
  Widget _buildQuickActions(DT dt, Color roleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _actionChip('ALL PRESENT', Icons.done_all, KagemaColors.teacherGreen, dt, () => _toggleAll('present')),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionChip('ALL ABSENT', Icons.close, KagemaColors.parentRed, dt, () => _toggleAll('absent')),
          ),
        ],
      ),
    );
  }

  Widget _actionChip(String label, IconData icon, Color color, DT dt, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  // ===================== STUDENT LIST =====================
  Widget _buildAttendanceList(DT dt, GeminiThemeExtension? theme, Color roleColor) {
    if (isLoading) return const Expanded(child: Center(child: CircularProgressIndicator()));

    if (students.isEmpty) {
      return const Expanded(
        child: Center(child: Text('No students found for this class/stream.')),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: theme?.buildGlowContainer(
              accentColor: roleColor,
              borderRadius: 20,
              padding: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: dt.roleSoftBg(roleColor),
                  child: Text(student['name'][0].toUpperCase(),
                      style: TextStyle(color: roleColor, fontWeight: FontWeight.bold)),
                ),
                title: Text(student['name'].toUpperCase(),
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13, color: dt.textPrimary, letterSpacing: 0.5)),
                subtitle: Text(student['id'], style: TextStyle(fontSize: 10, color: dt.textMuted)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _statusButton('P', 'present', student['status'] == 'present', KagemaColors.teacherGreen,
                        dt, () {
                          setState(() => student['status'] = 'present');
                        }),
                    const SizedBox(width: 8),
                    _statusButton('A', 'absent', student['status'] == 'absent', KagemaColors.parentRed,
                        dt, () {
                          setState(() => student['status'] = 'absent');
                        }),
                  ],
                ),
              ),
            ) ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }

  Widget _statusButton(String label, String status, bool isSelected, Color color, DT dt,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? color : dt.surfaceBg,
          shape: BoxShape.circle,
          border: isSelected ? null : Border.all(color: dt.cardBorder),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: isSelected ? Colors.white : dt.textMuted,
                  fontWeight: FontWeight.w900,
                  fontSize: 12)),
        ),
      ),
    );
  }

  // ===================== SUBMIT BUTTON =====================
  Widget _buildSubmitButton(DT dt, Color roleColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: roleColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            // Submit attendance to backend
            _submitAttendance();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: roleColor,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text('SUBMIT ATTENDANCE',
              style:
              TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2, color: Colors.white)),
        ),
      ),
    );
  }

  // ===================== SUBMIT LOGIC =====================
  Future<void> _submitAttendance() async {
    // Build payload
    final payload = {
      'date': DateFormat('yyyy-MM-dd').format(selectedDate),
      'grade': selectedGrade,
      'stream': selectedStream,
      'students': students.map((s) => {
        'id': s['id'],
        'name': s['name'],
        'status': s['status'],
      }).toList(),
    };

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // Simulate network call
    await Future.delayed(const Duration(seconds: 1));

    // Close dialog
    Navigator.pop(context);

    // Show success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Attendance for ${students.where((s) => s['status'] == 'present').length} students submitted.'),
        backgroundColor: KagemaColors.teacherGreen,
      ),
    );
  }
}