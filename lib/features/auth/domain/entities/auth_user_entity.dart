import 'package:equatable/equatable.dart';

class AuthUserEntity extends Equatable {
  const AuthUserEntity({
    required this.email,
    this.displayName,
    this.mobile,
    this.authToken,
  });

  final String email;
  final String? displayName;
  final String? mobile;
  final String? authToken;

  @override
  List<Object?> get props => [email, displayName, mobile, authToken];
}
