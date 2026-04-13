import 'package:shared_preferences/shared_preferences.dart';

class TemporaryAuthStore {
  TemporaryAuthStore({required SharedPreferences preferences})
    : _preferences = preferences;

  static const String _mobileKey = 'temp_mobile_number';
  static const String _tokenKey = 'temp_api_token';

  final SharedPreferences _preferences;

  String get mobile => _preferences.getString(_mobileKey)?.trim() ?? '';

  String get token => _preferences.getString(_tokenKey)?.trim() ?? '';

  Future<void> save({required String mobile, required String token}) async {
    await _preferences.setString(_mobileKey, mobile.trim());
    await _preferences.setString(_tokenKey, token.trim());
  }

  Future<void> clear() async {
    await _preferences.remove(_mobileKey);
    await _preferences.remove(_tokenKey);
  }
}
