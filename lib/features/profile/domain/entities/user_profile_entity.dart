import 'package:equatable/equatable.dart';

class UserProfileEntity extends Equatable {
  const UserProfileEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.photoUrl,
    required this.createdAt,
    required this.emailVerified,
    required this.extra,
  });

  final String id;
  final String name;
  final String email;
  final String mobile;
  final String photoUrl;
  final String createdAt;
  final bool emailVerified;

  /// Any additional fields returned by the backend that don't map to a known
  /// field above, keyed by their original JSON key. Lets the profile screen
  /// surface everything the API sends without needing a schema update every
  /// time the backend adds a field.
  final Map<String, dynamic> extra;

  @override
  List<Object?> get props =>
      [id, name, email, mobile, photoUrl, createdAt, emailVerified, extra];
}
