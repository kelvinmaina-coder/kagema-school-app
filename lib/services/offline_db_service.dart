import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class OfflineDbService {
  static final OfflineDbService instance = OfflineDbService._init();
  static Database? _database;

  OfflineDbService._init();

  Future<Database?> get database async {
    if (kIsWeb) return null; // Logic: Don't load sqflite on Web
    if (_database != null) return _database!;
    _database = await _initDB('kagema_offline.db');
    return _database!;
  }

  Future<Database?> _initDB(String filePath) async {
    if (kIsWeb) return null;
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
    await db.execute('CREATE TABLE cache (key TEXT PRIMARY KEY, data TEXT, timestamp TEXT)');
    await db.execute('CREATE TABLE sync_queue (id INTEGER PRIMARY KEY AUTOINCREMENT, action TEXT, payload TEXT, timestamp TEXT)');
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

  // --- SAFE WRAPPERS FOR WEB ---

  Future<void> saveStaffLocal(Map<String, dynamic> staff) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
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
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
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
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
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
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
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
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    return await db.query('students', 
      where: 'grade = ? AND stream = ?', 
      whereArgs: [grade, stream],
      orderBy: 'name ASC'
    );
  }

  Future<List<Map<String, dynamic>>> getAllStudentsLocal() async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    return await db.query('students', orderBy: 'grade ASC, stream ASC, name ASC');
  }

  Future<void> saveCache(String key, dynamic data) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    await db.insert('cache', {
      'key': key,
      'data': jsonEncode(data),
      'timestamp': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<dynamic> getCache(String key) async {
    if (kIsWeb) return null;
    final db = await database;
    if (db == null) return null;
    final maps = await db.query('cache', where: 'key = ?', whereArgs: [key]);
    if (maps.isNotEmpty) return jsonDecode(maps.first['data'] as String);
    return null;
  }

  Future<void> addToQueue(String action, Map<String, dynamic> payload) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    await db.insert('sync_queue', {
      'action': action,
      'payload': jsonEncode(payload),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getQueue() async {
    if (kIsWeb) return [];
    final db = await database;
    if (db == null) return [];
    return await db.query('sync_queue', orderBy: 'timestamp ASC');
  }

  Future<void> removeFromQueue(int id) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (kIsWeb) return null;
    final db = await database;
    if (db == null) return null;
    final maps = await db.query('user_profile', limit: 1);
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    if (kIsWeb) return;
    final db = await database;
    if (db == null) return;
    await db.insert('user_profile', profile, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
