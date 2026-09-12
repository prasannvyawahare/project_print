import '../../domain/entities/user_profile_entity.dart';

class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required super.id,
    required super.name,
    required super.email,
    required super.mobile,
    required super.photoUrl,
    required super.createdAt,
    required super.emailVerified,
    required super.extra,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    // Backend responses observed elsewhere in this app wrap the payload in
    // `data`; fall back to the top-level map when it isn't nested.
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final user = data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : data;

    const knownKeyAliases = <String, List<String>>{
      'id': ['_id', 'id', 'userId'],
      'name': ['name', 'displayName', 'fullName', 'full_name'],
      'email': ['email'],
      'mobile': ['mobile', 'phone', 'phoneNumber', 'mobileNumber'],
      'photoUrl': ['photoUrl', 'photo', 'avatar', 'profileImage', 'picture'],
      'createdAt': ['createdAt', 'created_at', 'joinedAt', 'joinedOn'],
      'emailVerified': ['emailVerified', 'isEmailVerified', 'email_verified'],
    };

    String pick(String field) {
      for (final key in knownKeyAliases[field]!) {
        final value = user[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
      return '';
    }

    bool pickBool(String field) {
      for (final key in knownKeyAliases[field]!) {
        final value = user[key];
        if (value is bool) return value;
        if (value is num) return value != 0;
        if (value is String) {
          final normalized = value.trim().toLowerCase();
          if (normalized == 'true') return true;
          if (normalized == 'false') return false;
        }
      }
      return false;
    }

    final consumedKeys = knownKeyAliases.values.expand((v) => v).toSet();
    final extra = <String, dynamic>{};
    for (final entry in user.entries) {
      if (!consumedKeys.contains(entry.key) && entry.value != null) {
        extra[entry.key] = entry.value;
      }
    }

    return UserProfileModel(
      id: pick('id'),
      name: pick('name'),
      email: pick('email'),
      mobile: pick('mobile'),
      photoUrl: pick('photoUrl'),
      createdAt: pick('createdAt'),
      emailVerified: pickBool('emailVerified'),
      extra: extra,
    );
  }
}
