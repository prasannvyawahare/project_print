import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../data/datasources/drive_upload_data_source.dart';
import '../../data/datasources/order_remote_data_source.dart';

enum FileUploadStatus { pending, uploading, success, failed }

class FileUploadTask {
  FileUploadTask({
    required this.itemId,
    required this.uploadSessionId,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.sessionUrl,
  });

  final String itemId;
  final String uploadSessionId;
  final String fileName;
  final String filePath;
  final int fileSize;
  final String sessionUrl;

  FileUploadStatus status = FileUploadStatus.pending;
  String? error;

  /// Fractional upload progress (0.0–1.0) of the Drive PUT, used to render a
  /// determinate progress bar with a live percentage.
  double progress = 0;

  /// True once the Drive PUT has succeeded, so a retry only re-runs the
  /// `upload/complete` call instead of re-uploading the bytes.
  bool driveUploaded = false;

  /// The metadata Drive returned from the PUT (file id, name, mimeType),
  /// available for logging or future use after a successful upload.
  DriveUploadResult? driveResult;
}

/// Drives parallel uploads of the order's files to their Drive session URLs and
/// exposes per-file status so the Review screen can show progress + retry.
class FileUploadController extends ChangeNotifier {
  FileUploadController({
    required DriveUploadDataSource dataSource,
    required OrderRemoteDataSource orderDataSource,
    required List<FileUploadTask> tasks,
    this.onAllUploadsComplete,
  }) : _dataSource = dataSource,
       _orderDataSource = orderDataSource,
       _tasks = tasks;

  final DriveUploadDataSource _dataSource;
  final OrderRemoteDataSource _orderDataSource;
  final List<FileUploadTask> _tasks;

  /// Called once after every file's `upload/complete` has succeeded, so the
  /// caller can refresh the finalized order (e.g. fetch `order/order-summary`).
  final VoidCallback? onAllUploadsComplete;

  /// Guards [onAllUploadsComplete] so it fires only on the first time all
  /// uploads reach success (not again on a later retry of a failed file).
  bool _completionNotified = false;

  List<FileUploadTask> get tasks => List.unmodifiable(_tasks);

  bool get isUploading =>
      _tasks.any((t) => t.status == FileUploadStatus.uploading);

  bool get hasFailures =>
      _tasks.any((t) => t.status == FileUploadStatus.failed);

  bool get allSucceeded =>
      _tasks.isNotEmpty &&
      _tasks.every((t) => t.status == FileUploadStatus.success);

  int get successCount =>
      _tasks.where((t) => t.status == FileUploadStatus.success).length;

  /// Uploads every not-yet-successful file in parallel.
  Future<void> startAll() {
    final pending = _tasks.where(
      (t) => t.status != FileUploadStatus.success,
    );
    return Future.wait(pending.map(_upload));
  }

  /// Re-attempts a single failed file.
  Future<void> retry(FileUploadTask task) => _upload(task);

  Future<void> _upload(FileUploadTask task) async {
    task.status = FileUploadStatus.uploading;
    task.error = null;
    // Keep the already-uploaded fraction (1.0) on a finalize-only retry;
    // otherwise restart the bar from zero.
    task.progress = task.driveUploaded ? 1 : 0;
    notifyListeners();

    try {
      // 1) Upload the bytes to the Drive resumable session (skip if a previous
      //    attempt already pushed the file and only the finalize step failed).
      if (!task.driveUploaded) {
        task.driveResult = await _dataSource.uploadFile(
          sessionUrl: task.sessionUrl,
          file: File(task.filePath),
          mimeType: _mimeTypeFor(task.fileName),
          onProgress: (progress) {
            task.progress = progress;
            notifyListeners();
          },
        );
        task.driveUploaded = true;
        task.progress = 1;
        notifyListeners();
      }

      // 2) Tell the backend this file is done so it can finalize the item.
      //    itemId comes from order/create; driveFileId is the id Drive
      //    returned from the PUT response.
      await _orderDataSource.completeUpload(
        itemId: task.itemId,
        driveFileId: task.driveResult?.id ?? '',
      );

      task.status = FileUploadStatus.success;
    } catch (error) {
      task.status = FileUploadStatus.failed;
      task.error = error.toString();
    }
    notifyListeners();

    // Once every file's upload/complete has gone through, let the caller fetch
    // the finalized order summary. Fires only once.
    if (!_completionNotified && allSucceeded) {
      _completionNotified = true;
      onAllUploadsComplete?.call();
    }
  }

  static String _mimeTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    final dot = lower.lastIndexOf('.');
    final ext = dot == -1 ? '' : lower.substring(dot + 1);
    return switch (ext) {
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };
  }
}
