import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import '../models/school_models.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kagema_school_pro_v22.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 22,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 22) {
      await _createDB(db, newVersion);
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';

    // 1. Users
    await db.execute('DROP TABLE IF EXISTS users');
    await db.execute('''
    CREATE TABLE users (
      userId $idType,
      identifier $textType UNIQUE,
      password $textType,
      role $textType,
      name $textType,
      photoUrl TEXT,
      status TEXT DEFAULT 'Active'
    )
    ''');

    // 2. Students
    await db.execute('DROP TABLE IF EXISTS students');
    await db.execute('''
    CREATE TABLE students (
      studentId $idType,
      admissionNumber $textType,
      name $textType,
      gender $textType,
      grade $textType,
      stream $textType,
      dateOfBirth $textType,
      parentName TEXT,
      parentPhone TEXT,
      parentEmail TEXT,
      address TEXT,
      medicalInfo TEXT,
      photoUrl TEXT,
      status TEXT DEFAULT 'Active',
      admissionDate TEXT,
      parentId TEXT
    )
    ''');

    // 3. Staff/Teachers
    await db.execute('DROP TABLE IF EXISTS staff');
    await db.execute('''
    CREATE TABLE staff (
      staffId $idType,
      name $textType,
      email $textType,
      phone $textType,
      role $textType,
      qualification TEXT,
      department TEXT,
      subjects TEXT,
      assignedClasses TEXT,
      photoUrl TEXT,
      status TEXT DEFAULT 'Active',
      salary REAL
    )
    ''');

    // 4. Attendance
    await db.execute('DROP TABLE IF EXISTS attendance');
    await db.execute('''
    CREATE TABLE attendance (
      attendanceId $idType,
      date $textType,
      targetId $textType,
      targetName $textType,
      targetType TEXT,
      status $textType,
      time TEXT,
      term TEXT,
      year INTEGER,
      grade TEXT,
      stream TEXT
    )
    ''');

    // 5. Marks
    await db.execute('DROP TABLE IF EXISTS marks');
    await db.execute('''
    CREATE TABLE marks (
      markId $idType,
      studentId $textType,
      studentName TEXT,
      subject $textType,
      score $doubleType,
      points INTEGER,
      achievementLevel TEXT,
      term TEXT,
      year INTEGER,
      examType TEXT,
      grade TEXT,
      stream TEXT
    )
    ''');

    // 6. Fees & Structure
    await db.execute('DROP TABLE IF EXISTS fees');
    await db.execute('''
    CREATE TABLE fees (
      feeId $idType,
      studentId $textType,
      studentName $textType,
      amountPaid $doubleType,
      term $textType,
      year $intType,
      paymentDate $textType,
      receiptNumber $textType,
      paymentMethod TEXT
    )
    ''');

    await db.execute('DROP TABLE IF EXISTS fee_structure');
    await db.execute('''
    CREATE TABLE fee_structure (grade $textType PRIMARY KEY, totalFee $doubleType)
    ''');

    // 7. Homework
    await db.execute('DROP TABLE IF EXISTS homework');
    await db.execute('''
    CREATE TABLE homework (
      homeworkId $idType,
      title $textType,
      description $textType,
      subject $textType,
      grade $textType,
      stream $textType,
      dueDate $textType,
      postedDate $textType,
      teacherId TEXT,
      postedBy TEXT
    )
    ''');

    // 8. Timetable
    await db.execute('DROP TABLE IF EXISTS timetable');
    await db.execute('''
    CREATE TABLE timetable (
      timetableId $idType,
      day $textType,
      time $textType,
      subject $textType,
      grade $textType,
      stream $textType,
      teacherId $textType,
      room TEXT,
      type TEXT DEFAULT 'Teaching'
    )
    ''');

    // 9. Appointments & Visitors
    await db.execute('DROP TABLE IF EXISTS appointments');
    await db.execute('''
    CREATE TABLE appointments (appointmentId $idType, visitorName TEXT, phone TEXT, purpose TEXT, date TEXT, time TEXT, status TEXT)
    ''');
    await db.execute('DROP TABLE IF EXISTS visitors');
    await db.execute('''
    CREATE TABLE visitors (visitorId $idType, name TEXT, phone TEXT, purpose TEXT, timeIn TEXT, timeOut TEXT, date TEXT)
    ''');

    // 10. Notifications
    await db.execute('DROP TABLE IF EXISTS notifications');
    await db.execute('''
    CREATE TABLE notifications (
      notificationId $idType, title TEXT, message TEXT, targetRole TEXT, targetId TEXT, senderId TEXT, timestamp TEXT, isRead INTEGER DEFAULT 0
    )
    ''');

    // 11. Expenses & Income
    await db.execute('DROP TABLE IF EXISTS expenses');
    await db.execute('''
    CREATE TABLE expenses (expenseId $idType, category TEXT, amount REAL, date TEXT, description TEXT)
    ''');
    await db.execute('DROP TABLE IF EXISTS income');
    await db.execute('''
    CREATE TABLE income (incomeId $idType, source TEXT, amount REAL, date TEXT, description TEXT)
    ''');

    // 12. Inventory
    await db.execute('DROP TABLE IF EXISTS inventory');
    await db.execute('''
    CREATE TABLE inventory (itemId $idType, name TEXT, category TEXT, quantity INTEGER, unit TEXT, lastUpdated TEXT)
    ''');

    // 13. Tasks
    await db.execute('DROP TABLE IF EXISTS tasks');
    await db.execute('''
    CREATE TABLE tasks (taskId $idType, staffId TEXT, title TEXT, description TEXT, status TEXT, dueDate TEXT)
    ''');

    // 14. Leave Requests
    await db.execute('DROP TABLE IF EXISTS leave_requests');
    await db.execute('''
    CREATE TABLE leave_requests (leaveId $idType, staffId TEXT, type TEXT, startDate TEXT, endDate TEXT, reason TEXT, status TEXT)
    ''');

    // 15. Books
    await db.execute('DROP TABLE IF EXISTS books');
    await db.execute('''
    CREATE TABLE books (bookId $idType, title TEXT, author TEXT, isbn TEXT, category TEXT, totalCopies INTEGER, availableCopies INTEGER)
    ''');

    // 16. Parents Table
    await db.execute('DROP TABLE IF EXISTS parents');
    await db.execute('''
    CREATE TABLE parents (
      parentId $idType,
      name $textType,
      phone $textType,
      email TEXT,
      address TEXT,
      occupation TEXT
    )
    ''');

    // 17. Resources Table
    await db.execute('DROP TABLE IF EXISTS resources');
    await db.execute('''
    CREATE TABLE resources (
      resourceId $idType,
      title $textType,
      type TEXT,
      subject TEXT,
      grade TEXT,
      filePath TEXT,
      uploadedBy TEXT,
      timestamp TEXT
    )
    ''');

    // SEED INITIAL DATA
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    // Roles - Matching AuthenticationService cleanId
    await db.insert('users', {'userId': 'admin', 'identifier': 'admin', 'password': 'password123', 'role': 'admin', 'name': 'Master Admin'});
    await db.insert('users', {'userId': 'teacher', 'identifier': 'teacher', 'password': 'password123', 'role': 'teacher', 'name': 'Mr. Kamau'});
    await db.insert('users', {'userId': 'secretary', 'identifier': 'secretary', 'password': 'password123', 'role': 'secretary', 'name': 'Alice Office'});
    await db.insert('users', {'userId': 'accountant', 'identifier': 'accountant', 'password': 'password123', 'role': 'accountant', 'name': 'James Finance'});
    await db.insert('users', {'userId': 'staff', 'identifier': 'staff', 'password': 'password123', 'role': 'staff', 'name': 'John Worker'});
    
    // Teacher Profile
    await db.insert('staff', {
      'staffId': 'teacher', 'name': 'Mr. Kamau', 'email': 'kamau@school.com', 'phone': '0711223344', 'role': 'teacher', 'department': 'Sciences', 'assignedClasses': 'Grade 1 North,Grade 2 South', 'subjects': 'Mathematics,Science'
    });

    // Students
    await db.insert('students', {
      'studentId': 's1', 'admissionNumber': 'ADM001', 'name': 'Little Doe', 'gender': 'Male', 'grade': 'Grade 1', 'stream': 'North', 'parentName': 'John Parent', 'parentPhone': '0712345678', 'admissionDate': today
    });
    await db.insert('students', {
      'studentId': 's2', 'admissionNumber': 'ADM002', 'name': 'Jane Smith', 'gender': 'Female', 'grade': 'Grade 2', 'stream': 'South', 'parentName': 'Mary Smith', 'parentPhone': '0787654321', 'admissionDate': today
    });

    // Fee Structure
    await db.insert('fee_structure', {'grade': 'Grade 1', 'totalFee': 25000.0});
    await db.insert('fee_structure', {'grade': 'Grade 2', 'totalFee': 28000.0});
  }

  // --- AUTH & USER METHODS ---

  Future<Map<String, dynamic>?> getUser(String id, String pass) async {
    final db = await database;
    final res = await db.query('users', where: 'identifier = ? AND password = ?', whereArgs: [id, pass]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<void> createUser(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('users', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- ADMIN DASHBOARD ---

  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;
    final students = await db.rawQuery('SELECT COUNT(*) as count FROM students');
    final teachers = await db.rawQuery('SELECT COUNT(*) as count FROM staff WHERE role = "teacher"');
    final staff = await db.rawQuery('SELECT COUNT(*) as count FROM staff');
    final parents = await db.rawQuery('SELECT COUNT(*) as count FROM parents');
    final fees = await db.rawQuery('SELECT SUM(amountPaid) as total FROM fees');
    
    final maleStudents = await db.rawQuery('SELECT COUNT(*) as count FROM students WHERE gender = "Male"');
    final femaleStudents = await db.rawQuery('SELECT COUNT(*) as count FROM students WHERE gender = "Female"');

    return {
      'counts': {
        'students': students.first['count'] ?? 0,
        'teachers': teachers.first['count'] ?? 0,
        'staff': staff.first['count'] ?? 0,
        'parents': parents.first['count'] ?? 0,
        'male': maleStudents.first['count'] ?? 0,
        'female': femaleStudents.first['count'] ?? 0,
      },
      'collectedFees': (fees.first['total'] as num?)?.toDouble() ?? 0.0,
      'attendanceRate': 95.5,
      'upcomingEvents': [],
    };
  }

  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    return []; // Placeholder
  }

  // --- STAFF MANAGEMENT ---

  Future<List<Map<String, dynamic>>> getAllStaff() async {
    final db = await database;
    return await db.query('staff');
  }

  Future<void> insertStaff(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('staff', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateStaff(Map<String, dynamic> data) async {
    final db = await database;
    await db.update('staff', data, where: 'staffId = ?', whereArgs: [data['staffId']]);
  }

  Future<void> deleteStaff(String staffId) async {
    final db = await database;
    await db.delete('staff', where: 'staffId = ?', whereArgs: [staffId]);
  }

  Future<Map<String, dynamic>?> getStaffProfile(String staffId) async {
    final db = await database;
    final res = await db.query('staff', where: 'staffId = ?', whereArgs: [staffId]);
    return res.isNotEmpty ? res.first : null;
  }

  // --- STAFF DASHBOARD FEATURES ---

  Future<List<Map<String, dynamic>>> getTasks(String staffId) async {
    final db = await database;
    return await db.query('tasks', where: 'staffId = ?', whereArgs: [staffId]);
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    final db = await database;
    await db.update('tasks', {'status': status}, where: 'taskId = ?', whereArgs: [taskId]);
  }

  Future<List<Map<String, dynamic>>> getStaffAttendanceHistory(String staffId) async {
    final db = await database;
    return await db.query('attendance', where: 'targetId = ? AND targetType = "Staff"', whereArgs: [staffId]);
  }

  Future<void> staffCheckInOut(String staffId, String status) async {
    final db = await database;
    await db.insert('attendance', {
      'attendanceId': DateTime.now().millisecondsSinceEpoch.toString(),
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'time': DateFormat('HH:mm').format(DateTime.now()),
      'targetId': staffId,
      'targetType': 'Staff',
      'status': status,
    });
  }

  Future<List<Map<String, dynamic>>> getLeaveHistory(String staffId) async {
    final db = await database;
    return await db.query('leave_requests', where: 'staffId = ?', whereArgs: [staffId]);
  }

  Future<List<Map<String, dynamic>>> getLeaveRequests() async {
    final db = await database;
    return await db.query('leave_requests');
  }

  Future<void> insertLeaveRequest(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('leave_requests', data);
  }

  Future<List<Map<String, dynamic>>> getPayrollSummary() async {
    final db = await database;
    final res = await db.rawQuery('SELECT SUM(salary) as total, COUNT(*) as employees FROM staff');
    return [{
      'month': DateFormat('MMMM yyyy').format(DateTime.now()),
      'employees': res.first['employees'] ?? 0,
      'total': res.first['total'] ?? 0.0,
      'status': 'Pending'
    }];
  }

  // --- TEACHER METHODS ---
  
  Future<Map<String, dynamic>> getTeacherStats(String teacherId, {String? grade, String? stream}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> args = [];
    if (grade != null && stream != null) {
      whereClause = ' WHERE grade = ? AND stream = ?';
      args = [grade, stream];
    }
    
    final students = await db.rawQuery('SELECT COUNT(*) as count FROM students$whereClause', args);
    final attendance = await db.rawQuery('SELECT COUNT(*) as present FROM attendance WHERE targetType = "Student" AND status = "Present"');
    final totalAtt = await db.rawQuery('SELECT COUNT(*) as total FROM attendance WHERE targetType = "Student"');
    
    double rate = 100.0;
    if (totalAtt.isNotEmpty && totalAtt.first['total'] != null && totalAtt.first['total'] != 0) {
      rate = ((attendance.first['present'] as int) / (totalAtt.first['total'] as int)) * 100;
    }

    final homework = await db.rawQuery('SELECT COUNT(*) as count FROM homework WHERE teacherId = ?', [teacherId]);

    return {
      'totalStudents': students.first['count'] ?? 0,
      'attendanceRate': rate,
      'pendingAssignments': homework.first['count'] ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getTeacherSchedule(String teacherId) async {
    final db = await database;
    final today = DateFormat('EEEE').format(DateTime.now());
    return await db.query('timetable', where: 'teacherId = ? AND day = ?', whereArgs: [teacherId, today]);
  }

  Future<List<Student>> getStudentsByClass(String grade, String stream) async {
    final db = await database;
    final res = await db.query('students', where: 'grade = ? AND stream = ?', whereArgs: [grade, stream]);
    return res.map((json) => Student.fromMap(json)).toList();
  }

  Future<void> insertMark(Mark mark) async {
    final db = await database;
    await db.insert('marks', mark.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistory(String grade, String stream, String date) async {
    final db = await database;
    return await db.query('attendance', where: 'grade = ? AND stream = ? AND date = ? AND targetType = "Student"', whereArgs: [grade, stream, date]);
  }

  Future<void> markAttendance(Attendance attendance) async {
    final db = await database;
    final data = attendance.toMap();
    data.remove('studentId');
    data.remove('studentName');
    
    await db.insert('attendance', {
      ...data,
      'attendanceId': '${attendance.date}_${attendance.studentId}',
      'targetId': attendance.studentId,
      'targetName': attendance.studentName,
      'targetType': 'Student',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> uploadResource(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('resources', data);
  }

  Future<List<Map<String, dynamic>>> getResources() async {
    final db = await database;
    return await db.query('resources');
  }

  Future<List<Map<String, dynamic>>> getLessonPlans() async {
    return [
      {'topic': 'Linear Equations', 'subject': 'Mathematics', 'grade': 'Grade 1'},
      {'topic': 'Force and Motion', 'subject': 'Science', 'grade': 'Grade 2'},
    ];
  }

  Future<Map<String, dynamic>> getSyllabusStatus(String subject) async {
    return {
      'subject': subject,
      'completed': 0.65,
      'remainingTopics': ['Quadratic Equations', 'Geometry', 'Probability'],
    };
  }

  // --- SECRETARY METHODS ---

  Future<Map<String, dynamic>> getSecretaryStats() async {
    final db = await database;
    final students = await db.rawQuery('SELECT COUNT(*) as count FROM students');
    final appointments = await db.rawQuery('SELECT COUNT(*) as count FROM appointments');
    return {
      'totalStudents': students.first['count'] ?? 0,
      'newAdmissions': 1,
      'upcomingAppointments': appointments.first['count'] ?? 0,
      'announcements': 2,
    };
  }

  Future<List<Map<String, dynamic>>> getAppointments() async {
    final db = await database;
    return await db.query('appointments');
  }

  Future<void> insertParent(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('parents', data, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert('users', {
      'userId': data['parentId'],
      'name': data['name'],
      'identifier': data['phone'],
      'password': 'password123',
      'role': 'Parent'
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getParents() async {
    final db = await database;
    return await db.query('parents');
  }

  // --- FINANCIALS ---

  Future<Map<String, dynamic>> getFeeStats() async {
    final db = await database;
    final res = await db.rawQuery('SELECT SUM(amountPaid) as collected FROM fees');
    return {
      'collected': (res.first['collected'] as num?)?.toDouble() ?? 0.0,
      'pending': 150000.0,
      'debtors': 12
    };
  }

  Future<List<Map<String, dynamic>>> getDebtors() async {
    return []; // Placeholder
  }

  Future<Map<String, dynamic>> getFinancialHealthSummary() async {
    final db = await database;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final feesToday = await db.rawQuery('SELECT SUM(amountPaid) as total FROM fees WHERE paymentDate LIKE ?', ['$todayStr%']);
    
    return {
      'today': (feesToday.first['total'] as num?)?.toDouble() ?? 0.0,
      'month': 50000.0,
      'outstanding': 120000.0,
      'studentsPaid': 15,
      'paid': 50000.0,
      'expected': 200000.0,
      'percentage': 25.0,
      'status': 'Stable'
    };
  }

  // --- ATTENDANCE STATS ---

  Future<Map<String, dynamic>> getAttendanceStats() async {
    return {
      'todayPresent': 240,
      'todayAbsent': 15,
      'averageRate': 94.2
    };
  }

  // --- ACADEMICS ---

  Future<List<String>> getClasses() async {
    return ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9'];
  }

  Future<List<String>> getSubjects() async {
    return ['Mathematics', 'English', 'Kiswahili', 'Science', 'Social Studies', 'CRE'];
  }

  // --- TRANSPORT ---

  Future<List<Map<String, dynamic>>> getBusRoutes() async {
    return [
      {'routeId': 'r1', 'name': 'Route A', 'driver': 'James', 'capacity': 40, 'students': 35},
      {'routeId': 'r2', 'name': 'Route B', 'driver': 'Peter', 'capacity': 40, 'students': 28},
    ];
  }

  // --- INVENTORY ---

  Future<List<Map<String, dynamic>>> getInventory() async {
    final db = await database;
    return await db.query('inventory');
  }

  Future<void> insertInventory(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('inventory', data);
  }

  // --- UNIVERSAL METHODS ---

  Future<void> insertNotification(NotificationModel n) async {
    final db = await database;
    await db.insert('notifications', n.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<NotificationModel>> getNotifications(String role) async {
    final db = await database;
    final res = await db.query('notifications', where: 'targetRole = ? OR targetRole = "All"', whereArgs: [role]);
    return res.map((json) => NotificationModel.fromMap(json)).toList();
  }

  Future<void> deleteNotification(String id) async {
    final db = await database;
    await db.delete('notifications', where: 'notificationId = ?', whereArgs: [id]);
  }

  Future<void> insertStudent(Student s) async {
    final db = await database;
    await db.insert('students', s.toMap());
  }

  Future<void> updateStudent(Student s) async {
    final db = await database;
    await db.update('students', s.toMap(), where: 'studentId = ?', whereArgs: [s.studentId]);
  }

  Future<List<Student>> getAllStudents() async {
    final db = await database;
    final res = await db.query('students');
    return res.map((json) => Student.fromMap(json)).toList();
  }

  Future<void> insertFeePayment(Map<String, dynamic> p) async {
    final db = await database;
    await db.insert('fees', p);
  }

  Future<List<Map<String, dynamic>>> getFeeHistory(String studentId) async {
    final db = await database;
    return await db.query('fees', where: 'studentId = ?', whereArgs: [studentId]);
  }

  Future<List<Mark>> getAllMarksForStudent(String studentId) async {
    final db = await database;
    final res = await db.query('marks', where: 'studentId = ?', whereArgs: [studentId]);
    return res.map((json) => Mark.fromMap(json)).toList();
  }

  Future<List<Mark>> getMarksForStudent(String studentId, String term, int year) async {
    final db = await database;
    final res = await db.query('marks', where: 'studentId = ? AND term = ? AND year = ?', whereArgs: [studentId, term, year]);
    return res.map((json) => Mark.fromMap(json)).toList();
  }

  Future<List<Attendance>> getAttendanceForStudent(String studentId) async {
    final db = await database;
    final res = await db.query('attendance', where: 'targetId = ? AND targetType = "Student"', whereArgs: [studentId]);
    return res.map((json) => Attendance.fromMap(json)).toList();
  }

  Future<List<Homework>> getHomeworkByClass(String grade, String stream) async {
    final db = await database;
    final res = await db.query('homework', where: 'grade = ? AND stream = ?', whereArgs: [grade, stream]);
    return res.map((json) => Homework.fromMap(json)).toList();
  }

  Future<void> insertHomework(Homework h) async {
    final db = await database;
    await db.insert('homework', h.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteHomework(String id) async {
    final db_handle = await database;
    await db_handle.delete('homework', where: 'homeworkId = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getEvents() async {
    final db = await database;
    return await db.query('events');
  }

  Future<void> insertVisitor(Map<String, dynamic> v) async {
    final db = await database;
    await db.insert('visitors', v);
  }

  Future<List<Map<String, dynamic>>> getVisitors() async {
    final db = await database;
    return await db.query('visitors');
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final db = await database;
    return await db.query('expenses');
  }

  Future<List<Map<String, dynamic>>> getIncome() async {
    final db = await database;
    return await db.query('income');
  }

  Future<void> insertIncome(Map<String, dynamic> i) async {
    final db = await database;
    await db.insert('income', i);
  }

  Future<List<Map<String, dynamic>>> getFeeStructure() async {
    final db = await database;
    return await db.query('fee_structure');
  }

  Future<void> updateFeeStructure(String grade, double amount) async {
    final db = await database;
    await db.insert('fee_structure', {'grade': grade, 'totalFee': amount}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Student>> getStudentsByParentPhone(String phone) async {
    final db = await database;
    final res = await db.query('students', where: 'parentPhone = ?', whereArgs: [phone]);
    return res.map((json) => Student.fromMap(json)).toList();
  }
}
