import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
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

      final String? firebaseIdToken = await user?.getIdToken();
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw ServerException(
          message: 'Failed to retrieve Firebase ID token.',
        );
      }

      _logger.i('Using Firebase ID token for verify-and-save request');

      await _temporaryAuthStore.save(
        mobile: mobile?.trim() ?? '',
        token: firebaseIdToken,
      );

      return AuthUserModel(email: email, mobile: mobile, authToken: firebaseIdToken);
    } on ServerException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      _logger.e(
        'Auth service error',
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
    } on PlatformException catch (error, stackTrace) {
      _logger.e(
        'Google sign-in platform error: ${error.code}',
        error: error,
        stackTrace: stackTrace,
      );
      if (error.code == 'sign_in_canceled') {
        throw ServerException(message: 'Sign-in was cancelled.');
      }
      throw ServerException(
        message: error.message ?? 'Google sign-in failed (${error.code})',
      );
    } catch (error, stackTrace) {
      _logger.e('Google sign-in error', error: error, stackTrace: stackTrace);
      throw ServerException(message: 'Unable to sign in with Google');
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
      final userId = (responseData is Map<String, dynamic>)
          ? (responseData['data']?['id']?.toString() ?? '')
          : '';

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
        return responseData['success'] == true;
      }
      return false;
    } on DioException catch (error) {
      final data = error.response?.data;
      final backendMessage = data is Map<String, dynamic>
          ? (data['message']?.toString() ?? data['error']?.toString())
          : null;
      throw ServerException(
        message: backendMessage ?? error.message ?? 'Failed to check storage',
        statusCode: error.response?.statusCode,
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
        data: {'id': userId},
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
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      await _temporaryAuthStore.clear();
    } catch (error, stackTrace) {
      _logger.e('Sign out error', error: error, stackTrace: stackTrace);
      throw ServerException(message: 'Unable to log out. Please try again.');
    }
  }
}
