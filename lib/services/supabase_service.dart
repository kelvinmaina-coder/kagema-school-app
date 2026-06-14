import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'offline_db_service.dart';
import 'package:intl/intl.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._init();
  SupabaseClient get client => Supabase.instance.client;
  SupabaseService._init();

  // --- HELPER: NETWORK AWARE WRAPPERS ---
  Future<dynamic> _getDataWithCache(String key, Future<dynamic> Function() networkCall) async {
    try {
      final data = await networkCall();
      await OfflineDbService.instance.saveCache(key, data);
      return data;
    } catch (e) {
      debugPrint("Offline Mode: Fetching $key from vault.");
      return await OfflineDbService.instance.getCache(key);
    }
  }

  Future<void> _performMutation(String action, Map<String, dynamic> payload, Future<void> Function() networkCall) async {
    try {
      await networkCall();
    } catch (e) {
      await OfflineDbService.instance.addToQueue(action, payload);
      throw "OFFLINE_QUEUED"; 
    }
  }

  // --- 1. ADMIN & SECRETARY HUB OPERATIONS ---
  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final students = await client.from('students').select().count(CountOption.exact);
      final staff = await client.from('staff').select().count(CountOption.exact);
      final parents = await client.from('parents').select().count(CountOption.exact);
      
      final feesData = await client.from('fees').select('amount_paid');
      double totalFees = 0;
      for (var f in feesData) {
        totalFees += (f['amount_paid'] as num? ?? 0).toDouble();
      }
      
      return {
        'students': students.count,
        'staff': staff.count,
        'parents': parents.count,
        'totalFees': totalFees.toInt(),
      };
    } catch (e) {
      return {'students': 0, 'staff': 0, 'parents': 0, 'totalFees': 0};
    }
  }

  Future<Map<String, dynamic>> getSecretaryStats() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastMonth = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 30)));
    
    try {
      final v = await client.from('visitors').select().eq('date', today).count(CountOption.exact);
      final a = await client.from('appointments').select().like('appointment_date', '$today%').count(CountOption.exact);
      final s = await client.from('students').select().count(CountOption.exact);
      final n = await client.from('students').select().gte('admission_date', lastMonth).count(CountOption.exact);
      
      return {
        'visitors_today': v.count,
        'upcomingAppointments': a.count,
        'totalStudents': s.count,
        'newAdmissions': n.count,
      };
    } catch (e) {
      return {'visitors_today': 0, 'upcomingAppointments': 0, 'totalStudents': 0, 'newAdmissions': 0};
    }
  }

  // --- 2. STAFF HUB OPERATIONS ---
  Future<Map<String, dynamic>?> getStaffProfileByEmail(String email) async {
    return await client.from('staff').select().eq('email', email).maybeSingle();
  }

  Future<Map<String, dynamic>?> getStaffProfile(String id) async => await client.from('staff').select().eq('staff_id', id).maybeSingle();
  
  Future<List<Map<String, dynamic>>> getTasks(String staffId) async {
    return List<Map<String, dynamic>>.from(await client.from('tasks').select().eq('assigned_to', staffId).order('due_date'));
  }

  Future<void> updateTaskStatus(String id, String status) async {
    await client.from('tasks').update({'status': status}).eq('task_id', id);
  }

  Future<void> requestLeave(Map<String, dynamic> data) async => await client.from('leave_requests').insert(data);
  
  Future<void> updateLeaveStatus(String id, String status) async {
    await client.from('leave_requests').update({'status': status}).eq('leave_id', id);
  }

  Future<List<Map<String, dynamic>>> getStaffLeaveHistory(String staffId) async {
    return List<Map<String, dynamic>>.from(await client.from('leave_requests').select().eq('staff_id', staffId).order('date', ascending: false));
  }

  Future<List<Map<String, dynamic>>> getStaffAttendanceHistory(String id) async {
    return List<Map<String, dynamic>>.from(await client.from('attendance').select().eq('target_id', id).order('date', ascending: false));
  }

  Future<void> staffCheckInOut(String id, String status) async {
    final now = DateTime.now();
    await client.from('attendance').insert({
      'target_id': id, 'status': status, 'date': DateFormat('yyyy-MM-dd').format(now),
      'time': DateFormat('hh:mm a').format(now), 'target_type': 'Staff',
    });
  }

  Future<List<Map<String, dynamic>>> getAllStaff() async {
    return List<Map<String, dynamic>>.from(await client.from('staff').select().order('name'));
  }

  Future<void> insertStaff(Map<String, dynamic> d) async => await client.from('staff').insert(d);
  Future<void> updateStaff(Map<String, dynamic> d) async => await client.from('staff').update(d).eq('staff_id', d['staff_id']);
  Future<void> deleteStaff(String staffId) async => await client.from('staff').delete().eq('staff_id', staffId);

  // --- 3. TEACHER & ACADEMICS ---
  Future<Map<String, dynamic>> getTeacherDashboardStats(String tid, String g, String s) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      final studentCount = await client.from('students').select().eq('grade', g).eq('stream', s).count(CountOption.exact);
      final attendance = await client.from('attendance').select().eq('grade', g).eq('stream', s).eq('date', today);
      final hw = await client.from('homework').select().eq('grade', g).eq('stream', s).count(CountOption.exact);
      
      double rate = (studentCount.count ?? 0) == 0 ? 0 : (attendance.where((r) => r['status'] == 'Present').length / studentCount.count!) * 100;
      return {
        'totalStudents': studentCount.count ?? 0,
        'attendanceRate': rate,
        'pendingAssignments': hw.count ?? 0,
      };
    } catch (e) {
      return {'totalStudents': 0, 'attendanceRate': 0.0, 'pendingAssignments': 0};
    }
  }

  Future<List<Map<String, dynamic>>> getTeacherSchedule(String id) async {
    final res = await client.from('timetable').select().eq('teacher_id', id).order('start_time');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> saveMarks(List<Map<String, dynamic>> m) async => await client.from('marks').upsert(m);
  
  Future<List<Map<String, dynamic>>> getMarksFiltered({required String studentId, required String term, required int year}) async {
    return List<Map<String, dynamic>>.from(await client.from('marks').select().eq('student_id', studentId).eq('term', term).eq('year', year));
  }

  Future<void> postHomework(Map<String, dynamic> d) async => await client.from('homework').upsert(d);
  Future<void> deleteHomework(String id) async => await client.from('homework').delete().eq('homework_id', id);
  Future<List<Map<String, dynamic>>> getHomeworkByClass(String g, String s) async {
    return List<Map<String, dynamic>>.from(await client.from('homework').select().eq('grade', g).eq('stream', s).order('posted_date', ascending: false));
  }

  // --- 4. PARENT & PUPIL NEXUS ---
  Future<List<Map<String, dynamic>>> getParentChildren(String phone) async {
    return List<Map<String, dynamic>>.from(await client.from('students').select().eq('parent_phone', phone).order('name'));
  }

  Future<List<Map<String, dynamic>>> getStudentsByParentPhone(String phone) async => await getParentChildren(phone);

  Future<List<Map<String, dynamic>>> getStudentMarks(String id) async => List<Map<String, dynamic>>.from(await client.from('marks').select().eq('student_id', id).order('year', ascending: false));
  
  Future<List<Map<String, dynamic>>> getChildAttendance(String id) async => List<Map<String, dynamic>>.from(await client.from('attendance').select().eq('target_id', id).order('date', ascending: false));

  Future<Map<String, dynamic>> getStudentBalance(String id, String grade) async {
    final struct = await client.from('fee_structure').select('total_fee').eq('grade', grade).maybeSingle();
    final paid = await client.from('fees').select('amount_paid').eq('student_id', id);
    double totalFee = (struct?['total_fee'] as num? ?? 15000.0).toDouble();
    double totalPaid = paid.fold(0.0, (sum, item) => sum + (item['amount_paid'] as num? ?? 0).toDouble());
    return {'total_fee': totalFee, 'total_paid': totalPaid, 'balance': totalFee - totalPaid};
  }

  Future<List<Map<String, dynamic>>> getClassTimetable(String g, String s) async {
    return List<Map<String, dynamic>>.from(await client.from('timetable').select().eq('grade', g).eq('stream', s).order('start_time'));
  }

  // --- 5. FINANCE & REVENUE OPERATIONS ---
  Future<Map<String, dynamic>> getFinancialSummary() async {
    final incomeRes = await client.from('income').select('amount');
    final feesRes = await client.from('fees').select('amount_paid, payment_method');
    final expensesRes = await client.from('expenses').select('amount');
    double totalIncome = incomeRes.fold(0.0, (sum, item) => sum + (item['amount'] as num? ?? 0.0).toDouble());
    double totalWaivers = 0.0;
    for (var item in feesRes) { 
      double amt = (item['amount_paid'] as num? ?? 0.0).toDouble();
      if (item['payment_method'] == 'Waiver') { totalWaivers += amt; } else { totalIncome += amt; }
    }
    double totalExpenses = expensesRes.fold(0.0, (sum, item) => sum + (item['amount'] as num? ?? 0.0).toDouble());
    return {'total_income': totalIncome, 'total_expenses': totalExpenses, 'total_waivers': totalWaivers};
  }

  Future<void> insertFeePayment(Map<String, dynamic> d) async => await client.from('fees').insert(d);
  Future<void> updateFeePayment(Map<String, dynamic> d) async => await client.from('fees').update(d).eq('fee_id', d['fee_id']);
  Future<void> deleteFeePayment(String id) async => await client.from('fees').delete().eq('fee_id', id);
  Future<List<Map<String, dynamic>>> getFeeHistory(String sid) async => List<Map<String, dynamic>>.from(await client.from('fees').select().eq('student_id', sid).order('payment_date', ascending: false));
  Future<List<Map<String, dynamic>>> getFeeStructure() async => List<Map<String, dynamic>>.from(await client.from('fee_structure').select());
  Future<void> updateFeeStructure(String g, double a) async => await client.from('fee_structure').upsert({'grade': g, 'total_fee': a});

  Future<List<Map<String, dynamic>>> getIncomeEntries() async => List<Map<String, dynamic>>.from(await client.from('income').select().order('date', ascending: false));
  Future<void> upsertIncome(Map<String, dynamic> d) async => await client.from('income').upsert(d);
  Future<void> deleteIncome(String id) async => await client.from('income').delete().eq('income_id', id);

  Future<List<Map<String, dynamic>>> getExpenses() async => List<Map<String, dynamic>>.from(await client.from('expenses').select().order('date', ascending: false));
  Future<void> upsertExpense(Map<String, dynamic> d) async => await client.from('expenses').upsert(d);
  Future<void> deleteExpense(String id) async => await client.from('expenses').delete().eq('expense_id', id);

  Future<List<Map<String, dynamic>>> getFeeReports(String date) async => List<Map<String, dynamic>>.from(await client.from('fees').select('*, students(name)').like('payment_date', '%$date%').order('payment_date'));

  // --- 6. LOGISTICS & ASSETS ---
  Future<List<Map<String, dynamic>>> getInventory() async {
    return List<Map<String, dynamic>>.from(await client.from('inventory').select().order('name'));
  }
  Future<void> insertInventory(Map<String, dynamic> d) async => await client.from('inventory').upsert(d);
  Future<void> deleteInventoryItem(String id) async => await client.from('inventory').delete().eq('item_id', id);
  Future<void> updateStock(String id, int q) async => await client.from('inventory').update({'quantity': q}).eq('item_id', id);

  Future<List<Map<String, dynamic>>> getStudentBorrowedBooks(String id) async => List<Map<String, dynamic>>.from(await client.from('borrowed_books').select('*, library_books(title)').eq('student_id', id));
  Future<List<Map<String, dynamic>>> getBusRoutes() async => List<Map<String, dynamic>>.from(await client.from('transport_routes').select().order('name'));
  Future<void> saveBusRoute(Map<String, dynamic> d) async => await client.from('transport_routes').upsert(d);

  // --- 7. GENERIC DATA OPS ---
  Future<void> saveStudent(Map<String, dynamic> data) async => await client.from('students').upsert(data);
  Future<void> deleteStudent(String studentId) async => await client.from('students').delete().eq('student_id', studentId);
  Future<List<Map<String, dynamic>>> getAllStudents() async => List<Map<String, dynamic>>.from(await client.from('students').select().order('name'));
  Future<List<Map<String, dynamic>>> getStudentsByClass(String g, String s) async => List<Map<String, dynamic>>.from(await client.from('students').select().eq('grade', g).eq('stream', s).order('name'));
  Future<List<Map<String, dynamic>>> getAttendanceHistory(String g, String s, String d) async => List<Map<String, dynamic>>.from(await client.from('attendance').select().eq('grade', g).eq('stream', s).eq('date', d));
  Future<void> markAttendance(List<Map<String, dynamic>> r) async => await client.from('attendance').upsert(r);
  Future<List<Map<String, dynamic>>> getVisitors() async => List<Map<String, dynamic>>.from(await client.from('visitors').select().order('date', ascending: false));
  Future<void> insertVisitor(Map<String, dynamic> d) async => await client.from('visitors').upsert(d);
  Future<List<Map<String, dynamic>>> getAppointments() async => List<Map<String, dynamic>>.from(await client.from('appointments').select().order('appointment_date'));
  Future<void> upsertAppointment(Map<String, dynamic> d) async => await client.from('appointments').upsert(d);
  Future<void> deleteAppointment(String id) async => await client.from('appointments').delete().eq('appointment_id', id);
  Future<List<Map<String, dynamic>>> getResources() async => List<Map<String, dynamic>>.from(await client.from('resources').select().order('created_at', ascending: false));
  Future<List<Map<String, dynamic>>> getEvents() async => List<Map<String, dynamic>>.from(await client.from('events').select().order('start_date'));
  Future<void> upsertEvent(Map<String, dynamic> d) async => await client.from('events').upsert(d);
  Future<void> upsertActivity(Map<String, dynamic> d) async => await client.from('activities').upsert(d);
  Future<List<Map<String, dynamic>>> getActivities() async => List<Map<String, dynamic>>.from(await client.from('activities').select().order('date', ascending: false));
  Future<List<Map<String, dynamic>>> getIncidents() async => List<Map<String, dynamic>>.from(await client.from('incidents').select().order('date', ascending: false));
  Future<void> upsertIncident(Map<String, dynamic> d) async => await client.from('incidents').upsert(d);
  Future<void> deleteIncident(String id) async => await client.from('incidents').delete().eq('incident_id', id);
  Future<List<Map<String, dynamic>>> getNotifications(String r) async => List<Map<String, dynamic>>.from(await client.from('notifications').select().or('target_role.eq.$r,target_role.eq.all').order('created_at', ascending: false));
  Future<void> postAnnouncement(String t, String m, String r) async => await client.from('notifications').insert({'title': t, 'message': m, 'target_role': r});
  Future<List<Map<String, dynamic>>> getGlobalAttendanceByDate(String d) async => List<Map<String, dynamic>>.from(await client.from('attendance').select().eq('date', d));
  Future<Map<String, dynamic>> getLatestAppVersion() async => {'version': '3.1.0', 'changelog': 'Stability patches applied.'};
  Future<List<Map<String, dynamic>>> getActionableInsights() async => [{'title': 'Daily Pulse', 'subtitle': 'System matrix stable', 'type': 'success'}];

  Future<List<String>> getClasses() async => ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'JSS 1', 'JSS 2', 'JSS 3'];
  Future<List<String>> getSubjects() async => ['Mathematics', 'English', 'Science', 'Social Studies', 'CRE'];
  Future<Map<String, dynamic>> getPayrollSummary() async {
    final res = await client.from('staff').select('salary');
    double t = res.fold(0.0, (sum, item) => sum + (item['salary'] ?? 0));
    return {'total': t, 'staffCount': res.length};
  }

  Future<List<Map<String, dynamic>>> getLeaveRequests() async => List<Map<String, dynamic>>.from(await client.from('leave_requests').select('*, staff(name)'));
  Future<List<Map<String, dynamic>>> getMarksForStudent(String sid, String term, int year) async => List<Map<String, dynamic>>.from(await client.from('marks').select().eq('student_id', sid).eq('term', term).eq('year', year));
  Future<List<Map<String, dynamic>>> getParents() async => List<Map<String, dynamic>>.from(await client.from('parents').select().order('name'));
  Future<List<Map<String, dynamic>>> getStudentDiscipline(String sid) async => List<Map<String, dynamic>>.from(await client.from('incidents').select().eq('student_id', sid));
  Future<void> saveLessonPlan(Map<String, dynamic> d) async => await client.from('lesson_plans').upsert(d);
  Future<List<Map<String, dynamic>>> getLessonPlans() async => List<Map<String, dynamic>>.from(await client.from('lesson_plans').select().order('date', ascending: false));

  Future<Map<String, dynamic>> getSyllabusStatus(String subject) async {
    try {
      final res = await client.from('syllabus').select().eq('subject_name', subject).maybeSingle();
      return res ?? {'subject_name': subject, 'completion_percentage': 0, 'remaining_topics': []};
    } catch (e) {
      return {'subject_name': subject, 'completion_percentage': 0, 'remaining_topics': []};
    }
  }

  Future<void> insertParent(Map<String, dynamic> d) async => await client.from('parents').upsert(d);
  Future<void> deleteParent(String id) async => await client.from('parents').delete().eq('parent_id', id);
}
