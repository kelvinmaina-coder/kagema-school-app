import 'package:flutter/material.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
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
    final dt = context.dt;
    final theme = context.kagemaTheme;
    final roleColor = RoleColors.of(widget.role);
    final compColor = RoleColors.complement(widget.role);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('STUDENT RECORDS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: RoleColors.gradient(widget.role, dark: context.isDark),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.group_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ),
      ),
      body: theme?.buildCreativeBackground(
        isDark: context.isDark,
        primaryBlob: roleColor,
        secondaryBlob: compColor,
        child: RoleAuraLayer(
          roleColor: roleColor,
          isDark: context.isDark,
          child: Column(
            children: [
              SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
              _buildSearchBox(dt, roleColor, theme),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: roleColor))
                    : _filteredStudents.isEmpty
                        ? _buildEmptyState(dt)
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: _filteredStudents.length,
                            itemBuilder: (context, index) {
                              final student = _filteredStudents[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: theme?.buildGlowContainer(
                                  accentColor: roleColor,
                                  borderRadius: 24,
                                  padding: EdgeInsets.zero,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: roleColor.withValues(alpha: 0.4), width: 1.5),
                                      ),
                                      child: CircleAvatar(
                                        radius: 24,
                                        backgroundColor: dt.roleSoftBg(roleColor),
                                        child: Text(student.name[0].toUpperCase(), 
                                          style: TextStyle(color: roleColor, fontWeight: FontWeight.w900, fontSize: 18)
                                        ),
                                      ),
                                    ),
                                    title: Text(student.name.toUpperCase(), 
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: dt.textPrimary, letterSpacing: 0.5)
                                    ),
                                    subtitle: Text('ADM: ${student.admissionNumber} • ${student.grade}', 
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: dt.textSecondary)
                                    ),
                                    trailing: Icon(Icons.chevron_right_rounded, color: dt.iconInactive),
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(student: student, userRole: widget.role))),
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

  Widget _buildSearchBox(DT dt, Color color, GeminiThemeExtension? theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: theme?.buildGlowContainer(
        accentColor: color,
        borderRadius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: TextStyle(fontWeight: FontWeight.bold, color: dt.textPrimary),
          decoration: InputDecoration(
            hintText: 'SEARCH BY NAME OR ADMISSION...',
            hintStyle: TextStyle(color: dt.hint, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            prefixIcon: Icon(Icons.search_rounded, color: color, size: 22),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(DT dt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_rounded, size: 80, color: dt.iconInactive),
          const SizedBox(height: 24),
          Text('NO STUDENT RECORDS FOUND', 
            style: TextStyle(color: dt.textMuted, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12)
          ),
        ],
      ),
    );
  }
}
