import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

/// Allowed MIME types for print-ready uploads.
const _allowedMimeTypes = <String>{
  'application/pdf',
  'image/jpeg',
  'image/png',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
};

/// Allowed file extensions shown in the picker.
const _allowedExtensions = <String>['pdf', 'jpg', 'jpeg', 'png', 'docx'];

/// 20 MB in bytes.
const _maxFileSizeBytes = 20 * 1024 * 1024;

/// Number of upload retries before giving up.
const _maxRetries = 3;

/// Timeout for the direct-to-storage PUT request (large files).
const _uploadTimeout = Duration(minutes: 5);

// ---------------------------------------------------------------------------

class UploadDriveService {
  UploadDriveService({
    required FirebaseAuth firebaseAuth,
    required DioClient dioClient,
    required Logger logger,
  })  : _firebaseAuth = firebaseAuth,
        _dioClient = dioClient,
        _logger = logger;

  final FirebaseAuth _firebaseAuth;
  final DioClient _dioClient;
  final Logger _logger;

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Guides the user through picking a file, validating it, uploading it to
  /// Google Drive via the print-hub backend, and confirming the upload.
  ///
  /// Shows inline progress feedback via a [SnackBar] overlay.
  /// [context] must be mounted for the duration of the call.
  Future<void> uploadFileToDrive(BuildContext context) async {
    // --- 1. Pick file -------------------------------------------------------
    final picked = await _pickFile();
    if (picked == null) return; // user cancelled

    if (!context.mounted) return;

    final filePath = picked.path!;
    final fileName = picked.name;
    final fileSize = picked.size;
    final mimeType = _mimeTypeFor(fileName);

    // --- 2. Validate --------------------------------------------------------
    final validationError = _validate(fileName, fileSize, mimeType);
    if (validationError != null) {
      _showError(context, validationError);
      return;
    }

    // mimeType is guaranteed non-null after validation above.
    final resolvedMimeType = mimeType!;

    // --- 3. Show progress scaffold ------------------------------------------
    final progressNotifier = ValueNotifier<_UploadProgress>(
      const _UploadProgress(phase: _Phase.requestingUrl),
    );

    _showProgressSnackBar(context, fileName, fileSize, progressNotifier);

    try {
      // --- 4. Firebase ID token -------------------------------------------
      final idToken = await _getFirebaseToken();

      // --- 5. Request upload URL from backend -----------------------------
      progressNotifier.value = const _UploadProgress(phase: _Phase.requestingUrl);

      final session = await _requestUploadSession(
        idToken: idToken,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: resolvedMimeType,
      );

      // --- 6. Upload bytes to Google --------------------------------------
      progressNotifier.value = const _UploadProgress(phase: _Phase.uploading, percent: 0);

      await _uploadToStorage(
        uploadUrl: session.uploadUrl,
        filePath: filePath,
        mimeType: resolvedMimeType,
        fileSize: fileSize,
        onProgress: (percent) {
          progressNotifier.value = _UploadProgress(
            phase: _Phase.uploading,
            percent: percent,
          );
        },
      );

      // --- 7. Confirm with backend ----------------------------------------
      progressNotifier.value = const _UploadProgress(phase: _Phase.confirming);

      await _confirmUpload(
        idToken: idToken,
        uploadSessionId: session.uploadSessionId,
        fileName: fileName,
        fileSize: fileSize,
      );

      progressNotifier.value = const _UploadProgress(phase: _Phase.done);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSuccess(context, fileName);
    } on FirebaseAuthException catch (e, st) {
      _logger.e('Firebase auth error during upload', error: e, stackTrace: st);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showError(context, 'Authentication error: ${e.message ?? 'please sign in again'}');
    } on _UploadException catch (e) {
      _logger.e('Upload failed: ${e.message}');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showError(context, e.message);
    } catch (e, st) {
      _logger.e('Unexpected upload error', error: e, stackTrace: st);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showError(context, 'Upload failed. Please try again.');
    }
  }

  // -------------------------------------------------------------------------
  // Step helpers
  // -------------------------------------------------------------------------

  Future<PlatformFile?> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: false,
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    if (file.path == null) return null;
    return file;
  }

  String? _validate(String fileName, int fileSize, String? mimeType) {
    if (fileSize > _maxFileSizeBytes) {
      final mb = (fileSize / (1024 * 1024)).toStringAsFixed(1);
      return 'File too large ($mb MB). Maximum allowed size is 20 MB.';
    }
    if (mimeType == null || !_allowedMimeTypes.contains(mimeType)) {
      return 'Unsupported file type. Please upload PDF, JPG, PNG, or DOCX.';
    }
    return null;
  }

  Future<String> _getFirebaseToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const _UploadException('You are not signed in. Please sign in and try again.');
    }
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw const _UploadException('Could not retrieve authentication token. Please sign in again.');
    }
    return token;
  }

  Future<_UploadSession> _requestUploadSession({
    required String idToken,
    required String fileName,
    required int fileSize,
    required String mimeType,
  }) async {
    try {
      final response = await _dioClient.post(
        path: ApiConstants.uploadRequestPath,
        data: {
          'fileName': fileName,
          'fileSize': fileSize,
          'mimeType': mimeType,
        },
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const _UploadException('Unexpected response from upload service.');
      }

      final uploadUrl = data['uploadUrl']?.toString();
      final uploadSessionId = data['uploadSessionId']?.toString();

      if (uploadUrl == null || uploadUrl.isEmpty) {
        throw const _UploadException('Upload service did not return a valid upload URL.');
      }
      if (uploadSessionId == null || uploadSessionId.isEmpty) {
        throw const _UploadException('Upload service did not return a session ID.');
      }

      return _UploadSession(uploadUrl: uploadUrl, uploadSessionId: uploadSessionId);
    } on DioException catch (e) {
      final msg = _extractBackendMessage(e) ?? 'Failed to request upload URL.';
      throw _UploadException(msg);
    }
  }

  Future<void> _uploadToStorage({
    required String uploadUrl,
    required String filePath,
    required String mimeType,
    required int fileSize,
    required void Function(double percent) onProgress,
  }) async {
    // Use a plain Dio instance — the upload URL is an external signed URL
    // (e.g. Google Cloud Storage) and must not carry app auth headers.
    final dio = Dio()
      ..options.sendTimeout = _uploadTimeout
      ..options.receiveTimeout = _uploadTimeout
      ..options.connectTimeout = _uploadTimeout;

    final file = File(filePath);
    if (!await file.exists()) {
      throw const _UploadException('Selected file no longer exists on device.');
    }

    DioException? lastError;

    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final bytes = await file.readAsBytes();

        await dio.put<dynamic>(
          uploadUrl,
          data: bytes,
          options: Options(
            headers: {
              'Content-Type': mimeType,
              'Content-Length': fileSize,
            },
            sendTimeout: _uploadTimeout,
            receiveTimeout: _uploadTimeout,
          ),
          onSendProgress: (sent, total) {
            if (total > 0) {
              onProgress((sent / total * 100).clamp(0.0, 100.0));
            }
          },
        );

        return; // success
      } on DioException catch (e, st) {
        _logger.w('Upload attempt $attempt/$_maxRetries failed', error: e, stackTrace: st);
        lastError = e;
        if (attempt < _maxRetries) {
          await Future<void>.delayed(Duration(seconds: attempt * 2));
        }
      }
    }

    final msg = lastError != null
        ? (_extractBackendMessage(lastError) ?? 'File upload failed after $_maxRetries attempts.')
        : 'File upload failed after $_maxRetries attempts.';
    throw _UploadException(msg);
  }

  Future<void> _confirmUpload({
    required String idToken,
    required String uploadSessionId,
    required String fileName,
    required int fileSize,
  }) async {
    try {
      await _dioClient.post(
        path: ApiConstants.uploadCompletePath,
        data: {
          'uploadSessionId': uploadSessionId,
          'fileName': fileName,
          'fileSize': fileSize,
        },
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );
    } on DioException catch (e) {
      final msg = _extractBackendMessage(e) ?? 'Failed to confirm upload with server.';
      throw _UploadException(msg);
    }
  }

  // -------------------------------------------------------------------------
  // UI helpers
  // -------------------------------------------------------------------------

  void _showProgressSnackBar(
    BuildContext context,
    String fileName,
    int fileSize,
    ValueNotifier<_UploadProgress> notifier,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(minutes: 10),
        behavior: SnackBarBehavior.floating,
        content: ValueListenableBuilder<_UploadProgress>(
          valueListenable: notifier,
          builder: (context, progress, child) {
            return _UploadProgressContent(
              fileName: fileName,
              fileSize: fileSize,
              progress: progress,
            );
          },
        ),
      ),
    );
  }

  void _showSuccess(BuildContext context, String fileName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF22A05B),
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '"$fileName" uploaded successfully.',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFC32222),
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Utilities
  // -------------------------------------------------------------------------

  String? _mimeTypeFor(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    return const <String, String>{
      'pdf': 'application/pdf',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    }[ext];
  }

  String? _extractBackendMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ?? data['error']?.toString();
    }
    return e.message;
  }
}

// ---------------------------------------------------------------------------
// Internal models
// ---------------------------------------------------------------------------

class _UploadSession {
  const _UploadSession({required this.uploadUrl, required this.uploadSessionId});
  final String uploadUrl;
  final String uploadSessionId;
}

enum _Phase { requestingUrl, uploading, confirming, done }

class _UploadProgress {
  const _UploadProgress({required this.phase, this.percent = 0});
  final _Phase phase;
  final double percent;
}

class _UploadException implements Exception {
  const _UploadException(this.message);
  final String message;
}

// ---------------------------------------------------------------------------
// Progress snack-bar widget
// ---------------------------------------------------------------------------

class _UploadProgressContent extends StatelessWidget {
  const _UploadProgressContent({
    required this.fileName,
    required this.fileSize,
    required this.progress,
  });

  final String fileName;
  final int fileSize;
  final _UploadProgress progress;

  String get _phaseLabel {
    return switch (progress.phase) {
      _Phase.requestingUrl => 'Preparing upload…',
      _Phase.uploading => 'Uploading… ${progress.percent.toStringAsFixed(0)}%',
      _Phase.confirming => 'Confirming…',
      _Phase.done => 'Done',
    };
  }

  String get _formattedSize {
    if (fileSize >= 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize / 1024).toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = progress.phase == _Phase.uploading;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.upload_file_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              _formattedSize,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: isUploading ? progress.percent / 100 : null,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _phaseLabel,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
