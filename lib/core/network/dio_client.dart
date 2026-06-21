import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/api_constants.dart';
import '../storage/temporary_auth_store.dart';

class DioClient {
  DioClient({required Dio dio, required TemporaryAuthStore temporaryAuthStore})
    : _dio = dio,
      _temporaryAuthStore = temporaryAuthStore {
    _dio.options = BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      //  headers: const {'Content-Type': 'application/json'},
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final shouldOmitContentType =
              options.extra['omitContentType'] == true;
          if (shouldOmitContentType) {
            options.headers.remove('Content-Type');
            options.headers.remove('content-type');
            options.contentType = null;
          }

          final token = _temporaryAuthStore.token;
          final hasAuthorizationHeader = options.headers.keys.any(
            (key) => key.toString().toLowerCase() == 'authorization',
          );

          if (token.isNotEmpty && !hasAuthorizationHeader) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['x-client-platform'] = 'mobile';
          handler.next(options);
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
