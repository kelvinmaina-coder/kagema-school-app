import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'offline_db_service.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class AuthenticationService extends ChangeNotifier {
  static final AuthenticationService _instance = AuthenticationService._internal();
  factory AuthenticationService() => _instance;
  AuthenticationService._internal();

  SupabaseClient get _supabase => Supabase.instance.client;

  String? _currentUserRole;
  String? _currentUserPhone;
  String? _currentUserName;
  String? _lastLogin;
  bool _isOffline = false;
  bool _isFirstTimeParent = false;

  // Realtime subscription to listen for database changes
  StreamSubscription? _userSubscription;

  String? get currentUserRole => _currentUserRole;
  String? get currentUserPhone => _currentUserPhone;
  String get currentUserName => _currentUserName ?? "Authorized User";
  String? get currentUserId => _supabase.auth.currentUser?.id;
  String? get currentUserEmail => _supabase.auth.currentUser?.email;
  String? get lastLogin => _lastLogin;
  bool get isOffline => _isOffline;
  bool get isFirstTimeParent => _isFirstTimeParent;
  
  String get memberSince {
    final date = _supabase.auth.currentUser?.createdAt;
    if (date == null) return "Unknown Node";
    try {
      final dt = DateTime.parse(date);
      return DateFormat('MMMM yyyy').format(dt);
    } catch (_) {
      return "New Node";
    }
  }

  String get lastSync {
    if (_lastLogin == null) return "Pending Sync";
    try {
      final dt = DateTime.parse(_lastLogin!);
      return DateFormat('HH:mm, dd MMM').format(dt);
    } catch (_) {
      return "Sync Unknown";
    }
  }

  // Helper to check if a profile exists locally for "Welcome Back" feature
  Future<Map<String, dynamic>?> getCachedProfile() async {
    return await OfflineDbService.instance.getUserProfile();
  }

  Future<bool> isAuthenticated() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        _startUserRealtimeListener(session.user.id); // Start listening to live changes
        // Attempt to refresh user data from network, but timeout if connection is poor
        try {
          await _loadUserData(session.user.id).timeout(const Duration(seconds: 4));
          _isOffline = false;
        } catch (_) {
          // If network refresh fails, we use the cached data
          final offlineProfile = await OfflineDbService.instance.getUserProfile();
          if (offlineProfile != null) {
            _currentUserRole = offlineProfile['role'] as String?;
            _currentUserPhone = offlineProfile['phone'] as String?;
            _currentUserName = offlineProfile['name'] as String?;
            _isOffline = true;
          }
        }
        return true;
      } else {
        final offlineProfile = await OfflineDbService.instance.getUserProfile();
        if (offlineProfile != null) {
          _currentUserRole = offlineProfile['role'] as String?;
          _currentUserPhone = offlineProfile['phone'] as String?;
          _currentUserName = offlineProfile['name'] as String?;
          _lastLogin = offlineProfile['last_login'] as String?;
          _isOffline = true;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint("Auth Session Error: $e");
    }
    return false;
  }

  // --- NEW: THE LIVE DATABASE LISTENER ---
  void _startUserRealtimeListener(String userId) {
    _userSubscription?.cancel();
    _userSubscription = _supabase
        .from('users')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty) {
            final updatedUser = data.first;
            _currentUserRole = updatedUser['role'];
            _currentUserPhone = updatedUser['identifier'];
            _currentUserName = updatedUser['name'];
            
            // Sync to local storage as data changes live
            OfflineDbService.instance.saveUserProfile({
              'id': userId,
              'name': _currentUserName,
              'role': _currentUserRole,
              'phone': _currentUserPhone,
              'last_login': _lastLogin
            });
            
            debugPrint("LIVE SYNC: Profile updated from Supabase");
            notifyListeners(); // This triggers the UI to refresh instantly
          }
        });
  }

  Future<void> _loadUserData(String userId) async {
    try {
      final data = await _supabase.from('users').select().eq('user_id', userId).maybeSingle();
      if (data != null) {
        _currentUserRole = data['role'];
        _currentUserPhone = data['identifier'];
        _currentUserName = data['name'];
        _lastLogin = DateTime.now().toIso8601String();
        
        await OfflineDbService.instance.saveUserProfile({
          'id': userId,
          'name': _currentUserName,
          'role': _currentUserRole,
          'phone': _currentUserPhone,
          'last_login': _lastLogin
        });
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
      rethrow;
    }
  }

  Future<bool> login(String role, String identifier, String password) async {
    try {
      if (role == 'parent') {
        return await _handleParentSecureAuth(identifier, password).timeout(const Duration(seconds: 10));
      }

      String finalEmail = identifier.trim();
      if (!finalEmail.contains('@')) {
        finalEmail = "${finalEmail.toLowerCase()}@kagema.com";
      }

      final response = await _supabase.auth.signInWithPassword(
        email: finalEmail, 
        password: password.trim()
      ).timeout(const Duration(seconds: 10));

      if (response.user != null) {
        _startUserRealtimeListener(response.user!.id); // Start live sync on login
        await _loadUserData(response.user!.id);
        _isOffline = false;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Login failed/timed out, checking offline availability: $e");
      // OFFLINE LOGIN FALLBACK
      final offlineProfile = await OfflineDbService.instance.getUserProfile();
      if (offlineProfile != null && 
          (offlineProfile['phone'] == identifier || offlineProfile['id'] == identifier || 
           (offlineProfile['email'] != null && offlineProfile['email'] == identifier))) {
        
        // Ensure the role matches for security
        if (offlineProfile['role'] == role) {
          _currentUserRole = offlineProfile['role'] as String?;
          _currentUserPhone = offlineProfile['phone'] as String?;
          _currentUserName = offlineProfile['name'] as String?;
          _lastLogin = offlineProfile['last_login'] as String?;
          _isOffline = true;
          notifyListeners();
          return true;
        }
      }
      return false;
    }
  }

  Future<bool> _handleParentSecureAuth(String identifier, String password) async {
    try {
      final studentLink = await _supabase
          .from('students')
          .select('parent_phone, parent_email, student_status')
          .or('parent_phone.eq.$identifier,parent_email.eq.$identifier')
          .eq('student_status', 'active')
          .maybeSingle();

      if (studentLink == null) throw "NO_STUDENT_LINK";

      String email = studentLink['parent_email'] ?? "${studentLink['parent_phone']}@kagema.com";
      
      final response = await _supabase.auth.signInWithPassword(
        email: email, 
        password: password.trim()
      );

      if (response.user != null) {
        _startUserRealtimeListener(response.user!.id); // Start live sync for parents
        await _loadUserData(response.user!.id);
        _isOffline = false;

        final userProfile = await _supabase.from('users').select('first_login').eq('user_id', response.user!.id).maybeSingle();
        if (userProfile != null && userProfile['first_login'] == true) {
          _isFirstTimeParent = true;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Parent login failed, checking offline availability: $e");
      final offlineProfile = await OfflineDbService.instance.getUserProfile();
      if (offlineProfile != null && offlineProfile['role'] == 'parent' && 
          (offlineProfile['phone'] == identifier)) {
        _currentUserRole = offlineProfile['role'] as String?;
        _currentUserPhone = offlineProfile['phone'] as String?;
        _currentUserName = offlineProfile['name'] as String?;
        _lastLogin = offlineProfile['last_login'] as String?;
        _isOffline = true;
        notifyListeners();
        return true;
      }
      return false;
    }
  }

  void clearFirstTimeFlag() {
    _isFirstTimeParent = false;
    notifyListeners();
  }

  Future<void> logout() async {
    _userSubscription?.cancel(); // Stop live listening on logout
    try { await _supabase.auth.signOut(); } catch (_) {}
    _currentUserRole = null; _currentUserPhone = null; _currentUserName = null; _isOffline = false;
    _isFirstTimeParent = false; _lastLogin = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> registerParent(String phone, String password) async {
    try {
      final email = "${phone.trim()}@kagema.com";
      final res = await _supabase.auth.signUp(email: email, password: password);
      if (res.user != null) {
        await _supabase.from('users').insert({
          'user_id': res.user!.id,
          'identifier': phone.trim(),
          'name': 'Parent',
          'role': 'parent',
          'first_login': true,
        });
        return {'success': true, 'message': 'Account created successfully.'};
      }
      return {'success': false, 'message': 'Registration failed.'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> updateName(String newName) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // This update will trigger the realtime listener above automatically
        await _supabase.from('users').update({'name': newName}).eq('user_id', user.id);
      }
    } catch (_) {}
  }

  Future<bool> changePassword(String oldPass, String newPass) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPass));
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('users').update({'first_login': false}).eq('user_id', user.id);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> signUp(String email, String password, String name, String role) async {
    try {
      final res = await _supabase.auth.signUp(email: email, password: password);
      if (res.user != null) {
        await _supabase.from('users').insert({
          'user_id': res.user!.id,
          'identifier': email,
          'name': name,
          'role': role,
        });
      }
    } catch (_) {}
  }
}
