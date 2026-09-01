import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/temporary_auth_store.dart';
import '../models/auth_user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthUserModel> signInWithGoogle();
  Future<AuthUserModel> signInWithEmailPassword({
    required String email,
    required String password,
  });
  Future<String> verifyAndSaveUser({
    required String email,
    required String mobile,
    required String authToken,
  });
  Future<bool> checkStorageExists();
  Future<void> createStorage(String userId);
  Future<void> signInWithApple();
  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required DioClient dioClient,
    required TemporaryAuthStore temporaryAuthStore,
    required Logger logger,
  }) : _firebaseAuth = firebaseAuth,
       _googleSignIn = googleSignIn,
       _dioClient = dioClient,
       _temporaryAuthStore = temporaryAuthStore,
       _logger = logger;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final DioClient _dioClient;
  final TemporaryAuthStore _temporaryAuthStore;
  final Logger _logger;

  String _extractStringValue(dynamic value) {
    if (value is String) {
      return value.trim();
    }
    if (value is num || value is bool) {
      return value.toString().trim();
    }
    return '';
  }

  String _firstNonEmptyString(Iterable<dynamic> values) {
    for (final value in values) {
      final parsed = _extractStringValue(value);
      if (parsed.isNotEmpty) {
        return parsed;
      }
    }
    return '';
  }

  /// True when the backend message signals the user's storage folder has not
  /// been created yet (e.g. "Folder does not exist.").
  bool _isFolderMissingMessage(String? message) {
    if (message == null) return false;
    final normalized = message.toLowerCase();
    return normalized.contains('folder does not exist') ||
        normalized.contains('folder not found') ||
        (normalized.contains('storage') && normalized.contains('not exist'));
  }

  bool? _extractBoolValue(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }

    return null;
  }

  @override
  Future<AuthUserModel> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();

      // Step 1 — Google Sign-In
      final GoogleSignInAccount account = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = account.authentication;

      if (googleAuth.idToken == null) {
        throw ServerException(
          message: 'Google sign-in failed: missing ID token.',
        );
      }

      // Step 2 — Create Firebase Credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Step 3 — Firebase Sign-In
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      final user = userCredential.user;

      if (user == null) {
        throw ServerException(message: 'Firebase user not available.');
      }

      final String email = user.email ?? account.email;
      final String displayName = user.displayName ?? account.displayName ?? '';

      final String? mobile = user.phoneNumber;

      if (email.isEmpty) {
        throw ServerException(message: 'Google account email not available.');
      }

      // Step 4 — Get Firebase ID Token
      // getIdToken(true) force-refreshes so we always get a Firebase-issued
      // JWT (aud = project ID), never the raw Google OpenID token.
      final String? firebaseIdToken = await user.getIdToken(true);

      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw ServerException(message: 'Failed to retrieve Firebase ID token.');
      }

      _logger.i('=== AUTH TOKENS ===');
      _logger.i('Google ID token : ${googleAuth.idToken}');
      _logger.i('Firebase ID token: $firebaseIdToken');
      _logger.i('==================+');

      await _temporaryAuthStore.save(
        mobile: mobile?.trim() ?? '',
        token: firebaseIdToken,
        displayName: displayName,
      );

      return AuthUserModel(
        email: email,
        displayName: displayName,
        mobile: mobile,
        authToken: firebaseIdToken,
      );
    } on ServerException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      _logger.e(
        'Firebase auth error',
        error: error,
        stackTrace: error.stackTrace,
      );

      throw ServerException(message: error.message ?? 'Authentication failed');
    } on GoogleSignInException catch (error, stackTrace) {
      _logger.e(
        'Google sign-in error: ${error.code}',
        error: error,
        stackTrace: stackTrace,
      );

      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw ServerException(message: 'Sign-in was cancelled.');
      }

      throw ServerException(
        message: 'Google sign-in failed (${error.code.name})',
      );
    } catch (error, stackTrace) {
      _logger.e('Google sign-in error', error: error, stackTrace: stackTrace);

      throw ServerException(message: 'Unable to sign in with Google');
    }
  }

  /// Email/password sign-in for testing without the Google/Apple OAuth
  /// consent screen. Auto-creates the account on first use since this app
  /// has no separate sign-up flow.
  @override
  Future<AuthUserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential;
      try {
        userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (error) {
        if (error.code == 'user-not-found') {
          userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      final user = userCredential.user;
      if (user == null) {
        throw ServerException(message: 'Firebase user not available.');
      }

      final String? firebaseIdToken = await user.getIdToken(true);
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw ServerException(message: 'Failed to retrieve Firebase ID token.');
      }

      await _temporaryAuthStore.save(
        mobile: user.phoneNumber?.trim() ?? '',
        token: firebaseIdToken,
        displayName: user.displayName ?? '',
      );

      return AuthUserModel(
        email: user.email ?? email,
        displayName: user.displayName ?? '',
        mobile: user.phoneNumber,
        authToken: firebaseIdToken,
      );
    } on ServerException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      _logger.e(
        'Email/password auth error',
        error: error,
        stackTrace: error.stackTrace,
      );
      throw ServerException(message: error.message ?? 'Authentication failed');
    } catch (error, stackTrace) {
      _logger.e(
        'Email/password sign-in error',
        error: error,
        stackTrace: stackTrace,
      );
      throw ServerException(
        message: 'Unable to sign in with email and password',
      );
    }
  }

  @override
  Future<String> verifyAndSaveUser({
    required String email,
    required String mobile,
    required String authToken,
  }) async {
    try {
      final trimmedToken = authToken.trim();
      final trimmedMobile = mobile.trim();

      if (trimmedToken.isEmpty) {
        throw ServerException(
          message: 'Auth token missing. Please sign in again.',
        );
      }

      // Keep the latest token in shared store so interceptor applies it to all next APIs.
      await _temporaryAuthStore.save(
        mobile: trimmedMobile,
        token: trimmedToken,
      );

      final user = AuthUserModel(email: email, mobile: mobile);
      final response = await _dioClient.post(
        path: ApiConstants.verifyAndSaveUserPath,
        data: user.toVerifyPayload(mobileNumber: trimmedMobile),
        headers: {
          'authorization': 'Bearer $trimmedToken',
          'content-type': 'application/json',
        },
      );

      final responseData = response.data;
      final map = responseData is Map<String, dynamic>
          ? responseData
          : const <String, dynamic>{};
      final data = map['data'] is Map<String, dynamic>
          ? map['data'] as Map<String, dynamic>
          : const <String, dynamic>{};

      final userId = _firstNonEmptyString([
        data['_id'],
        data['id'],
        data['userId'],
        (data['user'] is Map<String, dynamic>)
            ? (data['user'] as Map<String, dynamic>)['id']
            : null,
        map['_id'],
        map['id'],
        map['userId'],
      ]);

      if (userId.isNotEmpty) {
        await _temporaryAuthStore.saveUserId(userId);
      }

      return userId;
    } on DioException catch (error) {
      final data = error.response?.data;
      final backendMessage = data is Map<String, dynamic>
          ? (data['message']?.toString() ?? data['error']?.toString())
          : null;

      throw ServerException(
        message:
            backendMessage ?? error.message ?? 'Failed to verify and save user',
        statusCode: error.response?.statusCode,
      );
    } catch (error, stackTrace) {
      _logger.e('Verify and save failed', error: error, stackTrace: stackTrace);
      if (error is ServerException) {
        rethrow;
      }
      throw ServerException(message: 'Failed to verify and save user');
    }
  }

  @override
  Future<bool> checkStorageExists() async {
    try {
      final response = await _dioClient.get(
        path: ApiConstants.checkStorageExists,
      );
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        final data = responseData['data'];
        final nestedData = data is Map<String, dynamic>
            ? data
            : const <String, dynamic>{};

        final parsed =
            _extractBoolValue(responseData['exists']) ??
            _extractBoolValue(responseData['success']) ??
            _extractBoolValue(nestedData['exists']) ??
            _extractBoolValue(nestedData['storageExists']) ??
            _extractBoolValue(nestedData['isStorageExists']);

        if (parsed != null) {
          return parsed;
        }
      }
      return false;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      final backendMessage = data is Map<String, dynamic>
          ? (data['message']?.toString() ?? data['error']?.toString())
          : null;

      // Backend returns a non-2xx response with "Folder does not exist."
      // when the user has no storage yet. That is a valid "not created"
      // state, not an error — return false so the caller creates storage.
      if (_isFolderMissingMessage(backendMessage)) {
        return false;
      }

      throw ServerException(
        message: backendMessage ?? error.message ?? 'Failed to check storage',
        statusCode: statusCode,
      );
    } catch (error, stackTrace) {
      _logger.e('Check storage failed', error: error, stackTrace: stackTrace);
      if (error is ServerException) rethrow;
      throw ServerException(message: 'Failed to check storage');
    }
  }

  @override
  Future<void> createStorage(String userId) async {
    try {
      await _dioClient.post(
        path: ApiConstants.createStorage,
        data: {'id': userId, '_id': userId, 'userId': userId},
        headers: {'content-type': 'application/json'},
      );
    } on DioException catch (error) {
      final data = error.response?.data;
      final backendMessage = data is Map<String, dynamic>
          ? (data['message']?.toString() ?? data['error']?.toString())
          : null;
      throw ServerException(
        message: backendMessage ?? error.message ?? 'Failed to create storage',
        statusCode: error.response?.statusCode,
      );
    } catch (error, stackTrace) {
      _logger.e('Create storage failed', error: error, stackTrace: stackTrace);
      if (error is ServerException) rethrow;
      throw ServerException(message: 'Failed to create storage');
    }
  }

  @override
  Future<void> signInWithApple() async {
    final bool isAvailable = await SignInWithApple.isAvailable();
    if (!isAvailable) {
      throw Exception('Apple sign-in is not available on this device.');
    }

    final AuthorizationCredentialAppleID appleCredential =
        await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

    final OAuthCredential credential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    await _firebaseAuth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    try {
      _dioClient.cancelSession('signed out');
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      await _temporaryAuthStore.clear();
    } catch (error, stackTrace) {
      _logger.e('Sign out error', error: error, stackTrace: stackTrace);
      throw ServerException(message: 'Unable to log out. Please try again.');
    }
  }
}
