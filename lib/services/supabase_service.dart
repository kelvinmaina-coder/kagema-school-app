import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._init();
  SupabaseClient get _supabase => Supabase.instance.client;

  SupabaseService._init();

  // --- 1. ADMIN & GLOBAL ANALYTICS ---
  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final response = await _supabase.rpc('get_admin_summary');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      return {'students': 0, 'teachers': 0, 'staff': 0, 'parents': 0};
    }
  }

  Future<List<Map<String, dynamic>>> getClassStatistics() async {
    try {
      return List<Map<String, dynamic>>.from(await _supabase.from('class_stats').select());
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    try {
      return List<Map<String, dynamic>>.from(await _supabase.from('recent_activity_feed').select());
    } catch (e) { return []; }
  }

  // --- 2. STUDENT MANAGEMENT ---
  Future<List<Map<String, dynamic>>> getAllStudents() async {
    try {
      return List<Map<String, dynamic>>.from(await _supabase.from('students').select().order('name'));
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> getStudentsByClass(String grade, String stream) async {
    try {
      return List<Map<String, dynamic>>.from(await _supabase.from('students').select().eq('grade', grade).eq('stream', stream));
    } catch (e) { return []; }
  }

  Future<void> saveStudent(Map<String, dynamic> data) async {
    await _supabase.from('students').upsert(data);
  }

  // --- 3. TEACHER & ACADEMIC MODULE ---
  Future<Map<String, dynamic>> getTeacherDashboardStats(String teacherId, String grade, String stream) async {
    try {
      final res = await _supabase.from('students').select('student_id', count: CountOption.exact).eq('grade', grade).eq('stream', stream);
      return {'totalStudents': res.count ?? 0, 'attendanceRate': 95.0, 'pendingAssignments': 3};
    } catch (e) { return {'totalStudents': 0, 'attendanceRate': 0, 'pendingAssignments': 0}; }
  }

  Future<List<Map<String, dynamic>>> getTeacherSchedule(String teacherId) async {
    try {
      return List<Map<String, dynamic>>.from(await _supabase.from('timetable').select().eq('teacher_id', teacherId));
    } catch (e) { return []; }
  }

  Future<void> saveMarks(List<Map<String, dynamic>> marks) async {
    await _supabase.from('marks').upsert(marks);
  }

  Future<List<Map<String, dynamic>>> getMarksForStudent(String studentId, String term, int year) async {
    try {
      return List<Map<String, dynamic>>.from(await _supabase.from('marks').select().eq('student_id', studentId).eq('term', term).eq('year', year));
    } catch (e) { return []; }
  }

  // --- 4. ATTENDANCE ---
  Future<void> markAttendance(List<Map<String, dynamic>> records) async {
    await _supabase.from('attendance').upsert(records);
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistory(String grade, String stream, String date) async {
    try {
      return List<Map<String, dynamic>>.from(await _supabase.from('attendance').select().eq('grade', grade).eq('stream', stream).eq('date', date));
    } catch (e) { return []; }
  }

  // --- 5. FINANCE & FEES ---
  Future<List<Map<String, dynamic>>> getFeeStructure() async {
    try {
      return List<Map<String, dynamic>>.from(await _supabase.from('fee_structure').select());
    } catch (e) { return []; }
  }

  Future<void> insertFeePayment(Map<String, dynamic> data) async {
    await _supabase.from('fees').insert(data);
  }

  Future<List<Map<String, dynamic>>> getFeeHistory(String studentId) async {
    try {
      return List<Map<String, dynamic>>.from(await _supabase.from('fees').select().eq('student_id', studentId));
    } catch (e) { return []; }
  }

  // --- 6. STAFF & HR ---
  Future<List<Map<String, dynamic>>> getAllStaff() async {
    try {
      return List<Map<String, dynamic>>.from(await _supabase.from('staff').select());
    } catch (e) { return []; }
  }

  // --- 7. SECRETARY & OFFICE ---
  Future<Map<String, dynamic>> getSecretaryStats() async {
    try {
      final students = await _supabase.from('students').select('student_id', count: CountOption.exact);
      final appointments = await _supabase.from('appointments').select('appointment_id', count: CountOption.exact).eq('status', 'Scheduled');
      return {
        'totalStudents': students.count ?? 0,
        'newAdmissions': 5,
        'upcomingAppointments': appointments.count ?? 0,
        'announcements': 2
      };
    } catch (e) { return {'totalStudents': 0, 'newAdmissions': 0, 'upcomingAppointments': 0, 'announcements': 0}; }
  }

  Future<List<Map<String, dynamic>>> getAppointments() async {
    try {
      return List<Map<String, dynamic>>.from(await _supabase.from('appointments').select().order('appointment_date'));
    } catch (e) { return []; }
  }

  // --- 8. INVENTORY & LOGISTICS ---
  Future<List<Map<String, dynamic>>> getInventory() async {
    try {
      return List<Map<String, dynamic>>.from(await _supabase.from('inventory').select());
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> getBusRoutes() async {
    try {
      return List<Map<String, dynamic>>.from(await _supabase.from('transport_routes').select());
    } catch (e) { return []; }
  }

  // --- 9. NOTIFICATIONS ---
  Future<List<Map<String, dynamic>>> getNotifications(String role) async {
    try {
      return List<Map<String, dynamic>>.from(await _supabase.from('notifications').select().or('target_role.eq.All,target_role.eq.$role').order('created_at', ascending: false));
    } catch (e) { return []; }
  }

  Stream<List<Map<String, dynamic>>> get notificationStream {
    return _supabase.from('notifications').stream(primaryKey: ['notification_id']).order('created_at');
  }

  SupabaseClient get client => _supabase;
}
