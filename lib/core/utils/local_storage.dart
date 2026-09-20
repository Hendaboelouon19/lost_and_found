import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  LocalStorage._();

  static final LocalStorage instance = LocalStorage._();

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static const String _tokenKey = 'token';
  static const String _userIdKey = 'user_id';

  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    return await _prefs.getString(_tokenKey);
  }

  Future<void> saveUserId(String userId) async {
    await _prefs.setString(_userIdKey, userId);
  }

  Future<String?> getUserId() async {
    return await _prefs.getString(_userIdKey);
  }

  Future<void> clearUserData() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userIdKey);
  }
}