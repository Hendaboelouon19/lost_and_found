import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  LocalStorage._();

  static final LocalStorage instance = LocalStorage._();
  static SharedPreferences? _prefs;

  static const String _tokenKey = 'token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _matchAlertsKey = 'match_alerts_enabled';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveToken(String token) async {
    await _prefs?.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    return _prefs?.getString(_tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveUserId(String userId) async {
    await _prefs?.setString(_userIdKey, userId);
  }

  Future<String?> getUserId() async {
    return _prefs?.getString(_userIdKey);
  }

  Future<void> saveUserProfile({
    required String name,
    required String email,
  }) async {
    await _prefs?.setString(_userNameKey, name);
    await _prefs?.setString(_userEmailKey, email);
  }

  Future<String?> getUserName() async {
    return _prefs?.getString(_userNameKey);
  }

  Future<String?> getUserEmail() async {
    return _prefs?.getString(_userEmailKey);
  }

  Future<void> saveMatchAlertsEnabled(bool enabled) async {
    await _prefs?.setBool(_matchAlertsKey, enabled);
  }

  Future<bool> getMatchAlertsEnabled() async {
    return _prefs?.getBool(_matchAlertsKey) ?? true;
  }

  Future<void> clearUserData() async {
    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_userIdKey);
    await _prefs?.remove(_userNameKey);
    await _prefs?.remove(_userEmailKey);
  }
}