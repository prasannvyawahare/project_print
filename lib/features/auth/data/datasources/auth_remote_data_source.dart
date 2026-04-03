import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
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
    required Logger logger,
  }) : _firebaseAuth = firebaseAuth,
       _googleSignIn = googleSignIn,
       _dioClient = dioClient,
       _logger = logger;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final DioClient _dioClient;
  final Logger _logger;

  @override
  Future<AuthUserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = account.authentication;

      final String? _idToken = googleAuth.idToken;
      _logger.i('Google sign-in successful, ID token obtained');
      if (_idToken == null || _idToken.isEmpty) {
        throw ServerException(
          message: 'Google sign-in failed: missing account token.',
        );
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: _idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      final user = userCredential.user;
      final String email = user?.email ?? account.email;
      final String? mobile = user?.phoneNumber;

      final String resolvedToken = (await user?.getIdToken(true) ?? "");
      print("------------ ${resolvedToken.toString()} -------------");

      log(resolvedToken.toString() ?? "XXXXXXXXXXXX");
      // final String headerRToken = idToken.trim();
      // //_logger.i('headerToken: $headerToken');
      if (email.isEmpty) {
        throw ServerException(
          message: 'Google account email is not available.',
        );
      }

      if (resolvedToken.isEmpty || resolvedToken.isEmpty) {
        throw ServerException(
          message: 'Sign-in token is missing. Please try again.',
        );
      }

      //_logger.i('Fetched ID token: $resolvedToken');
      final metadata = {
        'email': email,
        'displayName': user?.displayName ?? account.displayName,
        'mobile': mobile,
        'uid': user?.uid,
        'providerId': userCredential.credential?.providerId,
        'googleAccountId': account.id,
        'photoUrl': user?.photoURL ?? account.photoUrl,
        'createdAt': user?.metadata.creationTime?.toIso8601String(),
        'lastSignInAt': user?.metadata.lastSignInTime?.toIso8601String(),
        'emailVerified': user?.emailVerified,

        'idToken': '$resolvedToken',
      };

      //_logger.i('Gmail login metadata: $metadata');
      _logger.i("Auth token (ccc): $resolvedToken");
      // //_logger.i('Auth token (idToken): $resolvedToken');
      // //_logger.i('Auth token (refreshToken): ${user?.refreshToken}');

      return AuthUserModel(
        email: email,
        mobile: mobile,
        authToken: resolvedToken,
      );
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
      //_logger.i('idToken for verify-and-save: $authToken');

      final user = AuthUserModel(email: email, mobile: mobile);
      await _dioClient.post(
        path: ApiConstants.verifyAndSaveUserPath,
        data: user.toVerifyPayload(mobileNumber: mobile),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        }, //'Authorization': '$authToken'
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
    } catch (error, stackTrace) {
      _logger.e('Sign out error', error: error, stackTrace: stackTrace);
      throw ServerException(message: 'Unable to log out. Please try again.');
    }
  }
}
