import 'package:flutter/material.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../secretary/student_registration.dart';
import 'student_detail_screen.dart';
import '../../app_theme.dart';

class StudentManagementScreen extends StatefulWidget {
  final String role; 
  const StudentManagementScreen({super.key, required this.role});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  List<Student> _students = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.instance.getAllStudents();
      if (mounted) {
        setState(() {
          _students = data.map((json) => Student.fromMap(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading students: $e");
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
    bool canManage = widget.role == 'Admin' || widget.role == 'Secretary';
    final Color primaryColor = _getRoleColor();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Student Registry', 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5, color: Colors.white)
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
            gradient: LinearGradient(
              colors: [primaryColor.withOpacity(0.9), primaryColor.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -10,
                child: Icon(Icons.school_rounded, size: 140, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadStudents,
          ),
        ],
      ),
      body: gemini?.buildCreativeBackground(
        isDark: theme.brightness == Brightness.dark,
        child: Column(
          children: [
            SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
            _buildSearchBox(theme, primaryColor, gemini),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredStudents.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            final content = ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundColor: primaryColor.withOpacity(0.1),
                                child: Text(student.name.isNotEmpty ? student.name[0].toUpperCase() : '?', 
                                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 18)
                                ),
                              ),
                              title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                              subtitle: Text('ADM: ${student.admissionNumber} • ${student.grade}', 
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(student: student, userRole: widget.role)));
                              },
                            );

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: gemini?.buildGlowContainer(
                                borderRadius: 24,
                                borderThickness: 1,
                                backgroundColor: theme.cardColor.withOpacity(0.85),
                                padding: EdgeInsets.zero,
                                child: content,
                              ) ?? Card(child: content),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: canManage ? gemini?.buildGlowContainer(
        borderRadius: 30,
        borderThickness: 2,
        backgroundColor: primaryColor,
        padding: EdgeInsets.zero,
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRegistrationScreen()));
            if (result == true) _loadStudents();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add_rounded),
          label: const Text('Enroll Student', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ) : null,
    );
  }

  Widget _buildSearchBox(ThemeData theme, Color color, GeminiThemeExtension? gemini) {
    final content = TextField(
      onChanged: (v) => setState(() => _searchQuery = v),
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: 'Search by name or ADM...',
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        prefixIcon: Icon(Icons.search_rounded, color: color, size: 22),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: gemini?.buildGlowContainer(
        borderRadius: 20,
        borderThickness: 1.5,
        backgroundColor: theme.cardColor.withOpacity(0.9),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: content,
      ) ?? Container(
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: content,
      ),
    );
  }

  Color _getRoleColor() {
    switch (widget.role.toLowerCase()) {
      case 'admin': return const Color(0xFF1A237E);
      case 'teacher': return const Color(0xFF00695C);
      case 'secretary': return const Color(0xFF4A148C);
      default: return const Color(0xFFD84315);
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('NO STUDENT RECORDS FOUND', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
