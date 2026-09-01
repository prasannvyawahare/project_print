import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

class AuthManualMobileSubmitted extends AuthEvent {
  const AuthManualMobileSubmitted({required this.mobile, required this.token});

  final String mobile;
  final String token;

  @override
  List<Object?> get props => [mobile, token];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
