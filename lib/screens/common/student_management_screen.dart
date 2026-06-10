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
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> studentMaps;
      
      if (widget.role.toLowerCase() == 'teacher') {
        studentMaps = await SupabaseService.instance.getStudentsByClass(_selectedGrade!, _selectedStream!);
      } else {
        // Fetch all students from Supabase
        final response = await SupabaseService.instance.client
            .from('students')
            .select()
            .order('name');
        studentMaps = List<Map<String, dynamic>>.from(response);
      }
      
      if (mounted) {
        setState(() {
          _students = studentMaps.map((m) => Student.fromMap(m)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading students from Supabase: $e");
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
    bool canAdd = widget.role.toLowerCase() == 'admin' || widget.role.toLowerCase() == 'secretary';
    final theme = Theme.of(context);
    final gemini = theme.extension<GeminiThemeExtension>();
    final Color primaryColor = _getRoleColor();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildHeroAppBar(theme, primaryColor),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    _buildSearchBox(theme, primaryColor),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PUPILS: ${_filteredStudents.length}',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: primaryColor.withOpacity(0.5), letterSpacing: 2),
                        ),
                        if (widget.role.toLowerCase() == 'teacher')
                          Text('$_selectedGrade $_selectedStream', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _isLoading
                        ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                        : _filteredStudents.isEmpty
                            ? _buildEmptyState()
                            : _buildStudentGrid(theme, primaryColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: canAdd ? FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRegistrationScreen()));
          if (result == true) _loadStudents();
        },
        backgroundColor: primaryColor,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Enroll Student', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
    );
  }

  Widget _buildHeroAppBar(ThemeData theme, Color color) {
    return SliverAppBar(
      expandedHeight: 120.0,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text('Class Directory', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBox(ThemeData theme, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search pupil by name or ADM...',
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
      default: return Colors.blueGrey;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Column(
          children: [
            Icon(Icons.group_off, size: 60, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('No pupils found in cloud database.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentGrid(ThemeData theme, Color primaryColor) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Text(student.name[0], style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),
            title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('ADM: ${student.admissionNumber} • ${student.grade}'),
            trailing: widget.role.toLowerCase() == 'teacher' 
              ? IconButton(
                  icon: const Icon(Icons.edit_document, color: Colors.orange), 
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => MarksEntryScreen(grade: student.grade, stream: student.stream, subject: 'Mathematics')));
                  }
                )
              : const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(student: student, userRole: widget.role)));
            },
          ),
        );
      },
    );
  }
}
