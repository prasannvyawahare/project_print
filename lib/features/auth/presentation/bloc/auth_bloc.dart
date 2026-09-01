import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';

import '../../domain/usecases/check_storage_exists.dart';
import '../../domain/usecases/create_storage.dart';
import '../../domain/usecases/sign_in_with_apple.dart';
import '../../domain/usecases/sign_in_with_email_password.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/verify_and_save_user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required SignInWithGoogle signInWithGoogle,
    required SignInWithApple signInWithApple,
    required SignInWithEmailPassword signInWithEmailPassword,
    required VerifyAndSaveUser verifyAndSaveUser,
    required CheckStorageExists checkStorageExists,
    required CreateStorage createStorage,
    required SignOut signOut,
  }) : _signInWithGoogle = signInWithGoogle,
       _signInWithApple = signInWithApple,
       _signInWithEmailPassword = signInWithEmailPassword,
       _verifyAndSaveUser = verifyAndSaveUser,
       _checkStorageExists = checkStorageExists,
       _createStorage = createStorage,
       _signOut = signOut,
       super(const AuthState()) {
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthAppleSignInRequested>(_onAppleSignInRequested);
    on<AuthEmailPasswordSignInRequested>(_onEmailPasswordSignInRequested);
    on<AuthManualMobileSubmitted>(_onManualMobileSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final SignInWithGoogle _signInWithGoogle;
  final SignInWithApple _signInWithApple;
  final SignInWithEmailPassword _signInWithEmailPassword;
  final VerifyAndSaveUser _verifyAndSaveUser;
  final CheckStorageExists _checkStorageExists;
  final CreateStorage _createStorage;
  final SignOut _signOut;

  /// Ensures the user's storage folder is ready after verify-and-save.
  ///
  /// Flow:
  /// 1. Call `storage-exists`.
  /// 2. If it exists → done (success).
  /// 3. If it does not exist (or backend 500) → call `create-storage`,
  ///    then re-run `storage-exists` to confirm.
  ///
  /// The "Folder does not exist." backend message is treated as a normal
  /// "not created yet" signal and is never surfaced to the user.
  Future<void> _ensureStorageReady(
    String userId,
    Emitter<AuthState> emit,
  ) async {
    final storageResult = await _checkStorageExists();

    await storageResult.fold(
      (failure) async {
        // Only recover from a backend 500; other failures are real errors.
        final isStorageCheck500 =
            failure is ServerFailure && failure.statusCode == 500;

        if (!isStorageCheck500) {
          emit(
            state.copyWith(
              status: AuthStatus.failure,
              errorMessage: failure.message,
              nextStep: AuthNextStep.none,
            ),
          );
          return;
        }

        await _createStorageAndReverify(userId, emit);
      },
      (exists) async {
        if (exists) {
          emit(
            state.copyWith(
              status: AuthStatus.success,
              nextStep: AuthNextStep.none,
            ),
          );
          return;
        }

        // Storage doesn't exist — create it, then re-run storage-exists.
        await _createStorageAndReverify(userId, emit);
      },
    );
  }

  /// Runs `create-storage`, then re-runs `storage-exists` to confirm the
  /// folder now exists. Emits success only when the re-check confirms it.
  Future<void> _createStorageAndReverify(
    String userId,
    Emitter<AuthState> emit,
  ) async {
    final createResult = await _createStorage(userId);

    await createResult.fold(
      (createFailure) async => emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: createFailure.message,
          nextStep: AuthNextStep.none,
        ),
      ),
      (_) async {
        final recheckResult = await _checkStorageExists();

        recheckResult.fold(
          (recheckFailure) => emit(
            state.copyWith(
              status: AuthStatus.failure,
              errorMessage: recheckFailure.message,
              nextStep: AuthNextStep.none,
            ),
          ),
          (existsAfterCreate) => emit(
            state.copyWith(
              status: existsAfterCreate
                  ? AuthStatus.success
                  : AuthStatus.failure,
              errorMessage: existsAfterCreate
                  ? ''
                  : 'Storage verification failed after create. Please retry.',
              nextStep: AuthNextStep.none,
            ),
          ),
        );
      },
    );
  }

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
              errorMessage: '',
              pendingEmail: email,
              pendingAuthToken: authToken,
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

        await verifyResult.fold(
          (failure) async => emit(
            state.copyWith(
              status: AuthStatus.failure,
              errorMessage: failure.message,
              nextStep: AuthNextStep.none,
            ),
          ),
          (userId) async => _ensureStorageReady(userId, emit),
        );
      },
    );
  }

  Future<void> _onEmailPasswordSignInRequested(
    AuthEmailPasswordSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: ''));

    final result = await _signInWithEmailPassword(
      email: event.email,
      password: event.password,
    );

    await result.fold(
      (failure) async => emit(
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
              errorMessage: '',
              pendingEmail: email,
              pendingAuthToken: authToken,
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

        await verifyResult.fold(
          (failure) async => emit(
            state.copyWith(
              status: AuthStatus.failure,
              errorMessage: failure.message,
              nextStep: AuthNextStep.none,
            ),
          ),
          (userId) async => _ensureStorageReady(userId, emit),
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
    final authToken = event.token.trim().isNotEmpty
        ? event.token.trim()
        : state.pendingAuthToken.trim();
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

    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: failure.message,
          nextStep: AuthNextStep.none,
        ),
      ),
      (userId) async => _ensureStorageReady(userId, emit),
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
