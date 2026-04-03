import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/sign_in_with_apple.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/verify_and_save_user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required SignInWithGoogle signInWithGoogle,
    required SignInWithApple signInWithApple,
    required VerifyAndSaveUser verifyAndSaveUser,
    required SignOut signOut,
  }) : _signInWithGoogle = signInWithGoogle,
       _signInWithApple = signInWithApple,
       _verifyAndSaveUser = verifyAndSaveUser,
       _signOut = signOut,
       super(const AuthState()) {
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthAppleSignInRequested>(_onAppleSignInRequested);
    on<AuthManualMobileSubmitted>(_onManualMobileSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final SignInWithGoogle _signInWithGoogle;
  final SignInWithApple _signInWithApple;
  final VerifyAndSaveUser _verifyAndSaveUser;
  final SignOut _signOut;

  Future<void> _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: ''));

    final result = await _signInWithGoogle();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: failure.message,
          nextStep: AuthNextStep.none,
        ),
      ),
      (user) async {
        final email = user.email;
        final mobile = user.mobile?.trim() ?? '';
        final authToken = user.authToken?.trim() ?? '';

        if (authToken.isEmpty) {
          emit(
            state.copyWith(
              status: AuthStatus.failure,
              errorMessage: 'Auth token missing. Please sign in again.',
              nextStep: AuthNextStep.none,
            ),
          );
          return;
        }

        if (mobile.isEmpty) {
          emit(
            state.copyWith(
              status: AuthStatus.initial,
              pendingEmail: email,
              pendingAuthToken: authToken,
              errorMessage: '',
              nextStep: AuthNextStep.enterMobile,
            ),
          );
          return;
        }

        final verifyResult = await _verifyAndSaveUser(
          VerifyAndSaveUserParams(
            email: email,
            mobile: mobile,
            authToken: authToken,
          ),
        );

        verifyResult.fold(
          (failure) => emit(
            state.copyWith(
              status: AuthStatus.failure,
              errorMessage: failure.message,
              nextStep: AuthNextStep.none,
            ),
          ),
          (_) => emit(
            state.copyWith(
              status: AuthStatus.success,
              nextStep: AuthNextStep.none,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onAppleSignInRequested(
    AuthAppleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: ''));

    final result = await _signInWithApple();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: failure.message,
          nextStep: AuthNextStep.none,
        ),
      ),
      (_) => emit(
        state.copyWith(status: AuthStatus.success, nextStep: AuthNextStep.none),
      ),
    );
  }

  Future<void> _onManualMobileSubmitted(
    AuthManualMobileSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final email = state.pendingEmail.trim();
    final authToken = state.pendingAuthToken.trim();
    final mobile = event.mobile.trim();

    if (email.isEmpty) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Email is missing. Please sign in again.',
          nextStep: AuthNextStep.none,
        ),
      );
      return;
    }

    if (authToken.isEmpty) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Auth token missing. Please sign in again.',
          nextStep: AuthNextStep.none,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: AuthStatus.loading,
        errorMessage: '',
        nextStep: AuthNextStep.none,
      ),
    );

    final result = await _verifyAndSaveUser(
      VerifyAndSaveUserParams(
        email: email,
        mobile: mobile,
        authToken: authToken,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: failure.message,
          nextStep: AuthNextStep.none,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: AuthStatus.success,
          errorMessage: '',
          pendingEmail: '',
          pendingAuthToken: '',
          nextStep: AuthNextStep.none,
        ),
      ),
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: ''));

    final result = await _signOut();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: failure.message,
          nextStep: AuthNextStep.none,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: AuthStatus.loggedOut,
          pendingEmail: '',
          pendingAuthToken: '',
          errorMessage: '',
          nextStep: AuthNextStep.none,
        ),
      ),
    );
  }
}
