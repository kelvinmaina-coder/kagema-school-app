import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthenticationService extends ChangeNotifier {
  static final AuthenticationService _instance = AuthenticationService._internal();
  factory AuthenticationService() => _instance;
  AuthenticationService._internal();

  final _supabase = Supabase.instance.client;

  String? _currentUserRole;
  String? _currentUserPhone;
  String? _currentUserName;

  String? get currentUserRole => _currentUserRole;
  String? get currentUserPhone => _currentUserPhone;
  String get currentUserName => _currentUserName ?? "Authorized User";

  Future<bool> isAuthenticated() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _loadUserData(session.user.id);
      return true;
    }
    return false;
  }

  Future<void> _loadUserData(String userId) async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      if (data != null) {
        _currentUserRole = data['role'];
        _currentUserPhone = data['identifier'];
        _currentUserName = data['name'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }

  Future<bool> login(String role, String identifier, String password) async {
    try {
      // Identifier is usually email for Supabase Auth
      final response = await _supabase.auth.signInWithPassword(
        email: identifier.trim(),
        password: password.trim(),
      );

      if (response.user != null) {
        await _loadUserData(response.user!.id);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Login Error: $e");
      return false;
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _currentUserRole = null;
    _currentUserPhone = null;
    _currentUserName = null;
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
        });
        return {'success': true, 'message': 'Account created successfully.'};
      }
      return {'success': false, 'message': 'Registration failed.'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> updateName(String newName) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _supabase.from('users').update({'name': newName}).eq('user_id', user.id);
      _currentUserName = newName;
      notifyListeners();
    }
  }

  Future<bool> changePassword(String oldPass, String newPass) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPass));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> signUp(String email, String password, String name, String role) async {
    final res = await _supabase.auth.signUp(email: email, password: password);
    if (res.user != null) {
      await _supabase.from('users').insert({
        'user_id': res.user!.id,
        'identifier': email,
        'name': name,
        'role': role,
      });
    }
  }
}
