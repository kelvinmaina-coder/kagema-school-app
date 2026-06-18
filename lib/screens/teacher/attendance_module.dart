import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app_theme.dart';

// Assuming these are defined elsewhere or need to be imported
// If they are missing, the user might have other errors, but I'll focus on the reported one.

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

  final Color primaryAccent = const Color(0xFF6366F1);
  final Color slateDark = const Color(0xFF0F172A);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gemini = Theme.of(context).extension<GeminiThemeExtension>();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F111A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : slateDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('ROLL CALL', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2, color: isDark ? Colors.white : slateDark)
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: primaryAccent),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(isDark),
          _buildAttendanceList(isDark, gemini),
          _buildSubmitButton(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: isDark 
            ? [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.02)]
            : [primaryAccent.withOpacity(0.2), Colors.transparent],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1C2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('EEEE, MMM d, yyyy').format(selectedDate).toUpperCase(), 
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: isDark ? Colors.white70 : const Color(0xFF334155))
                ),
                Icon(Icons.calendar_today_rounded, size: 16, color: isDark ? Colors.white30 : Colors.black26),
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
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    hint: 'STREAM',
                    value: selectedStream,
                    items: ['NORTH', 'SOUTH', 'EAST', 'WEST'],
                    onChanged: (v) => setState(() => selectedStream = v!),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : Colors.black26, letterSpacing: 1)),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: onChanged == null ? Colors.transparent : (isDark ? Colors.white30 : Colors.black26)),
          dropdownColor: isDark ? const Color(0xFF1A1C2E) : Colors.white,
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildAttendanceList(bool isDark, GeminiThemeExtension? gemini) {
    if (isLoading) return const Expanded(child: Center(child: CircularProgressIndicator()));

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1C2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: primaryAccent.withOpacity(0.1),
                child: Text(student['name'][0], style: TextStyle(color: primaryAccent, fontWeight: FontWeight.bold)),
              ),
              title: Text(student['name'], style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: isDark ? Colors.white : slateDark)),
              subtitle: Text(student['id'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _statusButton('P', 'present', student['status'] == 'present', Colors.green, isDark, () {
                    setState(() => student['status'] = 'present');
                  }),
                  const SizedBox(width: 8),
                  _statusButton('A', 'absent', student['status'] == 'absent', Colors.red, isDark, () {
                    setState(() => student['status'] = 'absent');
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statusButton(String label, String status, bool isSelected, Color color, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? color : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white24 : Colors.black26), fontWeight: FontWeight.w900, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: const Text('SUBMIT ATTENDANCE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1, color: Colors.white)),
      ),
    );
  }
}
