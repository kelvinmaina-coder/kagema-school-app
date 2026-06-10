import 'package:flutter/material.dart';
import '../../models/school_models.dart';
import '../../services/supabase_service.dart';
import '../secretary/student_registration.dart';
import 'student_detail_screen.dart';

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
    bool canEdit = widget.role == 'Admin' || widget.role == 'Secretary';
    bool canDelete = widget.role == 'Admin';
    bool canAdd = widget.role == 'Admin' || widget.role == 'Secretary';

    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      appBar: AppBar(
        title: const Text('Student Directory', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStudents.isEmpty
                    ? _buildEmptyState()
                    : _buildStudentList(canEdit, canDelete),
          ),
        ],
      ),
      floatingActionButton: canAdd ? FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentRegistrationScreen()));
          if (result == true) _loadStudents();
        },
        backgroundColor: const Color(0xFF26A69A),
        child: const Icon(Icons.person_add),
      ) : null,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF26A69A),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search Name or Admission No...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('No Students Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(_searchQuery.isEmpty ? 'Enroll your first student to see them here.' : 'Try a different search term.', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildStudentList(bool canEdit, bool canDelete) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF26A69A).withOpacity(0.1),
              child: Text(student.name.isNotEmpty ? student.name[0].toUpperCase() : '?', style: const TextStyle(color: Color(0xFF26A69A), fontWeight: FontWeight.bold)),
            ),
            title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ADM: ${student.admissionNumber}'),
                Text('${student.grade} - ${student.stream}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(student: student, userRole: widget.role)));
            },
          ),
        );
      },
    );
  }
}
