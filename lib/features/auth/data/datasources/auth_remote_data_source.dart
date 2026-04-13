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
  Future<void> verifyAndSaveUser({
    required String email,
    required String mobile,
    required String authToken,
  });
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

  @override
  Future<AuthUserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = account.authentication;

      final String? idToken = googleAuth.idToken?.trim();
      _logger.i('Google sign-in successful, ID token obtained');
      if (idToken == null || idToken.isEmpty) {
        throw ServerException(
          message: 'Google sign-in failed: missing account token.',
        );
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      final user = userCredential.user;
      final String email = user?.email ?? account.email;
      final String? mobile = user?.phoneNumber;

      if (email.isEmpty) {
        throw ServerException(
          message: 'Google account email is not available.',
        );
      }

      _logger.i('Using Google ID token for verify-and-save request');

      await _temporaryAuthStore.save(
        mobile: mobile?.trim() ?? '',
        token: idToken,
      );

      return AuthUserModel(email: email, mobile: mobile, authToken: idToken);
    } on ServerException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      _logger.e(
        'Auth service error',
        error: error,
        stackTrace: error.stackTrace,
      );
      throw ServerException(message: error.message ?? 'Authentication failed');
    } catch (error, stackTrace) {
      _logger.e('Google sign-in error', error: error, stackTrace: stackTrace);
      throw ServerException(message: 'Unable to sign in with Google');
    }
  }

  @override
  Future<void> verifyAndSaveUser({
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
      await _dioClient.post(
        path: ApiConstants.verifyAndSaveUserPath,
        data: user.toVerifyPayload(mobileNumber: trimmedMobile),
        headers: {
          'authorization': 'Bearer $trimmedToken',
          'content-type': 'application/json',
        },
      );
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
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      await _temporaryAuthStore.clear();
    } catch (error, stackTrace) {
      _logger.e('Sign out error', error: error, stackTrace: stackTrace);
      throw ServerException(message: 'Unable to log out. Please try again.');
    }
  }
}
