import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._init();
  final _supabase = Supabase.instance.client;

  SupabaseService._init();

  // --- ADMIN & ANALYTICS ---
  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final response = await _supabase.rpc('get_admin_summary');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint("Dashboard Summary Error: $e");
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getClassStatistics() async {
    try {
      final response = await _supabase.from('class_stats').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    try {
      final response = await _supabase.from('recent_activity_feed').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // --- TEACHER MODULE ---
  Future<Map<String, dynamic>> getTeacherDashboardStats(String teacherId, String grade, String stream) async {
    try {
      final response = await _supabase.rpc('get_teacher_stats', params: {
        'teacher_uuid': teacherId,
        'grade_filter': grade,
        'stream_filter': stream,
      });
      return Map<String, dynamic>.from(response);
    } catch (e) {
      return {
        'totalStudents': 0,
        'attendanceRate': 0.0,
        'pendingAssignments': 0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getTeacherSchedule(String teacherId) async {
    try {
      final response = await _supabase
          .from('timetable')
          .select()
          .eq('teacher_id', teacherId)
          .order('time_slot');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLessonPlans() async {
    try {
      final response = await _supabase.from('lesson_plans').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getSyllabusStatus(String subject) async {
    try {
      final response = await _supabase.from('syllabus_status').select().eq('subject_name', subject).maybeSingle();
      return response ?? {};
    } catch (e) {
      return {};
    }
  }

  // --- STUDENT & PARENT MODULE ---
  Future<List<Map<String, dynamic>>> getStudentsByClass(String grade, String stream) async {
    try {
      final response = await _supabase
          .from('students')
          .select()
          .eq('grade', grade)
          .eq('stream', stream)
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllStudents() async {
    try {
      final response = await _supabase.from('students').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStudentsByParentPhone(String phone) async {
    try {
      final response = await _supabase
          .from('students')
          .select('*, parents!inner(*)')
          .eq('parents.phone', phone);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getParentChildren(String parentPhone) async {
    return await getStudentsByParentPhone(parentPhone);
  }

  Future<void> saveStudentWithParent(Map<String, dynamic> data) async {
    try {
      String? parentId;
      final existingParent = await _supabase
          .from('parents')
          .select()
          .eq('phone', data['parentPhone'])
          .maybeSingle();

      if (existingParent != null) {
        parentId = existingParent['parent_id'];
      } else {
        final newParent = await _supabase.from('parents').insert({
          'name': data['parentName'],
          'phone': data['parentPhone'],
          'email': data['parentEmail'],
          'address': data['address'],
        }).select().single();
        parentId = newParent['parent_id'];
      }

      final studentData = {
        'student_id': data['studentId'],
        'admission_number': data['admissionNumber'],
        'name': data['name'],
        'gender': data['gender'],
        'grade': data['grade'],
        'stream': data['stream'],
        'date_of_birth': data['dateOfBirth'],
        'status': data['status'],
        'parent_id': parentId,
      };

      await _supabase.from('students').upsert(studentData);
    } catch (e) {
      debugPrint("Save Student Error: $e");
    }
  }

  // --- ACADEMICS (Attendance & Marks) ---
  Future<void> markAttendance(List<Map<String, dynamic>> records) async {
    await _supabase.from('attendance').upsert(records);
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistory(String grade, String stream, String date) async {
    try {
      final response = await _supabase
          .from('attendance')
          .select()
          .eq('grade', grade)
          .eq('stream', stream)
          .eq('date', date);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getGlobalAttendanceByDate(String date) async {
    try {
      final response = await _supabase
          .from('attendance')
          .select()
          .eq('date', date)
          .eq('target_type', 'Student');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceForStudent(String studentId) async {
    try {
      final response = await _supabase.from('attendance').select().eq('target_id', studentId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getChildAttendance(String studentId) async {
    return await getAttendanceForStudent(studentId);
  }

  Future<List<Map<String, dynamic>>> getStaffAttendanceHistory(String staffId) async {
    try {
      final response = await _supabase.from('attendance').select().eq('target_id', staffId).eq('target_type', 'Staff');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getAttendanceStats() async {
    try {
      final response = await _supabase.from('attendance').select('status');
      int present = response.where((e) => e['status'] == 'Present').length;
      return {'todayPresent': present, 'todayAbsent': response.length - present, 'total': response.length};
    } catch (e) {
      return {'todayPresent': 0, 'todayAbsent': 0, 'total': 0};
    }
  }

  Future<void> saveMarks(List<Map<String, dynamic>> marks) async {
    await _supabase.from('marks').upsert(marks);
  }

  Future<List<Map<String, dynamic>>> getMarksFiltered({
    required String studentId,
    required String term,
    required int year,
  }) async {
    try {
      final response = await _supabase
          .from('marks')
          .select()
          .eq('student_id', studentId)
          .eq('term', term)
          .eq('year', year);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMarksForStudent(String studentId, String term, int year) async {
    return await getMarksFiltered(studentId: studentId, term: term, year: year);
  }

  Future<List<Map<String, dynamic>>> getAllMarksForStudent(String studentId) async {
    try {
      final response = await _supabase
          .from('marks')
          .select()
          .eq('student_id', studentId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStudentMarks(String studentId) async {
    return await getAllMarksForStudent(studentId);
  }

  // --- STAFF MANAGEMENT ---
  Future<List<Map<String, dynamic>>> getAllStaff() async {
    try {
      final response = await _supabase.from('staff').select().order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> insertStaff(Map<String, dynamic> data) async {
    await _supabase.from('staff').insert(data);
  }

  Future<void> updateStaff(Map<String, dynamic> data) async {
    await _supabase.from('staff').update(data).eq('staff_id', data['staff_id']);
  }

  Future<void> deleteStaff(String staffId) async {
    await _supabase.from('staff').delete().eq('staff_id', staffId);
  }

  Future<Map<String, dynamic>?> getStaffProfile(String staffId) async {
    try {
      return await _supabase.from('staff').select().eq('staff_id', staffId).maybeSingle();
    } catch (e) {
      return null;
    }
  }

  // --- STAFF & HR FEATURES ---
  Future<List<Map<String, dynamic>>> getTasks(String staffId) async {
    try {
      return await _supabase.from('tasks').select().eq('staff_id', staffId);
    } catch (e) {
      return [];
    }
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    await _supabase.from('tasks').update({'status': status}).eq('task_id', taskId);
  }

  Future<void> staffCheckInOut(String staffId, String status) async {
    await _supabase.from('attendance').insert({
      'date': DateTime.now().toIso8601String().split('T')[0],
      'time': DateTime.now().toIso8601String().split('T')[1].substring(0, 5),
      'target_id': staffId,
      'target_type': 'Staff',
      'status': status,
    });
  }

  Future<List<Map<String, dynamic>>> getLeaveRequests() async {
    try {
      final response = await _supabase.from('leave_requests').select('*, staff(name)');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> updateLeaveStatus(String leaveId, String status) async {
    await _supabase.from('leave_requests').update({'status': status}).eq('leave_id', leaveId);
  }

  Future<List<Map<String, dynamic>>> getLeaveHistory(String staffId) async {
    try {
      final response = await _supabase.from('leave_requests').select().eq('staff_id', staffId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> insertLeaveRequest(Map<String, dynamic> data) async {
    await _supabase.from('leave_requests').insert(data);
  }

  Future<Map<String, dynamic>> getPayrollSummary() async {
    try {
      final response = await _supabase.from('staff').select('salary');
      double total = 0;
      for (var e in response) {
        total += (e['salary'] ?? 0);
      }
      return {'total': total, 'staffCount': response.length};
    } catch (e) {
      return {'total': 0.0, 'staffCount': 0};
    }
  }

  Future<List<Map<String, dynamic>>> getPayrollRecords() async {
    try {
      final response = await _supabase.from('staff').select('name, role, salary');
      return response.map((s) => {
        'month': 'Current',
        'employees': 1,
        'status': 'Processed',
        'total': s['salary'] ?? 0.0,
        'name': s['name']
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // --- SECRETARY MODULE ---
  Future<Map<String, dynamic>> getSecretaryStats() async {
    try {
      final studentsRes = await _supabase.from('students').select('student_id');
      final apptsRes = await _supabase.from('appointments').select('appointment_id').eq('status', 'Scheduled');
      final notifsRes = await _supabase.from('notifications').select('notification_id');

      return {
        'totalStudents': studentsRes.length,
        'newAdmissions': 1,
        'upcomingAppointments': apptsRes.length,
        'announcements': notifsRes.length,
      };
    } catch (e) {
      return {
        'totalStudents': 0,
        'newAdmissions': 0,
        'upcomingAppointments': 0,
        'announcements': 0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getAppointments() async {
    try {
      return await _supabase.from('appointments').select().order('appointment_date', ascending: true);
    } catch (e) {
      return [];
    }
  }

  Future<void> saveAppointment(Map<String, dynamic> data) async {
    final dbData = {
      'visitor_name': data['visitorName'],
      'phone': data['phone'],
      'purpose': data['purpose'],
      'appointment_date': data['date'],
      'appointment_time': data['time'],
      'status': data['status'],
    };
    if (data.containsKey('appointmentId') && data['appointmentId'] != null && !data['appointmentId'].toString().startsWith('APT_')) {
      await _supabase.from('appointments').update(dbData).eq('appointment_id', data['appointmentId']);
    } else {
      await _supabase.from('appointments').insert(dbData);
    }
  }

  Future<void> deleteAppointment(String id) async {
    await _supabase.from('appointments').delete().eq('appointment_id', id);
  }

  Future<List<Map<String, dynamic>>> getVisitors() async {
    try {
      final response = await _supabase.from('visitors').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> insertVisitor(Map<String, dynamic> data) async {
    await _supabase.from('visitors').insert({
      'name': data['name'],
      'phone': data['phone'],
      'purpose': data['purpose'],
      'time_in': data['timeIn'],
      'time_out': data['timeOut'],
      'date': data['date'],
    });
  }

  Future<List<Map<String, dynamic>>> getParents() async {
    try {
      final response = await _supabase.from('parents').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> insertParent(Map<String, dynamic> data) async {
    await _supabase.from('parents').insert(data);
  }

  // --- FINANCE ---
  Future<Map<String, dynamic>> getStudentBalance(String studentId, String grade) async {
    try {
      final structure = await _supabase.from('fee_structure').select('total_fee').eq('grade', grade).maybeSingle();
      final totalRequired = (structure?['total_fee'] as num?)?.toDouble() ?? 0.0;

      final payments = await _supabase.from('fees').select('amount_paid').eq('student_id', studentId);
      double totalPaid = 0;
      for (var item in payments) {
        totalPaid += (item['amount_paid'] ?? 0);
      }

      return {
        'required': totalRequired,
        'paid': totalPaid,
        'balance': totalRequired - totalPaid,
      };
    } catch (e) {
      return {'required': 0.0, 'paid': 0.0, 'balance': 0.0};
    }
  }

  Future<List<Map<String, dynamic>>> getFeeHistory(String studentId) async {
    try {
      final response = await _supabase.from('fees').select().eq('student_id', studentId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> insertFeePayment(Map<String, dynamic> data) async {
    await _supabase.from('fees').insert(data);
  }

  Future<List<Map<String, dynamic>>> getFeeStructure() async {
    try {
      final response = await _supabase.from('fee_structure').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> updateFeeStructure(String grade, double amount) async {
    await _supabase.from('fee_structure').upsert({'grade': grade, 'total_fee': amount});
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    try {
      final response = await _supabase.from('expenses').select().order('date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> insertExpense(Map<String, dynamic> data) async {
    await _supabase.from('expenses').insert(data);
  }

  Future<List<Map<String, dynamic>>> getIncome() async {
    try {
      final response = await _supabase.from('income').select().order('date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> insertIncome(Map<String, dynamic> data) async {
    await _supabase.from('income').insert(data);
  }

  Future<List<Map<String, dynamic>>> getFeeReports(String dateFilterPrefix) async {
    try {
      final response = await _supabase
          .from('fees')
          .select('*, students(name)')
          .like('payment_date', '$dateFilterPrefix%')
          .order('payment_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // --- NOTIFICATIONS ---
  Future<List<Map<String, dynamic>>> getNotifications(String role) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .or('target_role.eq.All,target_role.eq.$role')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> postAnnouncement(String title, String message, String role) async {
    await _supabase.from('notifications').insert({
      'title': title,
      'message': message,
      'target_role': role,
    });
  }

  Future<void> deleteNotification(String id) async {
    await _supabase.from('notifications').delete().eq('notification_id', id);
  }

  Stream<List<Map<String, dynamic>>> get notificationStream {
    return _supabase.from('notifications').stream(primaryKey: ['notification_id']).order('created_at');
  }

  // --- MISC (Inventory, Transport, etc) ---
  Future<List<Map<String, dynamic>>> getInventory() async {
    try {
      final response = await _supabase.from('inventory').select().order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> updateStock(String itemId, int qty) async {
    await _supabase.from('inventory').update({'quantity': qty}).eq('item_id', itemId);
  }

  Future<void> insertInventory(Map<String, dynamic> data) async {
    await _supabase.from('inventory').insert(data);
  }

  Future<void> deleteInventory(String id) async {
    await _supabase.from('inventory').delete().eq('item_id', id);
  }

  Future<List<Map<String, dynamic>>> getBusRoutes() async {
    try {
      final response = await _supabase.from('transport_routes').select().order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> saveBusRoute(Map<String, dynamic> data) async {
    await _supabase.from('transport_routes').upsert(data);
  }

  Future<void> deleteBusRoute(String id) async {
    await _supabase.from('transport_routes').delete().eq('route_id', id);
  }

  Future<List<Map<String, dynamic>>> getClubs() async {
    try {
      final response = await _supabase.from('clubs').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecentIncidents() async {
    try {
      final response = await _supabase.from('incidents').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getEvents() async {
    try {
      final response = await _supabase.from('events').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBooks() async {
    try {
      final response = await _supabase.from('library_books').select().order('title');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> saveBook(Map<String, dynamic> data) async {
    if (data.containsKey('book_id') && data['book_id'] != null) {
      await _supabase.from('library_books').upsert(data);
    } else {
      await _supabase.from('library_books').insert(data);
    }
  }

  Future<void> deleteBook(String id) async {
    await _supabase.from('library_books').delete().eq('book_id', id);
  }

  // --- HOMEWORK ---
  Future<List<Map<String, dynamic>>> getHomeworkByClass(String grade, String stream) async {
    try {
      final response = await _supabase
          .from('homework')
          .select('*, staff(name)')
          .eq('grade', grade)
          .eq('stream', stream)
          .order('posted_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> postHomework(Map<String, dynamic> data) async {
    await _supabase.from('homework').insert(data);
  }

  Future<void> deleteHomework(String homeworkId) async {
    await _supabase.from('homework').delete().eq('homework_id', homeworkId);
  }

  // --- RESOURCES ---
  Future<List<Map<String, dynamic>>> getResources() async {
    try {
      final response = await _supabase.from('resources').select().order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> uploadResource(Map<String, dynamic> data, File file) async {
    final fileName = 'resources/${DateTime.now().millisecondsSinceEpoch}_${data['title']}.pdf';
    await _supabase.storage.from('school-assets').upload(fileName, file);
    final fileUrl = _supabase.storage.from('school-assets').getPublicUrl(fileName);

    await _supabase.from('resources').insert({
      ...data,
      'file_path': fileUrl,
      'uploaded_by': _supabase.auth.currentUser?.id,
    });
  }

  Future<List<Map<String, dynamic>>> getSchoolAttendanceSummary() async {
    try {
      final response = await _supabase.from('attendance')
          .select('grade, status')
          .eq('target_type', 'Student')
          .eq('date', DateTime.now().toIso8601String().split('T')[0]);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> getClasses() async {
    return ['PP1', 'PP2', 'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'JSS 1', 'JSS 2', 'JSS 3'];
  }

  Future<List<String>> getSubjects() async {
    return ['Mathematics', 'English', 'Kiswahili', 'Science', 'Social Studies', 'CRE'];
  }

  SupabaseClient get client => _supabase;
}
