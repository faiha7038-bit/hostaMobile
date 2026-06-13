import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService instance = AuthService._();

  AuthService._();

  Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  // ================= ACCESS TOKEN =================

  Future<void> saveAccessToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString('authToken', token);
  }

  Future<String?> getAccessToken() async {
    final prefs = await _prefs;
    return prefs.getString('authToken');
  }

  // ================= REFRESH TOKEN =================

  Future<void> saveRefreshToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString('refreshToken', token);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _prefs;
    return prefs.getString('refreshToken');
  }

  // ================= CLEAR =================

  Future<void> clearAuth() async {
    final prefs = await _prefs;

    await prefs.remove('authToken');
    await prefs.remove('refreshToken');
    await prefs.remove('userId');
  }
}