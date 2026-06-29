import 'dart:convert';
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

  /// PUTs [file] to the Drive resumable [sessionUrl] and returns the file
  /// metadata Drive replies with on completion, e.g.:
  ///
  /// ```json
  /// {
  ///   "kind": "drive#file",
  ///   "id": "123gkHaAvsPzBPN8VQYGmmE6jrHGj1ctY",
  ///   "name": "..._globalwarming.pdf",
  ///   "mimeType": "application/pdf"
  /// }
  /// ```
  ///
  /// The returned [DriveUploadResult.id] is the Drive file id needed to
  /// finalize the item via `upload/complete`.
  Future<DriveUploadResult> uploadFile({
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
      final response = await _dio.putUri<dynamic>(
        Uri.parse(sessionUrl),
        data: file.openRead(),
        options: Options(
          headers: {
            if (accessToken.isNotEmpty)
              HttpHeaders.authorizationHeader: 'Bearer $accessToken',
            HttpHeaders.contentTypeHeader: mimeType,
            HttpHeaders.contentLengthHeader: length,
          },
          // Drive replies with a JSON body; ask Dio to decode it as a Map.
          responseType: ResponseType.json,
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

      final result = DriveUploadResult.fromResponse(response.data);
      _logger.i(
        'Drive upload finished for ${file.path}: id=${result.id}, name=${result.name}',
      );
      return result;
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

/// The Drive file metadata returned by the resumable session PUT once the
/// upload completes (see [DriveUploadDataSource.uploadFile]).
class DriveUploadResult {
  const DriveUploadResult({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.kind,
  });

  /// Parses Drive's JSON body. Dio may hand back a decoded [Map] or, if the
  /// content type wasn't JSON, a raw [String] that we decode here.
  factory DriveUploadResult.fromResponse(dynamic data) {
    final Map<String, dynamic> json;
    if (data is Map<String, dynamic>) {
      json = data;
    } else if (data is String && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      json = decoded is Map<String, dynamic> ? decoded : const {};
    } else {
      json = const {};
    }

    final id = (json['id'] as String?) ?? '';
    if (id.isEmpty) {
      throw const FileUploadException(
        'Drive did not return a file id for this upload.',
      );
    }

    return DriveUploadResult(
      id: id,
      name: (json['name'] as String?) ?? '',
      mimeType: (json['mimeType'] as String?) ?? '',
      kind: (json['kind'] as String?) ?? '',
    );
  }

  /// Google Drive file id, e.g. `123gkHaAvsPzBPN8VQYGmmE6jrHGj1ctY`.
  final String id;

  /// Stored file name returned by Drive.
  final String name;

  /// MIME type Drive recorded for the file.
  final String mimeType;

  /// Resource kind, typically `drive#file`.
  final String kind;
}
