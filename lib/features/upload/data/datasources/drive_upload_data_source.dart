import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Uploads a single file to a Google Drive resumable session URL returned by
/// `order/create` (the `uploadUrl` of each item).
///
/// Uses a bare [Dio] instance (not the app [DioClient]) because the target host
/// is `googleapis.com`, not our API base URL, and must not carry our auth
/// interceptor.
class DriveUploadDataSource {
  DriveUploadDataSource({required Logger logger, Dio? dio})
    : _logger = logger,
      _dio = dio ?? Dio();

  final Logger _logger;
  final Dio _dio;

  Future<void> uploadFile({
    required String sessionUrl,
    required String accessToken,
    required File file,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) async {
    if (sessionUrl.isEmpty) {
      throw const FileUploadException('Missing upload URL for this file.');
    }
    if (!await file.exists()) {
      throw const FileUploadException('File no longer exists on this device.');
    }

    final length = await file.length();

    try {
      await _dio.putUri<dynamic>(
        Uri.parse(sessionUrl),
        data: file.openRead(),
        options: Options(
          headers: {
            if (accessToken.isNotEmpty)
              HttpHeaders.authorizationHeader: 'Bearer $accessToken',
            HttpHeaders.contentTypeHeader: mimeType,
            HttpHeaders.contentLengthHeader: length,
          },
        ),
        // Report fractional upload progress (0.0–1.0). `total` comes from the
        // content-length header set above, so it is reliable here.
        onSendProgress: (sent, total) {
          _logger.d(
            'Drive upload progress for ${file.path}: ${(sent / total * 100).toStringAsFixed(1)}%',
          );
          if (onProgress != null && total > 0) {
            onProgress((sent / total).clamp(0.0, 1.0));
          }
        },
      );
    } on DioException catch (error, stackTrace) {
      _logger.e(
        'Drive upload failed for ${file.path}',
        error: error,
        stackTrace: stackTrace,
      );
      final status = error.response?.statusCode;
      throw FileUploadException(
        status != null
            ? 'Upload failed (HTTP $status).'
            : (error.message ?? 'Upload failed. Please retry.'),
      );
    }
  }
}

class FileUploadException implements Exception {
  const FileUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
