import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._init();
  SupabaseClient get client => Supabase.instance.client;
  SupabaseService._init();

  // --- 1. INTELLIGENCE & ANALYTICS ---
  Future<List<Map<String, dynamic>>> getActionableInsights() async {
    return [
      {'title': 'Attendance Quota', 'subtitle': 'Daily avg is stable at 96%', 'type': 'success'},
      {'title': 'Cloud Treasury', 'subtitle': 'Revenue sync is up to date', 'type': 'info'},
    ];
  }

  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final res = await client.rpc('get_admin_summary');
      return Map<String, dynamic>.from(res);
    } catch (e) {
      try {
        // FIXED: select() in Supabase takes a String, count is a named parameter outside or handled differently per version.
        // For Supabase Flutter 2.x, count is usually a parameter of the query builder.
        final response = await client.from('students').select('student_id');
        return {
          'students': response.length,
          'teachers': 0,
          'staff': 0,
          'parents': 0,
          'totalFees': 0,
        };
      } catch (_) {
        return {'students': 0, 'teachers': 0, 'staff': 0, 'parents': 0, 'totalFees': 0};
      }
    }
  }

  Future<List<Map<String, dynamic>>> getClassStatistics() async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('class_stats').select());
    } catch (_) { return []; }
  }

  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('recent_activity_feed').select().order('timestamp', ascending: false));
    } catch (_) { return []; }
  }

  // --- 2. STAFF & HR OPERATIONS ---
  Future<Map<String, dynamic>?> getStaffProfile(String id) async {
    try {
      return await client.from('staff').select().eq('staff_id', id).maybeSingle();
    } catch (_) { return null; }
  }

  Future<List<Map<String, dynamic>>> getAllStaff() async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('staff').select().order('name'));
    } catch (_) { return []; }
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

  Future<void> staffCheckInOut(String id, String status) async {
    await client.from('attendance').insert({
      'target_id': id,
      'target_type': 'Staff',
      'status': status,
      'date': DateTime.now().toIso8601String().split('T')[0],
      'time': DateTime.now().toIso8601String().split('T')[1].substring(0, 5),
    });
  }

  Future<List<Map<String, dynamic>>> getStaffAttendanceHistory(String id) async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('attendance').select().eq('target_id', id).eq('target_type', 'Staff'));
    } catch (_) { return []; }
  }

  Future<List<Map<String, dynamic>>> getTasks(String id) async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('tasks').select().eq('staff_id', id));
    } catch (_) { return []; }
  }

  Future<void> updateTaskStatus(String id, String s) async {
    await client.from('tasks').update({'status': s}).eq('task_id', id);
  }

  Future<Map<String, dynamic>> getPayrollSummary() async {
    try {
      final res = await client.from('staff').select('salary');
      double total = res.fold(0.0, (sum, item) => sum + (item['salary'] ?? 0));
      return {'total': total, 'staffCount': res.length};
    } catch (_) { return {'total': 0.0, 'staffCount': 0}; }
  }

  Future<List<Map<String, dynamic>>> getLeaveRequests() async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('leave_requests').select('*, staff(name)'));
    } catch (_) { return []; }
  }

  // --- 3. STUDENT & PARENT MANAGEMENT ---
  Future<List<Map<String, dynamic>>> getAllStudents() async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('students').select().order('name'));
    } catch (_) { return []; }
  }

  Future<void> saveStudent(Map<String, dynamic> data) async {
    await client.from('students').upsert(data);
  }

  Future<List<Map<String, dynamic>>> getStudentsByClass(String g, String s) async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('students').select().eq('grade', g).eq('stream', s).order('name'));
    } catch (_) { return []; }
  }

  Future<List<Map<String, dynamic>>> getStudentsByParentPhone(String p) async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('students').select().eq('parent_phone', p));
    } catch (_) { return []; }
  }

  Future<List<Map<String, dynamic>>> getParentChildren(String p) async => await getStudentsByParentPhone(p);

  Future<List<Map<String, dynamic>>> getParents() async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('parents').select().order('name'));
    } catch (_) { return []; }
  }

  Future<void> insertParent(Map<String, dynamic> d) async {
    await client.from('parents').insert(d);
  }

  // --- 4. ACADEMICS & MARKS ---
  Future<void> saveMarks(List<Map<String, dynamic>> m) async {
    await client.from('marks').upsert(m);
  }

  Future<List<Map<String, dynamic>>> getMarksForStudent(String sid, String t, int y) async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('marks').select().eq('student_id', sid).eq('term', t).eq('year', y));
    } catch (_) { return []; }
  }

  Future<List<Map<String, dynamic>>> getMarksFiltered({required String studentId, required String term, required int year}) => getMarksForStudent(studentId, term, year);

  Future<List<Map<String, dynamic>>> getStudentMarks(String sid) async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('marks').select().eq('student_id', sid));
    } catch (_) { return []; }
  }

  // --- 5. ATTENDANCE ---
  Future<void> markAttendance(List<Map<String, dynamic>> r) async {
    await client.from('attendance').upsert(r);
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistory(String g, String s, String d) async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('attendance').select().eq('grade', g).eq('stream', s).eq('date', d));
    } catch (_) { return []; }
  }

  Future<List<Map<String, dynamic>>> getChildAttendance(String sid) async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('attendance').select().eq('target_id', sid).eq('target_type', 'Student'));
    } catch (_) { return []; }
  }

  Future<List<Map<String, dynamic>>> getGlobalAttendanceByDate(String d) async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('attendance').select().eq('date', d).eq('target_type', 'Student'));
    } catch (_) { return []; }
  }

  Future<Map<String, dynamic>> getAttendanceStats() async {
    try {
      final res = await client.from('attendance').select('status').eq('date', DateTime.now().toIso8601String().split('T')[0]);
      int present = res.where((e) => e['status'] == 'Present').length;
      return {'present': present, 'total': res.length};
    } catch (_) { return {'present': 0, 'total': 0}; }
  }

  // --- 6. FINANCE ---
  Future<void> insertFeePayment(Map<String, dynamic> d) async {
    await client.from('fees').insert(d);
  }

  Future<List<Map<String, dynamic>>> getFeeHistory(String sid) async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('fees').select().eq('student_id', sid).order('payment_date', ascending: false));
    } catch (_) { return []; }
  }

  Future<Map<String, dynamic>> getStudentBalance(String sid, String g) async {
    try {
      final struct = await client.from('fee_structure').select().eq('grade', g).maybeSingle();
      final fees = await client.from('fees').select('amount_paid').eq('student_id', sid);
      double total = (struct?['total_fee'] ?? 0).toDouble();
      double paid = fees.fold(0.0, (sum, item) => sum + (item['amount_paid'] ?? 0));
      return {'required': total, 'paid': paid, 'balance': total - paid};
    } catch (_) { return {'required': 0, 'paid': 0, 'balance': 0}; }
  }

  Future<List<Map<String, dynamic>>> getFeeStructure() async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('fee_structure').select());
    } catch (_) { return []; }
  }

  Future<void> updateFeeStructure(String g, double a) async {
    await client.from('fee_structure').upsert({'grade': g, 'total_fee': a});
  }

  Future<List<Map<String, dynamic>>> getFeeReports(String filter) async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('fees').select('*, students(name)').ilike('payment_date', '%$filter%'));
    } catch (_) { return []; }
  }

  // --- 7. OFFICE & SECRETARY ---
  Future<Map<String, dynamic>> getSecretaryStats() async {
    try {
      final s = await client.from('students').select('student_id');
      final a = await client.from('appointments').select('appointment_id').eq('status', 'Scheduled');
      return {'totalStudents': s.length, 'upcomingAppointments': a.length, 'announcements': 3};
    } catch (_) { return {'totalStudents': 0, 'upcomingAppointments': 0, 'announcements': 0}; }
  }

  Future<List<Map<String, dynamic>>> getAppointments() async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('appointments').select().order('appointment_date'));
    } catch (_) { return []; }
  }

  Future<List<Map<String, dynamic>>> getVisitors() async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('visitors').select().order('date', ascending: false));
    } catch (_) { return []; }
  }

  Future<void> insertVisitor(Map<String, dynamic> d) async {
    await client.from('visitors').insert(d);
  }

  // --- 8. HOMEWORK & RESOURCES ---
  Future<void> postHomework(Map<String, dynamic> d) async {
    await client.from('homework').insert(d);
  }

  Future<List<Map<String, dynamic>>> getHomeworkByClass(String g, String s) async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('homework').select().eq('grade', g).eq('stream', s).order('posted_date', ascending: false));
    } catch (_) { return []; }
  }

  Future<void> deleteHomework(String id) async {
    await client.from('homework').delete().eq('homework_id', id);
  }

  Future<List<Map<String, dynamic>>> getResources() async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('resources').select().order('created_at', ascending: false));
    } catch (_) { return []; }
  }

  // --- 9. NOTIFICATIONS ---
  Future<void> postAnnouncement(String t, String m, String r) async {
    await client.from('notifications').insert({'title': t, 'message': m, 'target_role': r});
  }

  Future<List<Map<String, dynamic>>> getNotifications(String r) async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('notifications').select().or('target_role.eq.All,target_role.eq.$r').order('created_at', ascending: false));
    } catch (_) { return []; }
  }

  Future<void> deleteNotification(String id) async {
    await client.from('notifications').delete().eq('notification_id', id);
  }

  Stream<List<Map<String, dynamic>>> get notificationStream => client.from('notifications').stream(primaryKey: ['notification_id']).order('created_at');

  // --- 10. MISC ---
  Future<List<Map<String, dynamic>>> getInventory() async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('inventory').select().order('name'));
    } catch (_) { return []; }
  }

  Future<void> updateStock(String id, int q) async {
    await client.from('inventory').update({'quantity': q}).eq('item_id', id);
  }

  Future<List<Map<String, dynamic>>> getBusRoutes() async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('transport_routes').select().order('name'));
    } catch (_) { return []; }
  }

  Future<void> saveBusRoute(Map<String, dynamic> d) async {
    await client.from('transport_routes').upsert(d);
  }

  Future<void> deleteBusRoute(String id) async {
    await client.from('transport_routes').delete().eq('route_id', id);
  }

  Future<List<Map<String, dynamic>>> getBooks() async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('library_books').select().order('title'));
    } catch (_) { return []; }
  }

  Future<void> saveBook(Map<String, dynamic> d) async {
    await client.from('library_books').upsert(d);
  }

  Future<void> deleteBook(String id) async {
    await client.from('library_books').delete().eq('book_id', id);
  }

  Future<List<Map<String, dynamic>>> getEvents() async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('events').select().order('date'));
    } catch (_) { return []; }
  }

  Future<List<Map<String, dynamic>>> getRecentIncidents() async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('incidents').select().order('date', ascending: false));
    } catch (_) { return []; }
  }

  Future<List<Map<String, dynamic>>> getTeacherSchedule(String id) async {
    try {
      return List<Map<String, dynamic>>.from(await client.from('timetable').select().eq('teacher_id', id));
    } catch (_) { return []; }
  }

  Future<Map<String, dynamic>> getTeacherDashboardStats(String tid, String g, String s) async {
    try {
      final res = await client.from('students').select('student_id').eq('grade', g).eq('stream', s);
      return {'totalStudents': res.length, 'attendanceRate': 96.5, 'pendingAssignments': 2};
    } catch (_) { return {'totalStudents': 0, 'attendanceRate': 0, 'pendingAssignments': 0}; }
  }

  Future<List<String>> getClasses() async { return ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'JSS 1', 'JSS 2', 'JSS 3']; }
  Future<List<String>> getSubjects() async { return ['Mathematics', 'English', 'Science', 'Social Studies', 'CRE']; }
}
