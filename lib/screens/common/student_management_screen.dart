import 'package:flutter/material.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../secretary/student_registration.dart';
import '../teacher/marks_entry.dart';
import 'student_detail_screen.dart';
import '../../app_theme.dart';

class StudentManagementScreen extends StatefulWidget {
  final String role; 
  final String? initialGrade;
  final String? initialStream;

  const StudentManagementScreen({
    super.key, 
    required this.role,
    this.initialGrade,
    this.initialStream,
  });

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  List<Student> _students = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedGrade;
  String? _selectedStream;

  @override
  void initState() {
    super.initState();
    _selectedGrade = widget.initialGrade ?? 'Grade 1';
    _selectedStream = widget.initialStream ?? 'North';
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> studentMaps;
      if (widget.role.toLowerCase() == 'teacher') {
        studentMaps = await SupabaseService.instance.getStudentsByClass(_selectedGrade!, _selectedStream!);
      } else {
        studentMaps = await SupabaseService.instance.getAllStudents();
      }
      
      if (mounted) {
        setState(() {
          _students = studentMaps.map((m) => Student.fromMap(m)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Student> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    return _students.where((s) => 
      s.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
      s.admissionNumber.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final Color primaryColor = _getRoleColor();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Pupil Intelligence', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.8)]),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Column(
          children: [
            SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
            _buildSearchBox(theme, primaryColor),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredStudents.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: primaryColor.withOpacity(0.1),
                                  child: Text(student.name[0], style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                                ),
                                title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('ADM: ${student.admissionNumber} • ${student.grade}'),
                                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(student: student, userRole: widget.role))),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox(ThemeData theme, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search by name or ADM...',
          prefixIcon: Icon(Icons.search, color: color),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Color _getRoleColor() {
    switch (widget.role.toLowerCase()) {
      case 'admin': return const Color(0xFF5C6BC0);
      case 'teacher': return Colors.teal;
      case 'secretary': return Colors.blueGrey;
      default: return Colors.indigo;
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No pupils found in cloud database.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
