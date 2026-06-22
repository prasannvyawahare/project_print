import 'package:shared_preferences/shared_preferences.dart';

class TemporaryAuthStore {
  TemporaryAuthStore({required SharedPreferences preferences})
    : _preferences = preferences;

  static const String _mobileKey = 'temp_mobile_number';
  static const String _tokenKey = 'temp_api_token';
  static const String _userIdKey = 'temp_user_id';
  static const String _displayNameKey = 'temp_display_name';

  final SharedPreferences _preferences;

  String get mobile => _preferences.getString(_mobileKey)?.trim() ?? '';

  String get token => _preferences.getString(_tokenKey)?.trim() ?? '';

  String get userId => _preferences.getString(_userIdKey)?.trim() ?? '';

  String get displayName =>
      _preferences.getString(_displayNameKey)?.trim() ?? '';

  Future<void> save({
    required String mobile,
    required String token,
    String? displayName,
  }) async {
    await _preferences.setString(_mobileKey, mobile.trim());
    await _preferences.setString(_tokenKey, token.trim());

    if (displayName != null) {
      await _preferences.setString(_displayNameKey, displayName.trim());
    }
  }

  Future<void> saveUserId(String userId) async {
    await _preferences.setString(_userIdKey, userId.trim());
  }

  Future<void> clear() async {
    await _preferences.remove(_mobileKey);
    await _preferences.remove(_tokenKey);
    await _preferences.remove(_userIdKey);
    await _preferences.remove(_displayNameKey);
  }
}
