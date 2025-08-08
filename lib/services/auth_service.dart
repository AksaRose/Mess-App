import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'user_models.dart';
import 'config.dart';
import 'firebase_user_auth_service.dart';

class AuthService {
  static const String _usersKey = 'users_by_admission';
  static const String _sessionKey = 'current_user';

  Future<bool> signUp({
    required String admissionNo,
    String? email,
    required String fullName,
    required int passOutYear,
    required String password,
  }) async {
    if (AppConfig.isFirebaseEnabled) {
      final fbAuth = FirebaseUserAuthService();
      if (email != null && email.isNotEmpty) {
        await fbAuth.signUpWithEmail(
          email: email,
          fullName: fullName,
          admissionNo: admissionNo,
          passOutYear: passOutYear,
          password: password,
        );
      } else {
        await fbAuth.signUp(
          admissionNo: admissionNo,
          fullName: fullName,
          passOutYear: passOutYear,
          password: password,
        );
      }
      return true;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    final Map<String, dynamic> users = raw == null ? {} : jsonDecode(raw);
    if (users.containsKey(admissionNo)) return false; // already exists
    users[admissionNo] = {
      'user': AppUser(
        admissionNo: admissionNo,
        fullName: fullName,
        passOutYear: passOutYear,
      ).toJson(),
      'password':
          password, // For MVP only. Replace with proper hashing/auth later.
    };
    await prefs.setString(_usersKey, jsonEncode(users));
    await prefs.setString(_sessionKey, admissionNo);
    return true;
  }

  Future<bool> login({
    String? email,
    String? admissionNo,
    required String password,
  }) async {
    if (AppConfig.isFirebaseEnabled) {
      final fbAuth = FirebaseUserAuthService();
      if (email != null && email.isNotEmpty) {
        await fbAuth.loginWithEmail(email: email, password: password);
      } else if (admissionNo != null && admissionNo.isNotEmpty) {
        await fbAuth.login(admissionNo: admissionNo, password: password);
      } else {
        throw Exception('Provide email or admission number');
      }
      return true;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null) return false;
    final Map<String, dynamic> users = jsonDecode(raw);
    final key = admissionNo ?? '';
    if (key.isEmpty) return false;
    final entry = users[key];
    if (entry == null) return false;
    if (entry['password'] != password) return false;
    await prefs.setString(_sessionKey, key);
    return true;
  }

  Future<AppUser?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final admission = prefs.getString(_sessionKey);
    if (admission == null) return null;
    final raw = prefs.getString(_usersKey);
    if (raw == null) return null;
    final Map<String, dynamic> users = jsonDecode(raw);
    final entry = users[admission];
    if (entry == null) return null;
    return AppUser.fromJson(entry['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
