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

  final String _roleId = 'teacher';

  @override
  void initState() {
    super.initState();
    selectedGrade = widget.initialGrade;
    selectedStream = widget.initialStream;
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => isLoading = true);
    // Mock data fetching
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      students = List.generate(20, (index) => {
        'id': 'ID${100 + index}',
        'name': 'Student Name ${index + 1}',
        'status': 'present',
      });
      isLoading = false;
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
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 3, color: Colors.white)
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
                child: Icon(Icons.how_to_reg_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
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
              _buildAttendanceList(dt, theme, roleColor),
              _buildSubmitButton(dt, roleColor),
            ],
          ),
        ),
      ) ?? const SizedBox.shrink(),
    );
  }

  Widget _buildHeader(DT dt, GeminiThemeExtension? theme, Color roleColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: theme?.buildGlowContainer(
        accentColor: roleColor,
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('EEEE, MMM d, yyyy').format(selectedDate).toUpperCase(), 
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: dt.textPrimary)
                ),
                Icon(Icons.calendar_today_rounded, size: 16, color: dt.iconInactive),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    hint: 'SELECT CLASS',
                    value: selectedGrade,
                    items: ['GRADE 1', 'GRADE 2', 'GRADE 3', 'GRADE 4', 'GRADE 5', 'GRADE 6'],
                    onChanged: (v) => setState(() => selectedGrade = v!),
                    dt: dt,
                    roleColor: roleColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    hint: 'STREAM',
                    value: selectedStream,
                    items: ['NORTH', 'SOUTH', 'EAST', 'WEST'],
                    onChanged: (v) => setState(() => selectedStream = v!),
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
          value: value,
          hint: Text(hint, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: dt.hint, letterSpacing: 1)),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: dt.iconInactive),
          dropdownColor: dt.cardBg,
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: dt.textPrimary)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildAttendanceList(DT dt, GeminiThemeExtension? theme, Color roleColor) {
    if (isLoading) return const Expanded(child: Center(child: CircularProgressIndicator()));

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
                  child: Text(student['name'][0].toUpperCase(), style: TextStyle(color: roleColor, fontWeight: FontWeight.bold)),
                ),
                title: Text(student['name'].toUpperCase(), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: dt.textPrimary, letterSpacing: 0.5)),
                subtitle: Text(student['id'], style: TextStyle(fontSize: 10, color: dt.textMuted)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _statusButton('P', 'present', student['status'] == 'present', KagemaColors.teacherGreen, dt, () {
                      setState(() => student['status'] = 'present');
                    }),
                    const SizedBox(width: 8),
                    _statusButton('A', 'absent', student['status'] == 'absent', KagemaColors.parentRed, dt, () {
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

  Widget _statusButton(String label, String status, bool isSelected, Color color, DT dt, VoidCallback onTap) {
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
          child: Text(label, style: TextStyle(color: isSelected ? Colors.white : dt.textMuted, fontWeight: FontWeight.w900, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(DT dt, Color roleColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: roleColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: roleColor,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text('SUBMIT ATTENDANCE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2, color: Colors.white)),
        ),
      ),
    );
  }
}
