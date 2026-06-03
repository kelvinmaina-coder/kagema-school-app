import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Student {
  String id;
  String name;
  String className;
  String parentName;
  String parentPhone;
  String parentEmail;
  String birthCertificate;
  String dateOfBirth;
  String address;
  String medicalInfo;
  String previousSchool;
  String admissionNumber;

  Student({
    required this.id,
    required this.name,
    required this.className,
    required this.parentName,
    this.parentPhone = '',
    this.parentEmail = '',
    this.birthCertificate = '',
    this.dateOfBirth = '',
    this.address = '',
    this.medicalInfo = '',
    this.previousSchool = '',
    this.admissionNumber = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'className': className,
    'parentName': parentName,
    'parentPhone': parentPhone,
    'parentEmail': parentEmail,
    'birthCertificate': birthCertificate,
    'dateOfBirth': dateOfBirth,
    'address': address,
    'medicalInfo': medicalInfo,
    'previousSchool': previousSchool,
    'admissionNumber': admissionNumber,
  };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    id: json['id'],
    name: json['name'],
    className: json['className'],
    parentName: json['parentName'],
    parentPhone: json['parentPhone'] ?? '',
    parentEmail: json['parentEmail'] ?? '',
    birthCertificate: json['birthCertificate'] ?? '',
    dateOfBirth: json['dateOfBirth'] ?? '',
    address: json['address'] ?? '',
    medicalInfo: json['medicalInfo'] ?? '',
    previousSchool: json['previousSchool'] ?? '',
    admissionNumber: json['admissionNumber'] ?? '',
  );
}

class StudentDatabase {
  static const String _storageKey = 'kagema_students';
  
  static Future<List<Student>> getStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data == null) return [];
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.map((e) => Student.fromJson(e as Map<String, dynamic>)).toList();
  }
  
  static Future<void> saveStudents(List<Student> students) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(students.map((s) => s.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
  
  static Future<void> addStudent(Student student) async {
    final students = await getStudents();
    students.add(student);
    await saveStudents(students);
  }
  
  static Future<void> deleteStudent(String id) async {
    final students = await getStudents();
    students.removeWhere((s) => s.id == id);
    await saveStudents(students);
  }
  
  static Future<void> updateStudent(Student updated) async {
    final students = await getStudents();
    final index = students.indexWhere((s) => s.id == updated.id);
    if (index != -1) students[index] = updated;
    await saveStudents(students);
  }
}
