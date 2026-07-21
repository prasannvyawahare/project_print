import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../app/router/app_router.dart';
import '../constants/api_constants.dart';
import '../storage/temporary_auth_store.dart';

class DioClient {
  DioClient({
    required Dio dio,
    required TemporaryAuthStore temporaryAuthStore,
    required FirebaseAuth firebaseAuth,
  }) : _dio = dio,
       _temporaryAuthStore = temporaryAuthStore,
       _firebaseAuth = firebaseAuth {
    _dio.options = BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      //  headers: const {'Content-Type': 'application/json'},
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final shouldOmitContentType =
              options.extra['omitContentType'] == true;
          if (shouldOmitContentType) {
            options.headers.remove('Content-Type');
            options.headers.remove('content-type');
            options.contentType = null;
          }

          final hasAuthorizationHeader = options.headers.keys.any(
            (key) => key.toString().toLowerCase() == 'authorization',
          );

          if (!hasAuthorizationHeader) {
            final token = await _resolveFreshIdToken();
            if (token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          options.headers['x-client-platform'] = 'mobile';
          options.cancelToken ??= _sessionCancelToken;
          handler.next(options);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;
          final req = error.requestOptions;

          if (statusCode == 401 && req.extra['authRetry'] != true) {
            final user = _firebaseAuth.currentUser;
            if (user != null) {
              try {
                final fresh = await user.getIdToken(true);
                if (fresh != null && fresh.isNotEmpty) {
                  if (fresh != _temporaryAuthStore.token) {
                    await _temporaryAuthStore.save(
                      mobile: _temporaryAuthStore.mobile,
                      token: fresh,
                    );
                  }
                  req.headers['Authorization'] = 'Bearer $fresh';
                  req.extra['authRetry'] = true;
                  try {
                    final response = await _dio.fetch<dynamic>(req);
                    return handler.resolve(response);
                  } on DioException catch (retryError) {
                    final retryStatus = retryError.response?.statusCode;
                    if (retryStatus == 401 || retryStatus == 403) {
                      _handleUnauthorized();
                    }
                    return handler.next(retryError);
                  }
                }
              } catch (_) {
                // Fall through to the standard 401/403 handling below.
              }
            }
          }

          if (statusCode == 401 || statusCode == 403) {
            _handleUnauthorized();
          }
          handler.next(error);
        },
      ),
    );

    _dio.interceptors.add(
      PrettyDioLogger(
        requestBody: true,
        requestHeader: true,
        responseBody: true,
        responseHeader: true,
        error: true,
        compact: false,
        maxWidth: 120,
      ),
    );
  }

  final Dio _dio;
  final TemporaryAuthStore _temporaryAuthStore;
  final FirebaseAuth _firebaseAuth;

  /// Attached to every outbound request via the auth interceptor. Cancelled
  /// (and replaced) on sign-out or 401 redirect so pending responses can't
  /// land after the session ends.
  CancelToken _sessionCancelToken = CancelToken();

  /// Cancels every in-flight request tagged with the current session token
  /// and rotates in a fresh token for the next session.
  void cancelSession([String reason = 'session ended']) {
    if (!_sessionCancelToken.isCancelled) {
      _sessionCancelToken.cancel(reason);
    }
    _sessionCancelToken = CancelToken();
  }

  /// Returns a valid Firebase ID token, refreshing via Firebase when the
  /// cached copy is expired. Falls back to whatever is currently stored if
  /// Firebase has no user or the refresh call fails, so requests can still
  /// proceed (the server will reject with 401 if the token is truly bad).
  Future<String> _resolveFreshIdToken() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        final fresh = await user.getIdToken();
        if (fresh != null && fresh.isNotEmpty) {
          if (fresh != _temporaryAuthStore.token) {
            await _temporaryAuthStore.save(
              mobile: _temporaryAuthStore.mobile,
              token: fresh,
            );
          }
          return fresh;
        }
      } catch (_) {
        // fall through to stored token
      }
    }
    return _temporaryAuthStore.token;
  }

  /// Guards against multiple concurrent 401/403 responses each pushing the
  /// login screen.
  bool _isRedirectingToLogin = false;

  /// Clears the stored session and sends the user back to the login screen
  /// whenever the server rejects the token (401/403). Safe to call from
  /// anywhere via the global navigator key.
  void _handleUnauthorized() {
    if (_isRedirectingToLogin) return;

    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    _isRedirectingToLogin = true;
    cancelSession('unauthorized');
    _temporaryAuthStore.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigator.pushNamedAndRemoveUntil(AppRouter.auth, (route) => false);
      _isRedirectingToLogin = false;
    });
  }

  Future<Response<dynamic>> get({
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
    );
  }

  Future<Response<dynamic>> post({
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool omitContentType = false,
  }) {
    return _dio.post<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(
        headers: headers,
        extra: {'omitContentType': omitContentType},
      ),
    );
  }

  Future<Response<dynamic>> delete({
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool omitContentType = false,
  }) {
    return _dio.delete<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(
        headers: headers,
        extra: {'omitContentType': omitContentType},
      ),
    );
  }

  Future<Response<dynamic>> patch({
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool omitContentType = false,
  }) {
    return _dio.patch<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(
        headers: headers,
        extra: {'omitContentType': omitContentType},
      ),
    );
  }
}
