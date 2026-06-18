import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'offline_db_service.dart';

class AuthenticationService extends ChangeNotifier {
  static final AuthenticationService _instance = AuthenticationService._internal();
  factory AuthenticationService() => _instance;
  AuthenticationService._internal();

  SupabaseClient get _supabase => Supabase.instance.client;

  String? _currentUserRole;
  String? _currentUserPhone;
  String? _currentUserName;
  bool _isOffline = false;
  bool _isFirstTimeParent = false;

  String? get currentUserRole => _currentUserRole;
  String? get currentUserPhone => _currentUserPhone;
  String get currentUserName => _currentUserName ?? "Authorized User";
  bool get isOffline => _isOffline;
  bool get isFirstTimeParent => _isFirstTimeParent;

  Future<bool> isAuthenticated() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        await _loadUserData(session.user.id);
        _isOffline = false;
        return true;
      } else {
        final offlineProfile = await OfflineDbService.instance.getUserProfile();
        if (offlineProfile != null) {
          _currentUserRole = offlineProfile['role'];
          _currentUserPhone = offlineProfile['phone'];
          _currentUserName = offlineProfile['name'];
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

  Future<void> _loadUserData(String userId) async {
    try {
      final data = await _supabase.from('users').select().eq('user_id', userId).maybeSingle();
      if (data != null) {
        _currentUserRole = data['role'];
        _currentUserPhone = data['identifier'];
        _currentUserName = data['name'];
        await OfflineDbService.instance.saveUserProfile({
          'id': userId,
          'name': _currentUserName,
          'role': _currentUserRole,
          'phone': _currentUserPhone,
          'last_login': DateTime.now().toIso8601String()
        });
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }

  Future<bool> login(String role, String identifier, String password) async {
    try {
      if (role == 'parent') {
        return await _handleParentSecureAuth(identifier, password);
      }

      String finalEmail = identifier.trim();
      if (!finalEmail.contains('@')) {
        finalEmail = "${finalEmail.toLowerCase()}@kagema.com";
      }

      final response = await _supabase.auth.signInWithPassword(email: finalEmail, password: password.trim());
      if (response.user != null) {
        await _loadUserData(response.user!.id);
        _isOffline = false;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Login Error: $e");
      return false;
    }
  }

  /// FEATURE 4: SECURE PARENT AUTHENTICATION WORKFLOW
  /// - Database Cross-Check for student link
  /// - Fast Login with mobile token
  /// - First-time password prompt logic
  Future<bool> _handleParentSecureAuth(String identifier, String password) async {
    try {
      // 1. Database Cross-Check: Verify if parent is explicitly linked to an active student
      final studentLink = await _supabase
          .from('students')
          .select('parent_phone, parent_email, student_status')
          .or('parent_phone.eq.$identifier,parent_email.eq.$identifier')
          .eq('student_status', 'active')
          .maybeSingle();

      if (studentLink == null) {
        debugPrint("Auth Denied: No active student record linked to this identifier.");
        return false;
      }

      // 2. Fast Login: Map identifier to email and attempt authentication.
      // We allow the registered Mobile Number to act as a fast verification token.
      String email = studentLink['parent_email'] ?? "${studentLink['parent_phone']}@kagema.com";
      
      final response = await _supabase.auth.signInWithPassword(
        email: email, 
        password: password.trim()
      );

      if (response.user != null) {
        await _loadUserData(response.user!.id);
        _isOffline = false;

        // 3. First-Time Password Control: Identify if metadata or flag needs a secure setup
        final userProfile = await _supabase.from('users').select('first_login').eq('user_id', response.user!.id).maybeSingle();
        if (userProfile != null && userProfile['first_login'] == true) {
          _isFirstTimeParent = true;
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint("Parent Secure Auth Error: $e");
    }
    return false;
  }

  void clearFirstTimeFlag() {
    _isFirstTimeParent = false;
    notifyListeners();
  }

  Future<void> logout() async {
    try { await _supabase.auth.signOut(); } catch (_) {}
    _currentUserRole = null; _currentUserPhone = null; _currentUserName = null; _isOffline = false;
    _isFirstTimeParent = false;
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
        await _supabase.from('users').update({'name': newName}).eq('user_id', user.id);
        _currentUserName = newName;
        notifyListeners();
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
