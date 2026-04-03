import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

class AuthAppleSignInRequested extends AuthEvent {
  const AuthAppleSignInRequested();
}

class AuthManualMobileSubmitted extends AuthEvent {
  const AuthManualMobileSubmitted(this.mobile);

  final String mobile;

  @override
  List<Object?> get props => [mobile];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
