import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._init();
  SupabaseClient get client => Supabase.instance.client;

  SupabaseService._init();

  // --- 1. ADMIN & GLOBAL ANALYTICS ---
  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final response = await client.rpc('get_admin_summary');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      return {'students': 0, 'teachers': 0, 'staff': 0, 'parents': 0};
    }
  }

  Future<List<Map<String, dynamic>>> getClassStatistics() async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('class_stats').select());
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('recent_activity_feed').select().order('timestamp', ascending: false));
    } catch (e) { return []; }
  }

  // --- 2. STUDENT MANAGEMENT ---
  Future<List<Map<String, dynamic>>> getAllStudents() async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('students').select().order('name'));
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> getStudentsByClass(String grade, String stream) async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('students').select().eq('grade', grade).eq('stream', stream));
    } catch (e) { return []; }
  }

  Future<void> saveStudent(Map<String, dynamic> data) async {
    await client.from('students').upsert(data);
  }

  // --- 3. TEACHER & ACADEMIC MODULE ---
  Future<Map<String, dynamic>> getTeacherDashboardStats(String teacherId, String grade, String stream) async {
    try {
      final res = await client.from('students').select('student_id', count: CountOption.exact).eq('grade', grade).eq('stream', stream);
      return {'totalStudents': res.count ?? 0, 'attendanceRate': 96.5, 'pendingAssignments': 2};
    } catch (e) { return {'totalStudents': 0, 'attendanceRate': 0, 'pendingAssignments': 0}; }
  }

  Future<List<Map<String, dynamic>>> getTeacherSchedule(String teacherId) async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('timetable').select().eq('teacher_id', teacherId));
    } catch (e) { return []; }
  }

  Future<void> saveMarks(List<Map<String, dynamic>> marks) async {
    await client.from('marks').upsert(marks);
  }

  Future<List<Map<String, dynamic>>> getMarksFiltered({required String studentId, required String term, required int year}) async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('marks').select().eq('student_id', studentId).eq('term', term).eq('year', year));
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> getMarksForStudent(String studentId, String term, int year) async {
    return getMarksFiltered(studentId: studentId, term: term, year: year);
  }

  Future<List<Map<String, dynamic>>> getStudentMarks(String studentId) async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('marks').select().eq('student_id', studentId));
    } catch (e) { return []; }
  }

  // --- 4. ATTENDANCE ---
  Future<void> markAttendance(List<Map<String, dynamic>> records) async {
    await client.from('attendance').upsert(records);
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistory(String grade, String stream, String date) async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('attendance').select().eq('grade', grade).eq('stream', stream).eq('date', date));
    } catch (e) { return []; }
  }

  Future<List<Map<String, dynamic>>> getChildAttendance(String studentId) async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('attendance').select().eq('target_id', studentId));
    } catch (e) { return []; }
  }

  // --- 5. FINANCE & FEES ---
  Future<List<Map<String, dynamic>>> getFeeStructure() async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('fee_structure').select());
    } catch (e) { return []; }
  }

  Future<void> insertFeePayment(Map<String, dynamic> data) async {
    await client.from('fees').insert(data);
  }

  Future<List<Map<String, dynamic>>> getFeeHistory(String studentId) async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('fees').select().eq('student_id', studentId));
    } catch (e) { return []; }
  }

  Future<Map<String, dynamic>> getStudentBalance(String studentId, String grade) async {
    try {
      final structure = await client.from('fee_structure').select().eq('grade', grade).maybeSingle();
      final payments = await client.from('fees').select('amount_paid').eq('student_id', studentId);
      double totalRequired = (structure?['total_fee'] ?? 0).toDouble();
      double totalPaid = payments.fold(0.0, (sum, item) => sum + (item['amount_paid'] ?? 0));
      return {'required': totalRequired, 'paid': totalPaid, 'balance': totalRequired - totalPaid};
    } catch (e) { return {'required': 0, 'paid': 0, 'balance': 0}; }
  }

  // --- 6. STAFF & HR ---
  Future<List<Map<String, dynamic>>> getAllStaff() async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('staff').select());
    } catch (e) { return []; }
  }

  Future<void> insertStaff(Map<String, dynamic> data) async {
    await client.from('staff').insert(data);
  }

  Future<void> updateStaff(Map<String, dynamic> data) async {
    await client.from('staff').update(data).eq('staff_id', data['staff_id']);
  }

  Future<void> deleteStaff(String staffId) async {
    await client.from('staff').delete().eq('staff_id', staffId);
  }

  // --- 7. SECRETARY & OFFICE ---
  Future<Map<String, dynamic>> getSecretaryStats() async {
    try {
      final students = await client.from('students').select('student_id', count: CountOption.exact);
      final appointments = await client.from('appointments').select('appointment_id', count: CountOption.exact).eq('status', 'Scheduled');
      return {'totalStudents': students.count ?? 0, 'upcomingAppointments': appointments.count ?? 0, 'announcements': 3};
    } catch (e) { return {'totalStudents': 0, 'upcomingAppointments': 0, 'announcements': 0}; }
  }

  Future<List<Map<String, dynamic>>> getAppointments() async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('appointments').select().order('appointment_date'));
    } catch (e) { return []; }
  }

  // --- 8. INVENTORY ---
  Future<List<Map<String, dynamic>>> getInventory() async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('inventory').select());
    } catch (e) { return []; }
  }

  Future<void> updateStock(String itemId, int qty) async {
    await client.from('inventory').update({'quantity': qty}).eq('item_id', itemId);
  }

  // --- 9. PARENT PORTAL ---
  Future<List<Map<String, dynamic>>> getParentChildren(String phone) async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('students').select().eq('parent_phone', phone));
    } catch (e) { return []; }
  }

  // --- 10. NOTIFICATIONS ---
  Future<List<Map<String, dynamic>>> getNotifications(String role) async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('notifications').select().or('target_role.eq.All,target_role.eq.$role').order('created_at', ascending: false));
    } catch (e) { return []; }
  }

  Stream<List<Map<String, dynamic>>> get notificationStream {
    return client.from('notifications').stream(primaryKey: ['notification_id']).order('created_at');
  }
}
