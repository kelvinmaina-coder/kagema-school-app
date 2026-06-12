import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'offline_db_service.dart';

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
      debugPrint("Network error for $key, loading from cache...");
      return await OfflineDbService.instance.getCache(key);
    }
  }

  Future<void> _performMutation(String action, Map<String, dynamic> payload, Future<void> Function() networkCall) async {
    try {
      await networkCall();
    } catch (e) {
      debugPrint("Mutation failed for $action, adding to sync queue...");
      await OfflineDbService.instance.addToQueue(action, payload);
      throw "OFFLINE_QUEUED"; 
    }
  }

  // --- SYNC ENGINE ---
  Future<void> syncPendingActions() async {
    final queue = await OfflineDbService.instance.getQueue();
    if (queue.isEmpty) return;

    debugPrint("Syncing ${queue.length} pending actions...");
    for (var item in queue) {
      final id = item['id'] as int;
      final action = item['action'] as String;
      final payload = Map<String, dynamic>.from(jsonDecode(item['payload'] as String));

      try {
        switch (action) {
          case 'save_student':
            await client.from('students').upsert(payload);
            break;
          case 'mark_attendance':
            await client.from('attendance').upsert(payload);
            break;
          case 'insert_fee':
            await client.from('fees').insert(payload);
            break;
          case 'update_fee':
            await client.from('fees').update(payload).eq('fee_id', payload['fee_id']);
            break;
          case 'staff_attendance':
             await client.from('attendance').insert(payload);
             break;
          case 'save_marks':
             await client.from('marks').upsert(payload);
             break;
          case 'insert_staff':
             await client.from('staff').insert(payload);
             break;
          case 'update_staff':
             await client.from('staff').update(payload).eq('staff_id', payload['staff_id']);
             break;
          case 'post_announcement':
             await client.from('notifications').upsert(payload);
             break;
          case 'insert_visitor':
             await client.from('visitors').upsert(payload);
             break;
          case 'post_homework':
             await client.from('homework').upsert(payload);
             break;
          case 'insert_inventory':
             await client.from('inventory').upsert(payload);
             break;
          case 'save_book':
             await client.from('library_books').upsert(payload);
             break;
          case 'save_marks_list':
             final marks = List<Map<String, dynamic>>.from(payload['marks']);
             await client.from('marks').upsert(marks);
             break;
          case 'mark_attendance_list':
             final records = List<Map<String, dynamic>>.from(payload['records']);
             await client.from('attendance').upsert(records);
             break;
          case 'upsert_income':
             await client.from('income').upsert(payload);
             break;
          case 'upsert_expense':
             await client.from('expenses').upsert(payload);
             break;
          case 'upsert_appointment':
             await client.from('appointments').upsert(payload);
             break;
          case 'save_resource':
             await client.from('resources').upsert(payload);
             break;
          case 'upsert_incident':
             await client.from('incidents').upsert(payload);
             break;
        }
        await OfflineDbService.instance.removeFromQueue(id);
        debugPrint("Successfully synced action: $action");
      } catch (e) {
        debugPrint("Failed to sync $action: $e");
      }
    }
  }

  // --- 0. SYSTEM CONFIG & UPDATES ---
  Future<Map<String, dynamic>> getLatestAppVersion() async {
    try {
      // Fetches from a 'system_config' table where you store your app metadata
      final res = await client.from('system_config').select().eq('key', 'app_version').maybeSingle();
      if (res != null) {
        return {
          'version': res['value'] ?? '3.0.0',
          'url': res['metadata']?['download_url'] ?? '',
          'changelog': res['metadata']?['changelog'] ?? 'Stability and performance improvements.',
          'is_mandatory': res['metadata']?['is_mandatory'] ?? false,
        };
      }
    } catch (e) {
      debugPrint("Error fetching version: $e");
    }
    return {'version': '3.0.0', 'url': '', 'changelog': '', 'is_mandatory': false};
  }

  // --- 1. INTELLIGENCE & ANALYTICS ---
  Future<List<Map<String, dynamic>>> getActionableInsights() async {
    return await _getDataWithCache('insights', () async {
      return [
        {'title': 'Attendance Quota', 'subtitle': 'Daily avg is stable at 96%', 'type': 'success'},
        {'title': 'Cloud Treasury', 'subtitle': 'Revenue sync is up to date', 'type': 'info'},
        {'title': 'Stock Alert', 'subtitle': '5 items are below threshold', 'type': 'critical'},
      ];
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<Map<String, dynamic>> getDashboardSummary() async {
    return await _getDataWithCache('dashboard_summary', () async {
      try {
        final res = await client.rpc('get_admin_summary');
        return Map<String, dynamic>.from(res);
      } catch (e) {
        final students = await client.from('students').select('*').limit(0).count(CountOption.exact);
        final staff = await client.from('staff').select('*').limit(0).count(CountOption.exact);
        final parents = await client.from('parents').select('*').limit(0).count(CountOption.exact);
        return {
          'students': students.count ?? 0,
          'teachers': 0,
          'staff': staff.count ?? 0,
          'parents': parents.count ?? 0,
          'totalFees': 0,
        };
      }
    }) as Map<String, dynamic>? ?? {'students': 0, 'teachers': 0, 'staff': 0, 'parents': 0, 'totalFees': 0};
  }

  // --- 2. STAFF & HR OPERATIONS ---
  Future<Map<String, dynamic>?> getStaffProfile(String id) async {
    return await _getDataWithCache('staff_profile_$id', () async {
      return await client.from('staff').select().eq('staff_id', id).maybeSingle();
    });
  }

  Future<List<Map<String, dynamic>>> getAllStaff() async {
    return await _getDataWithCache('all_staff', () async {
      return List<Map<String, dynamic>>.from(await client.from('staff').select().order('name'));
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<void> insertStaff(Map<String, dynamic> data) async {
    await _performMutation('insert_staff', data, () async {
      await client.from('staff').insert(data);
    });
  }

  Future<void> updateStaff(Map<String, dynamic> data) async {
    await _performMutation('update_staff', data, () async {
      await client.from('staff').update(data).eq('staff_id', data['staff_id']);
    });
  }

  Future<void> deleteStaff(String staffId) async {
    await client.from('staff').delete().eq('staff_id', staffId);
  }

  // --- 3. STUDENT & PARENT MANAGEMENT ---
  Future<List<Map<String, dynamic>>> getAllStudents() async {
    return await _getDataWithCache('all_students', () async {
      final students = List<Map<String, dynamic>>.from(await client.from('students').select().order('name'));
      await OfflineDbService.instance.saveStudentsLocal(students);
      return students;
    }) as List<Map<String, dynamic>>? ?? await OfflineDbService.instance.getAllStudentsLocal();
  }

  Future<void> saveStudent(Map<String, dynamic> data) async {
    await OfflineDbService.instance.saveStudentLocal(data);
    await _performMutation('save_student', data, () async {
      await client.from('students').upsert(data);
    });
  }

  Future<void> deleteStudent(String studentId) async {
    await client.from('students').delete().eq('studentId', studentId);
  }

  Future<List<Map<String, dynamic>>> getStudentsByClass(String g, String s) async {
    return await _getDataWithCache('students_$g\_$s', () async {
      final list = List<Map<String, dynamic>>.from(await client.from('students').select().eq('grade', g).eq('stream', s).order('name'));
      await OfflineDbService.instance.saveStudentsLocal(list);
      return list;
    }) as List<Map<String, dynamic>>? ?? await OfflineDbService.instance.getStudentsByClassLocal(g, s);
  }

  Future<List<Map<String, dynamic>>> getParents() async {
    return await _getDataWithCache('all_parents', () async {
      return List<Map<String, dynamic>>.from(await client.from('parents').select().order('name'));
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<void> insertParent(Map<String, dynamic> d) async {
    await client.from('parents').upsert(d);
  }

  Future<void> deleteParent(String parentId) async {
    await client.from('parents').delete().eq('parentId', parentId);
    await client.from('students').update({'parentId': null}).eq('parentId', parentId);
  }

  // --- 4. ACADEMICS & MARKS ---
  Future<void> saveMarks(List<Map<String, dynamic>> m) async {
    try {
      await client.from('marks').upsert(m);
    } catch (e) {
      await OfflineDbService.instance.addToQueue('save_marks_list', {'marks': m});
      throw "OFFLINE_QUEUED";
    }
  }

  Future<List<Map<String, dynamic>>> getMarksFiltered({required String studentId, required String term, required int year}) async {
    return await _getDataWithCache('marks_$studentId\_$term\_$year', () async {
      return List<Map<String, dynamic>>.from(await client.from('marks').select().eq('student_id', studentId).eq('term', term).eq('year', year));
    }) as List<Map<String, dynamic>>? ?? [];
  }

  // --- 5. ATTENDANCE ---
  Future<void> markAttendance(List<Map<String, dynamic>> r) async {
    try {
      await client.from('attendance').upsert(r);
    } catch (e) {
      await OfflineDbService.instance.addToQueue('mark_attendance_list', {'records': r});
      throw "OFFLINE_QUEUED";
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistory(String g, String s, String d) async {
    return await _getDataWithCache('attendance_$g\_$s\_$d', () async {
      return List<Map<String, dynamic>>.from(await client.from('attendance').select().eq('grade', g).eq('stream', s).eq('date', d));
    }) as List<Map<String, dynamic>>? ?? [];
  }

  // --- 6. FINANCE ---
  Future<void> insertFeePayment(Map<String, dynamic> d) async {
    await _performMutation('insert_fee', d, () async {
      await client.from('fees').insert(d);
    });
  }

  Future<void> updateFeePayment(Map<String, dynamic> d) async {
    await _performMutation('update_fee', d, () async {
      await client.from('fees').update(d).eq('fee_id', d['fee_id']);
    });
  }

  Future<void> deleteFeePayment(String id) async {
    await client.from('fees').delete().eq('fee_id', id);
  }

  Future<List<Map<String, dynamic>>> getFeeHistory(String sid) async {
    return await _getDataWithCache('fee_history_$sid', () async {
      return List<Map<String, dynamic>>.from(await client.from('fees').select().eq('student_id', sid).order('payment_date', ascending: false));
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<List<Map<String, dynamic>>> getFeeStructure() async {
    return await _getDataWithCache('fee_structure', () async {
      return List<Map<String, dynamic>>.from(await client.from('fee_structure').select());
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<void> updateFeeStructure(String g, double a) async {
    await client.from('fee_structure').upsert({'grade': g, 'total_fee': a});
  }

  Future<List<Map<String, dynamic>>> getIncomeEntries() async {
    return await _getDataWithCache('income_entries', () async {
      return List<Map<String, dynamic>>.from(await client.from('income').select().order('date', ascending: false));
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<void> upsertIncome(Map<String, dynamic> data) async {
    await _performMutation('upsert_income', data, () async {
      await client.from('income').upsert(data);
    });
  }

  Future<void> deleteIncome(String id) async {
    await client.from('income').delete().eq('income_id', id);
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    return await _getDataWithCache('expenses', () async {
      return List<Map<String, dynamic>>.from(await client.from('expenses').select().order('date', ascending: false));
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<void> upsertExpense(Map<String, dynamic> data) async {
    await _performMutation('upsert_expense', data, () async {
      await client.from('expenses').upsert(data);
    });
  }

  Future<void> deleteExpense(String id) async {
    await client.from('expenses').delete().eq('expense_id', id);
  }

  // --- 7. OFFICE & SECRETARY ---
  Future<List<Map<String, dynamic>>> getAppointments() async {
    return await _getDataWithCache('appointments', () async {
      return List<Map<String, dynamic>>.from(await client.from('appointments').select().order('appointment_date'));
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<void> upsertAppointment(Map<String, dynamic> data) async {
    await _performMutation('upsert_appointment', data, () async {
      await client.from('appointments').upsert(data);
    });
  }

  Future<void> deleteAppointment(String id) async {
    await client.from('appointments').delete().eq('appointment_id', id);
  }

  Future<List<Map<String, dynamic>>> getVisitors() async {
    return await _getDataWithCache('visitors', () async {
      return List<Map<String, dynamic>>.from(await client.from('visitors').select().order('date', ascending: false));
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<void> upsertVisitor(Map<String, dynamic> d) async {
    await _performMutation('insert_visitor', d, () async {
      await client.from('visitors').upsert(d);
    });
  }

  Future<void> deleteVisitor(String id) async {
    await client.from('visitors').delete().eq('visitor_id', id);
  }

  // --- 8. HOMEWORK & RESOURCES ---
  Future<void> postHomework(Map<String, dynamic> d) async {
    await _performMutation('post_homework', d, () async {
      await client.from('homework').upsert(d);
    });
  }

  Future<List<Map<String, dynamic>>> getHomeworkByClass(String g, String s) async {
    return await _getDataWithCache('homework_$g\_$s', () async {
      return List<Map<String, dynamic>>.from(await client.from('homework').select().eq('grade', g).eq('stream', s).order('posted_date', ascending: false));
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<void> deleteHomework(String id) async {
    await client.from('homework').delete().eq('homework_id', id);
  }

  Future<List<Map<String, dynamic>>> getResources() async {
    return await _getDataWithCache('resources', () async {
      return List<Map<String, dynamic>>.from(await client.from('resources').select().order('created_at', ascending: false));
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<void> saveResource(Map<String, dynamic> data) async {
    await _performMutation('save_resource', data, () async {
      await client.from('resources').upsert(data);
    });
  }

  Future<void> deleteResource(String id) async {
    await client.from('resources').delete().eq('resource_id', id);
  }

  // --- 9. NOTIFICATIONS ---
  Future<void> postAnnouncement(String t, String m, String r) async {
    final payload = {'title': t, 'message': m, 'target_role': r};
    await _performMutation('post_announcement', payload, () async {
      await client.from('notifications').insert(payload);
    });
  }

  Future<void> deleteNotification(String id) async {
    await client.from('notifications').delete().eq('notification_id', id);
  }

  Stream<List<Map<String, dynamic>>> get notificationStream => client.from('notifications').stream(primaryKey: ['notification_id']).order('created_at');

  // --- 10. DISCIPLINE & INCIDENTS ---
  Future<List<Map<String, dynamic>>> getIncidents() async {
    return await _getDataWithCache('incidents', () async {
      return List<Map<String, dynamic>>.from(await client.from('incidents').select().order('date', ascending: false));
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<void> upsertIncident(Map<String, dynamic> data) async {
    await _performMutation('upsert_incident', data, () async {
      await client.from('incidents').upsert(data);
    });
  }

  Future<void> deleteIncident(String id) async {
    await client.from('incidents').delete().eq('incident_id', id);
  }

  // --- 11. MISC ---
  Future<List<Map<String, dynamic>>> getInventory() async {
    return await _getDataWithCache('inventory', () async {
      return List<Map<String, dynamic>>.from(await client.from('inventory').select().order('name'));
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<void> insertInventory(Map<String, dynamic> data) async {
    await _performMutation('insert_inventory', data, () async {
      await client.from('inventory').upsert(data);
    });
  }

  Future<void> deleteInventoryItem(String id) async {
    await client.from('inventory').delete().eq('item_id', id);
  }

  Future<void> updateStock(String id, int q) async {
    await client.from('inventory').update({'quantity': q}).eq('item_id', id);
  }

  Future<List<Map<String, dynamic>>> getBusRoutes() async {
    return await _getDataWithCache('bus_routes', () async {
      return List<Map<String, dynamic>>.from(await client.from('transport_routes').select().order('name'));
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<void> saveBusRoute(Map<String, dynamic> d) async {
    await client.from('transport_routes').upsert(d);
  }

  Future<void> deleteBusRoute(String id) async {
    await client.from('transport_routes').delete().eq('route_id', id);
  }

  Future<List<Map<String, dynamic>>> getBooks() async {
    return await _getDataWithCache('books', () async {
      return List<Map<String, dynamic>>.from(await client.from('library_books').select().order('title'));
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<void> saveBook(Map<String, dynamic> d) async {
    await _performMutation('save_book', d, () async {
      await client.from('library_books').upsert(d);
    });
  }

  Future<void> deleteBook(String id) async {
    await client.from('library_books').delete().eq('book_id', id);
  }

  Future<List<String>> getClasses() async { return ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'JSS 1', 'JSS 2', 'JSS 3']; }
  Future<List<String>> getSubjects() async { return ['Mathematics', 'English', 'Science', 'Social Studies', 'CRE']; }

  Future<Map<String, dynamic>> getPayrollSummary() async {
    return await _getDataWithCache('payroll_summary', () async {
      final res = await client.from('staff').select('salary');
      double total = res.fold(0.0, (sum, item) => sum + (item['salary'] ?? 0));
      return {'total': total, 'staffCount': res.length};
    }) as Map<String, dynamic>? ?? {'total': 0.0, 'staffCount': 0};
  }

  Future<List<Map<String, dynamic>>> getLeaveRequests() async {
    return await _getDataWithCache('leave_requests', () async {
      return List<Map<String, dynamic>>.from(await client.from('leave_requests').select('*, staff(name)'));
    }) as List<Map<String, dynamic>>? ?? [];
  }

  // --- COMPATIBILITY & MISSING METHODS ---

  Future<Map<String, dynamic>> getFinancialSummary() async {
    return await _getDataWithCache('financial_summary', () async {
      final incomeRes = await client.from('income').select('amount');
      final feesRes = await client.from('fees').select('amount_paid');
      final expensesRes = await client.from('expenses').select('amount');
      
      double totalIncome = 0.0;
      for (var item in incomeRes) { totalIncome += (item['amount'] as num? ?? 0.0).toDouble(); }
      for (var item in feesRes) { totalIncome += (item['amount_paid'] as num? ?? 0.0).toDouble(); }
      
      double totalExpenses = 0.0;
      for (var item in expensesRes) { totalExpenses += (item['amount'] as num? ?? 0.0).toDouble(); }
      
      return {'total_income': totalIncome, 'total_expenses': totalExpenses};
    }) as Map<String, dynamic>? ?? {'total_income': 0.0, 'total_expenses': 0.0};
  }

  Future<Map<String, dynamic>> getTeacherDashboardStats(String teacherId, String grade, String stream) async {
    return await _getDataWithCache('teacher_stats_$teacherId\_$grade\_$stream', () async {
      return {'students_count': 0, 'attendance_rate': '0%', 'average_score': 0.0};
    }) as Map<String, dynamic>? ?? {};
  }

  Future<List<Map<String, dynamic>>> getTeacherSchedule(String teacherId) async {
    return await _getDataWithCache('teacher_schedule_$teacherId', () async {
      return [];
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<List<Map<String, dynamic>>> getParentChildren(String phone) async {
    return await _getDataWithCache('parent_children_$phone', () async {
      return List<Map<String, dynamic>>.from(await client.from('students').select().eq('parent_phone', phone));
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<List<Map<String, dynamic>>> getStudentMarks(String studentId) async {
    return await _getDataWithCache('student_marks_$studentId', () async {
      return List<Map<String, dynamic>>.from(await client.from('marks').select().eq('student_id', studentId));
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<List<Map<String, dynamic>>> getChildAttendance(String studentId) async {
    return await _getDataWithCache('child_attendance_$studentId', () async {
      return List<Map<String, dynamic>>.from(await client.from('attendance').select().eq('target_id', studentId));
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<Map<String, dynamic>> getStudentBalance(String studentId, String grade) async {
    return await _getDataWithCache('student_balance_$studentId', () async {
      final struct = await client.from('fee_structure').select('total_fee').eq('grade', grade).maybeSingle();
      final paid = await client.from('fees').select('amount_paid').eq('student_id', studentId);
      
      double totalFee = (struct?['total_fee'] as num? ?? 0.0).toDouble();
      double totalPaid = paid.fold(0.0, (sum, item) => sum + (item['amount_paid'] as num? ?? 0).toDouble());
      
      return {'total_fee': totalFee, 'total_paid': totalPaid, 'balance': totalFee - totalPaid};
    }) as Map<String, dynamic>? ?? {'total_fee': 0.0, 'total_paid': 0.0, 'balance': 0.0};
  }

  Future<Map<String, dynamic>> getSecretaryStats() async {
    return await _getDataWithCache('secretary_stats', () async {
      return {'visitors_today': 0, 'appointments_today': 0};
    }) as Map<String, dynamic>? ?? {};
  }

  Future<List<Map<String, dynamic>>> getTasks(String staffId) async {
    return await _getDataWithCache('tasks_$staffId', () async {
      return [];
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<List<Map<String, dynamic>>> getNotifications(String role) async {
    return await _getDataWithCache('notifications_$role', () async {
      return List<Map<String, dynamic>>.from(await client.from('notifications').select().eq('target_role', role));
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<List<Map<String, dynamic>>> getStaffAttendanceHistory(String staffId) async {
    return await _getDataWithCache('staff_attendance_$staffId', () async {
      return [];
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<void> staffCheckInOut(String staffId, String status) async {
    await client.from('attendance').insert({'target_id': staffId, 'status': status, 'date': DateTime.now().toIso8601String()});
  }

  Future<List<Map<String, dynamic>>> getEvents() async {
    return await _getDataWithCache('events', () async {
      return [];
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<List<Map<String, dynamic>>> getFeeReports(String date) async {
    return await _getDataWithCache('fee_reports_$date', () async {
      return [];
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<void> upserIncident(Map<String, dynamic> data) async => await upsertIncident(data);

  Future<List<Map<String, dynamic>>> getMarksForStudent(String studentId, String term, int year) async {
    return await getMarksFiltered(studentId: studentId, term: term, year: year);
  }

  Future<List<Map<String, dynamic>>> getLessonPlans() async {
    return await _getDataWithCache('lesson_plans', () async {
      return [];
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<Map<String, dynamic>> getSyllabusStatus(String subject) async {
    return await _getDataWithCache('syllabus_$subject', () async {
      return {'completion': 0.0};
    }) as Map<String, dynamic>? ?? {};
  }

  Future<List<Map<String, dynamic>>> getStudentsByParentPhone(String phone) async => await getParentChildren(phone);

  Future<List<Map<String, dynamic>>> getStudentDiscipline(String studentId) async {
    return await _getDataWithCache('discipline_$studentId', () async {
      return List<Map<String, dynamic>>.from(await client.from('incidents').select().eq('student_id', studentId));
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<List<Map<String, dynamic>>> getClassTimetable(String grade, String stream) async {
    return await _getDataWithCache('timetable_$grade\_$stream', () async {
      return [];
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<List<Map<String, dynamic>>> getStudentBorrowedBooks(String studentId) async {
    return await _getDataWithCache('borrowed_books_$studentId', () async {
      return [];
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<List<Map<String, dynamic>>> getGlobalAttendanceByDate(String date) async {
    return await _getDataWithCache('global_attendance_$date', () async {
      return List<Map<String, dynamic>>.from(await client.from('attendance').select().eq('date', date));
    }) as List<Map<String, dynamic>>? ?? [];
  }

  Future<void> insertVisitor(Map<String, dynamic> data) async => await upsertVisitor(data);
}
