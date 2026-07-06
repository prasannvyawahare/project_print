import 'dart:convert';

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

  /// Whether there is a stored token that is present and (for JWTs) not expired.
  ///
  /// If the token is a decodable JWT with an `exp` claim, expiry is enforced
  /// locally. If it is a non-empty, non-JWT (or otherwise undecodable) token,
  /// it is treated as valid here — server-side rejection (401/403) is the
  /// authoritative fallback handled by the network layer.
  bool get hasValidToken {
    final value = token;
    if (value.isEmpty) return false;
    final expiry = _jwtExpiry(value);
    if (expiry == null) return true;
    return DateTime.now().isBefore(expiry);
  }

  /// Extracts the `exp` claim from a JWT as a [DateTime], or `null` if the
  /// token is not a decodable JWT or carries no `exp` claim.
  DateTime? _jwtExpiry(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      final decoded = utf8.decode(base64.decode(payload));
      final map = json.decode(decoded);
      if (map is! Map<String, dynamic>) return null;
      final exp = map['exp'];
      if (exp is! int) return null;
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (_) {
      return null;
    }
  }

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
