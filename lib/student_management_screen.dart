import 'package:flutter/material.dart';
import 'student_database.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  List<Student> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final students = await StudentDatabase.getStudents();
    setState(() {
      _students = students;
      _isLoading = false;
    });
  }

  Future<void> _addStudent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditStudentScreen()),
    );
    if (result == true) _loadStudents();
  }

  Future<void> _editStudent(Student student) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditStudentScreen(student: student)),
    );
    if (result == true) _loadStudents();
  }

  Future<void> _viewStudent(Student student) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StudentDetailScreen(student: student)),
    );
  }

  Future<void> _confirmDelete(Student student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.name}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await StudentDatabase.deleteStudent(student.id);
      _loadStudents();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student deleted successfully'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      appBar: AppBar(
        title: const Text('Student Management', style: TextStyle(fontWeight: FontWeight.bold)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addStudent,
        backgroundColor: const Color(0xFF26A69A),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('No Students Registered', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Tap + to register your first student', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _viewStudent(student),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [const Color(0xFF26A69A), const Color(0xFF1B8A7A)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      student.name[0].toUpperCase(),
                                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.name,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF26A69A).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              student.className,
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF26A69A)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(Icons.family_restroom, size: 14, color: Colors.grey[500]),
                                          const SizedBox(width: 4),
                                          Text(
                                            student.parentName,
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                      if (student.birthCertificate.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.description, size: 12, color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Birth Cert: ${student.birthCertificate}',
                                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF26A69A)),
                                      onPressed: () => _editStudent(student),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _confirmDelete(student),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class StudentDetailScreen extends StatelessWidget {
  final Student student;
  const StudentDetailScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      appBar: AppBar(
        title: Text(student.name),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF26A69A), const Color(0xFF1B8A7A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        student.name[0].toUpperCase(),
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF26A69A)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    student.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      student.className,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoCard(Icons.person, 'Full Name', student.name),
                  _buildInfoCard(Icons.class_, 'Class', student.className),
                  _buildInfoCard(Icons.family_restroom, 'Parent/Guardian', student.parentName),
                  _buildInfoCard(Icons.phone, 'Parent Phone', student.parentPhone),
                  _buildInfoCard(Icons.email, 'Parent Email', student.parentEmail),
                  _buildInfoCard(Icons.description, 'Birth Certificate', student.birthCertificate),
                  _buildInfoCard(Icons.calendar_today, 'Date of Birth', student.dateOfBirth),
                  _buildInfoCard(Icons.location_on, 'Address', student.address),
                  _buildInfoCard(Icons.medical_services, 'Medical Info', student.medicalInfo),
                  _buildInfoCard(Icons.school, 'Previous School', student.previousSchool),
                  _buildInfoCard(Icons.numbers, 'Admission Number', student.admissionNumber),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.edit),
                          label: const Text('EDIT PROFILE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF26A69A),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF26A69A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF26A69A), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AddEditStudentScreen extends StatefulWidget {
  final Student? student;
  const AddEditStudentScreen({super.key, this.student});

  @override
  State<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for all fields
  final _nameController = TextEditingController();
  final _classNameController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _birthCertificateController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _addressController = TextEditingController();
  final _medicalInfoController = TextEditingController();
  final _previousSchoolController = TextEditingController();
  final _admissionNumberController = TextEditingController();
  
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      _nameController.text = widget.student!.name;
      _classNameController.text = widget.student!.className;
      _parentNameController.text = widget.student!.parentName;
      _parentPhoneController.text = widget.student!.parentPhone;
      _parentEmailController.text = widget.student!.parentEmail;
      _birthCertificateController.text = widget.student!.birthCertificate;
      _dateOfBirthController.text = widget.student!.dateOfBirth;
      _addressController.text = widget.student!.address;
      _medicalInfoController.text = widget.student!.medicalInfo;
      _previousSchoolController.text = widget.student!.previousSchool;
      _admissionNumberController.text = widget.student!.admissionNumber;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _classNameController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _parentEmailController.dispose();
    _birthCertificateController.dispose();
    _dateOfBirthController.dispose();
    _addressController.dispose();
    _medicalInfoController.dispose();
    _previousSchoolController.dispose();
    _admissionNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 10)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF26A69A)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateOfBirthController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final student = Student(
      id: widget.student?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      className: _classNameController.text.trim(),
      parentName: _parentNameController.text.trim(),
      parentPhone: _parentPhoneController.text.trim(),
      parentEmail: _parentEmailController.text.trim(),
      birthCertificate: _birthCertificateController.text.trim(),
      dateOfBirth: _dateOfBirthController.text.trim(),
      address: _addressController.text.trim(),
      medicalInfo: _medicalInfoController.text.trim(),
      previousSchool: _previousSchoolController.text.trim(),
      admissionNumber: _admissionNumberController.text.trim(),
    );
    
    if (widget.student == null) {
      await StudentDatabase.addStudent(student);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student registered successfully!'), backgroundColor: Colors.green),
      );
    } else {
      await StudentDatabase.updateStudent(student);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student information updated!'), backgroundColor: Colors.green),
      );
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      appBar: AppBar(
        title: Text(widget.student == null ? 'Register New Student' : 'Edit Student'),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildSectionHeader('Basic Information', Icons.person),
              _buildTextField(_nameController, 'Student Full Name *', Icons.person),
              _buildTextField(_classNameController, 'Class/Form *', Icons.class_),
              _buildTextField(_admissionNumberController, 'Admission Number', Icons.numbers),
              
              _buildSectionHeader('Parent/Guardian Information', Icons.family_restroom),
              _buildTextField(_parentNameController, 'Parent/Guardian Name *', Icons.family_restroom),
              _buildTextField(_parentPhoneController, 'Parent Phone Number *', Icons.phone, keyboardType: TextInputType.phone),
              _buildTextField(_parentEmailController, 'Parent Email', Icons.email, keyboardType: TextInputType.emailAddress),
              
              _buildSectionHeader('Legal Documents', Icons.description),
              _buildTextField(_birthCertificateController, 'Birth Certificate Number', Icons.description),
              _buildDateField(_dateOfBirthController, () => _selectDate(context)),
              _buildTextField(_addressController, 'Home Address', Icons.location_on),
              
              _buildSectionHeader('School Information', Icons.school),
              _buildTextField(_previousSchoolController, 'Previous School', Icons.school),
              _buildTextField(_medicalInfoController, 'Medical Information (Allergies, etc.)', Icons.medical_services, maxLines: 2),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26A69A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    widget.student == null ? 'REGISTER STUDENT' : 'UPDATE STUDENT',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF26A69A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF26A69A), size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF26A69A)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: label.contains('*') ? (v) => v == null || v.isEmpty ? 'This field is required' : null : null,
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: 'Date of Birth',
          prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF26A69A)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF26A69A)),
        ),
      ),
    );
  }
}

