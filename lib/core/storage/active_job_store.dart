import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A print order the user has started and taken to checkout. Persisted locally
/// so it can be surfaced as an "Active Job" on the home screen and reopened at
/// the checkout step. (The backend has no "list my orders" endpoint yet.)
class ActiveJob {
  const ActiveJob({
    required this.orderId,
    required this.title,
    required this.fileCount,
    required this.status,
    required this.createdAtMs,
    this.address,
  });

  final String orderId;
  final String title;
  final int fileCount;
  final String status;
  final String? address;
  final int createdAtMs;

  ActiveJob copyWith({String? status, String? address}) {
    return ActiveJob(
      orderId: orderId,
      title: title,
      fileCount: fileCount,
      status: status ?? this.status,
      address: address ?? this.address,
      createdAtMs: createdAtMs,
    );
  }

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'title': title,
    'fileCount': fileCount,
    'status': status,
    'address': address,
    'createdAtMs': createdAtMs,
  };

  factory ActiveJob.fromJson(Map<String, dynamic> json) => ActiveJob(
    orderId: json['orderId']?.toString() ?? '',
    title: json['title']?.toString() ?? 'Print order',
    fileCount: (json['fileCount'] as num?)?.toInt() ?? 1,
    status: json['status']?.toString() ?? 'Awaiting payment',
    address: json['address']?.toString(),
    createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
  );
}

class ActiveJobStore {
  ActiveJobStore({required SharedPreferences preferences})
    : _preferences = preferences;

  static const String _key = 'active_jobs';

  final SharedPreferences _preferences;

  /// Active jobs, newest first.
  List<ActiveJob> getJobs() {
    final raw = _preferences.getString(_key);
    if (raw == null || raw.isEmpty) return const <ActiveJob>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <ActiveJob>[];
      final jobs = decoded
          .whereType<Map<String, dynamic>>()
          .map(ActiveJob.fromJson)
          .where((j) => j.orderId.isNotEmpty)
          .toList();
      jobs.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
      return jobs;
    } catch (_) {
      return const <ActiveJob>[];
    }
  }

  /// Insert or update a job, keyed by [ActiveJob.orderId].
  Future<void> upsert(ActiveJob job) async {
    final jobs = getJobs().toList()
      ..removeWhere((j) => j.orderId == job.orderId)
      ..add(job);
    await _save(jobs);
  }

  Future<void> remove(String orderId) async {
    final jobs = getJobs().where((j) => j.orderId != orderId).toList();
    await _save(jobs);
  }

  Future<void> clear() => _preferences.remove(_key);

  Future<void> _save(List<ActiveJob> jobs) async {
    final encoded = jsonEncode(jobs.map((j) => j.toJson()).toList());
    await _preferences.setString(_key, encoded);
  }
}
