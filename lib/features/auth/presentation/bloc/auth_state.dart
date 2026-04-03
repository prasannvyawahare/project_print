import 'package:equatable/equatable.dart';

enum AuthStatus { initial, loading, success, failure, loggedOut }

enum AuthNextStep { none, enterMobile }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage = '',
    this.pendingEmail = '',
    this.pendingAuthToken = '',
    this.nextStep = AuthNextStep.none,
  });

  final AuthStatus status;
  final String errorMessage;
  final String pendingEmail;
  final String pendingAuthToken;
  final AuthNextStep nextStep;

  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? pendingEmail,
    String? pendingAuthToken,
    AuthNextStep? nextStep,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      pendingAuthToken: pendingAuthToken ?? this.pendingAuthToken,
      nextStep: nextStep ?? this.nextStep,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    pendingEmail,
    pendingAuthToken,
    nextStep,
  ];
}
