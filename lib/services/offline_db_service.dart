import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class OfflineDbService {
  static final OfflineDbService instance = OfflineDbService._init();
  static Database? _database;

  OfflineDbService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kagema_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4, 
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _createStudentsTable(db);
    if (oldVersion < 3) await _createStaffTable(db);
    if (oldVersion < 4) await _createParentsTable(db);
  }

  Future _createDB(Database db, int version) async {
    // Table for Event Handling: Caching GET data
    await db.execute('CREATE TABLE cache (key TEXT PRIMARY KEY, data TEXT, timestamp TEXT)');
    
    // Table for Event Handling: Syncing POST/UPDATE actions (Sync Queue)
    await db.execute('CREATE TABLE sync_queue (id INTEGER PRIMARY KEY AUTOINCREMENT, action TEXT, payload TEXT, timestamp TEXT)');
    
    // User profile for offline login persistence
    await db.execute('CREATE TABLE user_profile (id TEXT PRIMARY KEY, name TEXT, role TEXT, phone TEXT, last_login TEXT)');
    
    await _createStudentsTable(db);
    await _createStaffTable(db);
    await _createParentsTable(db);
  }

  Future _createStudentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE students (
        student_id TEXT PRIMARY KEY, admission_number TEXT, name TEXT, gender TEXT, 
        grade TEXT, stream TEXT, date_of_birth TEXT, parent_name TEXT, 
        parent_phone TEXT, status TEXT, last_updated TEXT
      )
    ''');
  }

  Future _createStaffTable(Database db) async {
    await db.execute('''
      CREATE TABLE staff (
        staff_id TEXT PRIMARY KEY, name TEXT, phone TEXT, email TEXT, 
        role TEXT, department TEXT, salary REAL, status TEXT, last_updated TEXT
      )
    ''');
  }

  Future _createParentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE parents (
        parent_id TEXT PRIMARY KEY, name TEXT, phone TEXT, email TEXT, 
        occupation TEXT, address TEXT, last_updated TEXT
      )
    ''');
  }

  // --- REGISTRY METHODS (LOCAL FIRST) ---

  Future<void> saveStaffLocal(Map<String, dynamic> staff) async {
    final db = await instance.database;
    await db.insert('staff', {
      'staff_id': staff['staff_id'],
      'name': staff['name'],
      'phone': staff['phone'],
      'email': staff['email'],
      'role': staff['role'],
      'department': staff['department'] ?? 'General',
      'salary': staff['salary'],
      'status': staff['status'],
      'last_updated': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveParentLocal(Map<String, dynamic> parent) async {
    final db = await instance.database;
    await db.insert('parents', {
      'parent_id': parent['parent_id'],
      'name': parent['name'],
      'phone': parent['phone'],
      'email': parent['email'],
      'occupation': parent['occupation'],
      'address': parent['address'],
      'last_updated': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveStudentLocal(Map<String, dynamic> student) async {
    final db = await instance.database;
    await db.insert('students', {
      'student_id': student['student_id'] ?? student['studentId'],
      'admission_number': student['admission_number'] ?? student['admissionNumber'],
      'name': student['name'],
      'gender': student['gender'],
      'grade': student['grade'],
      'stream': student['stream'],
      'date_of_birth': student['date_of_birth'] ?? student['dateOfBirth'],
      'parent_name': student['parent_name'] ?? student['parentName'],
      'parent_phone': student['parent_phone'] ?? student['parentPhone'],
      'status': student['status'] ?? 'Active',
      'last_updated': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveStudentsLocal(List<Map<String, dynamic>> students) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var s in students) {
      batch.insert('students', {
        'student_id': s['student_id'] ?? s['studentId'],
        'admission_number': s['admission_number'] ?? s['admissionNumber'],
        'name': s['name'],
        'gender': s['gender'],
        'grade': s['grade'],
        'stream': s['stream'],
        'date_of_birth': s['date_of_birth'] ?? s['dateOfBirth'],
        'parent_name': s['parent_name'] ?? s['parentName'],
        'parent_phone': s['parent_phone'] ?? s['parentPhone'],
        'status': s['status'] ?? 'Active',
        'last_updated': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getStudentsByClassLocal(String grade, String stream) async {
    final db = await instance.database;
    return await db.query('students', 
      where: 'grade = ? AND stream = ?', 
      whereArgs: [grade, stream],
      orderBy: 'name ASC'
    );
  }

  Future<List<Map<String, dynamic>>> getAllStudentsLocal() async {
    final db = await instance.database;
    return await db.query('students', orderBy: 'grade ASC, stream ASC, name ASC');
  }

  // --- EVENT HANDLING: CACHE METHODS ---

  Future<void> saveCache(String key, dynamic data) async {
    final db = await instance.database;
    await db.insert('cache', {
      'key': key,
      'data': jsonEncode(data),
      'timestamp': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<dynamic> getCache(String key) async {
    final db = await instance.database;
    final maps = await db.query('cache', where: 'key = ?', whereArgs: [key]);
    if (maps.isNotEmpty) return jsonDecode(maps.first['data'] as String);
    return null;
  }

  // --- EVENT HANDLING: SYNC QUEUE METHODS ---

  Future<void> addToQueue(String action, Map<String, dynamic> payload) async {
    final db = await instance.database;
    await db.insert('sync_queue', {
      'action': action,
      'payload': jsonEncode(payload),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getQueue() async {
    final db = await instance.database;
    return await db.query('sync_queue', orderBy: 'timestamp ASC');
  }

  Future<void> removeFromQueue(int id) async {
    final db = await instance.database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  // --- USER PROFILE METHODS ---

  Future<Map<String, dynamic>?> getUserProfile() async {
    final db = await instance.database;
    final maps = await db.query('user_profile', limit: 1);
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    final db = await instance.database;
    await db.insert('user_profile', profile, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

